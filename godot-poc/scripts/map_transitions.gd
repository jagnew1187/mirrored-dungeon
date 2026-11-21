extends RefCounted
## Inward vectors define arrival facing for any edge or doorway orientation.
const LINKS={
	"vigil":{"road":{"map":"road","entrance":"vigil","inward":Vector2.LEFT},"bannerfall":{"map":"bannerfall","entrance":"vigil","inward":Vector2.UP}},
	"road":{"vigil":{"map":"vigil","entrance":"road","inward":Vector2.RIGHT},"bannerfall":{"map":"bannerfall","entrance":"road","inward":Vector2.LEFT}},
	"bannerfall":{"road":{"map":"road","entrance":"bannerfall","inward":Vector2.RIGHT},"vigil":{"map":"vigil","entrance":"bannerfall","inward":Vector2.LEFT}}
}
static func point(area: Node,id: String) -> Dictionary:
	for p in area.points:
		if p.id==id and p.kind=="exit": return p
	return {}
static func automatic(area_id: String, gate: Dictionary) -> bool:
	# The six authored roads are physical exits. Unknown/special travel defaults
	# to explicit confirmation; an individual point can opt out without new loaders.
	return gate.get("kind","")=="exit" and gate.get("travel_mode","physical" if LINKS.get(area_id,{}).has(gate.get("id","")) else "confirm")=="physical"
static func trigger_rect(area_id: String, gate: Dictionary) -> Rect2:
	var inward: Vector2=LINKS.get(area_id,{}).get(gate.id,{}).get("inward",Vector2.UP)
	var size:=Vector2(48,80) if absf(inward.x)>.5 else Vector2(80,48)
	return Rect2(gate.pos-size/2,size)
static func safe(area: Node,position: Vector2,occupied: Array) -> bool:
	if not area.clear(position,16): return false
	for p in area.points:
		if p.kind in ["mara","boy","anja","oren","ves"] and position.distance_to(p.pos)<30: return false
	for other in occupied:
		if position.distance_to(other)<32: return false
	return true
static func placements(area: Node,origin: Vector2,inward: Vector2,count:=6) -> Array[Vector2]:
	var result: Array[Vector2]=[]
	for ring in range(9):
		for step in range(1 if ring==0 else 16):
			var p: Vector2=origin if ring==0 else origin+inward.rotated(step*TAU/16)*ring*24
			if safe(area,p,result): result.append(p)
			if result.size()>=count: return result
	return result
static func arrival(area: Node,entrance: String,lateral: float) -> Dictionary:
	var link: Dictionary=LINKS.get(area.area_id,{}).get(entrance,{})
	var gate:=point(area,entrance)
	if gate.is_empty() or link.is_empty(): return {"ok":false,"warning":"Missing entrance %s/%s; using safe checkpoint fallback."%[area.area_id,entrance]}
	var inward: Vector2=link.inward
	# A consistent world-axis tangent preserves lateral position on return journeys.
	var tangent:=Vector2.DOWN if absf(inward.x)>.5 else Vector2.RIGHT
	var desired: Vector2=gate.pos+inward*96+tangent*clampf(lateral,-48,48)
	var positions:=placements(area,desired,inward)
	if positions.is_empty(): return {"ok":false,"warning":"Entrance has no safe arrival: "+entrance}
	return {"ok":true,"position":positions[0],"facing":inward,"party_positions":positions}
