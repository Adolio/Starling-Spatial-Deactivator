// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017-2021 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.deactivator
{
	import starling.display.Quad;

	/**
	 * A spatial cell in the regular spatial grid defined by the Spatial Deactivator.
	 *
	 * Used internally to separate space into areas.
	 *
	 * @see SpatialDeactivator
	 */
	internal class SpatialChunk
	{
		// Chunk management
		private var _gridX:int;
		private var _gridY:int;
		private var _isActive:Boolean = false;
		private var _elements:Vector.<SpatialElement> = new Vector.<SpatialElement>();
		private var _linkStamp:uint = 0;

		// Debug mode
		private var _debugQuad:Quad;
		private static const _COLOR:uint = 0x33D022;
		private static const _ACTIVE_ALPHA:Number = 0.4;
		private static const _INACTIVE_ALPHA:Number = 0.1;

		public function SpatialChunk(deactivator:SpatialDeactivator, gridX:int, gridY:int, debugRendering:Boolean = false)
		{
			_gridX = gridX;
			_gridY = gridY;

			// Debug mode
			if (debugRendering)
				createDebugQuad(deactivator);
		}

		// --------------------------------------------------------------------
		// -- Private / internal methods
		// --------------------------------------------------------------------

		internal function destroy():void
		{
			destroyDebugQuad();

			// Clear elements
			_elements.splice(0, _elements.length);

			// Nullify references
			_elements = null;
		}

		/**
		 * Creates the debug quad, which must be added to the debug sprite by the caller.
		 */
		internal function createDebugQuad(deactivator:SpatialDeactivator):Quad
		{
			var marginX:Number = 2.0;
			var marginY:Number = 2.0;
			_debugQuad = new Quad(deactivator.chunkWidth - marginX, deactivator.chunkHeight - marginY, _COLOR);
			_debugQuad.alpha = _isActive ? _ACTIVE_ALPHA : _INACTIVE_ALPHA;
			_debugQuad.x = _gridX * deactivator.chunkWidth + marginX * 0.5;
			_debugQuad.y = _gridY * deactivator.chunkHeight + marginY * 0.5;

			return _debugQuad;
		}

		internal function destroyDebugQuad():void
		{
			if (!_debugQuad)
				return;

			_debugQuad.removeFromParent(true);
			_debugQuad = null;
		}

		internal function activate(propagate:Boolean):void
		{
			if (_isActive)
				return;

			_isActive = true;

			// Update debug rendering
			if(_debugQuad)
				_debugQuad.alpha = _ACTIVE_ALPHA; // Graphics debug

			// Update touched elements
			var elementsCount:int = _elements.length;
			for (var i:int = 0; i < elementsCount; ++i)
				_elements[i].activate(propagate);
		}

		internal function deactivate():void
		{
			if (!_isActive)
				return;

			_isActive = false;

			// Update debug rendering
			if(_debugQuad)
				_debugQuad.alpha = _INACTIVE_ALPHA; // Graphics debug

			// Update touched elements
			var elementsCount:int = _elements.length;
			for (var i:int = 0; i < elementsCount; ++i) {
				_elements[i].checkActivityFromCoveredChunks();
			}
		}

		internal function get isActive():Boolean
		{
			return _isActive;
		}

		internal function get elements():Vector.<SpatialElement>
		{
			return _elements;
		}

		internal function get debugQuad():Quad
		{
			return _debugQuad;
		}

		internal function get gridX():int
		{
			return _gridX;
		}

		internal function get gridY():int
		{
			return _gridY;
		}

		/**
		 * Stamp of the last activity refresh which linked the chunk to the active area.
		 */
		internal function get linkStamp():uint
		{
			return _linkStamp;
		}

		internal function set linkStamp(value:uint):void
		{
			_linkStamp = value;
		}

		internal function addElement(value:SpatialElement):void
		{
			if (_elements.indexOf(value) == -1)
				_elements.push(value);
		}

		internal function removeElement(value:SpatialElement):void
		{
			var index:int = _elements.indexOf(value);
			if (index != -1)
				_elements.removeAt(index);
		}

		internal function fillListWithLinkedChunks(chunks:Vector.<SpatialChunk>, stamp:uint):void
		{
			var length:int = _elements.length;
			for (var i:int = 0; i < length; ++i)
			{
				_elements[i].fillListWithLinkedChunks(chunks, stamp);
			}
		}
	}
}