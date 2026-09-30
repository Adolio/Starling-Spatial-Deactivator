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

	/**
	 * A spatial element owner recording the activity notifications it receives.
	 *
	 * The element has no update cooldown, so that each move is processed right away.
	 */
	public class ElementProbe
	{
		private var _name:String;
		private var _element:SpatialElement;

		// notifications
		private var _isNotifiedActive:Boolean = false;
		private var _notificationsCount:int = 0;

		public function ElementProbe(name:String, deactivator:SpatialDeactivator, x:Number, y:Number, width:Number, height:Number, isActivityBridge:Boolean = true)
		{
			_name = name;
			_element = new SpatialElement(deactivator, isActivityBridge, onActivityChanged);
			_element.updateCooldown = 0;
			_element.updateAABB(x, y, width, height);
		}

		public function moveTo(x:Number, y:Number, width:Number, height:Number):void
		{
			_element.updateAABB(x, y, width, height);
		}

		/**
		 * Checks that both the element and its notified activity match the expected activity.
		 */
		public function assertIsActive(expected:Boolean, context:String):void
		{
			Assert.isTrue(_element.isActive == expected, context + ": " + _name + " is " + (_element.isActive ? "active" : "inactive"));
			Assert.isTrue(_isNotifiedActive == expected, context + ": " + _name + " was notified " + (_isNotifiedActive ? "active" : "inactive"));
		}

		public function assertNotificationsCount(expected:int, context:String):void
		{
			Assert.equalsInt(_notificationsCount, expected, context + ": " + _name + " notifications count");
		}

		public function get element():SpatialElement
		{
			return _element;
		}

		private function onActivityChanged(isActive:Boolean):void
		{
			Assert.isTrue(isActive != _isNotifiedActive, _name + " was notified of an unchanged activity");

			_isNotifiedActive = isActive;
			_notificationsCount++;
		}
	}
}
