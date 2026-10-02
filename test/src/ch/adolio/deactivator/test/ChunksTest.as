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
	import flash.geom.Rectangle;

	/**
	 * Allocation & freeing of the chunks.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class ChunksTest implements ITest
	{
		public function execute():void
		{
			testNoChunkForActiveArea();
			testChunksFreedWhenLeft();
			testEmptyActiveChunkFreedWhenDeactivated();
			testChunkCreatedAgainInsideActiveArea(true);
			testChunkCreatedAgainInsideActiveArea(false);
			testChunksFreedOnClear();
		}

		private function testNoChunkForActiveArea():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			assertChunksCount(deactivator, 0, "Active area set");

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			assertChunksCount(deactivator, 0, "Active area moved");

			deactivator.destroy();
		}

		private function testChunksFreedWhenLeft():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 50, 50, 2, 2);
			assertChunksCount(deactivator, 1, "Element created");

			element.moveTo(60, 60, 2, 2);
			assertChunksCount(deactivator, 1, "Element moved to another chunk");

			element.moveTo(65, 65, 10, 10);
			assertChunksCount(deactivator, 4, "Element covering 4 chunks");

			element.element.destroy();
			assertChunksCount(deactivator, 0, "Element destroyed");

			deactivator.destroy();
		}

		private function testEmptyActiveChunkFreedWhenDeactivated():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			// the left chunk stays allocated while active
			element.moveTo(50, 50, 2, 2);
			assertChunksCount(deactivator, 2, "Element left an active chunk");

			deactivator.updateActiveArea(new Rectangle(100, 100, 20, 20));
			assertChunksCount(deactivator, 1, "Empty chunk deactivated");

			deactivator.destroy();
		}

		private function testChunkCreatedAgainInsideActiveArea(isActivityBridge:Boolean):void
		{
			var context:String = isActivityBridge ? "Bridge" : "Non-bridge";
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2, isActivityBridge);

			// free the chunk of the active area
			deactivator.updateActiveArea(new Rectangle(100, 100, 20, 20));
			element.moveTo(50, 50, 2, 2);
			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());
			assertChunksCount(deactivator, 1, context + " out of the active area");

			element.moveTo(5, 5, 2, 2);
			element.assertIsActive(true, context + " entered a chunk created again in the active area");
			assertChunksCount(deactivator, 1, context + " entered a chunk created again in the active area");

			deactivator.destroy();
		}

		private function testChunksFreedOnClear():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			new ElementProbe("inside element", deactivator, 5, 5, 2, 2);
			new ElementProbe("outside element", deactivator, 50, 50, 2, 2);

			deactivator.clear();
			assertChunksCount(deactivator, 0, "Cleared");

			deactivator.destroy();
		}

		private function assertChunksCount(deactivator:SpatialDeactivator, expected:int, context:String):void
		{
			Assert.equalsInt(deactivator.chunksCount, expected, context + ": chunks count");
		}
	}
}
