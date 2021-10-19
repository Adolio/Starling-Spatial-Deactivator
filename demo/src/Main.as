// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017-2021 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import starling.core.Starling;

	public class Main extends Sprite
	{
		public function Main()
		{
			// Setup runtime
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

			// Setup Starling Framework
			var starling:Starling = new Starling(SpatialDeactivatorDemo, stage);
			starling.start();
			starling.showStats = true;
		}
	}
}