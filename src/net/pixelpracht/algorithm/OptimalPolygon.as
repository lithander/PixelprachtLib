package net.pixelpracht.algorithm
{
	import flash.display.Graphics;
	import flash.display.Shape;
	
	import net.pixelpracht.container.QueueNode;
	import net.pixelpracht.container.SortedQueueNode;
	import net.pixelpracht.geometry.Vector2D;
	
	import spark.primitives.Graphic;

	public class OptimalPolygon implements IOptimalPolygon
	{
		//input
		private var _vertices:Array;
		private var _nodeCnt:int;
		private var _graph:Array;
		
		//output
		private var _polygon:Array = [];
		
		public function OptimalPolygon()
		{
		}
		
		public function get polygon():Array
		{
			return _polygon;
		}
		
		public function get vertices():Array
		{
			return _vertices;
		}
		
		public function buildPolygon(accuracy:Number):Array
		{
			findShortestCircle(0, accuracy);
			return _polygon;			
		}
		
		public function setVertices(nodes:Array):void
		{
			_vertices = nodes;
			_nodeCnt = nodes.length;
			_graph = new Array(_nodeCnt);
			for(var i:int = 0; i < _nodeCnt; i++)
			{
				_graph[i] = new Array(_nodeCnt);
				for(var j:int = 0; j < _nodeCnt; j++)
					_graph[i][j] = -1; 		
			}
			initializeGraph();
		}		
		
		private function initializeGraph():void
		{
			var skipped:Number = 0;
			var cons:Number = 0;
			
			var constraintLeft:Vector2D = new Vector2D();
			var constraintRight:Vector2D = new Vector2D();
			var seg:Vector2D = new Vector2D();
			var startDir:Vector2D = new Vector2D();
			var off:Vector2D = new Vector2D();
			//find straight segments
			for(var i:int = 0; i < _nodeCnt; i++)
			{
				var j:int = i+3;
				var max:int = i + _nodeCnt;
				var si:int = (i+1)%_nodeCnt;
				var start:Vector2D = _vertices[i%_nodeCnt];
				startDir.copy(_vertices[si]).subtract(start);
				seg.copy(_vertices[j%_nodeCnt]).subtract(start);
				seg.subtract(_vertices[i]);
				constraintLeft.reset();
				constraintRight.reset();
				while(j < max)
				{
					//i->j is a straight subpath					
					var sj:int = (j-1)%_nodeCnt;
					var sk:int = j%_nodeCnt;

					//consider skippint?
					var c:Vector2D = _vertices[sj];
					var d:Vector2D = _vertices[sk];
					if( (startDir.crossProduct(c.subtracted(start)) != 0) ||
						(startDir.crossProduct(d.subtracted(start)) != 0))
					{
						_graph[si][sj] = rate(i, j);
						cons++;
					}
					else 
						skipped++;
					
					//try next
					seg.copy(_vertices[++j%_nodeCnt]);
					seg.subtract(_vertices[i]);
					
					//check left & right constraints
					if( (constraintLeft.crossProduct(seg) < 0) || (constraintRight.crossProduct(seg) > 0) )
						break;	
					
					//narrow constraints
					if (Math.abs(seg.x) <= 1 && Math.abs(seg.y) <= 1)
						continue;
					
					off.copy(seg);
					off.x += ((seg.y>0) || (seg.y == 0 && seg.x < 0)) ? 1 : -1;
					off.y += ((seg.x<0) || (seg.x == 0 && seg.y < 0)) ? 1 : -1;
					if (constraintLeft.crossProduct(off) >= 0)
						constraintLeft.copy(off);
					
					
					off.copy(seg);
					off.x += ((seg.y<0) || (seg.y == 0 && seg.x < 0)) ? 1 : -1;
					off.y += ((seg.x>0) || (seg.x == 0 && seg.y < 0)) ? 1 : -1;
					if (constraintRight.crossProduct(off) <= 0)
						constraintRight.copy(off);
				}
			}
			//trace("TOTAL CONS:",cons,"skipped:",skipped);
		}
		
		private function findShortestCircle(start:int, accuracy:Number):void
		{
			//alloc graph nodes and open-list
			var nodes:Array = new Array(_nodeCnt);
			for(var i:int = 0; i < _nodeCnt; i++)
				nodes[i] = new GraphNode(i, 1);
			
			var open:SortedQueueNode = new SortedQueueNode();
			//init start nodes
			for(i = 0; i < _nodeCnt; i++)
			{
				var conError:Number = _graph[start][i];
				if(_graph[start][i] >= 0) //connection exists
				{
					var node:GraphNode = nodes[i] as GraphNode;
					node.prev = start;
					node.distance = node.weight;
					node.error = conError * accuracy;
					open.add(node, 1/(node.distance+node.error));
				}
			}
			
			//flood graph until saturated
			var iteration:int = 0;
			while(open.data)
			{
				var current:GraphNode = open.data as GraphNode;
				open.remove(current);
				//update connected nodes
				for(i = 0; i < _nodeCnt; i++)
				{
					conError = _graph[current.id][i];
					if(conError >= 0) //connection exists
					{
						var next:GraphNode = nodes[i] as GraphNode;
						var dist:Number = current.distance + next.weight;
						var error:Number = current.error + conError * accuracy;
						if(next && ((dist+error) < (next.distance+next.error)))
						{
							//update distance
							next.prev = current.id;
							next.distance = dist;
							next.error = error;
							open.add(next, 1/(dist+error));
						}
					}
				}
				//trace("Iteration:",iteration++, "Open:",open.numChilds);
				//open.traceContent()
			}
			//backtrack from end to start
			_polygon = [];
			current = nodes[start];
			while(current)
			{
				//trace("Poly:",current.distance, current.error);
				_polygon.push(_vertices[current.id]);
				current = (current.prev != start) ? nodes[current.prev] : null;
			}
		}
		
		public function createDebugShape(scale:Number):Shape
		{
			var result:Shape = new Shape();
			var gfx:Graphics = result.graphics;
			gfx.clear();
			for(var i:int = 0; i < _nodeCnt; i++)
				for(var j:int = 0; j < _nodeCnt; j++)
				{
					var rating:Number = _graph[i][j];
					if(_graph[i][j] >= 0)
					{
						var r:int = 255 / (1+rating);
						var g:int = 255 - r;
						gfx.lineStyle(1, r*0x010000 + g*0x000100, 0.2);

						gfx.moveTo(_vertices[i].x * scale, _vertices[i].y * scale);
						gfx.lineTo(_vertices[j].x * scale, _vertices[j].y * scale);	
					}
				}
			gfx.lineStyle(1, 0x0000FF);
			var lastIdx:int = _nodeCnt - 1;
			gfx.moveTo(_vertices[lastIdx].x * scale, _vertices[lastIdx].y * scale);
			for each(var p:Vector2D in _vertices)
				gfx.lineTo(p.x * scale, p.y * scale);
						
			gfx.lineStyle(2, 0x000000);
			lastIdx = _polygon.length - 1;
			gfx.moveTo(_polygon[lastIdx].x * scale, _polygon[lastIdx].y * scale);
			for each(p in _polygon)
				gfx.lineTo(p.x * scale, p.y * scale);
			
			
			return result;
		}
		
		/* Readable but UNOPTIMIZED
		private function rate(first:int, last:int):Number
		{
			var sum:Number = 0;
			var start:Vector2D = _vertices[(first+1)%_nodeCnt];
			var end:Vector2D = _vertices[(last-1)%_nodeCnt];
			var temp:LineSegment2D = LineSegment2D.fromVectors(start, end);
			for(var k:int = first+1; k < last; k++)
				sum += temp.distanceSquared(_vertices[k%_nodeCnt]);
								
			return sum / (last-first);
		}
		*/
		
		private function rate(first:int, last:int):Number
		{
			//rating based on least squares
			var sum:Number = 0;
			var start:Vector2D = _vertices[(first+1)%_nodeCnt];
			var end:Vector2D = _vertices[(last-1)%_nodeCnt];
			
			//calc normalized direction vector of the line to rate
			var dx:Number = end.x - start.x;
			var dy:Number = end.y - start.y;
			var len:Number = Math.sqrt( dx * dx + dy * dy );
			var s:Number = 1 / len;
			dx *= s;
			dy *= s;
			//sum the squared distance of each vertex to the closest pont of the line
			for(var k:int = first+1; k < last; k++)
			{
				var v:Vector2D = _vertices[k%_nodeCnt];
				var toVx:Number = v.x - start.x;
				var toVy:Number = v.y - start.y;
				var t:Number = dx * toVx + dy * toVy;
				var sx:Number = (t * dx) - toVx;
				var sy:Number = (t * dy) - toVy;
				sum += ( sx * sx + sy * sy );
			}					
			return sum / (last-first); //normalize sum by the amount of vertices
		}
	}
}

//*** INTERNALLY USED CLASSES ***

class GraphNode
{
	public function GraphNode(nodeId:int, nodeWeight:Number)
	{
		id = nodeId;
		weight = nodeWeight;
	}
	
	public function toString():String
	{
		return id.toString();
	}
	
	public var id:int;
	public var weight:Number;
	public var distance:Number = Number.POSITIVE_INFINITY;
	public var error:Number = Number.POSITIVE_INFINITY;
	public var prev:int = -1;
}