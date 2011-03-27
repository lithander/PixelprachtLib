package net.pixelpracht.algorithm
{
	import flash.geom.Rectangle;
	
	import net.pixelpracht.geometry.Angle;
	import net.pixelpracht.geometry.CachedLineSegment2D;
	import net.pixelpracht.geometry.LineSegment2D;
	import net.pixelpracht.geometry.Rectangle2D;
	import net.pixelpracht.geometry.Vector2D;
	
	public class OldAreaOfSight implements IAreaOfSight
	{
		public var lightRange:Number = 0;
		public var lightPosition:Vector2D = new Vector2D();
		public var shadowCasters:Array = new Array();
		public var clipRect:Rectangle = null;
		public var points:Array = new Array();
		public var projected:Array = new Array();
		public var segments:Array = new Array();
		
		//intermediate
		private var _outline:Array = new Array();
		private var _lineCnt:int = 0;
		private var _lines:Array = null; //doesn't change the line objects - no copy needed
		private var _lightRay:CachedLineSegment2D = new CachedLineSegment2D();
		
		private const EPSILON_DIST:Number = 0.005;
		private const EPSILON_ANGLE:Number = 0.0005;
		private const BOUND_MARGIN:int = 3;
		private const LINE_CACHE_SIZE:int = 333;
		
		public function OldAreaOfSight()
		{
			//create line cache
			_lines = new Array();
			for(var i:int = 0; i < LINE_CACHE_SIZE; i++)
				_lines.push(new OutlineSegment());
		}

		public function get occluders():Array
		{
			return segments;
		}
		public function get outline():Array
		{
			return _outline;
		}
		public function setOccluders(occluders:Array, clipRect:Rectangle2D):void
		{
			//***REFERENCE implementation
			this.shadowCasters = occluders;
			this.clipRect = clipRect.toRectangle();	
		}
		public function buildOutline(viewPos:Vector2D):Array
		{
			this.lightRange = 500;
			this.lightPosition.reset(viewPos.x, viewPos.y);
			update();
			return _outline;
		}
		
		public function update():Boolean
		{
			if(!clipRect)
				return false;

			clip(clipRect);
			//calculate line-cones
			for(var i:int = 0; i < _lineCnt; i++)
				_lines[i].updateCone(lightPosition);
			points = [];
			projected = [];
			_outline = [];
			findCrossPoints(points);
			findEndPoints(points);
			points.sort(sortOnAngle);
			condense(points); //speeds up select
			select(points);
			condense(points);
			findDirections(points);
			projectPoints(points, projected);
			findConnections(projected);
			
			//special ignore
			var line:OutlineSegment = null;
			for each(p in points)
			{
				var c:int = 0;
				for each(line in p.segs)
					c += line.vectors.length - 1; //ignore self
				if(c < 2) //one to come from and one to go to
					p.ignore = true;
			}
			var start:int = points.length - 1;
			var segCnt:int = points.length + projected.length;
			var p:OutlineVector = null;
			for each(p in points)
				if(p.ignore)
					segCnt--;
			while(start > 0 && buildOutlineEx(points, projected, _outline, start) != segCnt)
			{
				start--;
				//trace("trying start", start);
				for each(p in points)
					p.done = false;
				for each(p in projected)
					p.done = false;					
			}
			if(start > 0)
				return true;
			else
				return false;
		}
		
		private function clone():void
		{
			//TODO: make use of the _line cache
			_lines.splice(0);
			_lines = shadowCasters.concat();
		}
		
		private function clip(rect:Rectangle):void
		{
			if(rect == null)
				return;
			
			_lineCnt = 0;
			_lines[_lineCnt++].reset(rect.left-BOUND_MARGIN, rect.top-BOUND_MARGIN, rect.right+BOUND_MARGIN, rect.top-BOUND_MARGIN);//top
			_lines[_lineCnt++].reset(rect.right+BOUND_MARGIN, rect.top-BOUND_MARGIN, rect.right+BOUND_MARGIN, rect.bottom+BOUND_MARGIN);//right
			_lines[_lineCnt++].reset(rect.left-BOUND_MARGIN, rect.top-BOUND_MARGIN, rect.left-BOUND_MARGIN, rect.bottom+BOUND_MARGIN);//left
			_lines[_lineCnt++].reset(rect.left-BOUND_MARGIN, rect.bottom+BOUND_MARGIN, rect.right+BOUND_MARGIN, rect.bottom+BOUND_MARGIN);//bottom
			
			
			var clipper:Rectangle2D = Rectangle2D.fromRectangle(rect);
			var line:LineSegment2D = null;
			var max:int = shadowCasters.length;
			for(var i:int = 0; i < max; i++)
			{
				var src:LineSegment2D = shadowCasters[i];
				var outline:OutlineSegment = _lines[_lineCnt];
				//quick early out test
				if(src.start.y < rect.top && src.end.y < rect.top)
					continue;
				if(src.start.y > rect.bottom && src.end.y > rect.bottom)
					continue;
				if(src.start.x < rect.left && src.end.x < rect.left)
					continue;
				if(src.start.x > rect.right && src.end.x > rect.right)
					continue;				
				outline.resetFromLine(src,false);
				var clipped:LineSegment2D = clipper.clip(outline);
				if(clipped != null && clipped.length)
					_lineCnt++;
			}
		}		
		
		private function sortOnAngle(a:OutlineVector, b:OutlineVector):Number 
		{
			if(a.angle > b.angle)
				return 1;
			else if(a.angle < b.angle)
				return -1;
			else if(a.distance > b.distance)
				return 1;
			else if(a.distance < b.distance)
				return -1;
			else
				return 0;
		}
		
		private function condense(points:Array):void
		{
			var i:int = 0;
			var j:int = 0;
			while(i < points.length)
			{
				while(++j < points.length && points[i].vector.nearEquals(points[j].vector, EPSILON_DIST));
				if(j > ++i)
				{
					points.splice(i,j-i); 
					j = i;
				}
			}
			//loop
			j = 0;
			i = points.length - 1;
			while(j < points.length && points[i].vector.nearEquals(points[j].vector, EPSILON_DIST))
				j++;
			if(j > 0)
				points.splice(0,j);
		}
		
		private function select(points:Array):void
		{
			var i:int = 0;
			var j:int = 0;
			while(i < points.length)
			{
				j = i;
				while(j < points.length && !hasLineOfSight(points[j]))
				{
					j++;
				}
				if(j > i)
					points.splice(i,j-i); 
				i++;
			}
		}
		
		private function findDirections(points:Array):void
		{
			for each(var ov:OutlineVector in points)
			{
				var v:Vector2D = ov.vector;
				var line:OutlineSegment = null;
				for(var i:int = 0; i < _lineCnt; i++)
				{
					line = _lines[i];
					if(line.insideCone(ov) && line.distance(v) < EPSILON_DIST)
					{
						line.vectors.push(ov);
						ov.segs.push(line);	
						if(!v.nearEquals(line.start, EPSILON_DIST))
							ov.dirs.push(line.start.subtracted(v));
						if(!v.nearEquals(line.end, EPSILON_DIST))
							ov.dirs.push(line.end.subtracted(v));
					}
				}
				if(ov.segs.length == 0)
				{
					ov.ignore = true;
					trace("unconnected pt!");
				}
			}
		}
		
		private function findConnections(points:Array):void
		{
			for each(var ov:OutlineVector in points)
			{
				var v:Vector2D = ov.vector;
				var line:OutlineSegment = null;
				for(var i:int = 0; i < _lineCnt; i++)
				{
					line = _lines[i];
					if(line.insideCone(ov) && line.distance(v) < EPSILON_DIST)
					{
						line.vectors.push(ov);
						ov.segs.push(line);	
					}
				}
				if(ov.segs.length == 0)
				{
					ov.ignore = true;
					trace("unconnected pt!");
				}
			}
		}
		
		private function findEndPoints(points:Array):void
		{
			var line:OutlineSegment = null;
			for(var i:int = 0; i < _lineCnt; i++)
			{
				line = _lines[i];
				var startOV:OutlineVector = new OutlineVector(line.start, lightPosition);
				var endOV:OutlineVector = new OutlineVector(line.end, lightPosition);
				//connect
				points.push(startOV);
				points.push(endOV);
			}
		}
		
		private function findCrossPoints(points:Array):void //split
		{
			var other:OutlineSegment = null;
			var line:OutlineSegment = null;
			for(var i:int = 0; i < _lineCnt; i++)
			{
				line = _lines[i];
				//crosspoints
				for(var j:int = 0; j < _lineCnt; j++)
				{
					other = _lines[j];
					if(other != line && line.intersectingCone(other) && line.isIntersecting(other))
					{
						var point:Vector2D = line.intersect(other);
						var crossPt:OutlineVector = new OutlineVector(point, lightPosition);
						//other.vectors.push(crossPt);
						//line.vectors.push(crossPt);
						points.push(crossPt);
					}
				}
			}					
		}
		
		private function projectPoints(source:Array, prjpoints:Array):void
		{
			var line:OutlineSegment = null;
			var point:Vector2D = null;
			var lightDir:Vector2D = null;
			var result:Array = new Array();
			var ignoredCnt:int = 0;
			_lightRay.start = lightPosition; //dirty!
			for each (var ov:OutlineVector in source)
			{
				point = ov.vector;
				_lightRay.end = point; //dirty!
				_lightRay.recalc();
				lightDir = _lightRay.direction.clone();
				var left:Boolean = false;
				var right:Boolean = false;
				var peak:Number = 0;
				for each(var dir:Vector2D in ov.dirs)
				{
					var cp:Number = dir.crossProduct(lightDir);
					if(cp > 0)
						left = true;
					else if(cp < 0)
						right = true;
					else
						peak++;
				}
				if(peak == 1 && ov.dirs.length == 1)
				{
					//looking parallel to a single line
					ov.ignore = true;
					continue;
				}
				if(left && right) //nothing to project
					continue;
				
				_lightRay.length = lightRange;
				var closestPoint:Vector2D = null;
				var closestDist:Number = 0xFFFFFF;
				var closestLine:OutlineSegment = null;
				var newPoint:Vector2D = null;
				var newDist:Number = 0;
				var minDist:Number = lightDir.length+1;
				//touch special-case
				var leftDist:Number = 0xFFFFFF;
				var rightDist:Number = 0xFFFFFF;
				var candidates:Array = new Array();
				//find closest intersection
				for(var i:int = 0; i < _lineCnt; i++)
				{
					line = _lines[i];
					if(!line.insideCone(ov))
						continue;
					var r:Number = line.getRelation(_lightRay);
					if(r > 0) //intersection - stop
					{
						newPoint = line.intersect(_lightRay);
						newDist = newPoint.distance(lightPosition);
						if(newDist > minDist && newDist < closestDist)
						{
							closestDist = newDist;
							closestPoint = newPoint;
							closestLine = line;
						}
					}
					else if(r == 0) //touching - okay if only one one side. gather now only here
					{
						if(line.isParallel(_lightRay, EPSILON_DIST))
							continue;
						
						newPoint = line.intersect(_lightRay);
						newDist = newPoint.distance(lightPosition);
						candidates.push(newPoint);
						
						var other:Vector2D = (newPoint.distance(line.start) < EPSILON_DIST) ? line.end : line.start;
						cp = other.subtracted(newPoint).crossProduct(lightDir);
						if(cp > 0 && newDist < leftDist)
							leftDist = newDist;
						if(cp < 0 && newDist < rightDist)
							rightDist = newDist;
					}
				}
				//touched to death? :P
				var deathDist:Number = Math.max(leftDist, rightDist);
				for each(newPoint in candidates)
				{
					newDist = newPoint.distance(lightPosition);
					if(newDist >= deathDist)
					{
						if(newDist > minDist && newDist < closestDist)
						{
							closestDist = newDist;
							closestPoint = newPoint;
							closestLine = line;
						}
					}
				}
				
				if(closestPoint)
				{
					var prj:OutlineVector = new OutlineVector(closestPoint, lightPosition);
					prj.projected = true;
					ov.projector = true;
					//add new outline segment
					var con:OutlineSegment = new OutlineSegment(ov.vector.x, ov.vector.y, prj.vector.x, prj.vector.y);
					con.vectors.push(ov);
					con.vectors.push(prj);
					ov.segs.push(con);
					prj.segs.push(con);
					prjpoints.push(prj);
					con.updateCone(lightPosition);
				}
			}
		}
		
		private function hasLineOfSight(ov:OutlineVector, min:Number = 0):Boolean
		{
			_lightRay.start = lightPosition;
			_lightRay.end = ov.vector;
			_lightRay.recalc();
			var line:OutlineSegment = null;
			for(var i:int = 0; i < _lineCnt; i++)
			{
				line = _lines[i];
				if(line.insideCone(ov) && line.getRelation(_lightRay) >= min && line.distance(ov.vector) > EPSILON_DIST)
					return false;
			}					
			return true;
		}
		
		private function angleAtoB(a:Number, b:Number):Number
		{
			var d:Number = b - a;
			while( d < -Math.PI)
				d += 2 * Math.PI;
			while( d > Math.PI)
				d -= 2 * Math.PI;
			return d;
		}

		private function countChoices(current:OutlineVector):int
		{
			var result:int = 0;
			for each(var seg:OutlineSegment in current.segs)
				if(seg.vectors.length >= 2)
					for each(var ov:OutlineVector in seg.vectors)
						if(!ov.done
						&& ov != current
						&& !ov.ignore 
						&& Angle.normalizeRad(ov.angle - current.angle) > -EPSILON_ANGLE)
						result++;
			return result;
		}			

		private function buildOutlineEx(points:Array, projected:Array, segments:Array, start:int = 0):int
		{
			points.sort(sortOnAngle);
			segments.splice(0);			
			var seg:OutlineSegment = null;
			var ov:OutlineVector = null;
			var current:OutlineVector = null;
			var next:OutlineVector = points[start];
			while(next && next.ignore)
				next = points[--start];
			var choice:Array = [];
			while(next && next != current)
			{
				choice.splice(0);
				if(current && next)
					segments.push(current.vector);
					//segments.push(new LineSegment2D(current.vector.x, current.vector.y, next.vector.x, next.vector.y));
				current = next;
				current.done = true;
				//fill choice
				for each(seg in current.segs)
				{
					if(seg.vectors.length >= 2)
						for each(ov in seg.vectors)
							if(!ov.done 
							&& !ov.ignore 
							&& Angle.normalizeRad(ov.angle - current.angle) > -EPSILON_ANGLE)
								choice.push(ov);
				}
				choice.sort(sortOnAngle);
				var candidate:OutlineVector = null;
				next = null;
				for each(candidate in choice)
					if(!candidate.done)
					{						
						if(next)
						{
							if(candidate && Math.abs(Angle.normalizeRad(candidate.angle-next.angle)) < EPSILON_ANGLE)
							{
								//trace("ambiguity!!");
								if(countChoices(next) > countChoices(candidate))
								{
									//trace("swap suggested!");
									next = candidate;
								}
							}
							break;
						}
						next = candidate;
					}
			}
			//close the loop if possible
			if(current)
				for each(seg in current.segs)
					for each(ov in seg.vectors)
						if(ov == points[start])
						{
							segments.push(current.vector);
							//segments.push(new LineSegment2D(current.vector.x, current.vector.y, points[start].vector.x, points[start].vector.y));
							return segments.length;
						}
			return segments.length;
		}
		/*
		private function buildOutline(points:Array, projected:Array, result:Array):void
		{
			points.sort(sortOnAngle);
			projected.sort(sortOnAngle);
			
			//fill outline array by taking vectors from points or projected so they form a consecutive outline
			var seg:LineSegment2D
			var i:int = 0;
			var iPts:int = 0;
			var ptsCnt:int = points.length;
			var iProj:int = 0;
			var prjCnt:int = projected.length;
			if(ptsCnt + prjCnt < 3)
				return;
			var prjStartBonus:int = 0;
			var last:OutlineVector = points[ptsCnt-1]; //TODO: might not be accurate! is the last point in points guaranteed to form the last point in the outline?
			do
			{
				var prj:OutlineVector = projected[iProj];
				var pt:OutlineVector = points[iPts];
				if(pt && pt.ignore)
				{
					if(pt.vector.isEqual(last.vector))
						result.push(prj.vector);
					iPts++;
					prjStartBonus++;
					continue;
				}				
				//***chose next: projected vs point *** 
				
				//prj get's a penalty except when it's the first pt in outline
				var prjRating:Number = (iPts <= prjStartBonus) ? 0.5 : -0.5;
				var ptRating:Number = 0.0;
				
				//favor projected if no point or point angle is equal or greater
				if(prj && (!pt || (prj.angle - pt.angle < EPSILON_ANGLE)))
					prjRating += 2;
				//favor point if no projected or projected angle is equal or greater
				if(pt && (!prj || (pt.angle - prj.angle < EPSILON_ANGLE)))
					ptRating += 2;	
				
				//favor projected is if on the last segment
				if(prj && prjRating > 0 && ptRating > prjRating)
					for each(seg in last.segs)
					if(seg.distance(prj.vector) <= EPSILON_DIST)
					{
						prjRating++;
						break;
					}
				
				//favor point if point is on the last segment
				if(ptRating > 0 && prjRating > ptRating)
					for each(seg in last.segs)
					if(seg.distance(pt.vector) <= EPSILON_DIST)
					{
						ptRating++;
						break;
					}		
				
				if(prjRating > 0 && prjRating > ptRating)
				{	
					iProj++;
					if(!prj.vector.isEqual(last.vector)) //done?
						result.push(prj.vector);
					last = prj;
				}
				else if( ptRating > 0)
				{	
					iPts++;
					if(!pt.vector.isEqual(last.vector))
						result.push(pt.vector);
					last = pt;
				}
			}
			while(iPts < ptsCnt || iProj < prjCnt); //caches not empty - look for more!
			
			//swap needed? if last doesn't share a line segment with first. swap first & second
			if(result.length >= 3)
			{
				var first:Vector2D = result[0];
				for each(seg in last.segs)
				if(seg.distance(first) < EPSILON_DIST)
					return;
				
				var tmp:Vector2D = result[0];
				result[0] = result[1];
				result[1] = tmp;
				//trace("swap!");
			}	
		}
		*/
	}
}

