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
	import flash.geom.Rectangle;

	/**
	 * Creates the deactivators used by the tests: 10 x 10 chunks, no active area update cooldown & an initial active area
	 * over the chunks (0, 0) to (1, 1).
	 */
	public class DeactivatorFactory
	{
		public static const CHUNK_SIZE:Number = 10;

		public static function create():SpatialDeactivator
		{
			var deactivator:SpatialDeactivator = new SpatialDeactivator(CHUNK_SIZE, CHUNK_SIZE);
			deactivator.activeAreaUpdateCooldown = 0;
			deactivator.updateActiveArea(createInitialActiveArea());
			return deactivator;
		}

		public static function createInitialActiveArea():Rectangle
		{
			return new Rectangle(0, 0, 2 * CHUNK_SIZE, 2 * CHUNK_SIZE);
		}
	}
}
