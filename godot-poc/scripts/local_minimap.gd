extends Control
## Cached schematic geometry, not a second camera. All positions are area-local.
var game: Node
var cache: Dictionary={}
var area_id:=""
var geometry: Dictionary={}
var cache_builds:=0
var static_redraws:=0
var marker: Control
var player_position:=Vector2.ZERO
var player_angle:=0.0
var fingers: Dictionary={}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	marker=Control.new();marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;marker.draw.connect(draw_player);add_child(marker)
	resized.connect(func():queue_redraw();marker.queue_redraw())

func refresh() -> void:
	visible=not game.menu_open
	if not is_instance_valid(game.area) or not is_instance_valid(game.hero): return
	if area_id!=game.area.area_id:
		area_id=game.area.area_id
		if not cache.has(area_id):
			var exits: Array[Vector2]=[]
			for point in game.area.points:
				if point.kind=="exit": exits.append(point.pos)
			var footprints: Array[Rect2]=[]
			for solid in game.area.solids:
				if solid.size.x>=48 and solid.size.y>=32: footprints.append(solid)
			cache[area_id]={"bounds":Rect2(Vector2.ZERO,game.area.bounds),"routes":game.area.routes.duplicate(true),"exits":exits,"footprints":footprints}
			cache_builds+=1
		geometry=cache[area_id];queue_redraw();marker.queue_redraw()
	var next_position: Vector2=game.hero.position
	var next_angle: float=game.hero.DIRECTIONS.find(game.hero.direction)*PI/4
	if player_position!=next_position or player_angle!=next_angle:
		player_position=next_position;player_angle=next_angle;marker.queue_redraw()

func map_rect() -> Rect2:
	if geometry.is_empty(): return Rect2()
	var available:=Rect2(Vector2(8,19),size-Vector2(16,27))
	var bounds: Rect2=geometry.bounds
	var factor:=minf(available.size.x/bounds.size.x,available.size.y/bounds.size.y)
	var fitted:=bounds.size*factor
	return Rect2(available.position+(available.size-fitted)/2,fitted)

func world_to_map(world: Vector2) -> Vector2:
	var bounds: Rect2=geometry.bounds
	var rect:=map_rect()
	return rect.position+(world-bounds.position)/bounds.size*rect.size

func _draw() -> void:
	static_redraws+=1
	var frame:=preload("res://scripts/ui_theme.gd").panel(Color("111b1eed"),0,Color("a28b54"));frame.set_border_width_all(1);frame.set_corner_radius_all(7);frame.shadow_size=2
	draw_style_box(frame,Rect2(Vector2.ZERO,size))
	for corner in [Vector2(3,3),Vector2(size.x-3,3),Vector2(3,size.y-3),size-Vector2(3,3)]:
		var inward: Vector2=(size/2-corner).sign()
		draw_line(corner,corner+Vector2(inward.x*8,0),Color("c2a96b"),1)
		draw_line(corner,corner+Vector2(0,inward.y*8),Color("c2a96b"),1)
	if geometry.is_empty(): return
	var title: String={"vigil":"VIGIL","road":"OLD MILL ROAD","bannerfall":"BANNERFALL"}.get(area_id,area_id.to_upper())
	draw_string(ThemeDB.fallback_font,Vector2(8,12),title,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,9,Color("c5b27d"))
	var rect:=map_rect();draw_rect(rect,Color("29332d"));draw_rect(rect,Color("4d5140"),false,1)
	for footprint in geometry.footprints:
		var p:=world_to_map(footprint.position);var end:=world_to_map(footprint.end)
		draw_rect(Rect2(p,end-p),Color("535044"))
	for route in geometry.routes:
		var line:=PackedVector2Array()
		for point in route: line.append(world_to_map(point))
		if line.size()>1: draw_polyline(line,Color("b19a69"),2,true)
	for exit in geometry.exits:
		var p:=world_to_map(exit)
		draw_rect(Rect2(p-Vector2(3,3),Vector2(6,6)),Color("141c1a"))
		draw_rect(Rect2(p-Vector2(3,3),Vector2(6,6)),Color("f1d38b"),false,1)

func draw_player() -> void:
	if geometry.is_empty(): return
	var p:=world_to_map(player_position)
	var triangle:=PackedVector2Array()
	for offset in [Vector2(5,0),Vector2(-3.5,-3.5),Vector2(-2,0),Vector2(-3.5,3.5)]: triangle.append(p+offset.rotated(player_angle))
	marker.draw_circle(p,5.5,Color("111b1e"));marker.draw_colored_polygon(triangle,Color("87c8ff"));triangle.append(triangle[0]);marker.draw_polyline(triangle,Color("edf5df"),.7,true)

func consume(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if not event.pressed and fingers.has(event.index): fingers.erase(event.index);return true
		if event.pressed and visible and get_global_rect().has_point(event.position): fingers[event.index]=true;return true
	if event is InputEventScreenDrag and fingers.has(event.index): return true
	if event is InputEventMouseButton and visible and get_global_rect().has_point(event.position): return true
	return false
