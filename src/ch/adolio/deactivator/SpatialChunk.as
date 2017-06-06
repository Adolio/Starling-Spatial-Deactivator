// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.deactivator
{
	import starling.display.Quad;
	
	/**
	 * A spatial cell in the orthonormed spatial grid defined by the Spatial Deactivator.
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
		
		// Debug mode
		private var _debugQuad:Quad;
		private static const _COLOR:uint = 0x00ff00;
		private static const _ACTIVE_ALPHA:Number = 0.4;
		private static const _INACTIVE_ALPHA:Number = 0.1;
		
		public function SpatialChunk(deactivator:SpatialDeactivator, gridX:int, gridY:int, debugRendering:Boolean = false)
		{
			_gridX = gridX;
			_gridY = gridY;
			
			// Debug mode
			if (debugRendering) {
				var marginX:Number = 2.0;
				var marginY:Number = 2.0;
				_debugQuad = new Quad(deactivator.chunkWidth - marginX, deactivator.chunkHeight - marginY, _COLOR);
				_debugQuad.alpha = _INACTIVE_ALPHA;
				_debugQuad.x = gridX * deactivator.chunkWidth + marginX * 0.5;
				_debugQuad.y = gridY * deactivator.chunkHeight + marginY * 0.5;
			}
		}
		
		// --------------------------------------------------------------------
		// -- Private / internal methods
		// --------------------------------------------------------------------
		
		internal function destroy():void
		{
			// Remove and dispose debug quad
			if (_debugQuad)
				_debugQuad.removeFromParent(true);
			
			// Clear elements
			_elements.splice(0, _elements.length);
			
			// Nullify references
			_debugQuad = null;
			_elements = null;
		}
		
		internal function activate(forceElementsUpdate:Boolean, propagate:Boolean):void
		{
			if (_isActive)
				return;
			
			_isActive = true;
			
			if(_debugQuad)
				_debugQuad.alpha = _ACTIVE_ALPHA; // Graphics debug
			
			if (forceElementsUpdate)
			{
				var elementsCount:Number = _elements.length;
				for (var i:uint = 0; i < elementsCount; ++i)
					_elements[i].activate(propagate); // Do not check chunks activity
			}
		}
		
		internal function deactivate(forceElementsUpdate:Boolean, propagate:Boolean):void
		{
			if (!_isActive)
				return;
			
			_isActive = false;
			
			if(_debugQuad)
				_debugQuad.alpha = _INACTIVE_ALPHA; // Graphics debug
			
			if (forceElementsUpdate)
			{
				var elementsCount:Number = _elements.length;
				for (var i:uint = 0; i < elementsCount; ++i)
					_elements[i].deactivate(propagate); // Do not check chunks activity
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
		
		internal function addElement(value:SpatialElement):void
		{
			if (_elements.indexOf(value) == -1)
				_elements.push(value);
		}
		
		internal function removeElement(value:SpatialElement):void
		{
			_elements.removeAt(_elements.indexOf(value));
		}
		
		internal function fillListWithLinkedChunks(chunks:Vector.<SpatialChunk>):void
		{
			var length:Number = _elements.length;
			for (var i:uint = 0; i < length; ++i)
			{
				_elements[i].fillListWithLinkedChunks(chunks);
			}
		}
	}
}