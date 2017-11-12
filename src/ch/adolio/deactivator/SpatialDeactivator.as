// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017 Aurelien Da Campo, All Rights Reserved.
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
		// Chunks
		private var _chunkWidth:Number = 128;
		private var _chunkHeight:Number = 128;
		private var _chunks:Dictionary = new Dictionary();
		private var _activeChunks:Vector.<SpatialChunk> = new Vector.<SpatialChunk>();
		
		// Active area
		private var _activeArea:Rectangle;
		private var _activeAreaUpdated:Boolean = false;
		private var _activeAreaUpdateCooldown:Number = 1.0 / 10.0; // sec
		private var _activeAreaTimeSinceLastUpdate:Number = Number.MAX_VALUE; // sec, make sure that the first update happens right away.
		
		// registered elements
		private var _elements:Vector.<SpatialElement> = new Vector.<SpatialElement>();
		
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
			if(debugRendering) {
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
			
			// Update chunks directly if cooldown is over
			if (_activeAreaTimeSinceLastUpdate >= _activeAreaUpdateCooldown)
				updateChunksActivity();
		}
		
		public function clear():void
		{
			// clear elements
			_elements.slice(0, _elements.length);
			purge();
			
			// clear chunks
			_activeChunks.slice(0, _activeChunks.length);
			for (var key:String in _chunks) {
				var chunk:SpatialChunk = _chunks[key];
				chunk.destroy();
				delete _chunks[key];
			}
			
			// clear active area
			_activeArea.setTo(0, 0, 1, 1);
			_activeAreaUpdated = false;
			_activeAreaTimeSinceLastUpdate = Number.MAX_VALUE; // make sure that the next update happens right away.
			
			// update debug
			updateActiveAreaDebugQuad();
		}
		
		public function destroy():void
		{
			clear();
			
			if (_debugSprite) {
				_activeAreaDebugQuad.dispose();
				_debugSprite.dispose();
			}
			
			// Nullify references
			_activeArea = null;
			_activeChunks = null;
			_chunks = null;
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
		
		public function get activeAreaUpdateCooldown():Number 
		{
			return _activeAreaUpdateCooldown;
		}
		
		public function set activeAreaUpdateCooldown(value:Number):void
		{
			_activeAreaUpdateCooldown = value;
		}
		
		/**
		 * This method is automatically called during advanceTime (IAnimatable) 
		 * when the active area has been updated and the refresh cooldown is over.
		 * 
		 * Anyway sometimes it could be useful to request a manual update to force the deactivator
		 * to refresh the connected chunks that's why the method has a public scope.
		 */
		public function updateChunksActivity():void
		{
			// Reset invalidation & cooldown
			_activeAreaTimeSinceLastUpdate = 0;
			_activeAreaUpdated = false;
			
			// Update debug
			updateActiveAreaDebugQuad();
			
			// Get the chunks touched by the new active area
			_activeChunks = getChunksTouchedBy(_activeArea, _activeChunks);
			
			// Find (recursively) all the connected chunks
			for (var i:int = 0; i < _activeChunks.length; ++i)
			{
				_activeChunks[i].fillListWithLinkedChunks(_activeChunks);
			}
			
			// Update only the old & new chunk activity
			for each (var chunk:SpatialChunk in _chunks)
			{
				var inNewActiveChunks:Boolean = _activeChunks.indexOf(chunk) != -1;
				
				// Activate chunks not yet active
				if (inNewActiveChunks && !chunk.isActive)
				{
					chunk.activate(false);
				}
				// Deactivate chunks not anymore active
				else if (!inNewActiveChunks && chunk.isActive)
				{
					chunk.deactivate(false);
				}
			}
		}
		
		// --------------------------------------------------------------------
		// -- Overrided methods
		// --------------------------------------------------------------------
		
		override public function advanceTime(time:Number):void
		{
			_activeAreaTimeSinceLastUpdate += time;
			
			if (_activeAreaUpdated && _activeAreaTimeSinceLastUpdate >= _activeAreaUpdateCooldown)
				updateChunksActivity();
			
			super.advanceTime(time);
		}
		
		// --------------------------------------------------------------------
		// -- Private / internal methods
		// --------------------------------------------------------------------
		
		private function updateActiveAreaDebugQuad():void
		{
			if(_activeAreaDebugQuad) {
				_activeAreaDebugQuad.x = _activeArea.x;
				_activeAreaDebugQuad.y = _activeArea.y;
				_activeAreaDebugQuad.width = _activeArea.width;
				_activeAreaDebugQuad.height = _activeArea.height;
			}
		}
		
		private static function getChunkId(ix:int, iy:int):String
		{
			// According to http://jacksondunstan.com/articles/669, String(x) is the most efficient way to cast to String.
			return String(ix) + "_" + String(iy);
		}
		
		private function createChunk(chunkX:int, chunkY:int):SpatialChunk
		{
			var chunk:SpatialChunk = new SpatialChunk(this, chunkX, chunkY, _debugSprite != null);
			_chunks[getChunkId(chunkX, chunkY)] = chunk;
			if(_debugSprite && chunk.debugQuad)
				_debugSprite.addChildAt(chunk.debugQuad, 0);
			return chunk;
		}
		
		internal function addElement(element:SpatialElement):void
		{
			_elements.push(element);
			add(element);
		}
		
		internal function removeElement(element:SpatialElement):void
		{
			remove(element);
			_elements.removeAt(_elements.indexOf(element));
		}
		
		internal function getChunksTouchedBy(aabb:Rectangle, result:Vector.<SpatialChunk> = null):Vector.<SpatialChunk>
		{
			// Initialize resulting list of chunks
			if (result)
				result.length = 0;
			else
				result = new Vector.<SpatialChunk>();
			
			// Find min/max index on each axis
			var xmin:int = Math.floor(aabb.left / _chunkWidth);
			var xmax:int = Math.ceil(aabb.right / _chunkWidth);
			var ymin:int = Math.floor(aabb.top / _chunkHeight);
			var ymax:int = Math.ceil(aabb.bottom / _chunkHeight);
			
			// Generate the list of chunks
			var chunk:SpatialChunk;
			for (var ix:int = xmin; ix < xmax; ++ix)
			{
				for (var iy:int = ymin; iy < ymax; ++iy)
				{
					chunk = _chunks[getChunkId(ix, iy)];
					
					if (!chunk)
						chunk = createChunk(ix, iy);
					
					result.push(chunk);
				}
			}
			
			return result;
		}
	}
}