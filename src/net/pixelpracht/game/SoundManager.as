package net.pixelpracht.game
{
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	

	public class SoundManager
	{
		private var _sfxs:Object = {};
		private var _mscs:Object = {};
		
		private var _soundTransform:SoundTransform = new SoundTransform(0.5);
		
		private var _music:Sound = null;
		private var _musicChannel:SoundChannel = null;
		private var _musicTransform:SoundTransform = new SoundTransform(0.5);
		
		public function SoundManager()
		{
			
		}
		
		public function addSfx(name:String, def:* = null):void
		{
			if(def is Class)
			{
				var sound:Sound = new def;
				_sfxs[name] = sound;
			}
		}
				
		public function playSfx(name:String, transform:SoundTransform = null):void
		{
			var sound:Sound = _sfxs[name] as Sound;
			if(sound)
			{
				var chan:SoundChannel = sound.play();
				chan.soundTransform = transform ? transform : _soundTransform;
				return;
			}
		}
		
		public function addMusic(name:String, rsx:Class):void
		{
			var music:Sound = new rsx() as Sound;
			_mscs[name] = music;			
		}
		
		public function playMusic(name:String):void
		{
			var music:Sound = _mscs[name] as Sound;
			if(music && music != _music)
			{
				if(_musicChannel)
					_musicChannel.stop();
				_music = music;
				_musicChannel = music.play(0, 99999);
				_musicChannel.soundTransform = _musicTransform;
			}
		}
	}
}