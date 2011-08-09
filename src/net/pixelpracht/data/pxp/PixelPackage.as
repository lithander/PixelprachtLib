package net.pixelpracht.data.pxp
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import net.pixelpracht.graphics.Color;

	public class PixelPackage
	{
		private var _rawData:ByteArray = null;
		private var _firstFramePosition:uint = 0;
		private var _seqArray:Array = null;
		public var sequences:Object = null;
		public var frames:Array = null;
		
		public var merger:CombineShader = new CombineShader();
		
		public function PixelPackage(pxpData:ByteArray)
		{
			_rawData = pxpData;
			_rawData.endian = Endian.LITTLE_ENDIAN;
		}
		
		public function open():void
		{
			if(isOpen())
				throw new Error("PixelPackage has been opened allready!");
			sequences = new Object();
			_seqArray = [];
			frames = [];
			_rawData.inflate();
			readHeader(_rawData);
			_rawData.position = _firstFramePosition;
			readFrames(_rawData);
		}
		
		public function close():void
		{
			_rawData.deflate();
			sequences = null;
			frames = null;
		}
		
		public function isOpen():Boolean
		{
			return (sequences != null && frames != null);
		}
		
		private function readFrames(data:ByteArray):void
		{
			var numSequences:int = _seqArray.length;
			var keyFramePos:int = _firstFramePosition;
			var firstDeltaFramePos:int = keyFramePos;
			for(var i:int = 0; i < numSequences; i++)
				firstDeltaFramePos += _seqArray[i].height * _seqArray[i].width *4;

			for(i = 0; i < numSequences; i++)
			{
				var seq:ImageSequence = _seqArray[i];
				var numFrames:int = seq.frameCount;
				var bytesPerLine:int = seq.width *4;
				var bytesPerFrame:int = seq.height * bytesPerLine;
				//prepare frames
				for(var j:int = 0; j < numFrames; j++)
					frames[seq.firstFrame + j] = new BitmapData(seq.width, seq.height);
				
				var r:uint = 0;
				var g:uint = 0;
				var b:uint = 0;
				var a:uint = 0;
				var c:uint = 0;
				
				for(var y:int = 0; y < seq.height; y++)
					for(var x:int = 0; x < seq.width; x++)
					{
						for(var k:int = 0; k < numFrames; k++)
						{
							var frame:BitmapData = frames[seq.firstFrame + k];
							//data.position = firstFramePos + k * bytesPerFrame + y * bytesPerLine + 4 * x;
							if(k == 0)//KEYFRAME
							{
								var p:uint = keyFramePos + y * bytesPerLine + 4 * x;
								b = data[p++];
								g = data[p++];
								r = data[p++];
								a = data[p];							
								c = a << 24 | r <<16 | g <<8 | b;
								//c = data[p+3] << 24 | data[p+2] <<16 | data[p+1] <<8 | data[p];
								frame.setPixel32(x,y,c);
							}
							else
							{
								p = firstDeltaFramePos + (k-1) * bytesPerFrame + y * bytesPerLine + 4 * x;
								b = (b + data[p++])%256;
								g = (g + data[p++])%256;
								r = (r + data[p++])%256;
								a = (a + data[p])%256;								
								c = a << 24 | r <<16 | g <<8 | b;
								//c = data[p+3] << 24 | data[p+2] <<16 | data[p+1] <<8 | data[p];
								frame.setPixel32(x,y,c);
							}
						}
					}
				
				keyFramePos += bytesPerFrame;
				firstDeltaFramePos += (numFrames-1)*bytesPerFrame;
			}
		}
		
		private function readFrame(data:ByteArray, width:int, height:int, prev:BitmapData):BitmapData
		{
			var numPixels:int = width * height;
			var bmd:BitmapData = new BitmapData(width, height);
			bmd.setPixels(bmd.rect, data);
			return bmd;
			/*
			var red:ByteArray = new ByteArray();
			var green:ByteArray = new ByteArray();
			var blue:ByteArray = new ByteArray();
			var alpha:ByteArray = new ByteArray();
			var rgba:ByteArray = new ByteArray();
			var color:Color = new Color();

			var numPixels:int = width * height;
			var bmd:BitmapData = new BitmapData(width, height);
			data.readBytes(red, 0, numPixels);
			data.readBytes(green, 0, numPixels);
			data.readBytes(blue, 0, numPixels);
			data.readBytes(alpha, 0, numPixels);
			for(var i:int = 0; i < numPixels; i++)
			{
				color.redByte = red.readUnsignedByte();
				color.greenByte = green.readUnsignedByte();
				color.blueByte = blue.readUnsignedByte();
				color.alphaByte = alpha.readUnsignedByte();
				rgba.writeUnsignedInt(color.rgba);
			}
			rgba.position = 0;
			bmd.setPixels(bmd.rect, rgba);
			return bmd;
			*/
		}
		
		private function readHeader(data:ByteArray):void
		{
			var nextFrame:int = 0;
			var numSequences:int = data.readShort();
			for(var i:int = 0; i < numSequences; i++)
			{
				var name:String = data.readUTF();
				var width:int = data.readShort();
				var height:int = data.readShort();
				var frameCount:int = data.readShort();
				var seq:ImageSequence = new ImageSequence(width, height, nextFrame, frameCount);
				_seqArray[i] = seq;
				sequences[name] = seq;
				nextFrame += frameCount;
			}
			_firstFramePosition = data.position;
		}
	}
}