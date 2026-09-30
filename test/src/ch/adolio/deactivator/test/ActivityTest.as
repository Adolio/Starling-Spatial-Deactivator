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
	 * Chunks are 10 x 10 and the active area starts over the chunks (0, 0) to (1, 1).
	 */
	public class ActivityTest implements ITest
	{
		private static const CHUNK_SIZE:Number = 10;

		public function execute():void
		{
			testElementInsideActiveArea();
			testElementOutsideActiveArea();
			testElementMovingOutAndBack();
			testActiveAreaMoving();
			testBridgePropagation();
			testNonBridgeNoPropagation();
		}

		private function testElementInsideActiveArea():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			element.assertIsActive(true, "Inside active area");
			element.assertNotificationsCount(1, "Inside active area");

			deactivator.destroy();
		}

		private function testElementOutsideActiveArea():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();
			var element:ElementProbe = new ElementProbe("element", deactivator, 50, 50, 2, 2);

			element.assertIsActive(false, "Outside active area");
			element.assertNotificationsCount(0, "Outside active area");

			deactivator.destroy();
		}

		private function testElementMovingOutAndBack():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();
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
			var deactivator:SpatialDeactivator = createDeactivator();
			var left:ElementProbe = new ElementProbe("left element", deactivator, 5, 5, 2, 2);
			var right:ElementProbe = new ElementProbe("right element", deactivator, 45, 45, 2, 2);

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			left.assertIsActive(false, "Active area moved away");
			right.assertIsActive(true, "Active area moved over");

			deactivator.destroy();
		}

		private function testBridgePropagation():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();

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
			var deactivator:SpatialDeactivator = createDeactivator();
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 25, 5, 2, 2);
			var nonBridge:ElementProbe = new ElementProbe("non-bridge", deactivator, 15, 5, 10, 2, false);

			nonBridge.assertIsActive(true, "Non-bridge propagation");
			outside.assertIsActive(false, "Non-bridge propagation");

			deactivator.destroy();
		}

		private function createDeactivator():SpatialDeactivator
		{
			var deactivator:SpatialDeactivator = new SpatialDeactivator(CHUNK_SIZE, CHUNK_SIZE);
			deactivator.activeAreaUpdateCooldown = 0;
			deactivator.updateActiveArea(new Rectangle(0, 0, 20, 20));
			return deactivator;
		}
	}
}
