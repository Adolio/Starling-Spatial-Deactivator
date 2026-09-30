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
	 * Destruction of elements & clearing of the deactivator.
	 *
	 * Chunks are 10 x 10 and the active area starts over the chunks (0, 0) to (1, 1).
	 */
	public class LifecycleTest implements ITest
	{
		private static const CHUNK_SIZE:Number = 10;
		private static const ACTIVE_AREA:Rectangle = new Rectangle(0, 0, 20, 20);

		public function execute():void
		{
			testElementDestroyedTwice();
			testElementDestroyedAfterClear();
			testClearWithoutNotification();
			testReuseAfterClear();
		}

		private function testElementDestroyedTwice():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();
			var destroyed:ElementProbe = new ElementProbe("destroyed element", deactivator, 5, 5, 2, 2);
			var other:ElementProbe = new ElementProbe("other element", deactivator, 5, 5, 2, 2);

			destroyed.element.destroy();
			destroyed.element.destroy();

			// the other element must still be registered in the deactivator & in its chunk
			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			other.assertIsActive(false, "Destroyed twice");

			deactivator.destroy();
		}

		private function testElementDestroyedAfterClear():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			deactivator.clear();
			element.element.destroy();

			deactivator.destroy();
		}

		private function testClearWithoutNotification():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			deactivator.clear();
			element.assertNotificationsCount(1, "Cleared");

			deactivator.destroy();
		}

		private function testReuseAfterClear():void
		{
			var deactivator:SpatialDeactivator = createDeactivator();
			new ElementProbe("cleared element", deactivator, 5, 5, 2, 2);

			deactivator.clear();
			deactivator.updateActiveArea(ACTIVE_AREA);

			var inside:ElementProbe = new ElementProbe("inside element", deactivator, 5, 5, 2, 2);
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 50, 50, 2, 2);
			inside.assertIsActive(true, "Reused after clear");
			outside.assertIsActive(false, "Reused after clear");

			inside.moveTo(50, 50, 2, 2);
			inside.assertIsActive(false, "Moved out after clear");

			deactivator.destroy();
		}

		private function createDeactivator():SpatialDeactivator
		{
			var deactivator:SpatialDeactivator = new SpatialDeactivator(CHUNK_SIZE, CHUNK_SIZE);
			deactivator.activeAreaUpdateCooldown = 0;
			deactivator.updateActiveArea(ACTIVE_AREA);
			return deactivator;
		}
	}
}
