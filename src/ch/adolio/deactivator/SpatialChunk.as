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
	import ch.adolio.deactivator.SpatialChunkDebugObject;
	import starling.display.DisplayObject;
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
		private var _debugObject:SpatialChunkDebugObject;
		
		public function SpatialChunk(deactivator:SpatialDeactivator, gridX:int, gridY:int, debugRendering:Boolean = false)
		{
			_gridX = gridX;
			_gridY = gridY;
			
			// Debug mode
			if (debugRendering) {
				var marginX:Number = 1.0;
				var marginY:Number = 1.0;
				_debugObject = new SpatialChunkDebugObject(deactivator.chunkWidth - marginX, deactivator.chunkHeight - marginY, this);
				_debugObject.x = gridX * deactivator.chunkWidth + marginX * 0.5;
				_debugObject.y = gridY * deactivator.chunkHeight + marginY * 0.5;
			}
		}
		
		// --------------------------------------------------------------------
		// -- Private / internal methods
		// --------------------------------------------------------------------
		
		internal function destroy():void
		{
			// Remove and dispose debug quad
			if (_debugObject)
				_debugObject.removeFromParent(true);
			
			// Clear elements
			_elements.splice(0, _elements.length);
			
			// Nullify references
			_debugObject = null;
			_elements = null;
		}
		
		internal function activate(propagate:Boolean):void
		{
			if (_isActive)
				return;
			
			_isActive = true;
			
			// Update debug rendering
			if(_debugObject)
				_debugObject.update();
			
			// Update touched elements
			var elementsCount:Number = _elements.length;
			for (var i:uint = 0; i < elementsCount; ++i)
				_elements[i].activate(propagate);
		}
		
		internal function deactivate(propagate:Boolean):void
		{
			if (!_isActive)
				return;
			
			_isActive = false;
			
			// Update debug rendering
			if(_debugObject)
				_debugObject.update();
			
			// Update touched elements
			var elementsCount:Number = _elements.length;
			for (var i:uint = 0; i < elementsCount; ++i) {
				_elements[i].checkActivityFromCoveredChunks(propagate);
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
		
		internal function get debugObject():DisplayObject 
		{
			return _debugObject;
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
			
			// TODO Add param to force check activity (if not active, now active?).
		}
		
		internal function removeElement(value:SpatialElement):void
		{
			_elements.removeAt(_elements.indexOf(value));
			
			// TODO Add param to force check activity (if active, still active?).
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