/*******************************************************************************
 * Copyright (c) 2009 by Thomas Jahn
 * Questions? Mail me at lithander@gmx.de!
 ******************************************************************************/
package net.pixelpracht.geometry
{
	public class CachedLineSegment2D extends LineSegment2D
	{
		public function CachedLineSegment2D(startX:Number=0, startY:Number=0, endX:Number=0, endY:Number=0)
		{
			super(startX, startY, endX, endY);
		}
		
		//returns cached copy
		public static function fromLineSegment(line:LineSegment2D):LineSegment2D
		{
			return new CachedLineSegment2D( line.start.x, line.start.y, line.end.x, line.end.y );			
		}
		
		/**
		 * Make a copy of this line segment.
		 */
		public override function clone():LineSegment2D
		{
			return new CachedLineSegment2D( start.x, start.y, end.x, end.y );
		}
		
		
		private var _direction:Vector2D = null;
		private var _length:Number = 0;
		private var _lengthSquared:Number = 0;
		private static var _tmp:Vector2D = new Vector2D();
		
		public override function recalc():void
		{
			_direction = end.subtracted(start);
			_length = _direction.length;
			_lengthSquared = _direction.lengthSquared;
		}
		
		public override function distance( v:Vector2D ):Number
		{
			//optimized: return snapped(v).distance(v);
			var pv:Number = _direction.x * (v.x - start.x) + _direction.y * (v.y - start.y);
			pv = Math.max(0, Math.min(1, pv/lengthSquared));
			_tmp.reset(start.x + _direction.x * pv, start.y + _direction.y * pv);
			return _tmp.distance(v);
		}		
		
		/**
		 * A cached vector covering the distance from start to end.
		 */		
		public override function get direction():Vector2D
		{
			return _direction;
		}	
		
		/**
		 * The length of this line segment
		 */
		public override function get length():Number
		{
			return _length;
		}
		
		/**
		 * The square of the length of this line segment
		 */
		public override function get lengthSquared():Number
		{
			return _lengthSquared;
		}
		
	}
}