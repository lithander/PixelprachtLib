/*******************************************************************************
 * Copyright (c) 2009 by Thomas Jahn
 * Questions? Mail me at lithander@gmx.de!
 ******************************************************************************/
package net.pixelpracht.geometry
{
	import flash.geom.Rectangle;

	public class Rectangle2D
	{
		public static const LINE_INSIDE:int = 1;
		public static const LINE_INTERSECTS:int = 0;
		public static const LINE_OUTSIDE:int = -1;		
		
		public static const RECT_AROUND:int = 2;
		public static const RECT_INSIDE:int = 1;
		public static const RECT_INTERSECTS:int = 0;
		public static const RECT_OUTSIDE:int = -1;			
		
		/**
		 * The x coordinate of the topleft edge of the rectangle.
		 */
		public var x:Number;
		
		/**
		 * The x coordinate of the topleft edge of the rectangle.
		 */
		public var y:Number;
		
		/**
		 * The width of the rectangle.
		 */
		public var width:Number;
		
		/**
		 * The height of the rectangle.
		 */
		public var height:Number;
		
		
		public function get left():Number
		{
			return x;	
		}
		public function get top():Number
		{
			return y;
		}
		public function get right():Number
		{
			return x + width;	
		}
		
		public function get bottom():Number
		{
			return y + height;
		}		
		
		/**
		 * Constructor
		 */
		public function Rectangle2D( vx:Number = 0, vy:Number = 0, w:Number = 0, h:Number = 0 )
		{
			x = vx;
			y = vy;
			width = w;
			height = h;
		}
		
		/**
		 * Converts from flash.geom.Rectangle to Rectangle2D.
		 */
		public static function fromRectangle( r:Rectangle ):Rectangle2D
		{
			return new Rectangle2D( r.x, r.y, r.width, r.height );
		}
		
		/**
		 * Converts from Rectangle2D to flash.geom.Rectangle.
		 */
		public function toRectangle():Rectangle
		{
			return new Rectangle( x, y, width, height);
		}		
		
		/**
		 * Assigns new coordinates and dimension to this rectangle and returns a reference to self.
		 */
		public function reset( vx:Number = 0, vy:Number = 0, w:Number = 0, h:Number = 0 ):Rectangle2D
		{
			x = vx;
			y = vy;
			width = w;
			height = h;
			return this;
		}
		
		/**
		 * Returns a new Rectangle2D that equals this one. 
		 */
		public function clone():Rectangle2D
		{
			return new Rectangle2D( x, y, width, height );
		}
		
		/**
		 * Tests if the rectangle includes the vector.
		 */
		public function contains(v:Vector2D):Boolean
		{
			if(v.x < x)
				return false;
			if(v.y < y)
				return false;
			if(v.x > (x + width))
				return false;
			if(v.y > (y + height))
				return false;
			
			return true;
		}
		
		public function equals(other:Rectangle2D):Boolean
		{
			return x == other.x && y == other.y && width == other.width && height == other.height;
		}
		
		public function addMargin(margin:Number):Rectangle2D
		{
			x -= margin;
			y -= margin;
			width += 2*margin;
			height += 2*margin;
			return this;
		}
		
		/**
		 * Enlarges the rectangle to include the position.
		 */
		public function addPosition(px:Number, py:Number):Rectangle2D
		{
			if(px < x)
			{
				width += x - px;
				x = px;
			}
			if(px > x+width)
				width += px-x;
			
			if(py < y)
			{
				height += y - py;
				y = py;
			}
			if(py > y+height)
				height += py-y;
			return this;
		}
				
		/**
		 * Enlarges the rectangle to include the vector.
		 */
		public function addVector(v:Vector2D):Rectangle2D
		{
			if(v.x < x)
			{
				width += x - v.x;
				x = v.x;
			}
			if(v.x > x+width)
				width += v.x-x;

			if(v.y < y)
			{
				height += y - v.y;
				y = v.y;
			}
			if(v.y > y+height)
				height += v.y-y;
			return this;
		}
		
		/**
		 * Enlarges the rectangle to include the rect.
		 */
		public function addRect(r:Rectangle2D):Rectangle2D
		{
			if(r.x < x)
			{
				width += x - r.x;
				x = r.x;
			}
			if(r.right > x+width)
				width = r.right-x;
			
			if(r.y < y)
			{
				height += y - r.y;
				y = r.y;
			}
			if(r.bottom > y+height)
				height = r.bottom-y;
			return this;
		}
		
		/**
		 * Moves the vector to be within the rectangle.
		 */
		public function snap(v:Vector2D):Vector2D
		{
			v.x = Math.max(x, Math.min(right, v.x));
			v.y = Math.max(y, Math.min(bottom, v.y));
			return v;
		}		
		
		/**
		 * Returns the point on or within this rectangle that is closest to the vector.
		 */
		public function snapped(v:Vector2D):Vector2D
		{
			return new Vector2D(Math.max(x, Math.min(right, v.x)), Math.max(y, Math.min(bottom, v.y)));
		}
		
		/**
		 * Returns 2 if surrounding, 1 if inside, 0 if intersecting and -1 outside.
		 */
		public function getRectRelation(rect:Rectangle2D):Number
		{
			//OUTSIDE?
			if(rect.x > x+width)
				return RECT_OUTSIDE;
			if(rect.y > y+height)
				return RECT_OUTSIDE;
			if(rect.right < x)
				return RECT_OUTSIDE;
			if(rect.bottom < y)
				return RECT_OUTSIDE;
			
			var leftInside:Boolean = (rect.x > x);
			var topInside:Boolean = (rect.y > y);
			var rightInside:Boolean = (rect.right < x+width);
			var bottomInside:Boolean = (rect.bottom < y+height);

			if(leftInside && topInside && rightInside && bottomInside)
				return RECT_INSIDE;
			
			if(leftInside || topInside || rightInside || bottomInside)
				return RECT_INTERSECTS;

			return RECT_AROUND;
		}		
		
		/**
		 * Returns 1 if inside, 0 if intersecting and -1 outside.
		 */
		public function getLineRelation(line:LineSegment2D):Number
		{
			//int x1, int y1, int x2, int y2, 
			var xmax:Number = x + width;
			var ymax:Number = y + height;
			
			var u1:Number = 0.0;
			var u2:Number = 1.0;
			
			var deltaX:Number = (line.end.x - line.start.x);
			var deltaY:Number = (line.end.y - line.start.y);
			
			/*
			* left edge, right edge, bottom edge and top edge checking
			*/
			var pPart:Array = new Array(-deltaX, deltaX, -deltaY, deltaY);
			var qPart:Array = new Array(line.start.x - x, xmax - line.start.x, line.start.y - y, ymax - line.start.y);
			
			for( var i:int = 0; i < 4; i ++ )
			{
				var p:Number = pPart[ i ];
				var q:Number = qPart[ i ];
				
				if( p == 0 && q < 0 )
					return LINE_OUTSIDE;
				
				var r:Number = q / p;
				
				if( p < 0 )
					u1 = Math.max(u1, r);
				else if( p > 0 )
					u2 = Math.min(u2, r);
				
				if( u1 > u2 )
					return LINE_OUTSIDE;					
			}
			
			if( u2 < 1 || u1 < 1 )
				return LINE_INTERSECTS;
			else
				return LINE_INSIDE;
		}
		
		/**
		 * Constrains a linesegment to fit in the rectangle. Uses Liang Barsky Algorithm. 
		 * Returns reference to the passed input argument after clipping or null if no portion of the line is within the rectangle.
		 */
		public function clipLine(line:LineSegment2D):LineSegment2D
		{
			//int x1, int y1, int x2, int y2, 
			var xmax:Number = x + width;
			var ymax:Number = y + height;
			
			var u1:Number = 0.0;
			var u2:Number = 1.0;
			
			var deltaX:Number = (line.end.x - line.start.x);
			var deltaY:Number = (line.end.y - line.start.y);
			
			/*
			* left edge, right edge, bottom edge and top edge checking
			*/
			/*
			var pPart:Array = new Array(-deltaX, deltaX, -deltaY, deltaY);
			var qPart:Array = new Array(line.start.x - x, xmax - line.start.x, line.start.y - y, ymax - line.start.y);
			
			for( var i:int = 0; i < 4; i ++ )
			{
				var p:Number = pPart[ i ];
				var q:Number = qPart[ i ];
				
				if( p == 0 && q < 0 )
					return null;
				
				var r:Number = q / p;
				
				if( p < 0 )
					u1 = Math.max(u1, r);
				else if( p > 0 )
					u2 = Math.min(u2, r);
				
				if( u1 > u2 )
					return null;					
			}*/
			
			//ugly but optimized
			//left
			var q:Number = line.start.x - x;
			if( deltaX == 0 && q < 0 )
				return null;
			var r:Number = q / (-deltaX);
			if(deltaX > 0 )
				u1 = Math.max(u1, r);
			else if( deltaX < 0 )
				u2 = Math.min(u2, r);
			if( u1 > u2 )
				return null;					
			//right
			q = xmax - line.start.x;
			if( deltaX == 0 && q < 0 )
				return null;
			r = q / deltaX;
			if( deltaX < 0 )
				u1 = Math.max(u1, r);
			else if( deltaX > 0 )
				u2 = Math.min(u2, r);
			if( u1 > u2 )
				return null;					
			//top
			q = line.start.y - y;
			if( deltaY == 0 && q < 0 )
				return null;
			r = q / -deltaY;
			if(deltaY > 0 )
				u1 = Math.max(u1, r);
			else if( deltaY < 0 )
				u2 = Math.min(u2, r);
			if( u1 > u2 )
				return null;					
			//bottom
			q = ymax - line.start.y;
			if( deltaY == 0 && q < 0 )
				return null;
			r = q / deltaY;
			if( deltaY < 0 )
				u1 = Math.max(u1, r);
			else if( deltaY > 0 )
				u2 = Math.min(u2, r);
			if( u1 > u2 )
				return null;				
		
			//clip
			if( u2 < 1 )
			{
				line.end.x = (line.start.x + u2 * deltaX);
				line.end.y = (line.start.y + u2 * deltaY);
			}
			if( u1 > 0)
			{
				line.start.x = (line.start.x + u1 * deltaX);
				line.start.y = (line.start.y + u1 * deltaY);
			}
			line.recalc();
			return line;    	
		}

		/**
		 * The area of this rectangle
		 */
		public function get area():Number
		{
			return width * height;
		}
		
		/**
		 * Get a string representation of this rectangle
		 */
		public function toString():String
		{
			return "(x=" + x + ", y=" + y + ", width=" + width + ", height=" + height + ")";
		}
	}
}