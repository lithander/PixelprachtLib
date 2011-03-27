/*******************************************************************************
 * Copyright (c) 2009 by Thomas Jahn
 * Questions or license requests? Mail me at lithander@gmx.de!
 ******************************************************************************/
package net.pixelpracht.geometry
{
	import flash.geom.Point;
	
	/**
	 * LineSegment2D is a part of a line in 2D space.
	 * It is bounded by the start and the end points.
	 * 
	 */
	public class LineSegment2D
	{	
		public static const THIS_START_TOUCHES_OTHER:int = 1;
		public static const THIS_END_TOUCHES_OTHER:int = 2;
		public static const OTHER_START_TOUCHES_THIS:int = 3;
		public static const OTHER_END_TOUCHES_THIS:int = 4;
		public static const THIS_AND_OTHER_INTERSECT:int = 5;
		public static const NO_CONNECTION:int = -1;
		
		/**
		 * The starting vector of the line segment. Read only!
		 */
		public var start:Vector2D;
		
		/**
		 * The end point of the line segment. Read only!
		 */
		public var end:Vector2D;
		
		//to keep it compatible with CachedLinesegment2D!
		public function recalc():void
		{
		}
		
		/**
		 * Constructor
		 */
		public function LineSegment2D( startX:Number = 0, startY:Number = 0, endX:Number = 0, endY:Number = 0)
		{
			start = new Vector2D(startX, startY);
			end = new Vector2D(endX, endY);
			recalc();
		}		
		
		/**
		 * Returns a LineSegment2D object from the start to the end point. 
		 */
		public static function fromPoints(start:Point, end:Point):LineSegment2D
		{
			return new LineSegment2D( start.x, start.y, end.x, end.y );
		}
		
		/**
		 * Returns a LineSegment2D object from the start to the end vectors. 
		 */
		public static function fromVectors(start:Vector2D, end:Vector2D):LineSegment2D
		{
			return new LineSegment2D( start.x, start.y, end.x, end.y );
		}
		
		/**
		 * Assign new coordinates to this line segment
		 */
		public function reset( startX:Number = 0, startY:Number = 0, endX:Number = 0, endY:Number = 0):void
		{
			start.reset(startX, startY);
			end.reset(endX, endY);
			recalc();
		}
		
		/**
		 * Make this a copy of another line segment.
		 */
		public function copy(other:LineSegment2D):LineSegment2D
		{
			start.copy(other.start);
			end.copy(other.end);
			recalc();
			return this;
		}
		
		/**
		 * Make a copy of this line segment.
		 */
		public function clone():LineSegment2D
		{
			return new LineSegment2D( start.x, start.y, end.x, end.y );
		}
				
		/**
		 * Compare this line segment to another and return true if the vectors have the same coordinates.
		 */
		public function isEqual( other:LineSegment2D ):Boolean
		{
			return start.isEqual(other.start) && end.isEqual(other.end);
		}
		
		/**
		 * Compare this line segment to another and return true if the lines are parallel.
		 */
		public function isParallel( other:LineSegment2D, tolerance:Number = 0 ):Boolean
		{
			return Math.abs(direction.crossProduct(other.direction)) <= tolerance;
		}
		
		/**
		 * Compare this line segment to another and return true if the lines have an intersection.
		 */
		public function isIntersecting( other:LineSegment2D ):Boolean
		{
			//line_this = start + a * direction
			//line_other = other.start + b * direction
			//start.x + a * direction.x = other.start.x + b * other.direction.x;
			//start.y + a * direction.y = other.start.y + b * other.direction.y;
			//solve to a...			
			var odx:Number = other.direction.x;
			var ody:Number = other.direction.y;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
			
			var invDenom:Number = 1.0 / (ody * dx - odx * dy);
			var a:Number = odx * (start.y - other.start.y) - ody * (start.x - other.start.x);
			a *= invDenom;
			var b:Number = dx * (start.y - other.start.y) - dy * (start.x - other.start.x);
			b *= invDenom;
			//The equations apply to lines, if the intersection of line segments is required then it is only necessary to test if ua and ub lie between 0 and 1. 
			//Whichever one lies within that range then the corresponding line segment contains the intersection point. 
			//If both lie within the range of 0 to 1 then the intersection point is within both line segments. 
			return (a > 0 && a < 1 && b > 0 && b < 1);
		}
		
		/**
		 * Get information on how the two lines interact.
		 */
		public function getRelation( other:LineSegment2D, tolerance:Number = 0):int
		{
			//see isIntersecting...
			var odx:Number = other.direction.x;
			var ody:Number = other.direction.y;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
			
			var invDenom:Number = 1.0 / (ody * dx - odx * dy);
			var a:Number = odx * (start.y - other.start.y) - ody * (start.x - other.start.x);
			a *= invDenom;
			var b:Number = dx * (start.y - other.start.y) - dy * (start.x - other.start.x);
			b *= invDenom;
			if(Math.abs(a-1) < tolerance && (b >= 0 && b <= 1)) //touching - a is 1 and b in range
				return THIS_END_TOUCHES_OTHER;
			if(Math.abs(a) < tolerance && (b >= 0 && b <= 1)) //touching - a is 0 and b in range
				return THIS_START_TOUCHES_OTHER;
			if(Math.abs(b) < tolerance && (a >= 0 && a <= 1)) //touching - b is 1 and a in range
				return OTHER_START_TOUCHES_THIS;
			if(Math.abs(b-1) < tolerance && (a >= 0 && a <= 1)) //touching - b is 0 and a in range
				return OTHER_END_TOUCHES_THIS;
			if (a > 0 && a < 1 && b > 0 && b < 1)
				return THIS_AND_OTHER_INTERSECT;
			
			return NO_CONNECTION; //-1 nothing
		}
		
		/**
		 * Returns the sample ratio where this line would intersect the other. Segment boundaries are not considered.
		 */
		public function getIntersectionRatio( other:LineSegment2D ):Number
		{
			//line_this = start + a * direction
			//line_other = other.start + b * direction
			//start.x + a * direction.x = other.start.x + b * other.direction.x;
			//start.y + a * direction.y = other.start.y + b * other.direction.y;
			//solve to a...			
			var odx:Number = other.direction.x;
			var ody:Number = other.direction.y;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
			
			var a:Number = odx * (start.y - other.start.y) - ody * (start.x - other.start.x);
			return a / (ody * dx - odx * dy); 						
		}
			
		
		/**
		 * Returns a new vector v at the position where the lines would intersect. Segment boundaries are not considered.
		 */
		public function intersect( other:LineSegment2D ):Vector2D
		{
			//line_this = start + a * direction
			//line_other = other.start + b * direction
			//start.x + a * direction.x = other.start.x + b * other.direction.x;
			//start.y + a * direction.y = other.start.y + b * other.direction.y;
			//solve to a...			
			var odx:Number = other.direction.x;
			var ody:Number = other.direction.y;
			var dx:Number = direction.x;
			var dy:Number = direction.y;
		
			var a:Number = odx * (start.y - other.start.y) - ody * (start.x - other.start.x);
			a /= ody * dx - odx * dy;
			return new Vector2D(start.x + a * dx, start.y + a * dy);			 			
		}
		
		/**
		 * Project the vector v on this line segment and return the ratio.
		 * return = 0      v = start
		 * return = 1      v = end
		 * return < 0      v is on the backward extension of AB
		 * return > 1      v is on the forward extension of AB
		 * 0< return <1    v is interior to AB
		 */
		public function project( v:Vector2D ):Number
		{
			/*    
			Let the point be C (Cx,Cy) and the line be AB (Ax,Ay) to (Bx,By).
		    Let P be the point of perpendicular projection of C on AB.  The parameter
		    r, which indicates P's position along AB, is computed by the dot product 
		    of AC and AB divided by the square of the length of AB:
		    
		    (1)     AC dot AB
		        r = ---------  
		            ||AB||^2
			*/
			return direction.dotProduct(v.subtracted(start)) / lengthSquared;
		}
		
		/**
		 * Returns a new vector on this line segment at the given 'ratio'. A ratio of 0 returns v1 and a ratio of 1 returns v2.
		 */
		public function sample( r:Number ):Vector2D
		{
			return start.added(direction.scaled(r));
		}
		
		/**
		 * Returns the point on this line segment that is closest to the vector.
		 */
		public function snapped( v:Vector2D ):Vector2D
		{
			return sample( Math.max(0, Math.min(1, project(v))) );
		}	
		
		/**
		 * Returns the distance of the vector to its closest point on this line segment.
		 */		
		public function distance( v:Vector2D ):Number
		{
			return snapped(v).distance(v);
		}		
	
		/**
		 * A new vector covering the distance from start to end.
		 */		
		public function get direction():Vector2D
		{
			return end.subtracted(start);
		}	
		
		/**
		 * The length of this line segment
		 */
		public function get length():Number
		{
			return start.distance(end);
		}
		
		/**
		 * The length of this line segment
		 */
		public function set length(value:Number):void
		{
			var sf:Number = value / start.distance(end);
			end = start.added(direction.scale(sf));
			recalc();
		}
				
		/**
		 * The square of the length of this line segment
		 */
		public function get lengthSquared():Number
		{
			return start.distanceSquared(end);
		}
		
		public function set lengthSquared(value:Number):void
		{
			var sf:Number = value / start.distanceSquared(end);
			end = start.added(direction.scale(sf));
			recalc();
		}
		
		/**
		 * Get a string representation of this vector
		 * 
		 * @return a string representation of this vector
		 */
		public function toString():String
		{
			return "(start=" + start.toString() + ", end=" + end.toString() + ")";
		}
	}
}
