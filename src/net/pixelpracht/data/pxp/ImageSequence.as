package net.pixelpracht.data.pxp
{
	public class ImageSequence
	{
		public var width:int = 0;
		public var height:int = 0;
		public var firstFrame:int = 0;
		public var frameCount:int = 0;
		public function ImageSequence(w:int, h:int, first:int, count:int)
		{
			width = w;
			height = h;
			firstFrame = first;
			frameCount = count;
		}
	}
}