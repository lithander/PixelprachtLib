/*******************************************************************************
 * Copyright (c) 2009 by Thomas Jahn
 * Questions? Mail me at lithander@gmx.de!
 ******************************************************************************/
package net.pixelpracht.geometry
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * Vector2D represents a 2D vector in cartesian coordinate space.
	 *
	 * <p>To convert between flash.geom.Point and this class, use the methods
	 * toPoint and fromPoint.</p>
	 * 
	 * <p>All the methods return a reference to the result, even when the result
	 * is the original vector. So you can chain methods together.
	 * e.g. <code>v.add( u ).multiply( 7 )</code></p>
	 * 
	 */
	public class Vector2D
	{
		
		/**
		 * The x coordinate of the vector.
		 */
		public var x:Number;
		
		/**
		 * The y coordinate of the vector.
		 */
		public var y:Number;
		
		/**
		 * Constructor
		 */
		public function Vector2D( vx:Number = 0, vy:Number = 0 )
		{
			x = vx;
			y = vy;
		}
		
		/**
		 * Converts from flash.geom.Point to Vector2D.
		 */
		public static function fromPoint( pt:Point ):Vector2D
		{
			return new Vector2D( pt.x, pt.y );
		}
		
		/**
		 * Converts from Vector2 to flash.geom.Point.
		 */
		public function toPoint():Point
		{
			return new Point( x, y );
		}
		
		/**
		 * Creates a Vector2 object from polar coordinates.
		 */
		public static function fromPolar( len:Number, angle:Number ):Vector2D
		{
			return new Vector2D( len * Math.cos( angle ), len * Math.sin( angle ) );
		}
		
		/**
		 * Creates a Vector2 object between the two input vectors. Ratio indicates the position
		 * between the two vectors. A ratio of 0 returns v1 and a ratio of 1 returns v2.
		 */
		public static function fromInterpolation( v1:Vector2D, v2:Vector2D, ratio:Number ):Vector2D
		{
			return v1.added( v2.subtracted( v1 ).scaled( ratio ) );
		}		
		
		/**
		 * Assigns new coordinates to this vector and returns a reference to self.
		 */
		public function reset( vx:Number = 0, vy:Number = 0 ):Vector2D
		{
			x = vx;
			y = vy;
			return this;
		}
		
		/**
		 * Copys another vector into this one and returns a reference to self.
		 */
		public function copy( v:Vector2D ):Vector2D
		{
			x = v.x;
			y = v.y;
			return this;
		}
		
		/**
		 * Returns a new Vector2D that equals this one. 
		 */
		public function clone():Vector2D
		{
			return new Vector2D( x, y );
		}

		/**
		 * Returns a new Vector2D that equals the sum of this and another vector.
		 */
		public function added( v:Vector2D ):Vector2D
		{
			return new Vector2D( x + v.x, y + v.y );
		}
		
		/**
		 * Adds another vector to this one and returns a reference to self.
		 */
		public function add( v:Vector2D ):Vector2D
		{
			x += v.x;
			y += v.y;
			return this;
		}
		
		/**
		 * Returns a new Vector2D covering the distance from the other vector to this one.
		 */		
		public function subtracted( v:Vector2D ):Vector2D
		{
			return new Vector2D( x - v.x, y - v.y );
		}
		
		/**
		 * Subtracts another vector from this one and returns a reference to self.
		 */
		public function subtract( v:Vector2D ):Vector2D
		{
			x -= v.x;
			y -= v.y;
			return this;
		}
		
		/**
		 * Returns a new vector equaling this vector multiplied by the other vector.
		 */
		public function multiplied( v:Vector2D ):Vector2D
		{
			return new Vector2D( -x, -y );
		}
		
		/**
		 * Multiplies this vector with another vector and returns a reference to self.
		 */
		public function multiply( v:Vector2D ):Vector2D
		{
			x *= -1;
			y *= -1;
			return this;
		}	

		
		public function scaled( s:Number ):Vector2D
		{
			return new Vector2D( x * s, y * s );
		}

		/**
		 * Multiplies this vector by a number and returns a reference to self.
		 */
		public function scale( s:Number ):Vector2D
		{
			x *= s;
			y *= s;
			return this;
		}
		
		/**
		 * Returns a new vector equalling this vector with angle added to its polar coordinates.
		 */
		public function rotated( angle:Number ):Vector2D
		{
			var newAngle:Number = Math.atan2( y, x ) + angle;
			return Vector2D.fromPolar( length, newAngle );
		}
		
		/**
		 * Rotates this vector and returns a reference to self.
		 */
		public function rotate( angle:Number ):Vector2D
		{
			var newAngle:Number = Math.atan2( y, x ) + angle;
			var len:Number = length;
			x = len * Math.cos( newAngle );
			y = len * Math.sin( newAngle );
			return this;
		}		
		
		/**
		 * Returns a new Vector2D equaling this vector translated by tx and ty.
		 */
		public function translated( tx:Number, ty:Number):Vector2D
		{
			return new Vector2D( x + tx, y + ty );
		}
		
		/**
		 * Translates this vector by tx and ty and returns a reference to self.
		 */
		public function translate( tx:Number, ty:Number):Vector2D
		{
			x += tx;
			y += ty;
			return this;
		}
		
		/**
		 * Returns a new Vector transformed by a matrix.
		 */
		public function transformed(mtx:Matrix):Vector2D
		{
			return new Vector2D( mtx.a * x + mtx.c * y + mtx.tx, mtx.b * x + mtx.d * y + mtx.ty );
		}
		
		/**
		 * Transforms this vector by a matrix.
		 */
		public function transform(mtx:Matrix):Vector2D
		{
			var ox:Number = x;
			x = mtx.a * x + mtx.c * y + mtx.tx;
			y = mtx.b * ox + mtx.d * y + mtx.ty;
			return this;
		}
				
		/**
		 * Returns a new vector of the same length but in the opposite direction.
		 */
		public function inverted():Vector2D
		{
			return new Vector2D( -x, -y );
		}
		
		/**
		 * Inverses this vector and returns a reference to self.
		 */
		public function inverse():Vector2D
		{
			x *= -1;
			y *= -1;
			return this;
		}	
		
		/**
		 * Rotate a copy of this vector that is orthogonal/perpendicular. (cw rotation by 90°).
		 */
		public function turnedRight():Vector2D
		{
			return new Vector2D(-y,x);
		}
		
		/**
		 * Rotate this vector cw by 90° and return a reference to self.
		 */
		public function turnRight():Vector2D
		{
			var tmp:Number = x;
			x = -y;
			y = tmp;
			return this;
		}	
		
		/**
		 * Rotate a copy of this vector that is orthogonal/perpendicular. (ccw rotation by 90°).
		 */
		public function turnedLeft():Vector2D
		{
			return new Vector2D(y,-x);
		}
		
		/**
		 * Rotate this vector cw by 90° and return a reference to self.
		 */
		public function turnLeft():Vector2D
		{
			var tmp:Number = x;
			x = y;
			y = -tmp;
			return this;
		}	
		
		/**
		 * Scales this vector to have unit length and returns a reference to self.
		 */
		public function normalize():Vector2D
		{
			var s:Number = this.length;
			if ( s != 0 )
			{
				s = 1 / s;
				x *= s;
				y *= s;
			}
			else
			{
				x = 0;
				y = 0;
			}
			return this;
		}
		
		/**
		 * Returns a new Vector of the same direction as this but with unit length.
		 */
		public function normalized():Vector2D
		{
			return clone().normalize();
		}
		
		/**
		 * Floors the components of the vector and returns a reference to self.
		 */
		public function floor():Vector2D
		{
			x = Math.floor(x);
			y = Math.floor(y);
			return this;
		}
		
		/**
		 * Returns a new Vector matching this but with floord components.
		 */
		public function floored():Vector2D
		{
			return clone().floor();
		}
		
		/**
		 * Rounds the components of the vector to the nearest integer and returns a reference to self.
		 */
		public function round():Vector2D
		{
			x = Math.round(x);
			y = Math.round(y);
			return this;
		}
		
		/**
		 * Returns a new Vector matching this but with rounded components.
		 */
		public function rounded():Vector2D
		{
			return clone().round();
		}		


		/**
		 * Compares this vector to another and return true if the vectors have the same coordinates.
		 */
		public function isEqual( v:Vector2D ):Boolean
		{
			return x == v.x && y == v.y;
		}

		/**
		 * Compares this vector to another and return true if the distance between them
		 * is within tolerance.
		 */
		public function nearEquals( v:Vector2D, tolerance:Number ):Boolean
		{
			return subtracted( v ).lengthSquared <= tolerance * tolerance;
		}
		
		/**
		 * Calculates the dot product with another vector.
		 */
		public function dotProduct( v:Vector2D ):Number
		{
			return ( x * v.x + y * v.y );
		}
		
		/**
		 * Calculates the cross product with another vector. Returns the magnitude of the resulting vector that is perpendicular to the 2D plane.
		 */
		public function crossProduct( v:Vector2D ):Number
		{
			//rotate one vector anti-clockwise by 90 degrees and take the dot product between both vectors
			return ( x * v.y - y * v.x );
		}
		
		/**
		 * Calculates the distance from the other vector.
		 */
		public function distance( v:Vector2D ):Number
		{
			var dx:Number = x - v.x;
			var dy:Number = y - v.y;
			return Math.sqrt( dx * dx + dy * dy );
		}
		
		/**
		 * Calculates the square of the distance from the other vector.
		 */
		public function distanceSquared( v:Vector2D ):Number
		{
			var dx:Number = x - v.x;
			var dy:Number = y - v.y;
			return ( dx * dx + dy * dy );
		}
		
		/**
		 * The length of this vector.
		 */
		public function set length(newLen:Number):void
		{
			var len:Number = Math.sqrt(lengthSquared);
			var f:Number = (len > 0) ? newLen / len : 0;
			x *= f;
			y *= f;
		}
		
		/**
		 * The length of this vector.
		 */
		public function get length():Number
		{
			return Math.sqrt( lengthSquared );
		}
		
		/**
		 * The square of the length of this vector.
		 */
		public function get lengthSquared():Number
		{
			return ( x * x + y * y );
		}
		
		/**
		 * An angle describing the orientation of the Vector. (-1,0) is 0. (1,0) is Pi. 
		 */
		public function get polarAngle():Number
		{	
			return Math.atan2(y, x) + Math.PI;
			/* 
			//the same effect but a lot slower..
			var r:Number = length;
			if(r == 0)
				return 0;
			else if(x >= 0)
				return Math.asin(y / r);
			else
				return Math.PI - Math.asin(y / r); 	
			*/
		}
		
		/**
		 * Get a string representation of this vector
		 */
		public function toString():String
		{
			return "(x=" + x + ", y=" + y + ")";
		}
	}
}
