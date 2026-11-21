extends Control
## Presentation only. The parent Button retains all activation and touch ownership.
const SYMBOLS={"knight":["sword","shield","cleave"],"mage":["bolt","burst","focus"],"rogue":["dagger","evade","twin"]}
const LABELS={"knight":["Attack","Guard","Cleave"],"mage":["Attack","Burst","Focus"],"rogue":["Attack","Evade","Twin"]}
const ACCENTS={"knight":Color("8cbbd3"),"mage":Color("ba9ae8"),"rogue":Color("94c8a0")}
var game: Node
var slot: int=-1
var held:=false
var icon_only:=false # Comparison fixture only; shipped presentation retains labels.
var remaining:=0.0
var fraction:=0.0
var unavailable:=false
var clock:=0.0
var button: Button
var symbol_origin:=Vector2.ZERO
var symbol_scale:=1.0

func _ready() -> void:
	button=get_parent();mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.button_down.connect(func():held=true;queue_redraw())
	button.button_up.connect(func():held=false;queue_redraw())
	button.mouse_entered.connect(queue_redraw);button.mouse_exited.connect(queue_redraw)
	for state in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]: button.add_theme_color_override(state,Color.TRANSPARENT)
	refresh()

func symbol() -> String: return SYMBOLS[game.selected][slot+1]
func short_label() -> String: return LABELS[game.selected][slot+1]
func description() -> String:
	if slot<0: return {"knight":"Sword strike — melee attack","mage":"Arcane bolt — ranged projectile","rogue":"Throw dagger — ranged projectile"}[game.selected]+"\nAttack interval: %.2fs"%game.stats.cooldown
	var data: Dictionary=game.abilities.DATA[game.selected][slot]
	var effect: String={"shield":"Reduce incoming damage while guarding.","cleave":"Sweep enemies in a forward arc.","burst":"Release a nearby arcane burst that staggers enemies.","focus":"Fire a focused arcane projectile.","evade":"Dash in the direction you face.","twin":"Throw two daggers in quick succession."}[symbol()]
	return "%s\n%s\nCooldown: %.1fs"%[data.name,effect,data.cooldown]

func refresh() -> void:
	if not is_instance_valid(game.hero): return
	remaining=game.cooldown if slot<0 else game.abilities.remaining[slot]
	var duration: float=game.stats.cooldown if slot<0 else game.abilities.DATA[game.selected][slot].cooldown
	fraction=clampf(remaining/maxf(.001,duration),0,1)
	unavailable=game.fallen or (game.abilities.active>=0 and (slot<0 or remaining<=0)) or button.disabled
	if not is_visible_in_tree() or (held and not button in game.overlay.combat_touches.values() and not button.is_pressed()): held=false
	button.tooltip_text="" if game.presentation.touch_mode else description()
	queue_redraw()

func _process(delta: float) -> void:
	clock+=delta
	if clock>=.05: clock=0;refresh()

func polygon(points: Array, color: Color) -> void:
	var vertices:=PackedVector2Array()
	for point in points: vertices.append(Vector2(point[0],point[1]))
	draw_colored_polygon(vertices,color)
	draw_polyline(vertices+PackedVector2Array([vertices[0]]),Color("131b24"),1.3,true)

func blade(x:=0.0,y:=0.0,angle:=0.0,small:=false) -> void:
	draw_set_transform(symbol_origin+Vector2(x,y)*symbol_scale,angle,Vector2.ONE*symbol_scale*(.78 if small else 1.0))
	polygon([[-4,6],[-4,-15],[0,-23],[4,-15],[4,6]],Color("d8e2de"))
	draw_line(Vector2(0,-18),Vector2(0,5),Color("8aa5b3"),1.6,true)
	polygon([[-10,5],[10,5],[8,9],[-8,9]],Color("dab778"))
	draw_line(Vector2(0,10),Vector2(0,18),Color("937755"),4,true)
	draw_circle(Vector2(0,20),3,Color("e5c887"))

