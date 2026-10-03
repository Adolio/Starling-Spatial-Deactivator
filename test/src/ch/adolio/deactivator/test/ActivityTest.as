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
	import ch.adolio.test.ITest;
	import flash.geom.Rectangle;

	/**
	 * Activity of elements entering & leaving the active area, directly or through activity bridges.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class ActivityTest implements ITest
	{
		public function execute():void
		{
			testElementInsideActiveArea();
			testElementOutsideActiveArea();
			testElementMovingOutAndBack();
			testActiveAreaMoving();
			testBridgePropagation();
			testNonBridgeNoPropagation();
			testSpanningElementWithChunksSwapped();
			testEmptyAABBOnChunkBorder();
			testEmptyActiveAreaOnChunkBorder();
		}

		private function testElementInsideActiveArea():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			element.assertIsActive(true, "Inside active area");
			element.assertNotificationsCount(1, "Inside active area");

			deactivator.destroy();
		}

		private function testElementOutsideActiveArea():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 50, 50, 2, 2);

			element.assertIsActive(false, "Outside active area");
			element.assertNotificationsCount(0, "Outside active area");

			deactivator.destroy();
		}

		private function testElementMovingOutAndBack():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			element.moveTo(50, 50, 2, 2);
			element.assertIsActive(false, "Moved out of active area");

			element.moveTo(5, 5, 2, 2);
			element.assertIsActive(true, "Moved back into active area");
			element.assertNotificationsCount(3, "Moved out & back");

			deactivator.destroy();
		}

		private function testActiveAreaMoving():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var left:ElementProbe = new ElementProbe("left element", deactivator, 5, 5, 2, 2);
			var right:ElementProbe = new ElementProbe("right element", deactivator, 45, 45, 2, 2);

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			left.assertIsActive(false, "Active area moved away");
			right.assertIsActive(true, "Active area moved over");

			deactivator.destroy();
		}

		private function testBridgePropagation():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			// the outside element is only linked to the active area by the bridge, which covers the chunks (1, 0) & (2, 0)
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 25, 5, 2, 2);
			var bridge:ElementProbe = new ElementProbe("bridge", deactivator, 15, 5, 10, 2);

			bridge.assertIsActive(true, "Bridge propagation");
			outside.assertIsActive(true, "Bridge propagation");

			// breaking the link deactivates the outside element
			bridge.moveTo(5, 5, 2, 2);
			bridge.assertIsActive(true, "Bridge link broken");
			outside.assertIsActive(false, "Bridge link broken");

			deactivator.destroy();
		}

		private function testNonBridgeNoPropagation():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 25, 5, 2, 2);
			var nonBridge:ElementProbe = new ElementProbe("non-bridge", deactivator, 15, 5, 10, 2, false);

			nonBridge.assertIsActive(true, "Non-bridge propagation");
			outside.assertIsActive(false, "Non-bridge propagation");

			deactivator.destroy();
		}

		private function testSpanningElementWithChunksSwapped():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			// the non-bridge covers the chunks (1, 0) & (2, 0): moving the active area by one chunk swaps their activity
			var nonBridge:ElementProbe = new ElementProbe("non-bridge", deactivator, 15, 5, 10, 2, false);
			deactivator.updateActiveArea(new Rectangle(20, 0, 20, 20));

			nonBridge.assertIsActive(true, "Covered chunks swapped");
			nonBridge.assertNotificationsCount(1, "Covered chunks swapped");

			deactivator.destroy();
		}

		private function testEmptyAABBOnChunkBorder():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			// an AABB without width or height on a chunk border is in the chunk starting on this border
			var point:ElementProbe = new ElementProbe("point", deactivator, 10, 10, 0, 0);
			var verticalLine:ElementProbe = new ElementProbe("vertical line", deactivator, 10, 5, 0, 2);
			var horizontalLine:ElementProbe = new ElementProbe("horizontal line", deactivator, 5, 10, 2, 0);
			var outsidePoint:ElementProbe = new ElementProbe("outside point", deactivator, 20, 20, 0, 0);

			point.assertIsActive(true, "Empty AABB on chunk border");
			verticalLine.assertIsActive(true, "Empty AABB on chunk border");
			horizontalLine.assertIsActive(true, "Empty AABB on chunk border");
			outsidePoint.assertIsActive(false, "Empty AABB on chunk border");

			deactivator.updateActiveArea(new Rectangle(20, 20, 20, 20));
			point.assertIsActive(false, "Active area moved away from empty AABB");
			outsidePoint.assertIsActive(true, "Active area moved over empty AABB");

			deactivator.destroy();
		}

		private function testEmptyActiveAreaOnChunkBorder():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var inside:ElementProbe = new ElementProbe("inside element", deactivator, 45, 45, 2, 2);
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 35, 45, 2, 2);

			deactivator.updateActiveArea(new Rectangle(40, 40, 0, 0));
			inside.assertIsActive(true, "Empty active area on chunk border");
			outside.assertIsActive(false, "Empty active area on chunk border");

			deactivator.destroy();
		}
	}
}
