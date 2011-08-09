package net.pixelpracht.graphics
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	import net.pixelpracht.data.ImageAtlas;
	
	public class AnimatedBitmap extends Bitmap
	{
		private var _source:ImageAtlas;
		private var _baseName:String;
		private var _startIdx:int;
		private var _endIdx:int;
		private var _currentIdx:int = 0;
		
		private var _autoplay:Boolean = false;
		private var _onDoneCallback:Function = null;
		private var _loop:Boolean = true;
		
		public function AnimatedBitmap(source:ImageAtlas, baseName:String = "", numFrames:int = 0)
		{
			super(null);
			_source = source;
			assignFramesByName(baseName, numFrames);
			bitmapData = _source.getByIndex(_currentIdx);
		}

		public function assignFramesByName(baseName:String, numFrames:int):void
		{
			var curOffset:int = Math.max(0, _currentIdx - _startIdx);
			if(_source.contains(baseName))
			{
				_startIdx = _source.getIndex(baseName);
				_endIdx = _startIdx + numFrames;
				_currentIdx = Math.min(_endIdx, _startIdx + curOffset);
			}
			bitmapData = _source.getByIndex(_currentIdx);
		}

		public function assignFrames(startFrame:int, lastFrame:int):void
		{
			var curOffset:int = Math.max(0, _currentIdx - _startIdx);
			_startIdx = startFrame;
			_endIdx = lastFrame;
			_currentIdx = Math.min(_endIdx, _startIdx + curOffset);
			bitmapData = _source.getByIndex(_currentIdx);
		}
		
		public function setFrame(curFrame:int):void
		{
			_currentIdx = _startIdx + curFrame;
			bitmapData = _source.getByIndex(_currentIdx);
		}
		
		public function nextFrame():void
		{
			_currentIdx++;
			if(_currentIdx > _endIdx)
				_currentIdx = _loop ? _startIdx : _endIdx;
			bitmapData = _source.getByIndex(_currentIdx);
		}
		
		public function play(onDoneCallback:Function = null):void
		{
			if(isPlaying())
			{
				var callbackChanged:Boolean = onDoneCallback != _onDoneCallback;
				stop(callbackChanged); //stop the animation, trigger callback if the callback has changed.
			}
			//enable auto update
			_onDoneCallback = onDoneCallback;
			_autoplay = true;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
		}
		
		public function stop(triggerCallback:Boolean):void
		{
			//stop auto update
			if(_autoplay)
			{
				if((_onDoneCallback != null) && triggerCallback)
				{
					_onDoneCallback.call(this, isLastFrame());
				}
				_onDoneCallback = null;
				_autoplay = false;
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		public function onEnterFrame(evt:Event):void
		{
			if(!looping && isLastFrame())
				stop(true);
			else		
				nextFrame();	
		}
		
		public function isPlaying():Boolean
		{
			return _autoplay;
		}
		
		public function isLastFrame():Boolean
		{
			return (_currentIdx == _endIdx);
		}
		
		public function get looping():Boolean
		{
			return _loop;
		}
		
		public function set looping(v:Boolean):void
		{
			_loop = v;	
		}
	}
}