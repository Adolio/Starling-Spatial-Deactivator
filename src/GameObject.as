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
		private var _elaspedTime:Number = 0;
		private var _ix:Number = 0;
		private var _iy:Number = 0;
		private var _iw:Number = 0;
		private var _ih:Number = 0;
		private var _mouvementRadius:Number = 0;
		private var _angularSpeed:Number = 0;
		private var _enableTeleportation:Boolean = false;
		private var _teleportCooldown:Number = 0;
		
		public function GameObject(x:Number, y:Number, width:Number, height:Number, deactivator:SpatialDeactivator)
		{
			_ix = x;
			_iy = y;
			_iw = width;
			_ih = height;
			
			// Setup graphics
			_quad = new Quad(width, height, 0xffffff);
			_quad.alpha = 0.5;
			addChild(_quad);
			
			// Setup behavior
			_elaspedTime = Math.random() * 1.0;
			_teleportCooldown = 2 + Math.random() * 3.0;
			_mouvementRadius = Math.random() * 100;
			_angularSpeed = ((Math.random() - 0.5) * 2) * 0.3;
			
			// Setup spatial element
			_spatialElement = new SpatialElement(deactivator, false);
			_spatialElement.activityChangedCallback = onSpatialElementActivityChanged;
			isActive = _spatialElement.isActive;
			
			// Setup starting position
			updatePosition();
		}
		
		public function advanceTime(time:Number):void
		{
			_elaspedTime += time;
			
			if (_enableTeleportation && _elaspedTime > _teleportCooldown)
			{
				_ix = Math.random() * Starling.current.stage.stageWidth;
				_iy = Math.random() * Starling.current.stage.stageHeight;
				_elaspedTime = 0;
			}
			
			updatePosition();
		}
		
		private function updatePosition():void
		{
			x = _ix + Math.sin(2 * Math.PI * _elaspedTime * _angularSpeed) * _mouvementRadius;
			y = _iy + Math.cos(2 * Math.PI * _elaspedTime * _angularSpeed) * _mouvementRadius;
			
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