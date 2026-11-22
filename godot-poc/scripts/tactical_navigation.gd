extends RefCounted
## Hidden navigation cells; neither selection nor presentation exposes a combat grid.
var game: Node
var center:=Vector2.ZERO
var radius:=390.0
const CELL:=24.0
var grid:=AStarGrid2D.new()
var mover: Node2D
func inside(p: Vector2) -> bool: return p.distance_to(center)<=radius-14
func clear(p: Vector2) -> bool:
 if not inside(p) or not game.area.clear(p,14): return false
 for e in game.enemies:
  if is_instance_valid(e.actor) and e.actor!=mover and e.actor.health>0 and p.distance_to(e.actor.position)<28: return false
 if mover!=game.hero and p.distance_to(game.hero.position)<28: return false
 return true
func segment(a: Vector2,b: Vector2) -> bool:
 for i in range(1,maxi(1,ceili(a.distance_to(b)/5))+1):
  if not clear(a.lerp(b,float(i)/maxi(1,ceili(a.distance_to(b)/5)))): return false
 return true
func rebuild(actor: Node2D) -> void:
 mover=actor;grid.region=Rect2i(Vector2i((center-Vector2.ONE*radius)/CELL),Vector2i.ONE*ceili(radius*2/CELL+2));grid.cell_size=Vector2.ONE*CELL;grid.offset=Vector2.ONE*CELL/2
 grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE;grid.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE;grid.update()
 for y in range(grid.region.position.y,grid.region.end.y):
  for x in range(grid.region.position.x,grid.region.end.x): grid.set_point_solid(Vector2i(x,y),not clear(Vector2(x,y)*CELL+grid.offset))
func cost(start: Vector2,route: PackedVector2Array) -> float:
 var total:=0.0
 for p in route: total+=start.distance_to(p);start=p
 return total
func route(start: Vector2,goal: Vector2,budget: float) -> PackedVector2Array:
 if not clear(goal): return PackedVector2Array()
 if segment(start,goal): return PackedVector2Array([goal]) if start.distance_to(goal)<=budget+.01 else PackedVector2Array()
 var a:=Vector2i(start/CELL);var b:=Vector2i(goal/CELL)
 if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or grid.is_point_solid(a) or grid.is_point_solid(b): return PackedVector2Array()
 var points:=grid.get_point_path(a,b)
 if points.is_empty(): return points
 points.append(goal);var previous:=start
 for point in points:
  if not segment(previous,point): return PackedVector2Array()
  previous=point
 return points if cost(start,points)<=budget+.01 else PackedVector2Array()
func reachable(start: Vector2,budget: float) -> Array[Vector2]:
 var result: Array[Vector2]=[]
 # Flood the same graph used for routing, caching this only when Move is selected.
 var origin:=Vector2i(start/CELL);var costs: Dictionary={origin:0.0};var open: Array[Vector2i]=[origin]
 while not open.is_empty():
  var best:=0
  for i in range(1,open.size()):
   if costs[open[i]]<costs[open[best]]: best=i
  var cell: Vector2i=open[best];open.remove_at(best);var point:=Vector2(cell)*CELL+grid.offset
  if clear(point): result.append(point)
  for direction in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
   var next: Vector2i=cell+direction;var dest:=Vector2(next)*CELL+grid.offset
   if not grid.is_in_boundsv(next) or grid.is_point_solid(next) or not segment(point,dest): continue
   var next_cost: float=costs[cell]+point.distance_to(dest)
   if next_cost>budget or (costs.has(next) and costs[next]<=next_cost): continue
   costs[next]=next_cost
   if not next in open: open.append(next)
 return result
