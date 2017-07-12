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
	import ch.adolio.deactivator.SpatialChunk;
	import ch.adolio.deactivator.display.BorderedQuad;
	
	public class SpatialChunkDebugObject extends BorderedQuad
	{
		private var _spatialChunk:SpatialChunk;
		
		// Style
		private static const _color:uint = 0x33D022;
		private static const _activeAlpha:Number = 0.4;
		private static const _inactiveAlpha:Number = 0.1;
		
		public function SpatialChunkDebugObject(width:Number, height:Number, spatialChunk:SpatialChunk) 
		{
			super(width, height, _color, 1.0);
			
			_spatialChunk = spatialChunk;
			
			update();
		}
		
		public function update():void
		{
			// Alpha
			alpha = _spatialChunk.isActive ? _activeAlpha : _inactiveAlpha;
			
			// Visibility
			//visible = _spatialChunk.isActive;
		}
	}
}