func draw_symbol(kind: String, accent: Color) -> void:
	match kind:
		"sword","dagger": blade(0,0,.55,kind=="dagger")
		"shield":
			polygon([[-17,-19],[0,-23],[17,-19],[14,6],[0,22],[-14,6]],Color("c8ad72"))
			polygon([[-12,-15],[0,-18],[12,-15],[10,4],[0,15],[-10,4]],Color("345c7a"))
			draw_line(Vector2(0,-12),Vector2(0,11),Color("f1d78e"),4,true);draw_line(Vector2(-8,-4),Vector2(8,-4),Color("f1d78e"),4,true)
		"cleave":
			draw_arc(Vector2(-3,1),22,-1.5,1.65,20,Color("e6b76a"),5,true)
			draw_arc(Vector2(-3,1),17,-1.3,1.4,20,Color("a26338"),2,true);blade(-4,1,.7,true)
		"bolt","focus":
			draw_line(Vector2(-19,17),Vector2(10,-12),Color("63547f"),12,true)
			draw_line(Vector2(-16,15),Vector2(10,-12),accent,5,true)
			polygon([[3,-15],[17,-22],[20,-8],[9,-3]],Color("a4dfe7"))
			draw_line(Vector2(-5,4),Vector2(13,-15),Color("f3e9ff"),2.5,true)
			if kind=="focus":
				draw_arc(Vector2.ZERO,18,-.3,1.6,16,accent,2,true);draw_arc(Vector2.ZERO,18,2.8,4.7,16,accent,2,true)
		"burst":
			for i in range(8):
				var dir:=Vector2.from_angle(i*TAU/8)
				draw_line(dir*12,dir*(23 if i%2==0 else 19),accent,3,true)
			polygon([[0,-15],[5,-5],[15,0],[5,5],[0,15],[-5,5],[-15,0],[-5,-5]],Color("a4dce7"))
			draw_circle(Vector2.ZERO,4,Color("f0e7ff"))
		"evade":
			for i in range(3): draw_line(Vector2(-23, float(-10+i*10)),Vector2(-11,float(-10+i*10)),Color("738777"),2,true)
			draw_circle(Vector2(8,-17),5,accent)
			draw_polyline(PackedVector2Array([Vector2(-9,-2),Vector2(3,-9),Vector2(11,-1),Vector2(21,-3)]),accent,4,true)
			draw_polyline(PackedVector2Array([Vector2(3,-9),Vector2(-2,6),Vector2(8,13),Vector2(4,23)]),Color("d1dfc7"),5,true)
			draw_polyline(PackedVector2Array([Vector2(-2,6),Vector2(-10,15),Vector2(-20,15)]),accent,4,true)
		"twin": blade(-9,0,-.35,true);blade(10,0,.35,true)

func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.hero): return
	var primary:=slot<0
	var phone: bool=game.presentation.profile=="Phone"
	var radius:=minf(size.x,size.y)/2-1
	var center:=size/2
	var gold:=Color("d5b878") if primary else Color("a89467")
	var accent: Color=ACCENTS[game.selected]
	
	if phone:
		draw_circle(center,radius,Color("151516"));draw_arc(center,radius-1,0,TAU,64,gold.darkened(.45 if unavailable else 0),2,true)
		draw_circle(center,radius-3,Color("3e2522") if primary else Color("20252a"))
		draw_arc(center,radius-4,-PI,-.3,32,Color("eed5a4") if held else Color("72644c"),1.5,true)
		draw_arc(center,radius-5,.2,2.7,24,Color("090e13"),2,true)
	else:
		var frame:=StyleBoxFlat.new();frame.bg_color=Color("392522") if primary else Color("20252a");frame.border_color=gold;frame.set_border_width_all(2);frame.set_corner_radius_all(9);draw_style_box(frame,Rect2(Vector2.ZERO,size))
	var icon_center:=Vector2(center.x,center.y-(5 if phone and not icon_only else 0)) if phone else Vector2(29,center.y)
	if held: icon_center+=Vector2(0,1.5)
	var icon_size:=42.0 if primary else 35.0
	if icon_only: icon_size+=7
	symbol_origin=icon_center;symbol_scale=icon_size/48
	draw_set_transform(icon_center,0,Vector2.ONE*symbol_scale)
	draw_symbol(symbol(),accent)
	draw_set_transform(Vector2.ZERO)
	if unavailable and remaining<=0: draw_circle(center,radius-3,Color(0.04,0.05,0.06,.53))
	if fraction>0:
		var sector:=PackedVector2Array([center])
		for i in range(33): sector.append(center+Vector2.from_angle(-PI/2+TAU*fraction*i/32)*(radius-3))
		draw_colored_polygon(sector,Color(0.02,0.025,0.04,.63))
		draw_arc(center,radius-3,-PI/2,-PI/2+TAU*fraction,33,gold.darkened(.2),1.5,true)
	var font:=ThemeDB.fallback_font
	if not icon_only:
		var label:=short_label()
		if not game.presentation.touch_mode: label=game.presentation.action_prompt(label,"Space" if primary else ("Q" if slot==0 else "R"))
		var font_size:=10 if phone else 13
		if primary and phone: font_size=12
		while phone and font_size>8 and font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>size.x-8: font_size-=1
		var width:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var origin:=Vector2((size.x-width)/2,size.y-9) if phone else Vector2(55,center.y+4)
		draw_string(font,origin+Vector2(1,1),label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color.BLACK)
		draw_string(font,origin,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("ece0c4").darkened(.25 if unavailable else 0))
	if remaining>0:
		var value:="%.1f"%remaining if remaining<1 else str(ceili(remaining))
		var width:=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		var pos:=center+Vector2(-width/2,3)
		draw_string_outline(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,16,4,Color("0b1017"));draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff0ce"))
	if held: draw_arc(center,radius-1,0,TAU,64,Color("fff0c7"),2,true)
	if primary and game.auto_attack:
		draw_arc(center,radius-1,-2.2,-.9,20,Color("a7d39a"),3,true)
		draw_circle(Vector2(size.x-12,12),3,Color("c7e7aa"))
