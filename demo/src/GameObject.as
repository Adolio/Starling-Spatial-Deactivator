// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017-2026 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package
{
	import ch.adolio.deactivator.SpatialDeactivator;
	import ch.adolio.deactivator.SpatialElement;
	import starling.animation.IAnimatable;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;

	/**
	 * A game object that can be deactivated by a Spatial Deactivator
	 */
	public class GameObject extends Sprite implements IAnimatable
	{
		// Chunk
		private var _spatialElement:SpatialElement;

		// Graphics
		private var _quad:Quad;

		// Behavior
		private var _elapsedTime:Number = 0;
		private var _ix:Number = 0;
		private var _iy:Number = 0;
		private var _iw:Number = 0;
		private var _ih:Number = 0;
		private var _movementRadius:Number = 0;
		private var _angularSpeed:Number = 0;
		private var _isTeleportationEnabled:Boolean = false;
		private var _teleportCooldown:Number = 0;
		private var _isStatic:Boolean;

		public function GameObject(x:Number, y:Number, width:Number, height:Number, deactivator:SpatialDeactivator, isStatic:Boolean)
		{
			_ix = x;
			_iy = y;
			_iw = width;
			_ih = height;
			_isStatic = isStatic;

			// Setup graphics
			_quad = new Quad(width, height, isStatic ? 0x269AD9 : 0xffffff);
			_quad.alpha = 0.8;
			addChild(_quad);

			// Setup behavior
			_elapsedTime = Math.random() * 1.0;
			_teleportCooldown = 2 + Math.random() * 3.0;
			_movementRadius = Math.random() * 100;
			_angularSpeed = ((Math.random() - 0.5) * 2) * 0.3;

			// Make sure that the object is starting inactive
			isActive = false;

			// Setup spatial element (static objects do not transfer activity over spatial chunks)
			_spatialElement = new SpatialElement(deactivator, !_isStatic);
			_spatialElement.activityChangedCallback = onSpatialElementActivityChanged;

			// Setup starting position
			updatePosition();
		}

		/**
		 * Destroys the game object & its spatial element.
		 */
		public function destroy():void
		{
			Starling.current.juggler.remove(this);
			_spatialElement.destroy();
			removeFromParent(true);
		}

		public function get isStatic():Boolean
		{
			return _isStatic;
		}

		public function get isTeleportationEnabled():Boolean
		{
			return _isTeleportationEnabled;
		}

		/**
		 * Makes the game object jump to a random position from time to time, while active.
		 */
		public function set isTeleportationEnabled(value:Boolean):void
		{
			_isTeleportationEnabled = value;
		}

		public function get isActivityBridge():Boolean
		{
			return _spatialElement.isActivityBridge;
		}

		public function set isActivityBridge(value:Boolean):void
		{
			_spatialElement.isActivityBridge = value;
		}

		public function advanceTime(time:Number):void
		{
			_elapsedTime += time;

			if (_isTeleportationEnabled && _elapsedTime > _teleportCooldown)
			{
				_ix = Math.random() * Starling.current.stage.stageWidth;
				_iy = Math.random() * Starling.current.stage.stageHeight;
				_elapsedTime = 0;
			}

			if(!_isStatic)
				updatePosition();
		}

		private function updatePosition():void
		{
			x = _ix + Math.sin(2 * Math.PI * _elapsedTime * _angularSpeed) * _movementRadius;
			y = _iy + Math.cos(2 * Math.PI * _elapsedTime * _angularSpeed) * _movementRadius;

			_spatialElement.updateAABB(x, y, _iw, _ih);
		}

		private function onSpatialElementActivityChanged(active:Boolean):void
		{
			isActive = active;
		}

		public function set isActive(value:Boolean):void
		{
			// Activate / deactivate logic
			if (value)
				Starling.current.juggler.add(this);
			else
				Starling.current.juggler.remove(this);

			// Activate / deactivate graphics
			_quad.visible = value;
		}
	}
}