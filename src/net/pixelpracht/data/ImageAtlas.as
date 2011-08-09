package net.pixelpracht.data
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import net.pixelpracht.geometry.Rectangle2D;

	public class ImageAtlas
	{
		protected var _entries:Array;
		protected var _entryMap:Object;
		
		public function ImageAtlas()
		{
			_entries = [];
			_entryMap = new Object();
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
			if (idx < 0 || idx >= _entries.length)
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
				if(!entry.unpackedImage)
					unpack(entry);
		}
		
		protected function unpack(entry:ImageAtlasEntry):void
		{
			//IMPLEMENT LATER
		}

	}
}