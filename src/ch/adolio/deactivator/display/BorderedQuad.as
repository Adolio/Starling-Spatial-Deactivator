// ============================================================================
//
//  Starling-Spatial-Deactivator
//  Copyright 2017 Aurelien Da Campo, All Rights Reserved.
//
//  This program is free software. You can redistribute and/or modify it
//  in accordance with the terms of the accompanying license agreement.
//
// ============================================================================

package ch.adolio.deactivator.display 
{
	import starling.display.Quad;
	import starling.display.Sprite;
	
	/**
	 * A quad which has a border.
	 * 
	 * As Starling quad, default pivot point is top-left corner.
	 */
	public class BorderedQuad extends Sprite
	{
		// Size
		private var _preferredWidth:Number;
		private var _preferredHeight:Number;
		
		// Quads
		private var _bodyQuad:Quad;
		private var _topQuad:Quad;
		private var _bottomQuad:Quad;
		private var _leftQuad:Quad;
		private var _rightQuad:Quad;
		
		// Style
		private var _color:uint;
		private var _borderSize:Number = 2;
		private var _bodyAlpha:Number = 0.8;
		private var _borderAlpha:Number = 1.0;
		
		public function BorderedQuad(width:Number, height:Number, color:uint=16777215, borderSize:Number=1.0)
		{
			_preferredWidth = width;
			_preferredHeight = height;
			
			_borderSize = borderSize;
			
			_bodyQuad = new Quad(1, 1);
			_topQuad = new Quad(1, 1);
			_bottomQuad = new Quad(1, 1);
			_leftQuad = new Quad(1, 1);
			_rightQuad = new Quad(1, 1);
			
			addChild(_bodyQuad);
			addChild(_topQuad);
			addChild(_bottomQuad);
			addChild(_leftQuad);
			addChild(_rightQuad);
			
			this.color = color;
			this.bodyAlpha = _bodyAlpha;
			this.borderAlpha = _borderAlpha;
			
			updateShape();
		}
		
		private function updateShape():void
		{
			// Cap border size
			var bs:Number = _borderSize;
			if (_borderSize * 2 > _preferredWidth || _borderSize * 2 > _preferredHeight)
				bs = Math.min(_preferredWidth * 0.5, _preferredHeight * 0.5);
			
			// Update body
			_bodyQuad.width = _preferredWidth - bs * 2;
			_bodyQuad.height = _preferredHeight - bs * 2;
			_bodyQuad.x = bs;
			_bodyQuad.y = bs;
			
			// Update top & bottom borders
			_topQuad.width = _bottomQuad.width = _preferredWidth;
			_topQuad.height = _bottomQuad.height = bs;
			_topQuad.x = 0;
			_topQuad.y = 0;
			_bottomQuad.x = 0;
			_bottomQuad.y = _preferredHeight - bs;
			
			// Update left & right borders
			_leftQuad.width = _rightQuad.width = bs;
			_leftQuad.height = _rightQuad.height = _bodyQuad.height;
			_leftQuad.x = 0;
			_leftQuad.y = bs;
			_rightQuad.x = _preferredWidth - bs;
			_rightQuad.y = bs;
		}
		
		override public function get width():Number
		{
			return _preferredWidth;
		}
		
		override public function set width(value:Number):void
		{
			_preferredWidth = value;
			
			updateShape();
		}
		
		override public function get height():Number
		{
			return _preferredHeight;
		}
		
		override public function set height(value:Number):void
		{
			_preferredHeight = value;
			
			updateShape();
		}
		
		public function get color():uint 
		{
			return _color;
		}
		
		public function set color(value:uint):void 
		{
			_color = value;
			
			_bodyQuad.color = _color;
			_topQuad.color = _color;
			_bottomQuad.color = _color;
			_leftQuad.color = _color;
			_rightQuad.color = _color;
		}
		
		public function get borderSize():Number 
		{
			return _borderSize;
		}
		
		public function set borderSize(value:Number):void 
		{
			// Border size cannot be negative
			if (_borderSize < 0)
				return;
			
			_borderSize = value;
			
			updateShape();
		}
		
		public function get bodyAlpha():Number 
		{
			return _bodyAlpha;
		}
		
		public function set bodyAlpha(value:Number):void 
		{
			_bodyAlpha = value;
			
			_bodyQuad.alpha = _bodyAlpha;
		}
		
		public function get borderAlpha():Number 
		{
			return _borderAlpha;
		}
		
		public function set borderAlpha(value:Number):void 
		{
			_borderAlpha = value;
			
			_topQuad.alpha = _borderAlpha;
			_bottomQuad.alpha = _borderAlpha;
			_leftQuad.alpha = _borderAlpha;
			_rightQuad.alpha = _borderAlpha;
		}
	}
}