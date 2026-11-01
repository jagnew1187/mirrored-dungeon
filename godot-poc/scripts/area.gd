extends Node2D

@export var area_id := "vigil"
var bounds := Vector2(1152,720)
var spawn := Vector2(420,520)
var solids: Array[Rect2] = []
var points: Array[Dictionary] = []
var routes: Array = []
var actors: Node2D
var grid := AStarGrid2D.new()
var tiles: Array[Texture2D] = []
var game: Node

func _ready() -> void:
	game = get_parent()
	actors = Node2D.new(); actors.y_sort_enabled = true; add_child(actors)
	for i in range(4): tiles.append(load("res://assets/tile_%d.png" % i))
	if area_id == "vigil": build_camp()
	elif area_id == "road": build_road()
	else: build_town()
	build_woodland_detail()
	build_ground()
	for rect in solids:
		var body:=StaticBody2D.new();body.position=rect.get_center();body.collision_layer=1
		var collision:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=rect.size;collision.shape=box;body.add_child(collision);add_child(body)
	grid.region = Rect2i(0,0,int(bounds.x/24),int(bounds.y/24))
	grid.cell_size = Vector2(24,24); grid.offset = Vector2(12,12)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(grid.region.size.y):
		for x in range(grid.region.size.x):
			if not clear(Vector2(x*24+12,y*24+12)): grid.set_point_solid(Vector2i(x,y))
	queue_redraw()

func prop(kind: String, p: Vector2, size: Vector2, label := "", color := Color("52655d")) -> void:
	var item := Node2D.new(); item.set_script(load("res://scripts/prop.gd"))
	item.kind = kind; item.position = p; item.footprint = size; item.title = label; item.tint = color
	actors.add_child(item)
	solids.append(Rect2(p-Vector2(size.x/2,size.y),size))

func decoration(kind: String, p: Vector2) -> void:
	var item:=Node2D.new();item.set_script(load("res://scripts/prop.gd"))
	item.kind=kind;item.position=p;item.footprint=Vector2(32,12);actors.add_child(item)

func build_woodland_detail() -> void:
	# Decorative edges never alter the established road solids or spawn geometry.
	if area_id=="vigil":
		for p in [Vector2(65,235),Vector2(130,175),Vector2(390,190),Vector2(570,175),Vector2(750,175),Vector2(1020,205),Vector2(1120,350),Vector2(40,510),Vector2(80,680),Vector2(1090,710)]:
			prop("tree",p,Vector2(24,22))
		for p in [Vector2(80,300),Vector2(1000,365),Vector2(540,220),Vector2(1010,670),Vector2(70,590)]: decoration("shrub",p)
		decoration("log",Vector2(770,650));decoration("rock",Vector2(55,390));decoration("rock",Vector2(1030,270))
	elif area_id=="road":
		var detail_rng:=RandomNumberGenerator.new();detail_rng.seed=7262
		for i in range(150):
			var p:=Vector2(detail_rng.randf_range(55,bounds.x-55),detail_rng.randf_range(200,bounds.y-80))
			if road_distance(p)<120 or not clear(p,55): continue
			if p.distance_to(Vector2(2700,530))<320: continue
			decoration(["shrub","shrub","rock","log"][i%4],p)

func point(id: String, label: String, p: Vector2, kind: String, text: String, target := "") -> void:
	points.append({"id":id,"name":label,"pos":p,"kind":kind,"text":text,"target":target})
	if kind in ["mara","boy","anja","oren","ves"]:
		var actor := CharacterBody2D.new(); actor.set_script(load("res://scripts/actor.gd")); actor.kind=kind;actor.position=p;actors.add_child(actor)

func build_camp() -> void:
	spawn=Vector2(510,575)
	routes = [[Vector2(510,720),Vector2(530,600),Vector2(650,530),Vector2(720,490)],[Vector2(680,510),Vector2(900,520),Vector2(1090,510)]]
	prop("tent",Vector2(250,295),Vector2(210,100),"Refuge tents")
	prop("pavilion",Vector2(865,325),Vector2(230,100),"Vigil pavilion")
	prop("fire",Vector2(710,465),Vector2(80,35))
	prop("chest",Vector2(220,500),Vector2(80,35))
	prop("table",Vector2(350,575),Vector2(130,55))
	prop("crate",Vector2(930,430),Vector2(75,35))
	prop("barrel",Vector2(130,350),Vector2(50,35))
	prop("supply_crate",Vector2(165,365),Vector2(45,35))
	point("mara","Mara",Vector2(430,360),"mara","You made it. Bram has been carving boats; Finn knows every bird here. I am keeping the camp supplied. Follow Old Mill Road east. The seized flour is at the mill in the northeast.")
	point("bram","Bram",Vector2(350,395),"boy","I made a boat! When the road is safe, can we try it in the millstream?")
	point("finn","Finn",Vector2(270,390),"boy","Bram says that bird is a rook. I think it is a jackdaw.")
	point("stash","Protected stash",Vector2(220,535),"stash","Camp supplies are safe.")
	point("roster","Camp supplies",Vector2(350,620),"management","Prepare for the next outing.")
	point("road","Old Mill Road →",Vector2(1050,530),"exit","","road")

