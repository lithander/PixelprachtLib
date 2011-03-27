package net.pixelpracht.container
{
	public class QueueNode
	{
		public var data:Object = null;
		public var next:QueueNode = null;
		public function add(toAdd:Object):void
		{
			if(data)
			{
				//move current data one up
				var newNode:QueueNode = _nodePop();
				newNode.data = this.data;
				newNode.next = this.next;
				next = newNode;
			}
			data = toAdd;
		}
		
		public function remove(toRemove:Object):void
		{
			if(data == toRemove)
			{
				//remove next
				if(next)
				{
					var oldNode:QueueNode = next;
					data = oldNode.data;
					next = oldNode.next;
					_nodePush(oldNode);	
				}
				else
					data = null;					
			}
			if(next)
				next.remove(toRemove);
		}
		
		public function contains(toFind:Object):Boolean
		{
			if(data == toFind)
				return true;
			if(next)
				return next.contains(toFind);
			return false;
		}
		
		public function clear():void
		{
			if(next)
			{
				next.clear();
				_nodePush(next);
			}
			data = null;					
			next = null;
		}
		
		public function get numChilds():int
		{
			if(data == null)
				return 0;
			var cnt:int = 0;
			var cur:QueueNode = this;
			while(cur)
			{
				cur = cur.next;
				cnt++;
			}
			return cnt;
		}			
		
		public function traceContent():void
		{
			trace("queue content");
			var cur:QueueNode = this;
			var i:int = 0;
			while(cur)
			{
				trace(i,":",cur.data);
				cur = cur.next;
				i++;
			}
		}
		
		//Node Pool
		
		private static var _nodePool:Array = [];
		
		private static function _nodePush(node:QueueNode):void
		{
			node.next = null;
			node.data = null;
			_nodePool.push(node);
		}
		private static function _nodePop():QueueNode
		{
			var result:QueueNode = _nodePool.pop();
			if(result)
				return result;
			//factory style - this is the only place creating instances
			return new QueueNode(); 
		}

	}
}