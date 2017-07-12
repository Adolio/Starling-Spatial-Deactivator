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
	import ch.adolio.deactivator.SpatialElement;
	import ch.adolio.deactivator.display.BorderedQuad;
	
	public class SpatialElementDebugObject extends BorderedQuad
	{
		private var _spatialElement:SpatialElement;
		
		// Style
		private var _activeAlpha:Number = 1.0;
		private var _inactiveAlpha:Number = 0.4;
		private var _activeBridgeColor:uint = 0xffffff;
		private var _inactiveBridgeColor:uint = 0x333333;
		private var _activeNonBridgeColor:uint = 0x269AD9;
		private var _inactiveNonBridgeColor:uint = 0x333333;
		
		public function SpatialElementDebugObject(width:Number, height:Number, spatialElement:SpatialElement) 
		{
			super(width, height, _activeBridgeColor, 1.0);
			
			_spatialElement = spatialElement;
			
			update();
		}
		
		public function update():void
		{
			// Color
			if (_spatialElement.isActivityBridge)
				color = _spatialElement.isActive ? _activeBridgeColor : _inactiveBridgeColor;
			else
				color = _spatialElement.isActive ? _activeNonBridgeColor : _inactiveNonBridgeColor;
			
			// Alpha
			alpha = _spatialElement.isActive ? _activeAlpha : _inactiveAlpha;
			
			// Visibility
			//visible = _spatialElement.isActive;
		}
	}
}