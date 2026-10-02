// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2026 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.deactivator.test
{
	import ch.adolio.deactivator.SpatialDeactivator;
	import ch.adolio.test.Assert;
	import ch.adolio.test.ITest;
	import starling.display.DisplayObject;
	import starling.display.Sprite;

	/**
	 * Content of the debug sprite: one quad for the active area, one per chunk & one per element.
	 *
	 * The deactivator has 10 x 10 chunks & an active area over the chunks (0, 0) to (1, 1).
	 */
	public class DebugRenderingTest implements ITest
	{
		public function execute():void
		{
			var deactivator:SpatialDeactivator = new SpatialDeactivator(DeactivatorFactory.CHUNK_SIZE, DeactivatorFactory.CHUNK_SIZE, true);
			deactivator.activeAreaUpdateCooldown = 0;
			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());

			var debugSprite:Sprite = deactivator.debugSprite;
			Assert.equalsInt(debugSprite.numChildren, 1, "Active area quad");

			var first:ElementProbe = new ElementProbe("first element", deactivator, 5, 5, 2, 2);
			var second:ElementProbe = new ElementProbe("second element", deactivator, 15, 5, 3, 4);
			Assert.equalsInt(debugSprite.numChildren, 5, "Active area, 2 chunks & 2 elements quads");

			// the quad of a moved element follows it & keeps its depth, under the quad of the second element
			first.moveTo(6, 7, 2, 2);
			Assert.equalsInt(debugSprite.numChildren, 5, "Quads after an element moved");
			assertQuadPosition(debugSprite.getChildAt(3), 6, 7, "Moved element quad");
			assertQuadPosition(debugSprite.getChildAt(4), 15, 5, "Top quad after an element moved");

			// the chunk left by the destroyed element is still active, so it is kept
			first.element.destroy();
			Assert.equalsInt(debugSprite.numChildren, 4, "Quads after an element was destroyed");

			deactivator.clear();
			Assert.equalsInt(debugSprite.numChildren, 1, "Quads after clearing");

			deactivator.destroy();
		}

		private function assertQuadPosition(quad:DisplayObject, x:Number, y:Number, context:String):void
		{
			Assert.isTrue(quad.x == x && quad.y == y, context + ": position (" + quad.x + ", " + quad.y + "), expected (" + x + ", " + y + ")");
		}
	}
}
