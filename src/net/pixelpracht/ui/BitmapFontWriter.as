package net.pixelpracht.ui
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class BitmapFontWriter
	{
		private var _charSheet:BitmapData = null;
		private var _charRects:Array = null;
		private var _lineHeight:int = 0; //don't count the delimiter row
		
		public var charOffset:int = 32;
		public var blankWidth:int = 5;
		public var lineWidth:int = 1000;
		
		public function BitmapFontWriter(charSheet:BitmapData, skipChars:int = 32)
		{
			charOffset = skipChars;
			loadFont(charSheet);
			_lineHeight = _charSheet.height - 1; //don't count the delimiter row
		}
		
		public function loadFont(charSheet:BitmapData):Boolean
		{
			_charSheet = charSheet;
			_charRects = new Array();
			var delimValue:uint = charSheet.getPixel(0, 0);
			var x:int = 0;
			var h:int = charSheet.height - 1;
			var charCode:int = charOffset;
			for(var i:int = 0; i < charSheet.width; i++)
			{
				if(charSheet.getPixel(i, 0) == delimValue)
				{
					if((i - x) > 1)
						_charRects[charCode] = new Rectangle(x, 1, i-x, h);
					while(charSheet.getPixel(i+1, 0) == delimValue) //support extended delimiters
						i++;
					x = i;
					charCode++;
				}
			}
			return true;
		}
		
		private var _width:int = 0;
		private var _height:int = 0;
		private var _breaks:Array = new Array();
		public function measure(text:String):void
		{
			_width = 0;
			_height = _lineHeight;
			_breaks.splice(0);
			var lineBreak:int = 0;
			var curWidth:int = 0;
			var breakWidth:int = 0;
			var line:int = 0;
			for (var i:int = 0; i < text.length; i++)
			{
				var code:int = text.charCodeAt(i);
				var rect:Rectangle = _charRects[code];
				if(rect)
					curWidth += rect.width;
				else
				{
					curWidth += blankWidth;
					breakWidth = curWidth;
					lineBreak = i;
				}
				if(curWidth > lineWidth) 
				{
					//break at last possible position
					_breaks[line++] = breakWidth;
					curWidth -= breakWidth;
					_width = Math.max(breakWidth, _width);
					_height += _lineHeight;
				}
			}
			_width = Math.max(curWidth, _width);
		}

		public function measureWidth(text:String):int
		{
			measure(text);
			return _width;
		}

		public function measureHeight(text:String):int
		{
			measure(text);
			return _height;
		}
		
		public function write(text:String):BitmapData
		{
			measure(text);
			if(_width < 1 || _height < 1)
				return null;
			var target:BitmapData = new BitmapData(_width, _height, true, 0x00FFFFFF);
			var pos:Point = new Point(0,0);
			var line:int = 0;
			for (var i:int = 0; i < text.length; i++)
			{
				var code:int = text.charCodeAt(i);
				var rect:Rectangle = _charRects[code];
				if(rect)
				{
					target.copyPixels(_charSheet, rect, pos);
					pos.x += rect.width;
				}
				else
					pos.x += blankWidth;
				
				if(pos.x >= _breaks[line])
				{
					line++;
					pos.x = 0;
					pos.y += _lineHeight;
				}
			}
			return target;
		}

	}
}