//internals
import net.pixelpracht.geometry.Angle;
import net.pixelpracht.geometry.CachedLineSegment2D;
import net.pixelpracht.geometry.LineSegment2D;
import net.pixelpracht.geometry.Vector2D;

class OutlineSegment extends CachedLineSegment2D
{
	public function OutlineSegment(startX:Number = 0, startY:Number = 0, endX:Number = 0, endY:Number = 0)
	{
		super(startX, startY, endX, endY);
	}
	public static function fromLineSegment(ls:LineSegment2D):OutlineSegment
	{
		return new OutlineSegment(ls.start.x, ls.start.y, ls.end.x, ls.end.y);
	}
	
	public override function reset( startX:Number = 0, startY:Number = 0, endX:Number = 0, endY:Number = 0):void
	{
		super.reset(startX, startY, endX, endY);
		vectors = [];
	}
	
	public function resetFromLine(ls:LineSegment2D, updateCache:Boolean = true):void
	{
		start.x = ls.start.x;
		start.y = ls.start.y;
		end.x = ls.end.x;
		end.y = ls.end.y;		
		if(updateCache)
			recalc();
		vectors = [];
	}	

	public function insideCone(ov:OutlineVector):Boolean
	{
		//trace(Angle.radToDeg(ov.angle), Angle.radToDeg(startAngle), Angle.radToDeg(endAngle));
		return (startAngle <= ov.angle && endAngle >= ov.angle);
	}
	
