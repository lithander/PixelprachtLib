/*******************************************************************************
 * Copyright (c) 2010 by Thomas Jahn
 * Questions or license requests? Mail me at lithander@gmx.de!
 ******************************************************************************/
package net.pixelpracht.geometry 
{
	/**
	 * Provides some Angle related helper methods
	 */
	public class Angle
	{
		public function Angle()
		{
			
		}
		
		public static const PI:Number = Math.PI;
		public static const TwoPI:Number = Math.PI*2;
		
		/*
		* Normalizes angle to be between -PI and +PI.
		*/		
		public static function normalizeRad(angle:Number):Number
		{
			while( angle < -PI)
				angle += TwoPI;
			while( angle > PI)
				angle -= TwoPI;
			return angle;
		}		
		
		/*
		* Normalizes angle to be between -180 and +180.
		*/		
		public static function normalizeDeg(angle:Number):Number
		{
			while( angle < -180)
				angle += 360;
			while( angle > 180)
				angle -= 360;
			return angle;
		}
		
		/*
		* Normalizes angle to be between 0 and 2PI.
		*/		
		public static function normalizeRad2(angle:Number):Number
		{
			while( angle < 0)
				angle += TwoPI;
			while( angle > TwoPI)
				angle -= TwoPI;
			return angle;
		}		
		
		/*
		* Normalizes angle to be between 0 and +360.
		*/		
		public static function normalizeDeg2(angle:Number):Number
		{
			while( angle < 0)
				angle += 360;
			while( angle > 360)
				angle -= 360;
			return angle;
		}
		
		/**
		 * Is an angle in the cone defined by min & max?
		 * Assumes angles are normalized to be between -PI and +PI.
		 */		
		public static function isEnclosedRad(angle:Number, min:Number, max:Number):Boolean
		{
			angle += PI;
			min += PI;
			max += PI;
			return (angle > min && angle < max);
		}
		
		/**
		 * These companion methods will convert radians to degrees
		 * and degrees to radians.
		 */		
		public static function radToDeg(radians:Number):Number
		{
			return radians * 180 / Math.PI;
		}
		
		public static function degToRad(degrees:Number):Number
		{
			return degrees * Math.PI / 180;
		}	
		
		public static function coneAngle(v:Vector2D, v2:Vector2D):Number
		{
			return Math.atan2(v.y,v.x) - Math.atan2(v2.y,v2.x);
		}
		
		public static function polarAngle(v:Vector2D):Number
		{
			return Math.atan2(v.y, v.x);
		}

	}
}