func build_road() -> void:
	bounds=Vector2(3072,2112);spawn=Vector2(180,1730)
	routes=[[spawn,Vector2(780,1500),Vector2(1500,1250),Vector2(2300,850),Vector2(2700,530)], [Vector2(780,1500),Vector2(650,650),Vector2(1500,650),Vector2(2300,850)], [Vector2(1500,1250),Vector2(2600,1650),Vector2(2880,1750)]]
	prop("house",Vector2(2700,380),Vector2(310,145),"Seized Mill",Color("5b6555"))
	prop("cross",Vector2(650,560),Vector2(24,24),"Pilgrim's Cross")
	prop("crate",Vector2(2410,490),Vector2(80,50))
	var rng:=RandomNumberGenerator.new();rng.seed=8732
	for i in range(155):
		var p:=Vector2(rng.randf_range(70,bounds.x-70),rng.randf_range(210,bounds.y-60))
		if road_distance(p)>140 and p.distance_to(Vector2(2700,530))>300:
			prop("tree",p,Vector2(24,22))
	point("vigil","← Vigil Camp",Vector2(100,1760),"exit","","vigil")
	point("bannerfall","Bannerfall →",Vector2(2900,1760),"exit","","bannerfall")
	prop("supply_crate",Vector2(2700,445),Vector2(60,24),"Seized flour")
	point("flour","Seized flour",Vector2(2700,470),"quest","Defeat the two authored mill guards, then recover the flour.")
	point("cross","Pilgrim's Cross",Vector2(650,640),"landmark","The north trail rejoins the road near the seized mill. The southeast fork leads to Bannerfall.")

func build_town() -> void:
	bounds=Vector2(2112,1536);spawn=Vector2(190,1200)
	routes=[[Vector2(100,1200),Vector2(1000,1200),Vector2(1000,400)],[Vector2(350,750),Vector2(1800,750)]]
	prop("checkpoint",Vector2(350,1120),Vector2(230,100),"Occupation checkpoint",Color("73484b"))
	prop("house",Vector2(630,620),Vector2(300,180),"Anja's bakery",Color("886347"))
	prop("house",Vector2(1430,620),Vector2(350,200),"Oren's smithy",Color("4b626a"))
	prop("house",Vector2(650,1050),Vector2(260,130),"Ration house")
	prop("house",Vector2(1520,1110),Vector2(330,160),"Town residences",Color("75604f"))
	prop("house",Vector2(1200,300),Vector2(300,150),"North district · future connection")
	prop("crate",Vector2(1190,910),Vector2(100,55))
	prop("gate",Vector2(190,1110),Vector2(65,110),"West gate")
	prop("gate",Vector2(190,1450),Vector2(65,110))
	point("anja","Anja",Vector2(650,700),"anja","The occupation took our flour. If you clear the mill patrol and recover the sacks, we can share bread again.")
	point("oren","Oren",Vector2(1410,720),"oren","I used to forge their weapons. Now I mend doors. A town needs room for people and carts, not just soldiers.")
	point("ves","Ves",Vector2(390,1200),"ves","Papers, please. Keep to the square. I keep a second ledger, where the missing names are safe.")
	point("road","← Old Mill Road",Vector2(100,1250),"exit","","road")
	point("vigil","Return to Vigil",Vector2(1850,1250),"exit","","vigil")

func clear(p: Vector2, radius := 13.0) -> bool:
	if p.x<radius or p.y<radius or p.x>bounds.x-radius or p.y>bounds.y-radius: return false
	for rect in solids:
		if rect.grow(radius).has_point(p): return false
	return true

func line_clear(a: Vector2, b: Vector2) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/8))
	for i in range(1,steps):
		if not clear(a.lerp(b,float(i)/steps),2): return false
	return true

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start:=Vector2i(from/24); var end:=Vector2i(to/24)
	if not grid.is_in_boundsv(start) or not grid.is_in_boundsv(end): return PackedVector2Array()
	# Manual movement may stop in a conservatively blocked grid cell.
	if grid.is_point_solid(start):
		var nearest:=start;var distance:=INF
		for y in range(-2,3):
			for x in range(-2,3):
				var cell:=start+Vector2i(x,y)
				if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
					var p:=Vector2(cell)*24+Vector2(12,12)
					if p.distance_to(from)<distance and line_clear(from,p): nearest=cell;distance=p.distance_to(from)
		start=nearest
	if grid.is_point_solid(end): return PackedVector2Array()
	return grid.get_point_path(start,end)

func road_distance(p: Vector2) -> float:
	var distance:=INF
	for road in routes:
		for i in range(1,road.size()): distance=minf(distance,p.distance_to(Geometry2D.get_closest_point_to_segment(p,road[i-1],road[i])))
	return distance

func _draw() -> void:
	for p in points:
		if p.kind=="exit": draw_string(ThemeDB.fallback_font,p.pos+Vector2(-90,32),p.name,HORIZONTAL_ALIGNMENT_CENTER,180,18,Color("f0ddb0"))

func build_ground() -> void:
	var ground:=ColorRect.new();ground.size=bounds;ground.z_index=-10;ground.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material:=ShaderMaterial.new();material.shader=load("res://scripts/ground.gdshader")
	material.set_shader_parameter("map_size",bounds);material.set_shader_parameter("camp",area_id=="vigil")
	for i in range(4): material.set_shader_parameter("tile"+str(i),tiles[i])
	var segments:=PackedVector4Array()
	for road in routes:
		for i in range(1,road.size()): segments.append(Vector4(road[i-1].x,road[i-1].y,road[i].x,road[i].y))
	material.set_shader_parameter("count",segments.size())
	while segments.size()<16: segments.append(Vector4.ZERO)
	material.set_shader_parameter("segments",segments);ground.material=material;add_child(ground)

