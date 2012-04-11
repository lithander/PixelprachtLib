package net.pixelpracht.algorithm
{
	import net.pixelpracht.geometry.Rectangle2D;
	import net.pixelpracht.geometry.Vector2D;
	
	public interface IOptimalPolygon
	{
		function get vertices():Array
		function get polygon():Array
		function setVertices(nodes:Array):void
		function buildPolygon(accuracy:Number):Array
	}
}