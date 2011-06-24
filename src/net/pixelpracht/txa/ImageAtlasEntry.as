package net.pixelpracht.txa
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;

	public class ImageAtlasEntry
	{
		public var sourceRect:Rectangle;
		public var trimmedLeft:int;
		public var trimmedRight:int;
		public var trimmedTop:int;
		public var trimmedBottom:int;
		public var unpackedImage:BitmapData;
		
		public function ImageAtlasEntry()
		{
			
		}
	}
}