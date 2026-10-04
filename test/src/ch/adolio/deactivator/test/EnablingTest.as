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
	import ch.adolio.deactivator.SpatialElement;
	import ch.adolio.test.Assert;
	import ch.adolio.test.ITest;
	import flash.geom.Rectangle;

	/**
	 * Disabling & re-enabling the deactivator.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class EnablingTest implements ITest
	{
		public function execute():void
		{
			testNoDeactivationWhileDisabled();
			testEnabledAfterMovingIn();
			testEnabledAfterMovingOut();
			testEnabledAfterActiveAreaMoved();
			testEnabledAfterElementCreated();
			testEnabledAfterElementCreatedWithoutPosition();
			testDeprecatedAlias();
		}

		private function testNoDeactivationWhileDisabled():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);
			var outside:ElementProbe = new ElementProbe("outside element", deactivator, 50, 50, 2, 2);

			deactivator.isEnabled = false;
			outside.assertIsActive(true, "Disabled");

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			element.assertIsActive(true, "Active area moved while disabled");

			deactivator.updateChunksActivity();
			element.assertIsActive(true, "Chunks activity updated while disabled");

			deactivator.advanceTime(1);
			element.assertIsActive(true, "Time advanced while disabled");

			element.moveTo(90, 90, 2, 2);
			element.assertIsActive(true, "Moved out while disabled");

			element.element.isActivityBridge = false;
			element.assertIsActive(true, "Stopped being a bridge while disabled");

			element.assertNotificationsCount(1, "Disabled");

			deactivator.destroy();
		}

		private function testEnabledAfterMovingIn():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 50, 50, 2, 2);

			deactivator.isEnabled = false;
			element.moveTo(5, 5, 2, 2);
			deactivator.isEnabled = true;

			// activated by the disabling, never toggled off & on again
			element.assertIsActive(true, "Enabled after moving in");
			element.assertNotificationsCount(1, "Enabled after moving in");

			deactivator.destroy();
		}

		private function testEnabledAfterMovingOut():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);

			deactivator.isEnabled = false;
			element.moveTo(50, 50, 2, 2);
			deactivator.isEnabled = true;

			element.assertIsActive(false, "Enabled after moving out");
			element.assertNotificationsCount(2, "Enabled after moving out");

			deactivator.destroy();
		}

		private function testEnabledAfterActiveAreaMoved():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var left:ElementProbe = new ElementProbe("left element", deactivator, 5, 5, 2, 2);
			var right:ElementProbe = new ElementProbe("right element", deactivator, 45, 45, 2, 2);

			deactivator.isEnabled = false;
			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			deactivator.isEnabled = true;

			left.assertIsActive(false, "Enabled after active area moved away");
			right.assertIsActive(true, "Enabled after active area moved over");
			right.assertNotificationsCount(1, "Enabled after active area moved over");

			deactivator.destroy();
		}

		private function testEnabledAfterElementCreated():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var neighbor:ElementProbe = new ElementProbe("neighbor", deactivator, 95, 5, 2, 2);

			// the new bridge must not activate its chunks, far from the active area
			deactivator.isEnabled = false;
			var created:ElementProbe = new ElementProbe("created element", deactivator, 91, 5, 2, 2);
			deactivator.isEnabled = true;

			created.assertIsActive(false, "Enabled after element created");
			neighbor.assertIsActive(false, "Enabled after element created");

			created.moveTo(92, 5, 2, 2);
			created.assertIsActive(false, "Moved after enabling");
			neighbor.assertIsActive(false, "Neighbor moved after enabling");

			deactivator.destroy();
		}

		private function testEnabledAfterElementCreatedWithoutPosition():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			deactivator.isEnabled = false;
			var element:SpatialElement = new SpatialElement(deactivator);
			Assert.isTrue(element.isActive, "Created while disabled: element is inactive");

			// without position, the element covers no chunk
			deactivator.isEnabled = true;
			Assert.isFalse(element.isActive, "Enabled after element created without position: element is active");

			deactivator.destroy();
		}

		private function testDeprecatedAlias():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 50, 50, 2, 2);

			// accessed by name, a direct access raising a deprecation warning
			deactivator["isEnable"] = false;
			Assert.isFalse(deactivator.isEnabled, "Disabled through the deprecated alias: deactivator is enabled");
			Assert.isFalse(deactivator["isEnable"], "Disabled through the deprecated alias: alias is enabled");
			element.assertIsActive(true, "Disabled through the deprecated alias");

			deactivator["isEnable"] = true;
			Assert.isTrue(deactivator.isEnabled && deactivator["isEnable"], "Enabled through the deprecated alias");
			element.assertIsActive(false, "Enabled through the deprecated alias");

			deactivator.destroy();
		}
	}
}
