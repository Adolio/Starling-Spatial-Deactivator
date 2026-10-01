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
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class LifecycleTest implements ITest
	{
		public function execute():void
		{
			testElementDestroyedTwice();
			testElementDestroyedAfterClear();
			testClearWithoutNotification();
			testReuseAfterClear();
		}

		private function testElementDestroyedTwice():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
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
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			deactivator.clear();
			element.element.destroy();

			deactivator.destroy();
		}

		private function testClearWithoutNotification():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			deactivator.clear();
			element.assertNotificationsCount(1, "Cleared");

			deactivator.destroy();
		}

		private function testReuseAfterClear():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			new ElementProbe("cleared element", deactivator, 5, 5, 2, 2);

			deactivator.clear();
			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());

			var inside:ElementProbe = new ElementProbe("inside element", deactivator, 5, 5, 2, 2);
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 50, 50, 2, 2);
			inside.assertIsActive(true, "Reused after clear");
			outside.assertIsActive(false, "Reused after clear");

			inside.moveTo(50, 50, 2, 2);
			inside.assertIsActive(false, "Moved out after clear");

			deactivator.destroy();
		}
	}
}
