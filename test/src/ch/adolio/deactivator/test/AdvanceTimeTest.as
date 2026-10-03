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
	import starling.animation.IAnimatable;
	import starling.animation.Juggler;

	/**
	 * Updates deferred by the cooldowns & applied when the deactivator advances time.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class AdvanceTimeTest implements ITest
	{
		public function execute():void
		{
			testAnimatableOnly();
			testElementUpdateCooldown();
			testActiveAreaUpdateCooldown();
			testAdvancedByJuggler();
			testCallbacksWhileAdvancing();
		}

		private function testAnimatableOnly():void
		{
			var deactivator:Object = DeactivatorFactory.create();
			Assert.isTrue(deactivator is IAnimatable, "Deactivator is not animatable");
			Assert.isFalse(deactivator is Juggler, "Deactivator is a juggler");

			deactivator.destroy();
		}

		private function testElementUpdateCooldown():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);
			element.element.updateCooldown = 1;

			element.moveTo(50, 50, 2, 2);
			element.assertIsActive(true, "Moved out during update cooldown");

			deactivator.advanceTime(0.5);
			element.assertIsActive(true, "Update cooldown not over");

			deactivator.advanceTime(0.6);
			element.assertIsActive(false, "Update cooldown over");

			// the cooldown restarted with the update
			element.moveTo(5, 5, 2, 2);
			element.assertIsActive(false, "Moved back during update cooldown");

			deactivator.advanceTime(1);
			element.assertIsActive(true, "Update cooldown over again");

			deactivator.destroy();
		}

		private function testActiveAreaUpdateCooldown():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);
			deactivator.activeAreaUpdateCooldown = 1;

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			element.assertIsActive(true, "Active area moved during update cooldown");

			deactivator.advanceTime(0.5);
			element.assertIsActive(true, "Active area update cooldown not over");

			deactivator.advanceTime(0.6);
			element.assertIsActive(false, "Active area update cooldown over");

			deactivator.destroy();
		}

		private function testAdvancedByJuggler():void
		{
			var juggler:Juggler = new Juggler();
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			juggler.add(deactivator);

			var element:ElementProbe = new ElementProbe("element", deactivator, 5, 5, 2, 2);
			element.element.updateCooldown = 1;
			element.moveTo(50, 50, 2, 2);

			juggler.advanceTime(1);
			element.assertIsActive(false, "Advanced by juggler");

			juggler.remove(deactivator);
			deactivator.destroy();
		}

		private function testCallbacksWhileAdvancing():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var created:Vector.<ElementProbe> = new Vector.<ElementProbe>();
			var first:ElementProbe = new ElementProbe("first element", deactivator, 5, 5, 2, 2);
			var destroyed:ElementProbe = new ElementProbe("destroyed element", deactivator, 5, 5, 2, 2);
			var last:ElementProbe = new ElementProbe("last element", deactivator, 5, 5, 2, 2);

			// the first element destroys the next one & creates another one while the elements are advanced
			first.reaction = function(isActive:Boolean):void
			{
				destroyed.element.destroy();
				created.push(new ElementProbe("created element", deactivator, 15, 5, 2, 2));
			};

			for each (var element:ElementProbe in new <ElementProbe>[first, destroyed, last])
			{
				element.element.updateCooldown = 1;
				element.moveTo(50, 50, 2, 2);
			}

			deactivator.advanceTime(1);
			first.assertIsActive(false, "Advanced with callbacks");
			last.assertIsActive(false, "Advanced with callbacks");
			destroyed.assertNotificationsCount(1, "Destroyed while advancing");
			Assert.equalsInt(created.length, 1, "Created elements count while advancing");
			created[0].assertIsActive(true, "Created while advancing");

			deactivator.destroy();
		}
	}
}
