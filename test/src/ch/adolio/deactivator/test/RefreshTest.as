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

	/**
	 * Bridge moves which must, or must not, refresh the activity of all the chunks.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 *
	 * A refresh is detected through a pending active area update: the active area is moved away with a cooldown, so
	 * that the move is only applied by the next refresh, which deactivates the witness element left in the initial
	 * active area.
	 */
	public class RefreshTest implements ITest
	{
		private var _deactivator:SpatialDeactivator;
		private var _witness:ElementProbe;

		public function execute():void
		{
			testInactiveBridgeCrossingChunks();
			testInactiveBridgeEnteringActiveArea();
			testActiveBridgeCrossingChunksOverActiveArea();
			testActiveBridgeLeavingChunkOutOfActiveArea();
			testActiveBridgeLeavingActiveArea();
		}

		private function testInactiveBridgeCrossingChunks():void
		{
			setUp();
			var bridge:ElementProbe = new ElementProbe("bridge", _deactivator, 50, 50, 2, 2);

			holdActiveAreaUpdate();
			bridge.moveTo(60, 50, 2, 2);
			bridge.assertIsActive(false, "Inactive bridge crossed chunks");
			assertRefreshed(false, "Inactive bridge crossed chunks");

			tearDown();
		}

		private function testInactiveBridgeEnteringActiveArea():void
		{
			setUp();
			var outside:ElementProbe = new ElementProbe("outside element", _deactivator, 25, 5, 2, 2);
			var bridge:ElementProbe = new ElementProbe("bridge", _deactivator, 50, 50, 2, 2);

			// the bridge enters the chunk (1, 0) of the active area & the chunk (2, 0) of the outside element
			holdActiveAreaUpdate();
			bridge.moveTo(15, 5, 10, 2);
			bridge.assertIsActive(true, "Inactive bridge entered the active area");
			outside.assertIsActive(true, "Inactive bridge entered the active area");
			assertRefreshed(false, "Inactive bridge entered the active area");

			tearDown();
		}

		private function testActiveBridgeCrossingChunksOverActiveArea():void
		{
			setUp();
			var outside:ElementProbe = new ElementProbe("outside element", _deactivator, 25, 5, 2, 2);
			var bridge:ElementProbe = new ElementProbe("bridge", _deactivator, 5, 5, 2, 2);

			// from the chunk (0, 0) to the chunks (1, 0) & (2, 0)
			holdActiveAreaUpdate();
			bridge.moveTo(15, 5, 10, 2);
			bridge.assertIsActive(true, "Active bridge crossed chunks over the active area");
			outside.assertIsActive(true, "Active bridge crossed chunks over the active area");
			assertRefreshed(false, "Active bridge crossed chunks over the active area");
			bridge.assertNotificationsCount(1, "Active bridge crossed chunks over the active area");

			tearDown();
		}

		private function testActiveBridgeLeavingChunkOutOfActiveArea():void
		{
			setUp();
			var outside:ElementProbe = new ElementProbe("outside element", _deactivator, 25, 5, 2, 2);
			var bridge:ElementProbe = new ElementProbe("bridge", _deactivator, 15, 5, 10, 2);
			outside.assertIsActive(true, "Linked by bridge");

			// the bridge leaves the chunk (2, 0), which it was the only one to link to the active area
			holdActiveAreaUpdate();
			bridge.moveTo(15, 5, 2, 2);
			outside.assertIsActive(false, "Active bridge left a chunk out of the active area");
			assertRefreshed(true, "Active bridge left a chunk out of the active area");

			tearDown();
		}

		private function testActiveBridgeLeavingActiveArea():void
		{
			setUp();
			var bridge:ElementProbe = new ElementProbe("bridge", _deactivator, 5, 5, 2, 2);

			holdActiveAreaUpdate();
			bridge.moveTo(50, 50, 2, 2);
			bridge.assertIsActive(false, "Active bridge left the active area");
			assertRefreshed(true, "Active bridge left the active area");

			tearDown();
		}

		private function setUp():void
		{
			_deactivator = DeactivatorFactory.create();
			_witness = new ElementProbe("witness", _deactivator, 5, 15, 2, 2);
		}

		private function tearDown():void
		{
			_deactivator.destroy();
			_deactivator = null;
			_witness = null;
		}

		private function holdActiveAreaUpdate():void
		{
			_deactivator.activeAreaUpdateCooldown = 1000;
			_deactivator.updateActiveArea(new Rectangle(1000, 1000, 20, 20));
			_witness.assertIsActive(true, "Active area update held");
		}

		private function assertRefreshed(expected:Boolean, context:String):void
		{
			_witness.assertIsActive(!expected, context + (expected ? ": not refreshed" : ": refreshed"));
		}
	}
}
