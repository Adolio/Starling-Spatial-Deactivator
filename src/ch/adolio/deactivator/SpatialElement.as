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
	import starling.animation.IAnimatable;
	import starling.display.Quad;
	
	/**
	 * A Spatial element represents a user object in the context of the Spatial Deactivator.
	 * 
	 * It can be active or inactive. The activity of the element is managed internally and 
	 * you cannot change it. This could break the consistency of the context.
	 * The function field 'activityChangedCallback', if defined, will let you know when the 
	 * activity has been updated.
	 * 
	 * The method 'updateAABB' must be called each time your object has moved.
	 * For optimization reasons, you can add an update cooldown to avoid updating the deactivator
	 * at each frame. Call the 'updateCooldown' setter to configure the cooldown time (in seconds).
	 * Note that the default cooldown is not 0.
	 */
	public class SpatialElement implements IAnimatable
	{
		// Spatial deactivation
		private var _deactivator:SpatialDeactivator;
		private var _aabb:Rectangle = new Rectangle();
		private var _newChunks:Vector.<SpatialChunk>;
		private var _isActive:Boolean = false;
		private var _coveredChunks:Vector.<SpatialChunk> = new Vector.<SpatialChunk>();
		
		// Update management
		private var _aabbUpdated:Boolean = false;
		private var _timeSinceLastUpdate:Number = 0; // sec
		private var _updateCooldown:Number = 1.0 / 10.0; // sec
		
		// Callback
		public var activityChangedCallback:Function;
		
		// Debug mode
		private var _debugQuad:Quad;
		private var _activeAlpha:Number = 0.8;
		private var _inactiveAlpha:Number = 0.6;
		private var _activeColor:uint = 0xffffff * Math.random();
		private var _inactiveColor:uint = 0x333333;
		
		/** 
		 * Constructor of a Spatial Element
		 * 
		 * @param	deactivator, deactivation manager
		 * @param	isActive, initial element activity
		 */
		public function SpatialElement(deactivator:SpatialDeactivator, isActive:Boolean)
		{
			_deactivator = deactivator;
			_isActive = isActive;
			
			// Register element
			_deactivator.addElement(this);
			
			// Create debug graphics
			if(_deactivator.debugSprite) {
				_debugQuad = new Quad(1, 1, _isActive ? _activeColor : _inactiveColor);
				_debugQuad.alpha = _isActive ? _activeAlpha : _inactiveAlpha;
				_deactivator.debugSprite.addChild(_debugQuad);
			}
		}
		
		// --------------------------------------------------------------------
		// -- Public API
		// --------------------------------------------------------------------
		
		public function updateAABB(x:Number, y:Number, width:Number, height:Number):void
		{
			_aabb.setTo(x, y, width, height);
			_aabbUpdated = true;
		}
		
		public function destroy():void
		{
			_deactivator.removeElement(this);
			
			// Remove element from chunks & clear chunk list
			// No need to clear _newChunks because _coveredChunks == _newChunks
			for (var i:int = 0; i < _coveredChunks.length; ++i )
				_coveredChunks[i].removeElement(this);
			_coveredChunks.splice(0, _coveredChunks.length);
			
			// Dispose graphical debug
			if (_debugQuad)
				_debugQuad.removeFromParent(true);
			
			// Nullify references
			_deactivator = null;
			_aabb = null;
			_newChunks = null;
			_coveredChunks = null;
			activityChangedCallback = null;
			_debugQuad = null;
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
		
		// --------------------------------------------------------------------
		// -- Interface methods
		// --------------------------------------------------------------------
		
		// Automatically called by the Spatial Deactivator
		public function advanceTime(time:Number):void
		{
			_timeSinceLastUpdate += time;
			
			if (_aabbUpdated && _timeSinceLastUpdate >= _updateCooldown)
			{
				_aabbUpdated = false;
				_timeSinceLastUpdate = 0;
				
				update();
			}
		}
		
		// --------------------------------------------------------------------
		// -- Private / internal methods
		// --------------------------------------------------------------------
		
		private function update():void
		{
			// Update debug graphics
			if (_debugQuad != null) {
				_debugQuad.x = _aabb.x;
				_debugQuad.y = _aabb.y;
				_debugQuad.width = _aabb.width;
				_debugQuad.height = _aabb.height;
				_deactivator.debugSprite.addChild(_debugQuad); // Move on top
			}
			
			// Acquire the new covered chunks (requires a new vector instance for later pointer assignment)
			_newChunks = _deactivator.getChunksTouchedBy(_aabb, null);
			
			// Temp variables
			var chunk:SpatialChunk;
			var i:int;
			
			// Left old chunks
			var leftChunk:Boolean = false
			for (i = 0; i < _coveredChunks.length; ++i)
			{
				chunk = _coveredChunks[i];
				if (_newChunks.indexOf(chunk) == -1)
				{
					chunk.removeElement(this);
					leftChunk = true;
				}
			}
			
			// Join new chunks
			var enteredChunk:Boolean = false
			for (i = 0; i < _newChunks.length; ++i)
			{
				chunk = _newChunks[i];
				if (_coveredChunks.indexOf(chunk) == -1)
				{
					chunk.addElement(this);
					enteredChunk = true;
				}
			}
			
			// New chunks become covered chunks (pointer assignment)
			_coveredChunks = _newChunks;
			
			// Enter a new chunk but did not left another
			if (enteredChunk && !leftChunk)
			{
				// If the element is active, all covered chunks must be active too
				if (_isActive)
				{
					for (i = 0; i < _coveredChunks.length; ++i)
						_coveredChunks[i].activate(true, true);
				}
				// If the element is inactive, it could enter in an active chunk and propagate activity
				else
				{
					// Check activity of new covered chunk and active element (with propagation) if one chunk is active
					for (i = 0; i < _coveredChunks.length; ++i)
					{
						if (_coveredChunks[i].isActive)
						{
							activate(true);
							break;
						}
					}
				}
			}
			// Left a chunk but did not enter another (it was a bridge element)
			else if (!enteredChunk && leftChunk)
			{
				// If the element was an active bridge, it could break the activity branch and become inactive
				// In that case it's necessary to re-check all the activity propagation.
				if (_isActive)
				{
					_deactivator.updateActiveChunksFromLastActiveArea();
				}
				// If the element was inactive (was a bridge between two inactive chunks)
				else
				{
					// Nothing to do, the element left an inactive chunk to another.
				}
			}
			// Left a chunk and entered into a new one (teleportation)
			else if (enteredChunk && leftChunk)
			{
				// If the element was an active bridge, it could break the activity tree and become inactive
				// In that case it's necessary to re-check all the activity propagation.
				_deactivator.updateActiveChunksFromLastActiveArea();
				
				// Update the element activity because updateActiveChunksFromLastActiveArea 
				// do not propagate to elements if there is no chunk activity change
				var newActivity:Boolean = false;
				for (i = 0; i < _coveredChunks.length; ++i)
				{
					if (_coveredChunks[i].isActive)
					{
						newActivity = true;
						break;
					}
				}
				
				// Update activity
				if (newActivity)
					activate(false);
				else
					deactivate(false);
			}
			else
			{
				// If the element didn't leave a chunk & didn't enter a chunk, there is nothing to do.
			}
		}
		
		private function checkCoveredChunksActivity():void
		{
			if (_isActive)
			{
				// If active, all covered chunks must be active too
				for (var i:int = 0; i < _coveredChunks.length; ++i)
					_coveredChunks[i].activate(true, true);
			}
		}
		
		internal function fillListWithLinkedChunks(chunks:Vector.<SpatialChunk>):void
		{
			for (var i:int = 0; i < _coveredChunks.length; ++i)
			{
				var chunk:SpatialChunk = _coveredChunks[i];
				
				// Add only unpresent chunk
				if (chunks.indexOf(chunk) == -1)
				{
					// Add the chunk
					chunks.push(chunk);
					
					// Recursively add linked chunks
					chunk.fillListWithLinkedChunks(chunks);
				}
			}
		}
		
		internal function activate(propagate:Boolean):void
		{
			if (_isActive)
				return;
			
			_isActive = true;
			
			if (_debugQuad) {
				_debugQuad.color = _activeColor;
				_debugQuad.alpha = _activeAlpha;
			}
			
			if (propagate)
				checkCoveredChunksActivity();
			
			if (activityChangedCallback)
				activityChangedCallback(_isActive);
		}
		
		internal function deactivate(propagate:Boolean):void
		{
			if (!_isActive)
				return;
			
			_isActive = false;
			
			if (_debugQuad) {
				_debugQuad.color = _inactiveColor;
				_debugQuad.alpha = _inactiveAlpha;
			}
			
			if (propagate)
				checkCoveredChunksActivity();
			
			if (activityChangedCallback)
				activityChangedCallback(_isActive);
		}
	}
}