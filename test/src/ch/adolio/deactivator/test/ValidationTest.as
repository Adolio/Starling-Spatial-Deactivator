// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017-2026 Aurelien Da Campo, All Rights Reserved.
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
	 * Rejection of invalid chunk sizes, active areas & AABBs, which must leave the context unchanged.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class ValidationTest implements ITest
	{
		public function execute():void
		{
			testInvalidChunkSizes();
			testInvalidActiveAreas();
			testInvalidAABBs();
			testEmptyRectanglesAccepted();
		}

		private function testInvalidChunkSizes():void
		{
			assertChunkSizeRejected(0, 10, "Zero chunk width");
			assertChunkSizeRejected(10, 0, "Zero chunk height");
			assertChunkSizeRejected(-10, 10, "Negative chunk width");
			assertChunkSizeRejected(10, -10, "Negative chunk height");
			assertChunkSizeRejected(NaN, 10, "NaN chunk width");
			assertChunkSizeRejected(10, NaN, "NaN chunk height");
			assertChunkSizeRejected(Infinity, 10, "Infinite chunk width");
			assertChunkSizeRejected(10, Infinity, "Infinite chunk height");
		}

		private function testInvalidActiveAreas():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			assertActiveAreaRejected(deactivator, null, "Null active area");
			assertActiveAreaRejected(deactivator, new Rectangle(NaN, 40, 20, 20), "NaN active area x");
			assertActiveAreaRejected(deactivator, new Rectangle(40, NaN, 20, 20), "NaN active area y");
			assertActiveAreaRejected(deactivator, new Rectangle(40, 40, NaN, 20), "NaN active area width");
			assertActiveAreaRejected(deactivator, new Rectangle(40, 40, 20, NaN), "NaN active area height");
			assertActiveAreaRejected(deactivator, new Rectangle(-Infinity, 40, 20, 20), "Infinite active area x");
			assertActiveAreaRejected(deactivator, new Rectangle(40, 40, Infinity, 20), "Infinite active area width");
			assertActiveAreaRejected(deactivator, new Rectangle(40, 40, -20, 20), "Negative active area width");
			assertActiveAreaRejected(deactivator, new Rectangle(40, 40, 20, -20), "Negative active area height");

			// the rejected areas must not replace the current one
			deactivator.updateChunksActivity();
			element.assertIsActive(true, "Active areas rejected");

			deactivator.destroy();
		}

		private function testInvalidAABBs():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			assertAABBRejected(element, NaN, 50, 2, 2, "NaN AABB x");
			assertAABBRejected(element, 50, NaN, 2, 2, "NaN AABB y");
			assertAABBRejected(element, 50, 50, NaN, 2, "NaN AABB width");
			assertAABBRejected(element, 50, 50, 2, NaN, "NaN AABB height");
			assertAABBRejected(element, 50, Infinity, 2, 2, "Infinite AABB y");
			assertAABBRejected(element, 50, 50, 2, Infinity, "Infinite AABB height");
			assertAABBRejected(element, 50, 50, -2, 2, "Negative AABB width");
			assertAABBRejected(element, 50, 50, 2, -2, "Negative AABB height");

			// the rejected AABBs must not replace the current one
			deactivator.advanceTime(1);
			element.assertIsActive(true, "AABBs rejected");

			element.moveTo(50, 50, 2, 2);
			element.assertIsActive(false, "Valid AABB after rejected ones");

			deactivator.destroy();
		}

		private function testEmptyRectanglesAccepted():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 0, 0);
			element.assertIsActive(true, "Empty AABB");

			deactivator.updateActiveArea(new Rectangle(40, 40, 0, 0));
			element.assertIsActive(false, "Empty active area");

			deactivator.destroy();
		}

		private function assertChunkSizeRejected(chunkWidth:Number, chunkHeight:Number, context:String):void
		{
			Assert.throws(ArgumentError, function():void
			{
				new SpatialDeactivator(chunkWidth, chunkHeight);
			}, context);
		}

		private function assertActiveAreaRejected(deactivator:SpatialDeactivator, area:Rectangle, context:String):void
		{
			Assert.throws(ArgumentError, function():void
			{
				deactivator.updateActiveArea(area);
			}, context);
		}

		private function assertAABBRejected(element:ElementProbe, x:Number, y:Number, width:Number, height:Number, context:String):void
		{
			Assert.throws(ArgumentError, function():void
			{
				element.moveTo(x, y, width, height);
			}, context);
		}
	}
}
