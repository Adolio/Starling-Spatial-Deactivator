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
	 * Activity propagation along a long chain of bridges, which must not overflow the stack.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>, with the active area reduced to the chunk (0, 0). The bridge
	 * of index i covers the chunks (i, 0) & (i + 1, 0), and the end element the chunk after the last bridge.
	 */
	public class BridgeChainTest implements ITest
	{
		private static const BRIDGES_COUNT:int = 10000;

		public function execute():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			var chunkSize:Number = DeactivatorFactory.CHUNK_SIZE;
			deactivator.updateActiveArea(new Rectangle(0, 0, chunkSize, chunkSize));

			// build the chain from its end, so that it stays inactive until its first bridge links it to the active area
			var end:ElementProbe = new ElementProbe("end element", deactivator, (BRIDGES_COUNT + 0.5) * chunkSize, 5, 2, 2);
			var bridges:Vector.<ElementProbe> = new Vector.<ElementProbe>();
			for (var i:int = BRIDGES_COUNT - 1; i > 0; --i)
				bridges.push(new ElementProbe("bridge " + i, deactivator, (i + 0.5) * chunkSize, 5, chunkSize, 2));

			end.assertIsActive(false, "Chain not linked");

			// activation propagated along the whole chain
			var first:ElementProbe = new ElementProbe("first bridge", deactivator, 0.5 * chunkSize, 5, chunkSize, 2);
			end.assertIsActive(true, "Chain linked");

			// linked chunks found along the whole chain
			deactivator.updateChunksActivity();
			end.assertIsActive(true, "Chain linked & chunks activity updated");

			first.element.destroy();
			end.assertIsActive(false, "Chain unlinked");

			deactivator.destroy();
		}
	}
}
