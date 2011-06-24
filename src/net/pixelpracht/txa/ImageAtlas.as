package net.pixelpracht.txa
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mx.controls.Image;
	
	import net.pixelpracht.geometry.Rectangle2D;

	public class ImageAtlas
	{
		public var _atlasImage:BitmapData;
		public var _entries:Array;
		public var _entryMap:Object;
		
		public function ImageAtlas(imageData:BitmapData, metaData:ByteArray, unpack:Boolean = true)
		{
			_entries = [];
			_entryMap = new Object();
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
				var entry:ImageAtlasEntry = new ImageAtlasEntry();
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
		
		public function contains(name:String):Boolean
		{
			return _entryMap.hasOwnProperty(name);
		}
		
		public function get lastIndex():int
		{
			return _entries.length -1;
		}
		
		public function getIndex(name:String):int
		{
			if(_entryMap.hasOwnProperty(name))
				return _entryMap[name];
			else
				throw new Error("No sprite has the name: " + name);
		}
		
		public function getByName(name:String):BitmapData
		{
			return getByIndex(getIndex(name));
		}
		
		public function getByIndex(idx:int):BitmapData
		{
			if (idx < 0 || idx > _entries.length)
				throw new Error("No sprite at index: " + idx);
			else
			{
				var entry:ImageAtlasEntry = _entries[idx];
				if(!entry.unpackedImage)
					unpack(entry);
				return entry.unpackedImage;
			}
		}
		
		public function unpackAll():void
		{
			for each(var entry:ImageAtlasEntry in _entries)
				unpack(entry);
			
		}
		
		private function unpack(entry:ImageAtlasEntry):void
		{
			var w:int = entry.sourceRect.width + entry.trimmedLeft + entry.trimmedRight;
			var h:int = entry.sourceRect.height + entry.trimmedTop + entry.trimmedBottom;
			var img:BitmapData = new BitmapData(w, h, true, 0x00000000);
			img.copyPixels(_atlasImage, entry.sourceRect, new Point(entry.trimmedLeft, entry.trimmedTop));
			entry.unpackedImage = img;
		}

	}
}