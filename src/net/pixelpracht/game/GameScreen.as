package net.pixelpracht.game
{
	import flash.display.DisplayObjectContainer;

	public class GameScreen
	{
		protected var _blocksUpdate:Boolean = false;
		protected var _blocksDraw:Boolean = false;
		protected var _updateIsBlocked:Boolean = false;
		protected var _drawIsBlocked:Boolean = false;
		
		public function GameScreen(blockDraw:Boolean = false, blockUpdate:Boolean = false)
		{
			_blocksUpdate = blockUpdate;
			_blocksDraw = blockDraw;
		}
		
		public function get blocksUpdate():Boolean
		{
			return _blocksUpdate;			
		}
		
		public function get blocksDraw():Boolean
		{
			return _blocksDraw;			
		}
		
		public function get updateIsBlocked():Boolean
		{
			return _updateIsBlocked;
		}
		
		public function set updateIsBlocked(v:Boolean):void
		{
			if(_updateIsBlocked != v)
			{
				if(_updateIsBlocked)
					endUpdateBlock();
				else
					beginUpdateBlock();
			}
			_updateIsBlocked = v;			
		}
		
		public function get drawIsBlocked():Boolean
		{
			return _drawIsBlocked;
		}
				
		public function set drawIsBlocked(v:Boolean):void
		{
			if(_drawIsBlocked != v)
			{
				if(_drawIsBlocked)
					endDrawBlock();
				else
					beginDrawBlock();
			}
			_drawIsBlocked = v;			
		}
		
		public function open(root:DisplayObjectContainer):void
		{
			
		}
		
		public function close(root:DisplayObjectContainer):void
		{

		}
		
		public function beginUpdateBlock():void
		{
			
		}
		
		public function endUpdateBlock():void
		{
			
		}
		
		public function update(deltaTime:Number):void
		{
			
		}
		
		public function beginDrawBlock():void
		{
			
		}
		
		public function endDrawBlock():void
		{
			
		}
		
		public function draw():void
		{
		
		}
	}
}