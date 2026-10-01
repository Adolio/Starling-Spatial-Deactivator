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

	/**
	 * Activity callback set after the element creation, through the <code>activityChangedCallback</code> setter.
	 *
	 * Deactivators come from <code>DeactivatorFactory</code>: 10 x 10 chunks & active area starting over the chunks (0, 0) to (1, 1).
	 */
	public class CallbackTest implements ITest
	{
		public function execute():void
		{
			testCallbackSetWhileDisabled();
			testCallbackSetOnActiveElement();
			testCallbackSetOnInactiveElement();
			testCallbackReplaced();
		}

		private function testCallbackSetWhileDisabled():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			deactivator.isEnable = false;

			var notifications:Vector.<Boolean> = new Vector.<Boolean>();
			var element:SpatialElement = createElement(deactivator, 50, 50);
			element.activityChangedCallback = createRecorder(notifications);
			assertNotifications(notifications, new <Boolean>[true], "Callback set while disabled");

			deactivator.isEnable = true;
			assertNotifications(notifications, new <Boolean>[true, false], "Enabled after callback set");

			deactivator.destroy();
		}

		private function testCallbackSetOnActiveElement():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			var notifications:Vector.<Boolean> = new Vector.<Boolean>();
			var element:SpatialElement = createElement(deactivator, 5, 5);
			element.activityChangedCallback = createRecorder(notifications);
			assertNotifications(notifications, new <Boolean>[true], "Callback set on active element");

			deactivator.destroy();
		}

		private function testCallbackSetOnInactiveElement():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			var notifications:Vector.<Boolean> = new Vector.<Boolean>();
			var element:SpatialElement = createElement(deactivator, 50, 50);
			element.activityChangedCallback = createRecorder(notifications);
			assertNotifications(notifications, new <Boolean>[], "Callback set on inactive element");

			element.updateAABB(5, 5, 2, 2);
			assertNotifications(notifications, new <Boolean>[true], "Moved in after callback set");

			deactivator.destroy();
		}

		private function testCallbackReplaced():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();

			var firstNotifications:Vector.<Boolean> = new Vector.<Boolean>();
			var element:SpatialElement = createElement(deactivator, 5, 5);
			element.activityChangedCallback = createRecorder(firstNotifications);

			// the new callback is only notified of the changes the previous one was not notified of
			var secondNotifications:Vector.<Boolean> = new Vector.<Boolean>();
			element.activityChangedCallback = createRecorder(secondNotifications);
			assertNotifications(secondNotifications, new <Boolean>[], "Callback replaced");

			element.updateAABB(50, 50, 2, 2);
			assertNotifications(firstNotifications, new <Boolean>[true], "Moved out after callback replaced");
			assertNotifications(secondNotifications, new <Boolean>[false], "Moved out after callback replaced");

			deactivator.destroy();
		}

		private function createElement(deactivator:SpatialDeactivator, x:Number, y:Number):SpatialElement
		{
			var element:SpatialElement = new SpatialElement(deactivator);
			element.updateCooldown = 0;
			element.updateAABB(x, y, 2, 2);
			return element;
		}

		private function createRecorder(notifications:Vector.<Boolean>):Function
		{
			return function(isActive:Boolean):void
			{
				notifications.push(isActive);
			};
		}

		private function assertNotifications(notifications:Vector.<Boolean>, expected:Vector.<Boolean>, context:String):void
		{
			Assert.isTrue(notifications.join() == expected.join(), context + ": notifications [" + notifications.join() + "], expected [" + expected.join() + "]");
		}
	}
}
