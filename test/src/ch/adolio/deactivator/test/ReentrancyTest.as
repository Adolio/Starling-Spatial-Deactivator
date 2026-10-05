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
	 * Activity callbacks destroying, creating or moving elements.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class ReentrancyTest implements ITest
	{
		public function execute():void
		{
			testElementsDestroyingThemselves();
			testElementDestroyingAnother();
			testElementCreatingElements();
			testElementMovingAnother();
		}

		private function testElementsDestroyingThemselves():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			// despawn when inactive, with several elements in the same chunk
			var despawning:Vector.<ElementProbe> = new Vector.<ElementProbe>();
			for (var i:int = 0; i < 4; ++i)
			{
				var probe:ElementProbe = new ElementProbe("despawning element " + i, deactivator, 5, 5, 2, 2);
				probe.reaction = createDestroyOnDeactivation(probe);
				despawning.push(probe);
			}

			var survivor:ElementProbe = new ElementProbe("survivor", deactivator, 5, 5, 2, 2);

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			for each (probe in despawning)
			{
				probe.assertIsActive(false, "Despawned");
				probe.assertNotificationsCount(2, "Despawned");
			}

			survivor.assertIsActive(false, "Despawned neighbors");

			// the survivor must still be in its chunk & the despawned elements must not be notified anymore
			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());
			survivor.assertIsActive(true, "Back after despawned neighbors");
			for each (probe in despawning)
				probe.assertNotificationsCount(2, "Back after despawn");

			deactivator.destroy();
		}

		private function testElementDestroyingAnother():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var destroyer:ElementProbe = new ElementProbe("destroyer", deactivator, 5, 5, 2, 2);
			var destroyed:ElementProbe = new ElementProbe("destroyed element", deactivator, 5, 5, 2, 2);
			destroyer.reaction = function(isActive:Boolean):void
			{
				if (!isActive)
					destroyed.element.destroy();
			};

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			destroyer.assertIsActive(false, "Destroyed another");

			// the pending deactivation of the destroyed element is dropped
			destroyed.assertNotificationsCount(1, "Destroyed by another");

			deactivator.destroy();
		}

		private function testElementCreatingElements():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var created:Vector.<ElementProbe> = new Vector.<ElementProbe>();

			// one element is created in the new active area, the other one in a chunk not existing yet
			var creator:ElementProbe = new ElementProbe("creator", deactivator, 45, 45, 2, 2);
			creator.reaction = function(isActive:Boolean):void
			{
				if (isActive && created.length == 0)
				{
					created.push(new ElementProbe("created inside element", deactivator, 55, 55, 2, 2));
					created.push(new ElementProbe("created outside element", deactivator, 95, 95, 2, 2));
				}
			};

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			creator.assertIsActive(true, "Created elements");
			Assert.equalsInt(created.length, 2, "Created elements count");
			created[0].assertIsActive(true, "Created from callback");
			created[1].assertIsActive(false, "Created from callback");

			deactivator.destroy();
		}

		private function testElementMovingAnother():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var mover:ElementProbe = new ElementProbe("mover", deactivator, 45, 45, 2, 2);
			var moved:ElementProbe = new ElementProbe("moved element", deactivator, 95, 95, 2, 2);
			mover.reaction = function(isActive:Boolean):void
			{
				if (isActive)
					moved.moveTo(55, 55, 2, 2);
				else
					moved.moveTo(95, 95, 2, 2);
			};

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			mover.assertIsActive(true, "Moved another in");
			moved.assertIsActive(true, "Moved in from callback");

			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());
			mover.assertIsActive(false, "Moved another out");
			moved.assertIsActive(false, "Moved out from callback");

			deactivator.destroy();
		}

		private function createDestroyOnDeactivation(probe:ElementProbe):Function
		{
			return function(isActive:Boolean):void
			{
				if (!isActive)
					probe.element.destroy();
			};
		}
	}
}
