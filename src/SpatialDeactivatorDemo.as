// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package
{
	import flash.geom.Rectangle;
	import ch.adolio.deactivator.SpatialDeactivator;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class SpatialDeactivatorDemo extends Sprite
	{
		// Deactivator
		private var _deactivator:SpatialDeactivator;
		
		// Active area
		private var _activeAreaAABB:Rectangle = new Rectangle();
		private var _activeArea:Quad = new Quad(120, 80, 0xffffff);
		private var _activeAreaTargetX:Number;
		private var _activeAreaTargetY:Number;
		
		// Game objects
		private var _objects:Vector.<GameObject> = new Vector.<GameObject>();
		
		public function SpatialDeactivatorDemo()
		{
			_deactivator = new SpatialDeactivator(_activeArea.width * 0.25, _activeArea.height * 0.25, true);
			Starling.current.juggler.add(_deactivator);
			
			// Create chunks grid
			if(_deactivator.debugSprite)
				addChild(_deactivator.debugSprite);
			
			// Create objects
			for (var i:uint = 0; i < 1024; ++i)
			{
				var go:GameObject = new GameObject(
					Math.random() * Starling.current.stage.stageWidth,
					Math.random() * Starling.current.stage.stageHeight,
					2 + Math.random() * 8,
					2 + Math.random() * 8,
					_deactivator
				);
				
				// Add game object graphics only when debug mode is off
				if(!_deactivator.debugSprite)
					addChild(go);
					
				_objects.push(go);
			}
			
			// Setup initial view target
			_activeAreaTargetX = Starling.current.stage.stageWidth * 0.5;
			_activeAreaTargetY = Starling.current.stage.stageHeight * 0.5;
			
			// Create active area
			_activeArea.alpha = 0.5;
			_activeArea.x = _activeAreaTargetX - _activeArea.width * 0.5;
			_activeArea.y = _activeAreaTargetY - _activeArea.height * 0.5;
			
			// Add active area graphics only when debug mode is off
			if(!_deactivator.debugSprite)
				addChild(_activeArea);
			
			// Update active area
			_activeAreaAABB.setTo(_activeArea.x, _activeArea.y, _activeArea.width, _activeArea.height);
			_deactivator.updateActiveArea(_activeAreaAABB);
			
			// Register event listeners
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(e:EnterFrameEvent):void
		{
			var oldx:int = _activeArea.x;
			var oldy:int = _activeArea.y;
			
			// Animate the active area
			_activeArea.x = lerp(_activeArea.x, _activeAreaTargetX - _activeArea.width * 0.5, e.passedTime * 10);
			_activeArea.y = lerp(_activeArea.y, _activeAreaTargetY - _activeArea.height * 0.5, e.passedTime * 10);
			
			// Update active area if view changed
			if (_activeArea.x != oldx || _activeArea.y != oldy)
			{
				_activeAreaAABB.setTo(_activeArea.x, _activeArea.y, _activeArea.width, _activeArea.height);
				_deactivator.updateActiveArea(_activeAreaAABB);
			}
		}
		
		private function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(TouchEvent.TOUCH, onStageTouched);
		}
		
		private function onStageTouched(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if (touch)
			{
				if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED)
				{
					_activeAreaTargetX = touch.globalX;
					_activeAreaTargetY = touch.globalY;
				}
			}
		}
		
		private function lerp(v0:Number, v1:Number, t:Number):Number
		{
			return (1.0 - t) * v0 + t * v1;
		}
	}
}