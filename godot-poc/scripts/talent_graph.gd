extends Control
## Five-node interactive graph; detailed prerequisites remain readable below it.
var record: Dictionary
var learned: Callable
const Classes=preload("res://scripts/class_progression.gd")
var buttons: Dictionary={}
func _ready() -> void:
	custom_minimum_size.y=302;size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for entry in Classes.nodes(record["class"]):
		var b:=Button.new();b.name="Talent_"+entry.id;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.add_theme_font_size_override("font_size",14)
		var rank:=int(record.talents.get(entry.id,0));b.text="%s\n%d / %d"%[entry.name,rank,entry.max_rank];b.disabled=not Classes.spend_error(record,entry.id).is_empty()
		if rank>0: b.add_theme_color_override("font_color",Color("d8b16a"));b.add_theme_color_override("font_disabled_color",Color("ad986b"))
		b.pressed.connect(func():learned.call(entry.id));add_child(b);buttons[entry.id]=b
	resized.connect(layout);layout()
func layout() -> void:
	var width:=maxf(110,(size.x-24)/2)
	var placements={"root_a":Vector2(0,0),"root_b":Vector2(width+24,0),"focus_a":Vector2(0,110),"focus_b":Vector2(width+24,110),"bridge":Vector2((size.x-width)/2,220)}
	for id in buttons: buttons[id].position=placements[id];buttons[id].size=Vector2(width,72)
	queue_redraw()
func _draw() -> void:
	if not buttons.has("bridge"): return
	var center:=size.x/2;var color:=Color("72654b")
	for branch in ["a","b"]:
		var point: Vector2=buttons["root_"+branch].position+Vector2(buttons["root_"+branch].size.x/2,72)
		draw_line(point,point+Vector2(0,38),color,2)
		draw_polyline(PackedVector2Array([point,Vector2(point.x,92),Vector2(center,92),Vector2(center,220)]),color,2)
