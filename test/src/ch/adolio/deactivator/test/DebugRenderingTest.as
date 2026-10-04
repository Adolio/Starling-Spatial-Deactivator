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
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;

	/**
	 * Content of the debug sprite: one quad for the active area, one per chunk & one per element.
	 *
	 * The deactivator has 10 x 10 chunks & an active area over the chunks (0, 0) to (1, 1).
	 */
	public class DebugRenderingTest implements ITest
	{
		public function execute():void
		{
			testQuadsFollowContext();
			testRuntimeToggle();
			testDebugSpriteRemovedOnDestroy();
			testElementQuadsShowActivity();
		}

		private function testQuadsFollowContext():void
		{
			var deactivator:SpatialDeactivator = new SpatialDeactivator(DeactivatorFactory.CHUNK_SIZE, DeactivatorFactory.CHUNK_SIZE, true);
			deactivator.activeAreaUpdateCooldown = 0;
			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());

			var debugSprite:Sprite = deactivator.debugSprite;
			Assert.equalsInt(debugSprite.numChildren, 1, "Active area quad");

			var first:ElementProbe = new ElementProbe("first element", deactivator, 5, 5, 2, 2);
			var second:ElementProbe = new ElementProbe("second element", deactivator, 15, 5, 3, 4);
			Assert.equalsInt(debugSprite.numChildren, 5, "Active area, 2 chunks & 2 elements quads");

			// the quad of a moved element follows it & keeps its depth, under the quad of the second element
			first.moveTo(6, 7, 2, 2);
			Assert.equalsInt(debugSprite.numChildren, 5, "Quads after an element moved");
			assertQuadPosition(debugSprite.getChildAt(3), 6, 7, "Moved element quad");
			assertQuadPosition(debugSprite.getChildAt(4), 15, 5, "Top quad after an element moved");

			// the chunk left by the destroyed element is still active, so it is kept
			first.element.destroy();
			Assert.equalsInt(debugSprite.numChildren, 4, "Quads after an element was destroyed");

			deactivator.clear();
			Assert.equalsInt(debugSprite.numChildren, 1, "Quads after clearing");

			deactivator.destroy();
		}

		private function testRuntimeToggle():void
		{
			var deactivator:SpatialDeactivator = DeactivatorFactory.create();
			Assert.isTrue(!deactivator.isDebugRenderingEnabled && deactivator.debugSprite == null, "Debug rendering disabled by default");

			var first:ElementProbe = new ElementProbe("first element", deactivator, 5, 5, 2, 2);
			var second:ElementProbe = new ElementProbe("second element", deactivator, 15, 5, 3, 4);

			// quads are created for the existing chunks & elements, the elements on top
			deactivator.isDebugRenderingEnabled = true;
			var debugSprite:Sprite = deactivator.debugSprite;
			var parent:Sprite = new Sprite();
			parent.addChild(debugSprite);
			Assert.isTrue(deactivator.isDebugRenderingEnabled, "Debug rendering enabled");
			Assert.equalsInt(debugSprite.numChildren, 5, "Active area, 2 chunks & 2 elements quads after enabling");
			assertQuadPosition(debugSprite.getChildAt(3), 5, 5, "First element quad after enabling");
			assertQuadPosition(debugSprite.getChildAt(4), 15, 5, "Second element quad after enabling");

			// quads keep following the context
			first.moveTo(6, 7, 2, 2);
			assertQuadPosition(debugSprite.getChildAt(3), 6, 7, "Moved element quad after enabling");

			deactivator.isDebugRenderingEnabled = false;
			Assert.isTrue(!deactivator.isDebugRenderingEnabled && deactivator.debugSprite == null, "Debug rendering disabled");
			Assert.equalsInt(parent.numChildren, 0, "Debug sprite removed from its parent");

			// the context keeps working without debug rendering
			second.moveTo(16, 5, 3, 4);
			first.element.destroy();

			deactivator.isDebugRenderingEnabled = true;
			Assert.equalsInt(deactivator.debugSprite.numChildren, 4, "Active area, 2 chunks & 1 element quads after enabling again");

			deactivator.destroy();
			parent.dispose();
		}

		private function testDebugSpriteRemovedOnDestroy():void
		{
			var deactivator:SpatialDeactivator = new SpatialDeactivator(DeactivatorFactory.CHUNK_SIZE, DeactivatorFactory.CHUNK_SIZE, true);
			var parent:Sprite = new Sprite();
			parent.addChild(deactivator.debugSprite);
			new ElementProbe("element", deactivator, 5, 5, 2, 2);

			deactivator.destroy();
			Assert.isTrue(!deactivator.isDebugRenderingEnabled && deactivator.debugSprite == null, "Debug rendering destroyed");
			Assert.equalsInt(parent.numChildren, 0, "Debug sprite removed from its parent on destroy");

			parent.dispose();
		}

		private function testElementQuadsShowActivity():void
		{
			var deactivator:SpatialDeactivator = new SpatialDeactivator(DeactivatorFactory.CHUNK_SIZE, DeactivatorFactory.CHUNK_SIZE, true);
			deactivator.activeAreaUpdateCooldown = 0;
			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());
			new ElementProbe("bridge", deactivator, 5, 5, 2, 2);
			new ElementProbe("non-bridge", deactivator, 5, 5, 2, 2, false);

			// quads above the chunk & the active area ones
			var bridgeQuad:Quad = deactivator.debugSprite.getChildAt(2) as Quad;
			var nonBridgeQuad:Quad = deactivator.debugSprite.getChildAt(3) as Quad;
			var activeBridgeColor:uint = bridgeQuad.color;
			var activeNonBridgeColor:uint = nonBridgeQuad.color;
			var activeAlpha:Number = bridgeQuad.alpha;
			Assert.isTrue(activeBridgeColor != activeNonBridgeColor, "Active bridge & non-bridge quads have the same color");
			Assert.isTrue(nonBridgeQuad.alpha == activeAlpha, "Active bridge & non-bridge quads have different alphas");

			deactivator.updateActiveArea(new Rectangle(40, 40, 20, 20));
			Assert.isTrue(bridgeQuad.color != activeBridgeColor && bridgeQuad.alpha < activeAlpha, "Inactive bridge quad looks active");
			Assert.isTrue(nonBridgeQuad.color != activeNonBridgeColor && nonBridgeQuad.alpha < activeAlpha, "Inactive non-bridge quad looks active");

			deactivator.updateActiveArea(DeactivatorFactory.createInitialActiveArea());
			Assert.isTrue(bridgeQuad.color == activeBridgeColor && bridgeQuad.alpha == activeAlpha, "Active bridge quad looks inactive");
			Assert.isTrue(nonBridgeQuad.color == activeNonBridgeColor && nonBridgeQuad.alpha == activeAlpha, "Active non-bridge quad looks inactive");

			deactivator.destroy();
		}

		private function assertQuadPosition(quad:DisplayObject, x:Number, y:Number, context:String):void
		{
			Assert.isTrue(quad.x == x && quad.y == y, context + ": position (" + quad.x + ", " + quad.y + "), expected (" + x + ", " + y + ")");
		}
	}
}
