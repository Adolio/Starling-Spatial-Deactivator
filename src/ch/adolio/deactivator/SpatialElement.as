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
	import starling.display.Quad;

	/**
	 * A Spatial element represents a user object in the context of the Spatial Deactivator.
	 *
	 * It can be active or inactive. The activity of the element is managed internally and
	 * cannot be changed manually (it could break the consistency of the context).
	 * The function field 'activityChangedCallback', if defined, will let you know when the
	 * activity has been updated.
	 * Callbacks are triggered once the whole context is up to date, before the call that changed the activity
	 * returns, so they can safely create, destroy or move elements. An activity changed & restored during the
	 * same update is not notified.
	 *
	 * The method 'updateAABB' must be called each time your object has changed (position and/or size).
	 * For optimization reasons, you can add an update cooldown to avoid updating the element and
	 * its context at each frame. Call the 'updateCooldown' setter to configure the cooldown time (in seconds).
	 * Note that the default cooldown is not equals to 0.
	 */
	public class SpatialElement
	{
		// covered chunks changes
		internal static const ENTERED_CHUNK:int = 1;
		internal static const LEFT_CHUNK:int = 2;
		internal static const LEFT_CHUNK_OUT_OF_ACTIVE_AREA:int = 4;

		// Spatial deactivation
		private var _deactivator:SpatialDeactivator;
		private var _aabb:Rectangle = new Rectangle();
		private var _newCoveredChunks:Vector.<SpatialChunk> = new Vector.<SpatialChunk>();
		private var _isActive:Boolean = false;
		private var _isActivityBridge:Boolean = true; // A bridge propagates activity over chunks
		private var _coveredChunks:Vector.<SpatialChunk> = new Vector.<SpatialChunk>();

		// Update management
		private var _hasAABB:Boolean = false;
		private var _aabbUpdated:Boolean = false;
		private var _timeSinceLastUpdate:Number = Number.MAX_VALUE; // sec, make sure that the first update happens right away.
		private var _updateCooldown:Number = 1.0 / 10.0; // sec

		// Callback
		private var _activityChangedCallback:Function;
		private var _isActivityChangePending:Boolean = false;
		private var _wasActiveNotified:Boolean = false;

		// Debug mode
		private var _debugQuad:Quad;
		private var _activeAlpha:Number = 0.8;
		private var _inactiveAlpha:Number = 0.4;
		private var _activeBridgeColor:uint = 0xffffff;
		private var _inactiveBridgeColor:uint = 0x333333;
		private var _activeNonBridgeColor:uint = 0x269AD9;
		private var _inactiveNonBridgeColor:uint = 0x333333;

		/**
		 * Constructor of a Spatial Element
		 *
		 * @param	deactivator, deactivation manager
		 * @param	isActivityBridge, the element transfers its activity over chunks.
		 * @param	activityChangedCallbackFunc, callback called when activity changed. Prototype: function(bool isActive):void
		 */
		public function SpatialElement(deactivator:SpatialDeactivator, isActivityBridge:Boolean = true, activityChangedCallbackFunc:Function = null)
		{
			_deactivator = deactivator;
			_isActivityBridge = isActivityBridge;
			_activityChangedCallback = activityChangedCallbackFunc;

			// Register element
			_deactivator.addElement(this);

			// Create debug graphics
			if (_deactivator.debugSprite)
				createDebugQuad();

			// make sure the element is active if the deactivator is disabled
			if (!_deactivator.isEnabled)
				activate(false);

			_deactivator.dispatchActivityChanges();
		}

		// --------------------------------------------------------------------
		// -- Public API
		// --------------------------------------------------------------------

		/**
		 * Updates the bounding box of the element.
		 *
		 * The element is updated right away if its update cooldown is over, otherwise when the deactivator advances
		 * time once it is over.
		 *
		 * @throws ArgumentError if a value is not finite or if a size is negative
		 */
		public function updateAABB(x:Number, y:Number, width:Number, height:Number):void
		{
			SpatialDeactivator.validateRectangle("AABB", x, y, width, height);

			_aabb.setTo(x, y, width, height);
			_hasAABB = true;
			_aabbUpdated = true;

			// update debugging when deactivator is disabled
			if (!_deactivator.isEnabled)
				updateDebugAABB();

			// Update directly if cool down is over
			if (_timeSinceLastUpdate >= _updateCooldown)
				update();

			_deactivator.dispatchActivityChanges();
		}

		/**
		 * Unregisters the element from its deactivator. Safe to call more than once.
		 */
		public function destroy():void
		{
			// already destroyed, possibly by the deactivator being cleared
			if (!_deactivator)
				return;

			// an active bridge covering several chunks may be the only link keeping some of them active
			var deactivator:SpatialDeactivator = _deactivator;
			var mayBreakActivityLinks:Boolean = _isActive && _isActivityBridge && _coveredChunks.length > 1;

			release();

			if (mayBreakActivityLinks)
			{
				deactivator.refreshChunksActivity();
				deactivator.dispatchActivityChanges();
			}
		}

		/**
		 * Unregisters the element from its deactivator & its chunks, without updating the activity of the context.
		 */
		internal function release():void
		{
			if (!_deactivator)
				return;

			_deactivator.removeElement(this);

			// Remove elements from covered chunks
			while (_coveredChunks.length > 0)
			{
				var chunk:SpatialChunk = _coveredChunks.pop();
				chunk.removeElement(this);
				_deactivator.freeChunkIfUnused(chunk);
			}

			// clear new chunk list
			_newCoveredChunks.length = 0;

			destroyDebugQuad();

			// Nullify references
			_deactivator = null;
			_aabb = null;
			_newCoveredChunks = null;
			_coveredChunks = null;
			_activityChangedCallback = null;
		}

		public function get isActive():Boolean
		{
			return _isActive;
		}

		public function get updateCooldown():Number
		{
			return _updateCooldown;
		}

		public function set updateCooldown(value:Number):void
		{
			_updateCooldown = value;
		}

		public function get isActivityBridge():Boolean
		{
			return _isActivityBridge;
		}

		public function set isActivityBridge(value:Boolean):void
		{
			// Only if value has changed
			if (value == _isActivityBridge)
				return;

			_isActivityBridge = value;

			// Is active...
			if (_isActive)
			{
				// ...and become a bridge
				if(_isActivityBridge)
				{
					// If the element is now an active bridge, it could now transfer its activity.
					// In that case it's necessary to activate all touched chunks.
					for (var i:int = 0; i < _coveredChunks.length; ++i)
						_deactivator.activateChunkWithPropagation(_coveredChunks[i]);
				}
				// ...and stop being a bridge
				else
				{
					// If the element was an active bridge, it could break the activity tree.
					// In that case it's necessary to re-check all the activity propagation.
					_deactivator.refreshChunksActivity();
				}
			}

			updateDebugFromStatus();
			_deactivator.dispatchActivityChanges();
		}

		public function get activityChangedCallback():Function
		{
			return _activityChangedCallback;
		}

		/**
		 * Callback called when the activity changes. Prototype: function(isActive:Boolean):void
		 *
		 * The callback owner is assumed to start inactive: a callback set while the element is active is called
		 * right away, unless a previous callback was already notified of this activity.
		 */
		public function set activityChangedCallback(value:Function):void
		{
			_activityChangedCallback = value;

			// notify the activity reached without callback
			if (_deactivator)
			{
				queueActivityChange();
				_deactivator.dispatchActivityChanges();
			}
		}

		// --------------------------------------------------------------------
		// -- Private / internal methods
		// --------------------------------------------------------------------

		/**
		 * Applies the pending AABB update once the update cooldown is over, without dispatching activity changes.
		 */
		internal function advanceTime(time:Number):void
		{
			_timeSinceLastUpdate += time;

			if (_aabbUpdated && _timeSinceLastUpdate >= _updateCooldown)
				update();
		}

		/**
		 * Creates the debug quad on top of the debug sprite of the deactivator.
		 */
		internal function createDebugQuad():void
		{
			_debugQuad = new Quad(1, 1);
			_deactivator.debugSprite.addChild(_debugQuad);
			updateDebugAABB();
			updateDebugFromStatus();
		}

		internal function destroyDebugQuad():void
		{
			if (!_debugQuad)
				return;

			_debugQuad.removeFromParent(true);
			_debugQuad = null;
		}

		private function updateDebugAABB():void
		{
			if (_debugQuad)
			{
				_debugQuad.x = _aabb.x;
				_debugQuad.y = _aabb.y;
				_debugQuad.width = _aabb.width;
				_debugQuad.height = _aabb.height;
			}
		}

		private function updateDebugFromStatus():void
		{
			if (_debugQuad)
			{
				_debugQuad.color = _isActive ? (_isActivityBridge ? _activeBridgeColor : _activeNonBridgeColor) : (_isActivityBridge ? _inactiveBridgeColor : _inactiveNonBridgeColor);
				_debugQuad.alpha = _isActive ? _activeAlpha : _inactiveAlpha;
			}
		}

		/**
		 * Moves the element into the chunks covered by its AABB, without updating any activity.
		 *
		 * @return the changes, as a combination of the <code>ENTERED_CHUNK</code>, <code>LEFT_CHUNK</code> &
		 *         <code>LEFT_CHUNK_OUT_OF_ACTIVE_AREA</code> flags
		 */
		internal function updateCoveredChunks():int
		{
			// Reset invalidation & cooldown
			_aabbUpdated = false;
			_timeSinceLastUpdate = 0;

			// update debugging
			updateDebugAABB();

			// Acquire the new covered chunks, none as long as the element has no AABB
			if (_hasAABB)
				_deactivator.getChunksTouchedBy(_aabb, _newCoveredChunks);
			else
				_newCoveredChunks.length = 0;

			// Temp variables
			var changes:int = 0;
			var chunk:SpatialChunk;
			var i:int;

			// Left old chunks
			for (i = 0; i < _coveredChunks.length; ++i)
			{
				chunk = _coveredChunks[i];
				if (_newCoveredChunks.indexOf(chunk) == -1)
				{
					changes |= LEFT_CHUNK;
					if (!_deactivator.isChunkOverActiveArea(chunk))
						changes |= LEFT_CHUNK_OUT_OF_ACTIVE_AREA;

					chunk.removeElement(this);
					_deactivator.freeChunkIfUnused(chunk);
				}
			}

			// Join new chunks
			for (i = 0; i < _newCoveredChunks.length; ++i)
			{
				chunk = _newCoveredChunks[i];
				if (_coveredChunks.indexOf(chunk) == -1)
				{
					chunk.addElement(this);
					changes |= ENTERED_CHUNK;
				}
			}

			// Transfer new covered chunks in the covered chunks
			_coveredChunks.length = 0;
			while (_newCoveredChunks.length > 0)
				_coveredChunks.push(_newCoveredChunks.pop());

			return changes;
		}

		private function update():void
		{
			// Only update if the deactivator is active
			if (!_deactivator.isEnabled)
				return;

			var changes:int = updateCoveredChunks();
			var leftChunk:Boolean = (changes & LEFT_CHUNK) != 0;
			var enteredChunk:Boolean = (changes & ENTERED_CHUNK) != 0;
			var i:int;

			// If non-activity bridge, just check new covered chunks activity
			if (!_isActivityBridge)
			{
				if (enteredChunk || leftChunk)
					checkActivityFromCoveredChunks();
				return;
			}

			// Activity bridge:
			// An inactive bridge only covered inactive chunks, so leaving them cannot break any activity link.
			// It could enter in an active chunk and propagate activity.
			if (!_isActive)
			{
				if (enteredChunk)
				{
					for (i = 0; i < _coveredChunks.length; ++i)
					{
						if (_coveredChunks[i].isActive)
						{
							activate(true);
							break;
						}
					}
				}

				return;
			}

			// An active bridge leaving chunks could break the activity links going through them and become inactive.
			// In that case it's necessary to re-check all the activity propagation, unless the active area keeps
			// active by itself both the left chunks and the element.
			if (leftChunk && ((changes & LEFT_CHUNK_OUT_OF_ACTIVE_AREA) != 0 || !isCoveringActiveArea()))
			{
				_deactivator.refreshChunksActivity();
				checkActivityFromCoveredChunks();
			}
			// The element stays active, all covered chunks must be active too
			else if (enteredChunk)
			{
				for (i = 0; i < _coveredChunks.length; ++i)
					_deactivator.activateChunkWithPropagation(_coveredChunks[i]);
			}
		}

		private function isCoveringActiveArea():Boolean
		{
			for (var i:int = 0; i < _coveredChunks.length; ++i)
			{
				if (_deactivator.isChunkOverActiveArea(_coveredChunks[i]))
					return true;
			}

			return false;
		}

		/** Check if element must be active according to covered chunks */
		internal function checkActivityFromCoveredChunks():void
		{
			var i:int;
			if (_isActive)
			{
				// All chunks must be inactive to become inactive
				for (i = 0; i < _coveredChunks.length; ++i)
					if (_coveredChunks[i].isActive)
						return;

				deactivate();
			}
			else
			{
				// At least one chunk is active to become active
				for (i = 0; i < _coveredChunks.length; ++i)
				{
					if (_coveredChunks[i].isActive)
					{
						activate(false);
						return;
					}
				}
			}
		}

		/**
		 * Adds the covered chunks not stamped with the given stamp to the list & stamps them, if the element is an
		 * activity bridge.
		 *
		 * The added chunks are not walked: the caller walks the list while it grows, which reaches the chunks linked
		 * to them without recursion.
		 */
		internal function fillListWithLinkedChunks(chunks:Vector.<SpatialChunk>, stamp:uint):void
		{
			// Only activity bridge are linking chunks
			if (!_isActivityBridge)
				return;

			for (var i:int = 0; i < _coveredChunks.length; ++i)
			{
				var chunk:SpatialChunk = _coveredChunks[i];
				if (chunk.linkStamp != stamp)
				{
					chunk.linkStamp = stamp;
					chunks.push(chunk);
				}
			}
		}

		internal function activate(propagate:Boolean):void
		{
			if (_isActive)
				return;

			_isActive = true;
			updateDebugFromStatus();

			// Only propagate activity if the object is a bridge
			if (_isActivityBridge && propagate)
			{
				for (var i:int = 0; i < _coveredChunks.length; ++i)
					_deactivator.activateChunkWithPropagation(_coveredChunks[i]);
			}

			queueActivityChange();
		}

		private function deactivate():void
		{
			if (!_isActive)
				return;

			_isActive = false;
			updateDebugFromStatus();
			queueActivityChange();
		}

		private function queueActivityChange():void
		{
			if (_isActivityChangePending)
				return;

			_isActivityChangePending = true;
			_deactivator.queueActivityChange(this);
		}

		/** Triggers the callback if the activity differs from the last notified one */
		internal function dispatchActivityChange():void
		{
			_isActivityChangePending = false;

			// destroyed elements are not notified anymore, and a change without callback stays to be notified
			if (!_deactivator || _activityChangedCallback == null || _isActive == _wasActiveNotified)
				return;

			_wasActiveNotified = _isActive;
			_activityChangedCallback(_isActive);
		}
	}
}