/*******************************************************************************
 * Copyright (c) 2010 by Thomas Jahn
 * Questions? Mail me at lithander@gmx.de!
 ******************************************************************************/
package net.pixelpracht.algorithm
{
	import net.pixelpracht.container.QueueNode;
	import net.pixelpracht.geometry.CachedLineSegment2D;
	import net.pixelpracht.geometry.LineSegment2D;
	import net.pixelpracht.geometry.Rectangle2D;
	import net.pixelpracht.geometry.Vector2D;

	public class AreaOfSight implements IAreaOfSight
	{
		//input
		private var _viewPos:Vector2D = new Vector2D();
		private var _occluders:Array = [];
		
		//output
		private var _outline:Array = [];
		
		//intermediate
		private var _startEvents:Array = [];
		private var _endEvents:Array = [];
		private var _openList:QueueNode = new QueueNode();
		private var _current:Occluder = null;
		private var _currentDir:LineSegment2D = null;
		private var _currentAngle:Number = 0;
		private var _currentPoint:Vector2D = null;
		private var _helper:Vector2D = new Vector2D();
		
		//pools
		private var _segPool:Array = [];
		private var _eventPool:Array = [];

		//*************		
		
		public function AreaOfSight()
		{
			
		}
		
		public function get occluders():Array
		{
			return _occluders;
		}
		public function get outline():Array
		{
			return _outline;
		}
		
		public function setOccluders(occluders:Array, clipRect:Rectangle2D):void
		{
			//recycle old occluders
			var i:int = 0;
			var max:int = _occluders.length;
			for(i = 0; i < max; i++)
				_pushSeg(_occluders[i]);
			_occluders = [];
			
			//clip new occluders
			var segment:LineSegment2D = _popSeg();
			max = occluders.length;
			for(i = 0; i < max; i++)
			{
				segment.copy(occluders[i]);
				if(clipRect.clip(segment))
				{
					_occluders.push(segment);
					segment = _popSeg();					
				}
			}	
			_pushSeg(segment);
			
			//add clippers
			_occluders.push(_popAndSetSeg(clipRect.left, clipRect.top, clipRect.right, clipRect.top));//top
			_occluders.push(_popAndSetSeg(clipRect.right, clipRect.top, clipRect.right, clipRect.bottom));//right
			_occluders.push(_popAndSetSeg(clipRect.left, clipRect.top, clipRect.left, clipRect.bottom));//left
			_occluders.push(_popAndSetSeg(clipRect.left, clipRect.bottom, clipRect.right, clipRect.bottom));//bottom
		}
		
		
		public function buildOutline(viewPos:Vector2D):Array
		{
			_viewPos = viewPos;
			_outline = [];
			//1. calc start & end events
			calcBasicEvents();
			//2. initialize _openList
			_openList.clear();
			traverseEvents();
			//3. identify segment to start with (closest at 0°)
			_currentAngle = 0;
			_currentPoint = null;
			_currentDir = new LineSegment2D(_viewPos.x, _viewPos.y, _viewPos.x - 1, _viewPos.y); 
			_current = getClosestIntersection(_currentDir);
			//2. traverse events
			traverseEvents(handleStartEvent, handleEndEvent);
			return _outline;
		}
		
		private function addToOutline(segment:Occluder, angle:Number, p1:Vector2D, p2:Vector2D = null):void
		{
			_currentAngle = angle;
			_current = segment;
			//push p1?
			if(!(_currentPoint && p1.isEqual(_currentPoint)))
				_outline.push(p1);
			_currentPoint = p1; 
			//p2 exists?
			if(!p2)
				return;
			//push p2?
			if(!p2.isEqual(_currentPoint))
				_outline.push(p2);
			_currentPoint = p2; 
			
		}
		
		private function calcBasicEvents():void
		{
			//recycle old startevents
			var i:int = 0;
			var max:int = _startEvents.length;
			for(i = 0; i < max; i++)
				_pushEvent(_startEvents[i]);
			_startEvents = [];
			
			//recycle old startevents
			max = _endEvents.length;
			for(i = 0; i < max; i++)
				_pushEvent(_endEvents[i]);
			_endEvents = [];			
			
			//build new event lists
			max = _occluders.length;
			for(i = 0; i < max; i++)
			{
				var seg:Occluder = _occluders[i];
				var a:AngularEvent = _popEvent();
				a.copyStart(seg, _viewPos);
				var b:AngularEvent = _popEvent();
				b.copyEnd(seg, _viewPos);
				//discard segments parallel to sight
				if(a.angle == b.angle)
					continue;
				
				//segment oriented clockwise?
				var cw:Boolean = a.angle < b.angle;
				//has angle reset? -> small is actualy bigger
				if(Math.abs(a.angle - b.angle) > Math.PI)
					cw = !cw;
				seg.clockwise = cw;
				
				_startEvents.push(cw ? a : b);
				_endEvents.push(cw ? b : a);
			}
			_startEvents.sort(sortOnAngle);
			_endEvents.sort(sortOnAngle);
		}
		
		private function traverseEvents(onStart:Function = null, onEnd:Function = null):void
		{
			//a complete loop to build the openList
			var iStart:int = 0;
			var iStartMax:int = _startEvents.length - 1;
			var iEnd:int = 0;
			var iEndMax:int = _endEvents.length - 1;
			do
			{
				var se:AngularEvent = (iStart <= iStartMax) ? _startEvents[iStart] : null;
				var ee:AngularEvent = (iEnd <= iEndMax) ? _endEvents[iEnd] : null;
				//ee AND se? Decide! (take start on tie!)
				if(ee && se)
				{
					if(se.angle <= ee.angle)
						ee = null;
					else
						se = null;
				}
				if(se)
				{
					_openList.add(se.segment);
					if(onStart != null)
						onStart.call(this, se);
					iStart++;
				}
				else if(ee)
				{
					_openList.remove(ee.segment);
					if(onEnd != null)
						onEnd.call(this, ee);
					iEnd++;
				}
			}	
			while(se || ee);
		}
		
		private function handleStartEvent(e:AngularEvent):void
		{
			handleIntersections(e.angle);
			
			//is new segment infront of 'current'? project startPoint on _current 
			var startPoint:Vector2D = e.segment.clockwise ? e.segment.start : e.segment.end;
			_currentDir.end.copy(startPoint);
			var d:Number = _current.getIntersectionRatio(_currentDir);
			if(d >= 0 && d <= 1)
			{
				var projection:Vector2D = _current.sample(d);
				var pLength:Number = _viewPos.distance(projection) - _viewPos.distance(startPoint);
				//startPoint is closer then projection? 
				if(pLength > 0)
					addToOutline(e.segment, e.angle, projection, startPoint);
				else if(pLength == 0 && e.alignment > 0) //startPoint touches & end point is closer?
					addToOutline(e.segment, e.angle, startPoint);
			}
		}
		
		private function handleEndEvent(e:AngularEvent):void
		{
			handleIntersections(e.angle);
			//did 'current' end?
			if(_current != e.segment)
				return; //OTHER DOES NOT MATTER

			//find correct endpoint!
			var endPoint:Vector2D = _current.clockwise ? _current.end : _current.start;
			
			if(handleSubsequentSegments(endPoint))
				return; //SUBSEQUENT SEGMENT FOUND
			
			//ELSE: project endpoint on each member of open list
			var bestPoint:Vector2D = null;
			var bestSeg:Occluder = null;
			var bestDist:Number = 0xFFFFFF;
			var cur:QueueNode = _openList;
			_currentDir.end.copy(endPoint);
			while(cur && cur.data)
			{
				//setup direction & find intersection with seg
				var seg:Occluder = cur.data as Occluder;
				if(seg == _current)
				{
					cur = cur.next;
					continue;
				}
				var d:Number = seg.getIntersectionRatio(_currentDir);
				if(d >= 0 && d <= 1)
				{
					//seg is a candidate - but is it the best one?
					var projection:Vector2D = seg.sample(d);
					var viewDist:Number = _viewPos.distanceSquared(projection);
					if(viewDist < bestDist)
					{
						bestPoint = projection;
						bestSeg = seg;
						bestDist = viewDist;
					}
				}
				cur = cur.next;
			}
			if(!bestPoint)
				return; //PROJECTION FAILED (ERROR)

			//best candidate is new current!
			addToOutline(bestSeg, e.angle, endPoint, bestPoint);
		}
		
		private function handleIntersections(maxAngle:Number):void
		{
			var cur:QueueNode = _openList;
			//find minimal-angle intersection with _current
			var intersection:Vector2D = null;
			var bestPoint:Vector2D = null;
			var bestSeg:Occluder = null;
			var bestAngle:Number = maxAngle;
			while(cur && cur.data)
			{
				var seg:Occluder = cur.data as Occluder; //intersecting with _current?
				if(seg == _current)
				{
					cur = cur.next;
					continue;
				}
				var relation:int = _current.getRelation(seg);
				//seg.start touches and seg.end visible? (seg.endAngle > _currentAngle)
				if(relation == LineSegment2D.OTHER_START_TOUCHES_THIS && seg.endDist < seg.startDist)
				{
					//touch is new current if angle < bestAngle
					if(seg.startAngle < bestAngle)
					{
						bestPoint = seg.start;
						bestSeg = seg;
						bestAngle = seg.startAngle;
					}
				}
				//seg.end touches and seg.start visible? (seg.startAngle > _currentAngle)
				else if(relation == LineSegment2D.OTHER_END_TOUCHES_THIS && seg.startDist < seg.endDist)
				{
					//touch is new current if angle < bestAngle
					if(seg.endAngle < bestAngle)
					{
						bestPoint = seg.end;
						bestSeg = seg;
						bestAngle = seg.endAngle;
					}
				}
				//intersection?
				else if(relation == LineSegment2D.THIS_AND_OTHER_INTERSECT)
				{
					//intersection is new current if angle of intersection < bestAngle
					intersection = _current.intersect(seg);
					_helper.copy(intersection);
					_helper.subtract(_viewPos);
					var angle:Number = _helper.polarAngle;
					if(angle > _currentAngle && angle < bestAngle)
					{
						bestPoint = intersection;
						bestSeg = seg;
						bestAngle = angle;
					}
				}
				cur = cur.next;
			}
			//best intersection makes new current
			if(bestPoint)
				addToOutline(bestSeg, bestAngle, bestPoint);
		}
		
		//renturns true if a visible subsequent segment was found
		private function handleSubsequentSegments(endPoint:Vector2D):Boolean
		{
			//get normalized light-dir
			_currentDir.end.copy(endPoint);
			var lightDir:Vector2D = _currentDir.direction.normalize();
			
			//find visible segment touching _current
			var bestPoint:Vector2D = null;
			var bestSeg:Occluder = null;
			var bestRating:Number = -1;
			var cur:QueueNode = _openList;
			while(cur && cur.data)
			{
				var seg:Occluder = cur.data as Occluder; 
				var touchPoint:Vector2D = null;
				if(seg.end.isEqual(endPoint))
				{
					touchPoint = seg.end;
					_helper.copy(seg.direction).normalize().inverse();
				}
				else if(seg.start.isEqual(endPoint))
				{
					touchPoint = seg.start;
					_helper.copy(seg.direction).normalize();
				}
				if(touchPoint)
				{
					//left or right of light dir?
					var x:Number = _helper.crossProduct(lightDir);
					if(x <= 0)//it's on the (b)right side! the more it points towards the light the better!
					{
						var rating:Number = 1 + _helper.dotProduct(lightDir);
						//trace("on the bright side! Rating: ", rating);
						if(rating > bestRating)
						{
							bestRating = rating;
							bestPoint = touchPoint;
							bestSeg = seg;
						}
					}
				}
				cur = cur.next;
			}
			if(bestPoint)
			{
				//best followUp makes new current (_currentAngle stays the same!)
				addToOutline(bestSeg, _currentAngle, bestPoint);
				return true;
			}
			return false;
		}
		
		private function getClosestIntersection(v:LineSegment2D):Occluder
		{
			var best:Occluder = null;
			var bestDist:Number = -1;
			var cur:QueueNode = _openList;
			while(cur && cur.data)
			{
				var d:Number = v.getIntersectionRatio(cur.data as LineSegment2D);
				if(bestDist < 0 || bestDist > d)
				{
					best = cur.data as Occluder;
					bestDist = d;
				}
				cur = cur.next;
			}
			return best;
		}
		
		private function sortOnAngle(a:AngularEvent, b:AngularEvent):Number 
		{
			if(a.angle > b.angle)
				return 1;
			else if(a.angle < b.angle)
				return -1;
			else if(a.distance > b.distance)
				return 1;
			else if(a.distance < b.distance)
				return -1;
			else if(a.alignment > b.alignment)
				return -1;
			else if(a.alignment < b.alignment)
				return 1;
			else
				return 0;
		}
		
		//AngularEvent
		private function _popEvent():AngularEvent
		{
			var result:AngularEvent = _eventPool.pop();
			if(result)
				return result;
			//else
			return new AngularEvent();
			
		}
		
		private function _pushEvent(evt:AngularEvent):void
		{
			_eventPool.push(evt);
		}		
		
		//LineSegment Pool
		private function _popAndSetSeg(startX:Number = 0, startY:Number = 0, endX:Number = 0, endY:Number = 0):LineSegment2D
		{
			var result:LineSegment2D = _segPool.pop();
			if(result)
			{
				result.reset(startX, startY, endX, endY);
				return result;
			}
			//factory style - this is the only place creating instances
			return new Occluder(startX, startY, endX, endY); 
		}
		
		private function _popSeg():LineSegment2D
		{
			var result:LineSegment2D = _segPool.pop();
			if(result)
				return result;
			//factory style - this is the only place creating instances
			return new Occluder(); 
		}
		
		private function _pushSeg(seg:LineSegment2D):void
		{
			_segPool.push(seg);
		}
	}	
}

