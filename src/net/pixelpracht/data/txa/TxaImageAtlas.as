package net.pixelpracht.data.txa
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import net.pixelpracht.data.ImageAtlas;
	import net.pixelpracht.data.ImageAtlasEntry;
	import net.pixelpracht.geometry.Rectangle2D;

	public class TxaImageAtlas extends ImageAtlas
	{
		protected var _atlasImage:BitmapData;

		public function TxaImageAtlas(imageData:BitmapData, metaData:ByteArray, unpack:Boolean = true)
		{
			super();
			_atlasImage = imageData;
			parseMetaData(metaData);
			if(unpack)
				unpackAll();
		}
		
		private function parseMetaData(data:ByteArray):void
		{
			data.endian = Endian.LITTLE_ENDIAN;
			var foo:int = data.readInt();
			var bar:int = data.readInt();
			var numEntries:int = data.readInt();
			//parse sourceRects
			for(var i:int = 0; i < numEntries; i++)
			{
				var entry:TxaImageAtlasEntry = new TxaImageAtlasEntry();
				_entries.push(entry);
				var x:int = data.readInt();
				var y:int = data.readInt();
				var w:int = data.readInt();
				var h:int = data.readInt();
				entry.sourceRect = new Rectangle(x,y,w,h);
			}
			//parse names (null-terminated char-string) and map it to array index
			for(i = 0; i < numEntries; i++)
			{
				var name:String = "";
				var byte:int = data.readByte();
				while(byte != 0)
				{
					name += String.fromCharCode(byte);
					byte = data.readByte();
				}
				_entryMap[name] = i;
			}
			//parse trimmedBorders
			for(i = 0; i < numEntries; i++)
			{
				entry = _entries[i];
				entry.trimmedLeft = data.readInt();
				entry.trimmedTop = data.readInt();
				entry.trimmedRight = data.readInt();
				entry.trimmedBottom = data.readInt();
				//trace(name, i, entry.sourceRect);
			}
		}
		
		protected override function unpack(entry:ImageAtlasEntry):void
		{
			var txaFrame:TxaImageAtlasEntry = entry as TxaImageAtlasEntry;
			var w:int = txaFrame.sourceRect.width + txaFrame.trimmedLeft + txaFrame.trimmedRight;
			var h:int = txaFrame.sourceRect.height + txaFrame.trimmedTop + txaFrame.trimmedBottom;
			var img:BitmapData = new BitmapData(w, h, true, 0x00000000);
			img.copyPixels(_atlasImage, txaFrame.sourceRect, new Point(txaFrame.trimmedLeft, txaFrame.trimmedTop));
			entry.unpackedImage = img;
		}
	}
}