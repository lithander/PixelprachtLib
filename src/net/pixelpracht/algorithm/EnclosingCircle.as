package net.pixelpracht.algorithm
{
	import net.pixelpracht.geometry.Rectangle2D;
	import net.pixelpracht.geometry.Vector2D;

	public class EnclosingCircle
	{
		private var _center:Vector2D = new Vector2D();
		private var _radius:Number = 0;

		public function EnclosingCircle()
		{
		}
		
		public function get center():Vector2D
		{
			return _center;
		}
		
		public function get radius():Number
		{
			return _radius;
		}
		
		public function buildCircle(nodes:Array):void
		{
			//return _buildCircleFromAverage(nodes);
			return _buildRittersCircle(nodes);
		}
		
		private function _buildRittersCircle(nodes:Array):void
		{
			var p:Vector2D = nodes[0];
			//build a bounding rectangle
			var rect:Rectangle2D = new Rectangle2D(p.x, p.y);
			for each(p in nodes)
				rect.addVector(p);
			//build a circle that fits between the two farther opposite edges of the box (it's still too small)
			_radius = Math.max(rect.width/2, rect.height/2);
			_center = rect.center;
			// now check that all nodes are inside
			// if not, expand the circle just enough to include them
			for each(p in nodes)
			{
				var d:Number = p.distance(_center);
				if(d > _radius)
				{
					_radius = (_radius + d) / 2.0;
					//shift _center by |d-radius| towards p
					_center.add(p.subtracted(_center).scale((d-_radius)/d));
				}
			}
		}
		
		private function _buildCircleFromAverage(nodes:Array):void
		{
			var p:Vector2D = null;
			//find center
			_center.reset();
			for each(p in nodes)
				_center.add(p);
			_center.scale(1/nodes.length);
			//calc max distance from center
			_radius = 0;
			for each(p in nodes)
				_radius = Math.max(_radius, _center.distance(p));			
		}
	}
}