	public function intersectingCone(ol:OutlineSegment):Boolean
	{
		return (startAngle <= ol.startAngle && endAngle >= ol.startAngle) //ol.start in?
			|| (startAngle <= ol.endAngle && endAngle >= ol.endAngle) //ol.end in?
			|| (ol.startAngle <= startAngle && ol.endAngle >= endAngle); //no intersection! does ol _contain_ this?
		
		/*
		return (startAngle <= ol.startAngle && endAngle >= ol.startAngle)
			|| (startAngle <= ol.endAngle && endAngle >= ol.endAngle)
			|| (startAngle >= ol.startAngle && endAngle <= ol.startAngle)
			|| (startAngle >= ol.endAngle && endAngle <= ol.endAngle);
		*/
	}
	
	public function updateCone(light:Vector2D):void
	{
		_coneHelper.copy(start);
		_coneHelper.subtract(light);
		startAngle = _coneHelper.polarAngle;
		_coneHelper.copy(end);
		_coneHelper.subtract(light);
		endAngle = _coneHelper.polarAngle;
		if(startAngle > endAngle)
		{
			var tmp:Number = endAngle;
			endAngle = startAngle;
			startAngle = tmp;
		}
		//to wide... can't create a cone
		if(endAngle - startAngle > Math.PI)
		{
			startAngle = -Math.PI*2;
			endAngle = Math.PI*2;
		}
	}
	
	private static var _coneHelper:Vector2D = new Vector2D();
	
	public var startAngle:Number = -1;
	public var endAngle:Number = -1;
	public var vectors:Array = new Array();
}

class OutlineVector
{
	public function OutlineVector(vec:Vector2D, light:Vector2D)
	{
		vector = vec;
		_angleHelper.copy(vec);
		_angleHelper.subtract(light);
		angle = _angleHelper.polarAngle;
		distance = _angleHelper.length;
		ignore = false;
		done = false;
		projected = false;
		projector = false;
	}
	
	private static var _angleHelper:Vector2D = new Vector2D();
	
	public var vector:Vector2D;
	public var angle:Number;
	public var distance:Number;
	public var ignore:Boolean;
	public var done:Boolean;
	public var projected:Boolean;
	public var projector:Boolean;
	public var dirs:Array = new Array();
	public var segs:Array = new Array();
}
