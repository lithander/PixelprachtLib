package net.pixelpracht.game
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;

	public class ScreenManager
	{
		private var _blocker:GameScreen = null;
		private var _screen:GameScreen = null;
		private var _screens:Object = new Object();
		private var _activeScreens:Array = [];
		private var _temp:Array = [];
		private var _root:DisplayObjectContainer = null;
		

		public function ScreenManager(root:DisplayObjectContainer)
		{
			_root = root;
			_root.addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		}
		
		public function addScreen(name:String, screen:GameScreen):void
		{
			_screens[name] = screen;
		}
		
		public function removeScreen(name:String):void
		{
			delete _screens[name];
		}
		
		public function getScreen(name:String):GameScreen
		{
			if(_screens.hasOwnProperty(name))
				return _screens[name];
			else
				return null;
		}
		
		public function push(name:String):void
		{
			if(_screens.hasOwnProperty(name))
			{
				var screen:GameScreen = _screens[name];
				_activeScreens.push(screen);
				screen.open(_root);
			}
		}
				
		public function pop():void
		{
			var screen:GameScreen = _activeScreens.pop();
			screen.close(_root);
		}
		
		public function remove(name:String):void
		{
			if(_screens.hasOwnProperty(name))
			{
				var screen:GameScreen = _screens[name];
				var idx:int = _activeScreens.indexOf(screen);
				if(idx > 0)
					_activeScreens.splice(idx,1);
				screen.close(_root);				
			}	
		}
		
		protected function _onEnterFrame(evt:Event):void
		{
			var frameRate:Number = _root.stage.frameRate;
			_update(1/frameRate);
			_draw();
		}
		
		protected function _update(deltaTime:Number):void
		{
			//create temp list so changes to _activeScreens list don't effect this frames update order
			_temp = [];
			_blocker = null;
			for(var i:int = _activeScreens.length-1; i >= 0; i--)
			{	
				_screen = _activeScreens[i];
				_temp.push(_screen);
				if(_screen.blocksUpdate && !_blocker)
					_blocker = _screen;//top blocker
			}
			
			//update top to bottom
			var blocked:Boolean = false;
			for each(_screen in _temp)
			{
				_screen.updateIsBlocked = blocked;
				if(!blocked)
				{
					_screen.update(deltaTime);
					if(_screen == _blocker) //blocked from now on?
						blocked = true;
				}
			}
			_blocker = null;
		}
		
		protected function _draw():void
		{
			var screen:GameScreen = null;
			_blocker = null;
			//identify blocking screen
			for each(_screen in _activeScreens)
				if(_screen.blocksDraw)
					_blocker = _screen;//top blocker
			
			//render bottom up
			var blocked:Boolean = _blocker ? true : false;
			for each(_screen in _activeScreens)
			{	
				if(blocked && _screen == _blocker) //remove block?
					blocked = false;
				_screen.drawIsBlocked = blocked;
				if(!blocked)
					_screen.draw();
			}
			_blocker = null;
		}
	}
}