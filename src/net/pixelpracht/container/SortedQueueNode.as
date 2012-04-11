package net.pixelpracht.container
{
	public class SortedQueueNode
	{
		public var data:Object = null;
		public var next:SortedQueueNode = null;
		private var _weight:Number = 0;
		
		public function add(toAdd:Object, weight:Number):void
		{
			if(data)
			{
				if(weight >= _weight) //take this position?
				{
					//move current data one up
					var newNode:SortedQueueNode = _nodePop();
					newNode.data = this.data;
					newNode.next = this.next;
					newNode._weight = this._weight;
					//update this
					next = newNode;
					data = toAdd;
					_weight = weight;
				}
				else if(next)
					next.add(toAdd, weight);
				else
				{
					//add as last
					newNode = _nodePop();
					newNode.data = toAdd;
					newNode._weight = weight;
					next = newNode;
				}
			}
			else
			{
				data = toAdd;
				_weight = weight;
			}
		}
		
		public function remove(toRemove:Object):void
		{
			if(data == toRemove)
			{
				//remove next
				if(next)
				{
					var oldNode:SortedQueueNode = next;
					data = oldNode.data;
					next = oldNode.next;
					_weight = oldNode._weight;
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
			var cur:SortedQueueNode = this;
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
			var cur:SortedQueueNode = this;
			var i:int = 0;
			while(cur)
			{
				trace(i,":",cur.data,"weight:",cur._weight);
				cur = cur.next;
				i++;
			}
		}
		
		//Node Pool
		
		private static var _nodePool:Array = [];
		
		private static function _nodePush(node:SortedQueueNode):void
		{
			node.next = null;
			node.data = null;
			_nodePool.push(node);
		}
		private static function _nodePop():SortedQueueNode
		{
			var result:SortedQueueNode = _nodePool.pop();
			if(result)
				return result;
			//factory style - this is the only place creating instances
			return new SortedQueueNode(); 
		}
		
	}
}