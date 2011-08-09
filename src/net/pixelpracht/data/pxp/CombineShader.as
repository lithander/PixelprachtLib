package net.pixelpracht.data.pxp 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.utils.ByteArray;

	//this simple class sets up the pixelBender shader and uses it to apply a delta
	//frame to a previous frame
	public class CombineShader
	{
		[Embed(source="../pb/combine.pbj", mimeType="application/octet-stream")]
		private static var RsxCombineShader:Class;
		
		private var _shader:Shader = null;
		
		public function CombineShader()
		{
			_shader = new Shader(new RsxCombineShader());
		}
		
		public function combine(base:BitmapData, delta:ByteArray):BitmapData
		{
			var p:int = delta.position;
			var w:int = base.width;
			var h:int = base.height;
			var bytes:ByteArray = new ByteArray();
			delta.readBytes(bytes,p,w*h*4);
			var target:BitmapData = new BitmapData(w, h);
			//target.setPixels(bmd.rect, delta);
			
			_shader.data.base.input = base;
			_shader.data.delta.input = delta;
			_shader.data.delta.width = w;
			_shader.data.delta.height = h;
			var _job:ShaderJob = new ShaderJob(_shader, target);
			_job.start(true);
			
			delta.position = p + w*h*4;
			return target;
		}
	}
}