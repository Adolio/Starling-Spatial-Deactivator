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
	import ch.adolio.test.ITest;
	import flash.geom.Rectangle;
	import starling.animation.Juggler;

	/**
	 * Destruction of elements, clearing & destruction of the deactivator.
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
			testLinkingBridgeDestroyed();
			testLinkingBridgeDestroyedWhileDisabled();
			testSpanningNonBridgeDestroyed();
			testDeactivatorDestroyedTwice();
			testDeactivatorDestroyedInJuggler();
			testDeactivatorDestroyedFromCallback();
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

		private function testLinkingBridgeDestroyed():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			// the outside element is only linked to the active area by the bridge, which covers the chunks (1, 0) & (2, 0)
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 25, 5, 2, 2);
			var bridge:ElementProbe = new ElementProbe("bridge", deactivator, 15, 5, 10, 2);
			outside.assertIsActive(true, "Linked by bridge");

			bridge.element.destroy();
			outside.assertIsActive(false, "Linking bridge destroyed");
			outside.assertNotificationsCount(2, "Linking bridge destroyed");

			deactivator.destroy();
		}

		private function testLinkingBridgeDestroyedWhileDisabled():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 25, 5, 2, 2);
			var bridge:ElementProbe = new ElementProbe("bridge", deactivator, 15, 5, 10, 2);

			deactivator.isEnabled = false;
			bridge.element.destroy();
			outside.assertIsActive(true, "Linking bridge destroyed while disabled");

			deactivator.isEnabled = true;
			outside.assertIsActive(false, "Enabled after linking bridge destroyed");

			deactivator.destroy();
		}

		private function testSpanningNonBridgeDestroyed():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var inside:ElementProbe = new ElementProbe("inside element", deactivator, 5, 5, 2, 2);
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 25, 5, 2, 2);
			var nonBridge:ElementProbe = new ElementProbe("non-bridge", deactivator, 15, 5, 10, 2, false);

			nonBridge.element.destroy();
			inside.assertIsActive(true, "Spanning non-bridge destroyed");
			outside.assertIsActive(false, "Spanning non-bridge destroyed");
			inside.assertNotificationsCount(1, "Spanning non-bridge destroyed");

			deactivator.destroy();
		}

		private function testDeactivatorDestroyedTwice():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			deactivator.destroy();
			deactivator.destroy();

			element.element.destroy();
			element.assertNotificationsCount(1, "Deactivator destroyed twice");
		}

		private function testDeactivatorDestroyedInJuggler():void
		{
			var juggler:Juggler = new Juggler();
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			juggler.add(deactivator);
			new ElementProbe("element", deactivator, 5, 5, 2, 2);

			// a destroyed deactivator left in its juggler must not fail when advanced
			deactivator.destroy();
			juggler.advanceTime(1);
		}

		private function testDeactivatorDestroyedFromCallback():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var destroyer:ElementProbe = new ElementProbe("destroyer", deactivator, 5, 5, 2, 2);
			var other:ElementProbe = new ElementProbe("other element", deactivator, 5, 5, 2, 2);
			destroyer.reaction = function(isActive:Boolean):void
			{
				if (!isActive)
					deactivator.destroy();
			};

			// the pending deactivation of the other element is dropped
			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			destroyer.assertNotificationsCount(2, "Deactivator destroyed from callback");
			other.assertNotificationsCount(1, "Deactivator destroyed from callback");
		}
	}
}
