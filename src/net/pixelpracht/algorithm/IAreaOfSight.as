package net.pixelpracht.algorithm
{
	import net.pixelpracht.geometry.Rectangle2D;
	import net.pixelpracht.geometry.Vector2D;

	public interface IAreaOfSight
	{
		function get occluders():Array
		function get outline():Array
		function setOccluders(occluders:Array, clipRect:Rectangle2D):void
		function buildOutline(viewPos:Vector2D):Array
	}
}