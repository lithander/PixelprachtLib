package net.pixelpracht.graphics
{
	import flash.geom.ColorTransform;
	
	import net.pixelpracht.geometry.Angle;

	public class Color
	{
		public var red:Number = 0;
		public var green:Number = 0;
		public var blue:Number = 0;
		public var alpha:Number = 0;
				
		public function Color(r:Number = 0, g:Number = 0, b:Number = 0, a:Number = 1)
		{
			red = r;
			green = g;
			blue = b;
			alpha = a;
		}
		
		/**
		 * Set Hue [0..2PI], Saturation [0..1] and Value [0..1]
		 */	
		public static function fromHSV(hue:Number, saturation:Number, value:Number):Color
		{
			var result:Color = new Color();
			result.setHSV(hue, saturation, value);
			return result;
		}
		
		public function toColorTransform():ColorTransform
		{
			return new ColorTransform(red, green, blue, alpha);
		}	
		
		public function get redByte():uint
		{
			return red < 0 ? 0 : red > 1 ? 255 : red * 255;
		}
		public function set redByte(v:uint):void
		{
			red = v / 255;
		}
		public function get blueByte():uint
		{
			return blue < 0 ? 0 : blue > 1 ? 255 : blue * 255;
		}
		public function set blueByte(v:uint):void
		{
			blue = v / 255;
		}
		public function get greenByte():uint
		{
			return green < 0 ? 0 : green > 1 ? 255 : green * 255;
		}
		public function set greenByte(v:uint):void
		{
			green = v / 255;
		}
		public function get alphaByte():uint
		{
			return alpha < 0 ? 0 : alpha > 1 ? 255 : alpha * 255;
		}
		public function set alphaByte(v:uint):void
		{
			alpha = v / 255;
		}
		
		//getters
		public function get rgba():uint
		{
			return alphaByte << 24 | redByte <<16 | greenByte <<8 | blueByte;
		}
		public function set rgba(v:uint):void
		{
			var a:uint = v>> 24 & 0xFF;
			var r:uint = v>> 16 & 0xFF;
			var g:uint = v>> 8 & 0xFF;
			var b:uint = v & 0xFF;
			red = r / 255;
			green = g / 255;
			blue = b / 255;
			alpha = a / 255;
		}
		
		/**
		* Set Hue [0..2PI], Saturation [0..1] and Value [0..1]
		*/	
		public function setHSV(hue:Number, saturation:Number, value:Number):void
		{
			hue = Angle.normalizeRad2(hue);
			var hseg:Number = 3 * hue / Math.PI;
			var c:Number = saturation * value;
			var x:Number = c * ( 1 - Math.abs(hseg%2 - 1));
			var i:int = Math.floor(hseg);
			switch (i) {
				case 0: red = c; green = x; blue = 0; break;
				case 1: red = x; green = c; blue = 0; break;
				case 2: red = 0; green = c; blue = x; break;
				case 3: red = 0; green = x; blue = c; break;
				case 4: red = x; green = 0; blue = c; break;
				case 5: red = c; green = 0; blue = x; break;
			}
			var m:Number = value - c;
			red += m;
			green += m;
			blue += m;
		}
		
		/**
		 * Get a string representation of this color
		 */
		public function toString():String
		{
			return "(r=" + redByte + ", g=" + greenByte + ", b=" + blueByte + ", a=" + alphaByte + ")";
		}
		
	}
}