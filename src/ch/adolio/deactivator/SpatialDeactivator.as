// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017-2021 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.deactivator
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.animation.Juggler;
	import starling.display.Quad;
	import starling.display.Sprite;

	/**
	 * The spatial deactivation manager.
	 *
	 * It controls activation & deactivation of the spatial elements if they are
	 * in contact (directly or indirectly) with the active area.
	 *
	 * The active area (usually a camera view) represents the area in which spatial
	 * elements must be activated. To update the activeArea, call the 'updateActiveArea' setter.
	 * For optimization reasons, you can add an update cooldown to avoid updating the active area
	 * at each frame. Call the 'activeAreaUpdateCooldown' setter to configure the cooldown time (in seconds).
	 * Note that the default cooldown is not 0.
	 *
	 * The space managed by the spatial deactivator is divided into orthonormed chunks (or cells).
	 * An element which is touching an active chunk will forward the activation to
	 * all the touched chunks which will result of the activation of all the elements
	 * touched by the chunks and so on.
	 */
	public class SpatialDeactivator extends Juggler
	{
		// version
		public static const VERSION:String = "0.3";

		// State
		private var _isEnable:Boolean = true;

		// Chunks
		private var _chunkWidth:Number = 128;
		private var _chunkHeight:Number = 128;
		private var _chunksX:Dictionary = new Dictionary(); // Dictionary (X) of Dictionaries (Y)
		private var _chunksCount:int = 0;
		private var _chunksRange:Rectangle = new Rectangle();
		private var _activeChunks:Vector.<SpatialChunk> = new Vector.<SpatialChunk>();

		// links to the active area
		private var _linkedChunks:Vector.<SpatialChunk> = new Vector.<SpatialChunk>();
		private var _linkStamp:uint = 0;

		// Active area
		private var _activeArea:Rectangle;
		private var _activeAreaChunksRange:Rectangle = new Rectangle();
		private var _activeAreaUpdated:Boolean = false;
		private var _activeAreaUpdateCooldown:Number = 1.0 / 10.0; // sec
		private var _activeAreaTimeSinceLastUpdate:Number = Number.MAX_VALUE; // sec, make sure that the first update happens right away.

		// registered elements
		private var _elements:Vector.<SpatialElement> = new Vector.<SpatialElement>();

		// activity propagation
		private var _chunksToActivate:Vector.<SpatialChunk> = new Vector.<SpatialChunk>();
		private var _isPropagatingActivity:Boolean = false;

		// activity changes dispatch
		private var _elementsWithPendingActivityChange:Vector.<SpatialElement> = new Vector.<SpatialElement>();
		private var _isDispatchingActivityChanges:Boolean = false;

		// Debug
		private var _debugSprite:Sprite;
		private var _activeAreaDebugQuad:Quad;

		public function SpatialDeactivator(chunkWidth:Number, chunkHeight:Number, debugRendering:Boolean = false)
		{
			// Setup core
			_activeArea = new Rectangle();
			_chunkWidth = chunkWidth;
			_chunkHeight = chunkHeight;

			// Setup debug
			if (debugRendering)
			{
				_debugSprite = new Sprite();
				_activeAreaDebugQuad = new Quad(1, 1, 0xffffff);
				_activeAreaDebugQuad.alpha = 0.3;
				_debugSprite.addChild(_activeAreaDebugQuad);
			}
		}

		// --------------------------------------------------------------------
		// -- Public API
		// --------------------------------------------------------------------

		public function updateActiveArea(area:Rectangle):void
		{
			// Update active area
			_activeArea.setTo(area.x, area.y, area.width, area.height);
			_activeAreaUpdated = true;

			// update debugging when deactivator is disabled
			if (!_isEnable)
				updateActiveAreaDebugQuad();

			// Update chunks directly if cooldown is over
			if (_activeAreaTimeSinceLastUpdate >= _activeAreaUpdateCooldown)
				refreshChunksActivity();

			dispatchActivityChanges();
		}

		/**
		 * Destroys every remaining element & every chunk, and resets the active area.
		 *
		 * Remaining elements are destroyed without triggering their activity callback. Calling their
		 * <code>destroy()</code> method afterwards is safe, but they must not be used in any other way.
		 */
		public function clear():void
		{
			// release elements before chunks, each element unregisters itself from its covered chunks & from the list
			while (_elements.length > 0)
				_elements[_elements.length - 1].release();

			purge();

			// clear chunks
			_activeChunks.length = 0;
			_linkedChunks.length = 0;
			for (var xKey:int in _chunksX)
			{
				var chunksY:Dictionary = _chunksX[xKey];
				for (var yKey:int in chunksY)
				{
					var chunk:SpatialChunk = chunksY[yKey];
					chunk.destroy();
					delete chunksY[yKey];
				}

				delete _chunksX[xKey];
			}

			_chunksCount = 0;

			// clear active area
			_activeArea.setTo(0, 0, 1, 1);
			_activeAreaChunksRange.setEmpty();
			_activeAreaUpdated = false;
			_activeAreaTimeSinceLastUpdate = Number.MAX_VALUE; // make sure that the next update happens right away.

			// update debug
			updateActiveAreaDebugQuad();
		}

		public function destroy():void
		{
			clear();

			if (_debugSprite)
			{
				_activeAreaDebugQuad.dispose();
				_debugSprite.dispose();
			}

			// Nullify references
			_activeArea = null;
			_activeChunks = null;
			_linkedChunks = null;
			_chunksX = null;
			_activeAreaDebugQuad = null;
			_debugSprite = null;
		}

		public function get chunkWidth():Number
		{
			return _chunkWidth;
		}

		public function get chunkHeight():Number
		{
			return _chunkHeight;
		}

		public function get debugSprite():Sprite
		{
			return _debugSprite;
		}

		/**
		 * Number of allocated chunks, for monitoring purposes.
		 *
		 * Only the chunks containing elements are kept, plus the empty ones still active until the next refresh of the
		 * chunks activity.
		 */
		public function get chunksCount():int
		{
			return _chunksCount;
		}

		public function get activeAreaUpdateCooldown():Number
		{
			return _activeAreaUpdateCooldown;
		}

		public function set activeAreaUpdateCooldown(value:Number):void
		{
			_activeAreaUpdateCooldown = value;
		}

		public function get isEnable():Boolean
		{
			return _isEnable;
		}

		public function set isEnable(value:Boolean):void
		{
			_isEnable = value;

			if (_isEnable)
				refreshAll();
			else
				activateAll();

			dispatchActivityChanges();
		}

		/**
		 * Recomputes the chunk memberships & the activity of every element, which are frozen while disabled.
		 */
		private function refreshAll():void
		{
			var ei:int;

			// move elements into their current chunks first, so that the activity propagation follows their current position
			for (ei = 0; ei < _elements.length; ei++)
				_elements[ei].updateCoveredChunks();

			refreshChunksActivity();

			// the refresh only updates the elements of chunks whose activity changed, so elements left active by the
			// disabled state in no chunk or in chunks that were never active must be checked individually
			for (ei = 0; ei < _elements.length; ei++)
				_elements[ei].checkActivityFromCoveredChunks(false);
		}

		private function activateAll():void
		{
			// Activate all chunks
			for each (var chunksY:Dictionary in _chunksX)
			{
				for each (var chunk:SpatialChunk in chunksY)
				{
					activateChunk(chunk, false);
				}
			}

			// Activate all elements
			for (var ei:int = 0; ei < _elements.length; ei++)
			{
				_elements[ei].activate(false);
			}
		}

		/**
		 * This method is automatically called during advanceTime (IAnimatable)
		 * when the active area has been updated and the refresh cooldown is over.
		 *
		 * Anyway sometimes it could be useful to request a manual update to force the deactivator
		 * to refresh the connected chunks that's why the method has a public scope.
		 *
		 * Does nothing while the deactivator is disabled.
		 */
		public function updateChunksActivity():void
		{
			refreshChunksActivity();
			dispatchActivityChanges();
		}

		// --------------------------------------------------------------------
		// -- Overrided methods
		// --------------------------------------------------------------------

		override public function advanceTime(time:Number):void
		{
			// Do not process when not enable
			if (!_isEnable)
				return;

			_activeAreaTimeSinceLastUpdate += time;

			if (_activeAreaUpdated && _activeAreaTimeSinceLastUpdate >= _activeAreaUpdateCooldown)
			{
				refreshChunksActivity();
				dispatchActivityChanges();
			}

			super.advanceTime(time);
		}

		// --------------------------------------------------------------------
		// -- Private / internal methods
		// --------------------------------------------------------------------

		/**
		 * Recomputes the activity of the chunks & elements without dispatching activity changes.
		 *
		 * Internal code must call this method instead of <code>updateChunksActivity()</code>, since it may
		 * run while chunks or elements are being iterated.
		 *
		 * Does nothing while disabled: everything stays active, and a pending active area update is kept
		 * for when the deactivator is enabled again.
		 */
		internal function refreshChunksActivity():void
		{
			if (!_isEnable)
				return;

			// Reset invalidation & cooldown
			_activeAreaTimeSinceLastUpdate = 0;
			_activeAreaUpdated = false;

			// Update debug
			updateActiveAreaDebugQuad();

			// Get the existing chunks touched by the new active area, stamped so that a linked chunk is recognized in
			// constant time. Missing chunks contain no element & are activated when created.
			_linkStamp++;
			computeChunksRange(_activeArea, _activeAreaChunksRange);
			getChunksTouchedBy(_activeArea, _linkedChunks, false);
			var i:int;
			for (i = 0; i < _linkedChunks.length; ++i)
				_linkedChunks[i].linkStamp = _linkStamp;

			// Find all the connected chunks, the list growing while being walked
			for (i = 0; i < _linkedChunks.length; ++i)
				_linkedChunks[i].fillListWithLinkedChunks(_linkedChunks, _linkStamp);

			// Activate linked chunks not yet active first, so that an element covering both a newly active chunk & a
			// newly inactive one stays active instead of being deactivated then reactivated
			for (i = 0; i < _linkedChunks.length; ++i)
				activateChunk(_linkedChunks[i], false);

			// Deactivate active chunks not linked anymore
			for (i = 0; i < _activeChunks.length; ++i)
			{
				var chunk:SpatialChunk = _activeChunks[i];
				if (chunk.linkStamp != _linkStamp)
				{
					chunk.deactivate(false);
					freeChunkIfUnused(chunk);
				}
			}

			// the linked chunks are now exactly the active ones
			var previousActiveChunks:Vector.<SpatialChunk> = _activeChunks;
			_activeChunks = _linkedChunks;
			_linkedChunks = previousActiveChunks;
			_linkedChunks.length = 0;
		}

		/**
		 * Activates the chunk & records it in the active chunks.
		 *
		 * Every chunk activation must go through this method: chunks are only deactivated by
		 * <code>refreshChunksActivity()</code>, which only visits the recorded active chunks to find the ones to deactivate.
		 */
		private function activateChunk(chunk:SpatialChunk, propagate:Boolean):void
		{
			if (chunk.isActive)
				return;

			_activeChunks.push(chunk);
			chunk.activate(propagate);
		}

		/**
		 * Activates the chunk & propagates the activity through the activity bridges it contains.
		 *
		 * The propagation is iterative, so that long chains of bridges cannot overflow the stack: chunks reached while
		 * propagating are queued & activated by the ongoing loop.
		 */
		internal function activateChunkWithPropagation(chunk:SpatialChunk):void
		{
			if (chunk.isActive)
				return;

			_chunksToActivate.push(chunk);

			if (_isPropagatingActivity)
				return;

			_isPropagatingActivity = true;
			while (_chunksToActivate.length > 0)
				activateChunk(_chunksToActivate.pop(), true);

			_isPropagatingActivity = false;
		}

		internal function queueActivityChange(element:SpatialElement):void
		{
			_elementsWithPendingActivityChange.push(element);
		}

		/**
		 * Triggers the activity callbacks of the elements whose activity changed since the last dispatch.
		 *
		 * Must only be called at the end of a public entry point, once no chunk or element is being iterated,
		 * so that callbacks can safely create, destroy or move elements.
		 */
		internal function dispatchActivityChanges():void
		{
			// changes queued by a callback are dispatched by the ongoing loop
			if (_isDispatchingActivityChanges)
				return;

			_isDispatchingActivityChanges = true;
			var dispatchedCount:int = 0;
			try
			{
				while (dispatchedCount < _elementsWithPendingActivityChange.length)
					_elementsWithPendingActivityChange[dispatchedCount++].dispatchActivityChange();
			}
			finally
			{
				// only drop dispatched changes, so that a throwing callback doesn't discard the following ones
				_elementsWithPendingActivityChange.splice(0, dispatchedCount);
				_isDispatchingActivityChanges = false;
			}
		}

		private function updateActiveAreaDebugQuad():void
		{
			if(_activeAreaDebugQuad) {
				_activeAreaDebugQuad.x = _activeArea.x;
				_activeAreaDebugQuad.y = _activeArea.y;
				_activeAreaDebugQuad.width = _activeArea.width;
				_activeAreaDebugQuad.height = _activeArea.height;
			}
		}

		private function createChunk(chunkX:int, chunkY:int):SpatialChunk
		{
			var chunk:SpatialChunk = new SpatialChunk(this, chunkX, chunkY, _debugSprite != null);
			setChunk(chunkX, chunkY, chunk);
			_chunksCount++;
			if(_debugSprite && chunk.debugQuad)
				_debugSprite.addChildAt(chunk.debugQuad, 0);

			// chunks are only created for elements, so the ones over the active area, or created while disabled, must
			// start active for the entering elements to be activated
			if (!_isEnable || isChunkOverActiveArea(chunk))
				activateChunk(chunk, false);

			return chunk;
		}

		/**
		 * Tells if the chunk is touched by the active area, as of the last refresh of the chunks activity.
		 *
		 * Such a chunk is active whatever the elements it contains.
		 */
		internal function isChunkOverActiveArea(chunk:SpatialChunk):Boolean
		{
			return _activeAreaChunksRange.contains(chunk.gridX, chunk.gridY);
		}

		/**
		 * Frees the chunk if it is inactive & contains no element.
		 *
		 * A freed chunk is created again when an element enters it, with the activity it would have had.
		 */
		internal function freeChunkIfUnused(chunk:SpatialChunk):void
		{
			// already freed
			var chunksY:Dictionary = _chunksX[chunk.gridX];
			if (!chunksY || chunksY[chunk.gridY] != chunk)
				return;

			if (chunk.isActive || chunk.elements.length > 0)
				return;

			delete chunksY[chunk.gridY];
			chunk.destroy();
			_chunksCount--;

			// drop the column once its last chunk is freed
			for (var yKey:* in chunksY)
				return;

			delete _chunksX[chunk.gridX];
		}

		internal function addElement(element:SpatialElement):void
		{
			_elements.push(element);
			add(element);
		}

		internal function removeElement(element:SpatialElement):void
		{
			remove(element);

			var index:int = _elements.indexOf(element);
			if (index != -1)
				_elements.removeAt(index);
		}

		/**
		 * Fills the output with the chunks touched by the AABB.
		 *
		 * @param createMissingChunks creates the touched chunks not existing yet, otherwise they are skipped
		 */
		internal function getChunksTouchedBy(aabb:Rectangle, output:Vector.<SpatialChunk>, createMissingChunks:Boolean = true):Vector.<SpatialChunk>
		{
			// Clear output
			output.length = 0;

			// Find min/max index on each axis
			computeChunksRange(aabb, _chunksRange);
			var xmin:int = _chunksRange.left;
			var xmax:int = _chunksRange.right;
			var ymin:int = _chunksRange.top;
			var ymax:int = _chunksRange.bottom;

			// Generate the list of chunks
			var chunk:SpatialChunk;
			for (var ix:int = xmin; ix < xmax; ++ix)
			{
				var chunksY:Dictionary = _chunksX[ix];

				// Create missing dimension Dictionary
				if (!chunksY)
				{
					if (!createMissingChunks)
						continue;

					_chunksX[ix] = chunksY = new Dictionary();
				}

				for (var iy:int = ymin; iy < ymax; ++iy)
				{
					chunk = chunksY[iy];

					if (!chunk)
					{
						if (!createMissingChunks)
							continue;

						chunk = createChunk(ix, iy);
					}

					output.push(chunk);
				}
			}

			return output;
		}

		/**
		 * Computes the range of chunk indices touched by the AABB, the right & bottom bounds being exclusive.
		 */
		private function computeChunksRange(aabb:Rectangle, output:Rectangle):void
		{
			var xmin:int = Math.floor(aabb.left / _chunkWidth);
			var xmax:int = Math.ceil(aabb.right / _chunkWidth);
			var ymin:int = Math.floor(aabb.top / _chunkHeight);
			var ymax:int = Math.ceil(aabb.bottom / _chunkHeight);
			output.setTo(xmin, ymin, xmax - xmin, ymax - ymin);
		}

		internal function getChunk(x:int, y:int):SpatialChunk
		{
			var chunksY:Dictionary = _chunksX[x];
			if (chunksY != null)
				return chunksY[y];

			return null;
		}

		internal function setChunk(x:int, y:int, chunk:SpatialChunk):void
		{
			var chunksY:Dictionary = _chunksX[x];
			if (chunksY == null)
				_chunksX[x] = chunksY = new Dictionary();

			chunksY[y] = chunk;
		}
	}
}