package net.pixelpracht.data.txa
{
	import flash.geom.Rectangle;
	
	import net.pixelpracht.data.ImageAtlasEntry;

	public class TxaImageAtlasEntry extends ImageAtlasEntry
	{
		public var sourceRect:Rectangle;
		public var trimmedLeft:int;
		public var trimmedRight:int;
		public var trimmedTop:int;
		public var trimmedBottom:int;
		
		public function TxaImageAtlasEntry()
		{
		}
	}
}