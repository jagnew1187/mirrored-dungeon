extends Button
const Palette=preload("res://scripts/ui_theme.gd")
const Bank=preload("res://scripts/animation_bank.gd")
var kind:="knight"
var chosen:=false
var preview: AnimatedSprite2D
func _ready() -> void:
	text=kind.to_upper();clip_text=true;custom_minimum_size.y=142;size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: add_theme_color_override(state,Color.TRANSPARENT)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,10)
	add_child(margin);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);margin.add_child(row)
	var art:=Control.new();art.custom_minimum_size=Vector2(76,112);art.clip_contents=true;row.add_child(art)
	preview=AnimatedSprite2D.new();preview.sprite_frames=Bank.frames_for(kind,"militia");preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;preview.position=Vector2(38,56);preview.scale=Vector2.ONE*.72;preview.speed_scale=.65;preview.play("walk_right");art.add_child(preview)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
	var model=preload("res://scripts/campaign.gd").new();model.fresh(kind)
	var values: Array=[kind.capitalize(),"%d health"%model.stats().hp,{"knight":"Sword & shield","mage":"Arcane bolt","rogue":"Thrown daggers"}[kind],{"knight":"Guard incoming blows and cleave nearby foes.","mage":"Burst at close range or focus a powerful bolt.","rogue":"Evade danger and throw paired daggers."}[kind]]
	for i in range(values.size()):
		var label:=Label.new();label.text=values[i];label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",18 if i==0 else 13);label.add_theme_color_override("font_color",Palette.GOLD if i==0 else Palette.PAPER);words.add_child(label)
	for node in find_children("*","Control",true,false): node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	refresh()
func refresh() -> void:
	for state in ["normal","hover","pressed","focus"]:
		var frame:=Palette.panel(Color("2b2a24") if chosen else Color("141a20"),8,Color("e5c47b") if chosen else Color("635b48"));frame.set_corner_radius_all(6);frame.set_border_width_all(3 if chosen else 1);add_theme_stylebox_override(state,frame)
	button_pressed=chosen
