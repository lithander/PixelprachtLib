package net.pixelpracht.data.pxp
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import net.pixelpracht.data.ImageAtlas;
	import net.pixelpracht.data.ImageAtlasEntry;
	import net.pixelpracht.geometry.Rectangle2D;

	public class PxpImageAtlas extends ImageAtlas
	{
		private var _pixelPackage:PixelPackage = null;
		
		public function PxpImageAtlas(pxpData:PixelPackage)
		{
			super();
			_pixelPackage = pxpData;
			_pixelPackage.open();
			createEntries(pxpData);
			unpackAll();
			_pixelPackage.close();
		}
		
		private function createEntries(pack:PixelPackage):void
		{			
			var entryIdx:int = 0;
			for(var name:String in pack.sequences)
			{
				var seq:ImageSequence = pack.sequences[name];
				for(var i:int = 0; i < seq.frameCount; i++)
				{
					var entry:PxpImageAtlasEntry = new PxpImageAtlasEntry();
					entry.frame = seq.firstFrame + i;
					var entryName:String = name+i;
					_entries[entryIdx] = entry;
					_entryMap[entryName] = entryIdx++;
				}				
			}
		}
		
		protected override function unpack(entry:ImageAtlasEntry):void
		{
			if(!_pixelPackage.isOpen())
				throw new Error("Can't unpack Entries from a closed PixelPackage");
			var pxpFrame:PxpImageAtlasEntry = entry as PxpImageAtlasEntry;
			pxpFrame.unpackedImage = _pixelPackage.frames[pxpFrame.frame];
		}
	}
}