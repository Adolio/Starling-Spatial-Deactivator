// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017-2026 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package
{
	import ch.adolio.deactivator.SpatialDeactivator;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextField;
	import starling.text.TextFormat;
	import starling.utils.Align;

	/**
	 * Demo of the Spatial Deactivator: the active area follows the pointer & the keyboard toggles the features
	 * listed by the help panel.
	 */
	public class SpatialDeactivatorDemo extends Sprite
	{
		private static const STATIC_OBJECTS_COUNT:int = 128;
		private static const MOVING_OBJECTS_COUNT:int = 512;
		private static const DESTROYED_OBJECTS_RATIO:Number = 0.1;

		// Deactivator
		private var _deactivator:SpatialDeactivator;

		// Active area
		private var _activeAreaAABB:Rectangle = new Rectangle();
		private var _activeArea:Quad = new Quad(120, 80, 0xffffff);
		private var _activeAreaTargetX:Number;
		private var _activeAreaTargetY:Number;

		// Game objects
		private var _objects:Vector.<GameObject> = new Vector.<GameObject>();
		private var _objectsLayer:Sprite = new Sprite();
		private var _isTeleportationEnabled:Boolean = false;
		private var _areMovingObjectsBridges:Boolean = true;

		// Help
		private var _helpPanel:Sprite = new Sprite();
		private var _helpText:TextField;

		public function SpatialDeactivatorDemo()
		{
			_deactivator = new SpatialDeactivator(_activeArea.width * 0.25, _activeArea.height * 0.25);
			Starling.current.juggler.add(_deactivator);

			// Setup initial view target
			_activeAreaTargetX = Starling.current.stage.stageWidth * 0.5;
			_activeAreaTargetY = Starling.current.stage.stageHeight * 0.5;

			// Create active area, shown with the game objects when the debug rendering is off
			_activeArea.alpha = 0.5;
			_activeArea.x = _activeAreaTargetX - _activeArea.width * 0.5;
			_activeArea.y = _activeAreaTargetY - _activeArea.height * 0.5;
			_objectsLayer.addChild(_activeArea);
			addChild(_objectsLayer);

			createHelpPanel();
			createObjects();
			updateDeactivatorActiveArea();
			setDebugRenderingEnabled(true);
			updateHelpText();

			// Register event listeners
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		// --------------------------------------------------------------------
		// -- Game objects
		// --------------------------------------------------------------------

		private function createObjects():void
		{
			var i:int;

			for (i = 0; i < STATIC_OBJECTS_COUNT; ++i)
				createObject(8 + Math.random() * 32, 8 + Math.random() * 32, true);

			for (i = 0; i < MOVING_OBJECTS_COUNT; ++i)
				createObject(2 + Math.random() * 8, 2 + Math.random() * 8, false);
		}

		private function createObject(width:Number, height:Number, isStatic:Boolean):void
		{
			var go:GameObject = new GameObject(
				Math.random() * Starling.current.stage.stageWidth,
				Math.random() * Starling.current.stage.stageHeight,
				width,
				height,
				_deactivator,
				isStatic
			);
			go.isTeleportationEnabled = _isTeleportationEnabled;

			if (!isStatic)
				go.isActivityBridge = _areMovingObjectsBridges;

			// Keep the active area above the game objects
			_objectsLayer.addChildAt(go, _objectsLayer.numChildren - 1);
			_objects.push(go);
		}

		private function destroySomeObjects():void
		{
			var count:int = Math.ceil(_objects.length * DESTROYED_OBJECTS_RATIO);
			for (var i:int = 0; i < count; ++i)
				_objects.removeAt(int(Math.random() * _objects.length)).destroy();
		}

		private function clearAndRecreateObjects():void
		{
			// Clearing the deactivator destroys the spatial elements & resets the active area
			_deactivator.clear();

			for each (var go:GameObject in _objects)
				go.destroy();

			_objects.length = 0;

			createObjects();
			updateDeactivatorActiveArea();
		}

		// --------------------------------------------------------------------
		// -- Options
		// --------------------------------------------------------------------

		private function setDebugRenderingEnabled(value:Boolean):void
		{
			_deactivator.isDebugRenderingEnabled = value;

			// The debug rendering replaces the game objects graphics, under the help panel
			if (value)
				addChildAt(_deactivator.debugSprite, getChildIndex(_helpPanel));

			_objectsLayer.visible = !value;
		}

		private function setTeleportationEnabled(value:Boolean):void
		{
			_isTeleportationEnabled = value;

			for each (var go:GameObject in _objects)
				go.isTeleportationEnabled = value;
		}

		private function setMovingObjectsAsBridges(value:Boolean):void
		{
			_areMovingObjectsBridges = value;

			for each (var go:GameObject in _objects)
			{
				if (!go.isStatic)
					go.isActivityBridge = value;
			}
		}

		// --------------------------------------------------------------------
		// -- Help
		// --------------------------------------------------------------------

		private function createHelpPanel():void
		{
			var width:Number = 300;
			var height:Number = 96;
			var margin:Number = 6;

			var background:Quad = new Quad(width, height, 0x000000);
			background.alpha = 0.7;
			_helpPanel.addChild(background);

			_helpText = new TextField(width - 2 * margin, height - 2 * margin, "", new TextFormat("Verdana", 11, 0xffffff, Align.LEFT, Align.TOP));
			_helpText.x = margin;
			_helpText.y = margin;
			_helpPanel.addChild(_helpText);

			_helpPanel.touchable = false;
			_helpPanel.x = margin;
			_helpPanel.y = Starling.current.stage.stageHeight - height - margin;
			addChild(_helpPanel);
		}

		private function updateHelpText():void
		{
			_helpText.text =
				"[E] Deactivator: " + (_deactivator.isEnabled ? "enabled" : "disabled") + "\n" +
				"[D] Debug rendering: " + (_deactivator.isDebugRenderingEnabled ? "on" : "off") + "\n" +
				"[T] Teleportation of active objects: " + (_isTeleportationEnabled ? "on" : "off") + "\n" +
				"[B] Moving objects as activity bridges: " + (_areMovingObjectsBridges ? "on" : "off") + "\n" +
				"[X] Destroy " + Math.round(DESTROYED_OBJECTS_RATIO * 100) + "% of the " + _objects.length + " objects\n" +
				"[C] Clear the deactivator & recreate the objects";
		}

		// --------------------------------------------------------------------
		// -- Active area
		// --------------------------------------------------------------------

		private function updateDeactivatorActiveArea():void
		{
			_activeAreaAABB.setTo(_activeArea.x, _activeArea.y, _activeArea.width, _activeArea.height);
			_deactivator.updateActiveArea(_activeAreaAABB);
		}

		private function lerp(v0:Number, v1:Number, t:Number):Number
		{
			return (1.0 - t) * v0 + t * v1;
		}

		// --------------------------------------------------------------------
		// -- Event handlers
		// --------------------------------------------------------------------

		private function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(TouchEvent.TOUCH, onStageTouched);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		private function onEnterFrame(e:EnterFrameEvent):void
		{
			var oldx:Number = _activeArea.x;
			var oldy:Number = _activeArea.y;

			// Animate the active area, without overshooting the target on long frames
			var t:Number = Math.min(1, e.passedTime * 10);
			_activeArea.x = lerp(_activeArea.x, _activeAreaTargetX - _activeArea.width * 0.5, t);
			_activeArea.y = lerp(_activeArea.y, _activeAreaTargetY - _activeArea.height * 0.5, t);

			// Update active area if view changed
			if (_activeArea.x != oldx || _activeArea.y != oldy)
				updateDeactivatorActiveArea();
		}

		private function onStageTouched(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(stage);
			if (touch)
			{
				if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED)
				{
					_activeAreaTargetX = touch.globalX;
					_activeAreaTargetY = touch.globalY;
				}
			}
		}

		private function onKeyDown(e:KeyboardEvent):void
		{
			switch (e.keyCode)
			{
				case Keyboard.E:
					_deactivator.isEnabled = !_deactivator.isEnabled;
					break;

				case Keyboard.D:
					setDebugRenderingEnabled(!_deactivator.isDebugRenderingEnabled);
					break;

				case Keyboard.T:
					setTeleportationEnabled(!_isTeleportationEnabled);
					break;

				case Keyboard.B:
					setMovingObjectsAsBridges(!_areMovingObjectsBridges);
					break;

				case Keyboard.X:
					destroySomeObjects();
					break;

				case Keyboard.C:
					clearAndRecreateObjects();
					break;

				default:
					return;
			}

			updateHelpText();
		}
	}
}