//*** INTERNALLY USED CLASSES ***

import net.pixelpracht.geometry.CachedLineSegment2D;
import net.pixelpracht.geometry.LineSegment2D;
import net.pixelpracht.geometry.Vector2D;

class Occluder extends CachedLineSegment2D
{
	public var startDist:Number = 0;
	public var startAngle:Number = 0;
	public var endDist:Number = 0;
	public var endAngle:Number = 0;
	public var clockwise:Boolean = false;
	public var cwUndefined:Boolean = false;
	
	public function Occluder(startX:Number=0, startY:Number=0, endX:Number=0, endY:Number=0)
	{
		super(startX, startY, endX, endY);
	}
	
	public override function toString():String
	{
		return startAngle.toFixed(2) + "->" + endAngle.toFixed(2) + super.toString();
	}
}

class AngularEvent
{
	public var angle:Number; //polar angle with the viewpoint as reference and (-1,0) being 0°
	public var distance:Number; //distance from viewpoint
	public var alignment:Number; //alignment of the segment relative to the viewpoint. 1 if it points to vp directly. -1 if away.
	public var segment:Occluder;
	
	private static var _helper:Vector2D = new Vector2D();
	
	public function copyStart(seg:Occluder, viewPos:Vector2D):void
	{
		segment = seg;
		//angle & distance & alignment
		_helper.copy(segment.start);
		_helper.subtract(viewPos);
		angle = _helper.polarAngle;
		distance = _helper.length;
		alignment = -_helper.dotProduct(segment.direction) / distance / segment.length;
		//update segment
		segment.startDist = distance;
		segment.startAngle = angle;
	}
	public function copyEnd(seg:Occluder, viewPos:Vector2D):void
	{
		segment = seg;
		//angle & distance & alignment
		_helper.copy(segment.end);
		_helper.subtract(viewPos);
		angle = _helper.polarAngle;
		distance = _helper.length;	
		alignment = _helper.dotProduct(segment.direction) / distance / segment.length;
		//update segment
		segment.endDist = distance;
		segment.endAngle = angle;
	}
}