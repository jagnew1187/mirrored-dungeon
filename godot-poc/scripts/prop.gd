extends Node2D

var kind := "house"
var footprint := Vector2(240,150)
var title := ""
var tint := Color("5a635e")
var art: Texture2D
var time := 0.0
var origin := Vector2.ZERO
var visual_size := Vector2.ZERO
var fade := 1.0
static var textures: Dictionary = {}
const ART := ["tent","pavilion","chest","crate","table","fire","barrel","supply_crate","barricade","rubble","arch","banner","dummy","brazier"]
const NATURE := ["oak","pine","birch","shrub","rock","log"]

func texture(path: String) -> Texture2D:
	if not textures.has(path): textures[path]=load(path)
	return textures[path]

func _ready() -> void:
	var key:=kind
	if kind=="tree": key=["oak","pine","birch"][posmod(int(position.x+position.y),3)]
	if key in NATURE:
		art=texture("res://assets/pass07/"+key+".png");visual_size=art.get_size()
		origin=Vector2(visual_size.x/2,visual_size.y-8 if key in ["shrub","rock","log"] else visual_size.y-16)
	elif kind in ["house","checkpoint"]:
		key="checkpoint" if kind=="checkpoint" else ("bakery" if "bakery" in title else ("smithy" if "smithy" in title else ("mill" if "Mill" in title else ("ration" if "Ration" in title else "residence"))))
		art=texture("res://assets/pass07/"+key+".png");visual_size=art.get_size();origin=Vector2(visual_size.x/2,visual_size.y-12)
	elif kind in ART:
		art=texture("res://assets/"+kind+".png");visual_size=Vector2(footprint.x,footprint.x*art.get_height()/art.get_width());origin=Vector2(visual_size.x/2,visual_size.y)
	elif kind=="gate":
		art=texture("res://assets/arch.png");visual_size=Vector2(160,240);origin=Vector2(80,240)
	# Static artwork is drawn once; only near-camera fire is redrawn each frame.
	queue_redraw()

func _process(delta: float) -> void:
	var game:=get_parent().get_parent().get_parent()
	if not is_instance_valid(game.hero): return
	var relative: Vector2=game.hero.global_position-global_position
	visible=absf(relative.x)<950 and absf(relative.y)<780
	if not visible: return
	var cover:=kind in ["tree","house","checkpoint","tent","pavilion","gate","shrub","rock","log"]
	var obscures:=cover and relative.y<0 and relative.y>-origin.y+25 and absf(relative.x)<visual_size.x*.43
	if cover and not obscures:
		for enemy in game.enemies:
			var behind: Vector2=enemy.actor.global_position-global_position
			if enemy.actor.visible and behind.y<0 and behind.y>-origin.y+25 and absf(behind.x)<visual_size.x*.43: obscures=true;break
	var previous:=fade
	fade=move_toward(fade,.32 if obscures else 1.0,delta*4)
	if not is_equal_approx(previous,fade): queue_redraw()
	if kind=="fire" and not game.menu_open: time+=delta;queue_redraw()

func _draw() -> void:
	if art:
		# Small ground shadow at the base, never a full-image collision footprint.
		draw_set_transform(Vector2(5,-3),0,Vector2(1,.25));draw_circle(Vector2.ZERO,minf(footprint.x*.52,70),Color(0.02,.035,.025,.28));draw_set_transform(Vector2.ZERO)
		if kind=="fire":
			for i in range(6,0,-1):
				draw_set_transform(Vector2(0,-15),0,Vector2(1,.55));draw_circle(Vector2.ZERO,22+i*12,Color(.9,.38,.06,.012+sin(time*6)*.002));draw_set_transform(Vector2.ZERO)
		if kind in ["house","checkpoint","tree"] and fade<1.0:
			var base_height:=80.0 if kind!="tree" else 38.0
			var split:=visual_size.y-base_height
			draw_texture_rect_region(art,Rect2(-origin,Vector2(visual_size.x,split)),Rect2(0,0,visual_size.x,split),Color(1,1,1,fade))
			draw_texture_rect_region(art,Rect2(-origin+Vector2(0,split),Vector2(visual_size.x,base_height)),Rect2(0,split,visual_size.x,base_height))
		else: draw_texture_rect(art,Rect2(-origin,visual_size),false,Color(1,1,1,fade))
		if kind=="fire":
			for i in range(7):
				var progress:=fmod(time*.5+i*.13,1.0)
				draw_rect(Rect2(sin(i*5.0+time)*12,-25-progress*60,2,3),Color(1,.65,.2,1-progress))
	elif kind=="cross":
		draw_rect(Rect2(-7,-95,14,95),Color("574e3c"));draw_rect(Rect2(-32,-74,64,13),Color("796d52"));draw_line(Vector2(-4,-90),Vector2(-4,-5),Color("a3936e"),2)
	if title!="":
		draw_string(ThemeDB.fallback_font,Vector2(-maxf(footprint.x,180)/2,24),title,HORIZONTAL_ALIGNMENT_CENTER,maxf(footprint.x,180),16,Color("ddc99e"))
