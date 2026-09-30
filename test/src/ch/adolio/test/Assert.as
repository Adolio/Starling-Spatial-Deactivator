// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2026 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.test
{
	public class Assert
	{
		public static function isTrue(value:Boolean, message:String):void
		{
			if (!value)
				throw new Error(message);
		}

		public static function isFalse(value:Boolean, message:String):void
		{
			if (value)
				throw new Error(message);
		}

		public static function equalsInt(value:int, expected:int, message:String):void
		{
			if (value != expected)
				throw new Error("Value: " + value + ", expected: " + expected + ". Message: " + message);
		}
	}
}
