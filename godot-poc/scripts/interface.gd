extends CanvasLayer
const Palette=preload("res://scripts/ui_theme.gd")
const Preferences=preload("res://scripts/ui_preferences.gd")
const ItemPresenter=preload("res://scripts/item_presenter.gd")
const Journal=preload("res://scripts/ui_journal.gd")
var game: Node
var root: Control
var veil: ColorRect
var window: PanelContainer
var column: VBoxContainer
var content: VBoxContainer
var scroll: ScrollContainer
var footer: HBoxContainer
var hud: PanelContainer
var hud_box: VBoxContainer
var status_strip: Control
var minimap: Control
var status: Label
var health: ProgressBar
var toast: Label
var attack_button: Button
var ability_buttons: Array[Button]=[]
var combat_touches: Dictionary={}
var page_id: String="title"
var toast_time:=0.0
var controls: Label
var objective_label: Label
var hero_name: String=""
var creation_class:="knight"
var creation_cards: Array[Button]=[]
var creation_name: LineEdit
var creation_begin: Button
var sheet_character_id: String="protagonist"
var sheet_compact:=false
var bag_mode: String="inventory"
var bag_page:=0
var bag_sort: String="name"
var bag_filter: String=""
var compatible_only:=false
var slot_page:=0
var save_warning: Label
var hud_clock:=0.0
var hud_updates:=0
var menu_builds:=0
var inventory_builds:=0
var target_label: Label
var character_button: Button
var interact_button: Button
var bubble: Label
var bubble_position:=Vector2.ZERO
var bubble_time:=0.0
var menu_button: Button
var tooltip_panel: PanelContainer
var tooltip_label: Label
var tooltip_updates:=0
var preferences=Preferences.new()
var character_tab: String="Equipment"
var settings_return: String="title"
var grid: GridContainer
var modal_footer: Button
var stats_snapshot: Dictionary={}
var item_popup: PanelContainer
var popup_wrapper: Control
var popup_label: RichTextLabel
var popup_icon: TextureRect
var popup_anchor:=Vector2.ZERO
var last_pointer_position:=Vector2(-1,-1)
var popup_scroll: ScrollContainer
var popup_actions: Array[Button]=[]
var popup_callbacks: Array[Callable]=[]
var popup_count:=0
var popup_pinned:=false
var last_viewport:=Vector2.ZERO
var ui_size:=Vector2(1152,720)
var settings_help: Label
var toast_action: Array[String]=[]
const SHORT_ABILITIES={"knight":["Guard","Cleave"],"mage":["Burst","Focus"],"rogue":["Evade","Twin"]}

func style(color: Color, margin:=18) -> StyleBoxFlat: return Palette.panel(color,margin)
func _ready() -> void:
	# Headless Windows starts with a 64px placeholder when stretch is disabled.
	# Give offscreen execution the configured startup viewport, respecting explicit sizes.
	if DisplayServer.get_name()=="headless" and get_tree().root.size==Vector2i(64,64):
		get_tree().root.size=Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width",1152),ProjectSettings.get_setting("display/window/size/viewport_height",720))
	var atmosphere:=CanvasLayer.new();atmosphere.layer=5;game.add_child(atmosphere)
	var shade:=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material:=ShaderMaterial.new();material.shader=load("res://scripts/atmosphere.gdshader");shade.material=material;atmosphere.add_child(shade)
	layer=20;preferences.read();preferences.apply_audio_display();game.show_touch=preferences.touch;game.presentation.override_profile=preferences.profile
	root=Control.new();root.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;root.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.theme=Palette.build();add_child(root)
	hud=PanelContainer.new();hud.set_script(load("res://scripts/phone_hud_frame.gd"));hud.game=game;root.add_child(hud)
	hud_box=VBoxContainer.new();hud.add_child(hud_box);status=Label.new();status.clip_text=true;status.add_theme_font_size_override("font_size",16);hud_box.add_child(status)
	health=ProgressBar.new();health.custom_minimum_size=Vector2(0,14);health.show_percentage=false;hud_box.add_child(health)
	menu_button=Button.new();menu_button.focus_mode=Control.FOCUS_NONE;menu_button.pressed.connect(func():page("pause"));root.add_child(menu_button)
	character_button=Button.new();character_button.focus_mode=Control.FOCUS_NONE;character_button.pressed.connect(toggle_character);root.add_child(character_button)
	attack_button=Button.new();attack_button.focus_mode=Control.FOCUS_NONE;attack_button.button_down.connect(func():game.attack_held=true;game.request_attack());attack_button.button_up.connect(func():game.attack_held=false);root.add_child(attack_button);add_combat_face(attack_button,-1)
	for i in range(2):
		var button:=Button.new();button.focus_mode=Control.FOCUS_NONE;button.pressed.connect(func():game.abilities.activate(i));root.add_child(button);ability_buttons.append(button);add_combat_face(button,i)
	controls=Label.new();controls.text="WASD / arrows · Move\nC / I · Character   J · Journal   E · Interact";controls.add_theme_font_size_override("font_size",14);root.add_child(controls)
	objective_label=Label.new();objective_label.add_theme_font_size_override("font_size",15);objective_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(objective_label)
	target_label=Label.new();target_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;target_label.add_theme_color_override("font_color",Palette.GOLD);root.add_child(target_label)
	toast=Label.new();toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;toast.add_theme_color_override("font_color",Palette.GOLD);root.add_child(toast)
	for label in [controls,objective_label,target_label,toast]:
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2)
	veil=ColorRect.new();veil.color=Color(.025,.03,.04,.9);root.add_child(veil)
	window=PanelContainer.new();window.set_script(load("res://scripts/ui_frame.gd"));window.add_theme_stylebox_override("panel",Palette.panel(Palette.INK,20));root.add_child(window)
	column=VBoxContainer.new();window.add_child(column)
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
	tooltip_panel=PanelContainer.new();tooltip_panel.custom_minimum_size.y=56;tooltip_panel.add_theme_stylebox_override("panel",Palette.panel(Color("11151a"),8,Color("535548")));column.add_child(tooltip_panel)
	tooltip_label=Label.new();tooltip_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;tooltip_label.add_theme_font_size_override("font_size",14);tooltip_panel.add_child(tooltip_label)
	footer=HBoxContainer.new();column.add_child(footer)
	save_warning=Label.new();save_warning.add_theme_color_override("font_color",Color("ffb9a2"));root.add_child(save_warning)
	var pad:=Node2D.new();pad.set_script(load("res://scripts/touch_pad.gd"));pad.game=game;add_child(pad)
	build_item_popup()
	interact_button=Button.new();interact_button.text="Interact";interact_button.focus_mode=Control.FOCUS_NONE;interact_button.pressed.connect(game.interact_nearest);root.add_child(interact_button)
	bubble=Label.new();bubble.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;bubble.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;bubble.add_theme_stylebox_override("normal",Palette.panel(Palette.INK,8));bubble.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(bubble);bubble.hide()
	status_strip=Control.new();status_strip.set_script(load("res://scripts/status_strip.gd"));status_strip.game=game;root.add_child(status_strip)
	minimap=Control.new();minimap.set_script(load("res://scripts/local_minimap.gd"));minimap.game=game;root.add_child(minimap)
	get_viewport().size_changed.connect(relayout);relayout()

func relayout() -> void:
	if not is_instance_valid(root): return
	var extent: Vector2=get_viewport().get_visible_rect().size
	var safe: Rect2=game.presentation.safe_rect(extent)
	ui_size=safe.size/preferences.ui_scale;root.position=safe.position;root.scale=Vector2.ONE*preferences.ui_scale;root.size=ui_size
	last_viewport=extent
	veil.position=Vector2.ZERO;veil.size=ui_size
	window.size=Vector2(minf(1040,ui_size.x-32),minf(860,ui_size.y-32));window.position=(ui_size-window.size)/2
	if page_id=="characters":
		var visible_area: Rect2=game.presentation.menu_rect(extent)
		var available:=Rect2((visible_area.position-safe.position)/preferences.ui_scale,visible_area.size/preferences.ui_scale)
		window.size=Vector2(minf(560,available.size.x-20),maxf(150,available.size.y-20));window.position=available.position+(available.size-window.size)/2
	if page_id=="dialogue":
		var phone_landscape: bool=game.presentation.profile=="Phone" and ui_size.y<500
		window.size=Vector2(minf(920,ui_size.x-24),ui_size.y*(.55 if phone_landscape else (.33 if ui_size.x>=900 else (.55 if ui_size.y<500 else .45))))
		window.position=Vector2((ui_size.x-window.size.x)/2,ui_size.y-window.size.y-12)
	hud.position=Vector2(18,16);hud.size=Vector2(minf(328,ui_size.x*.43),104)
	configure_hud(game.presentation.profile=="Phone")
	menu_button.position=Vector2(ui_size.x-152,16);menu_button.size=Vector2(128,52)
	character_button.position=Vector2(ui_size.x-152,76);character_button.size=Vector2(128,52)
	var button_width:=minf(204,(ui_size.x-48)/3.0)
	attack_button.position=Vector2(ui_size.x-button_width-18,ui_size.y-88);attack_button.size=Vector2(button_width,70)
	for i in range(2):
		ability_buttons[i].position=Vector2(ui_size.x-button_width*2-28,ui_size.y-164+i*76);ability_buttons[i].size=Vector2(button_width,70)
	controls.position=Vector2(18,ui_size.y-65);controls.visible=not game.menu_open and not game.presentation.touch_mode and ui_size.x>850
	objective_label.position=Vector2(18,128);objective_label.size=Vector2(minf(420,ui_size.x*.5),52)
	target_label.position=Vector2(ui_size.x*.36,20) if ui_size.x>=1000 else Vector2(ui_size.x-290,138);target_label.size=Vector2(ui_size.x*.34,52) if ui_size.x>=1000 else Vector2(272,52)
	toast.position=Vector2(ui_size.x*.24,182);toast.size=Vector2(ui_size.x*.52,56)
	save_warning.position=Vector2(18,0);save_warning.size=Vector2(ui_size.x-36,20)
	if is_instance_valid(grid): grid.columns=2 if window.size.x<560 else (4 if window.size.x<850 else 6)
	if is_instance_valid(item_popup): position_item_popup()
	if ui_size.x<650:
		target_label.position=Vector2(18,190);target_label.size=Vector2(ui_size.x-36,52)
		toast.position=Vector2(18,248);toast.size=Vector2(ui_size.x-36,56)
	objective_label.visible=not game.menu_open and game.presentation.profile!="Phone"
	character_button.text=game.presentation.action_prompt("Character","C")
	menu_button.text=game.presentation.action_prompt("Menu","Esc")
	if is_instance_valid(interact_button):
		interact_button.visible=not game.menu_open
		interact_button.position=Vector2(ui_size.x-152,136);interact_button.size=Vector2(128,52)
	if game.presentation.profile=="Phone":
		hud.size=Vector2(minf(210,ui_size.x-142),62)
		objective_label.visible=false
		menu_button.size=Vector2(96,44);menu_button.position=Vector2(ui_size.x-114,16)
		character_button.size=Vector2(96,44);character_button.position=Vector2(ui_size.x-114,68)
		attack_button.size=Vector2(72,72);attack_button.position=Vector2(ui_size.x-90,ui_size.y-90)
		for i in range(2):
			ability_buttons[i].size=Vector2(56,56);ability_buttons[i].position=Vector2(ui_size.x-154,ui_size.y-146+i*64)
		interact_button.size=Vector2(112,44);interact_button.position=Vector2(ui_size.x-130,ui_size.y-202)
		for button in [menu_button,character_button,interact_button]+ability_buttons:
			button.size.y=maxf(button.size.y,44.0/preferences.ui_scale)
		target_label.position=Vector2(18,132);target_label.size=Vector2(minf(360,ui_size.x-190),48)
		toast.position=Vector2(18,184);toast.size=Vector2(minf(360,ui_size.x-190),64)
	for button in [attack_button,menu_button,character_button,interact_button]+ability_buttons:
		style_game_button(button,game.presentation.profile=="Phone")
	layout_navigation()
	if page_id=="characters" and is_instance_valid(creation_name) and creation_name.has_focus(): scroll.call_deferred("ensure_control_visible",creation_name)
	status_strip.position=hud.position+Vector2(0,hud.size.y+2)
	refresh_prompts()
	var compact_now: bool=window.size.x<650
	if compact_now!=sheet_compact:
		sheet_compact=compact_now
		if game.menu_open and page_id=="equipment" and character_tab=="Equipment": call_deferred("_refresh_character_layout")

func _refresh_character_layout() -> void:
	if game.menu_open and page_id=="equipment" and character_tab=="Equipment": character(character_tab,sheet_character_id)

func layout_navigation() -> void:
	var phone: bool=game.presentation.profile=="Phone"
	var map_size:=144.0 if game.presentation.profile=="Tablet" else 156.0
	if phone:
		map_size=minf(120,ui_size.x-hud.size.x-48) if ui_size.x<ui_size.y else 128.0
		# Reserve independent upper navigation and bottom combat lanes.
		if ui_size.x>ui_size.y: map_size=minf(map_size,maxf(48,ui_size.y-72-maxf(44,44/preferences.ui_scale)-60))
	minimap.size=Vector2.ONE*map_size;minimap.position=Vector2(ui_size.x-map_size-18,16)
	if phone:
		var hit_height:=maxf(44,44/preferences.ui_scale)
		var tray_width:=minf(ui_size.x-36,maxf(minimap.size.x,156.0/preferences.ui_scale))
		var utility_width:=(tray_width-4)/2
		var tray_origin:=minimap.position+Vector2(minimap.size.x-tray_width,minimap.size.y+4)
		menu_button.size=Vector2(utility_width,hit_height);character_button.size=Vector2(utility_width,hit_height)
		menu_button.position=tray_origin;character_button.position=tray_origin+Vector2(utility_width+4,0)
		for button in [menu_button,character_button]:
			button.add_theme_font_size_override("font_size",12 if game.presentation.touch_mode else 11)
			for state in ["normal","hover","pressed","disabled"]:
				var box: StyleBoxFlat=button.get_theme_stylebox(state).duplicate()
				box.content_margin_left=3;box.content_margin_right=3
				box.set_expand_margin(SIDE_TOP,-(hit_height-38)/2);box.set_expand_margin(SIDE_BOTTOM,-(hit_height-38)/2)
				button.add_theme_stylebox_override(state,box)
		# Large HUD scale in short landscape needs the contextual action in the
		# free slot above Attack. Combat controls themselves stay in RC3 positions.
		if interact_button.position.y<menu_button.position.y+hit_height+8:
			interact_button.position=Vector2(ui_size.x-90,ui_size.y-146);interact_button.size.x=72
	else:
		var utility_width:=minf(128,minimap.size.x)
		menu_button.size.x=utility_width;character_button.size.x=utility_width
		menu_button.position=minimap.position+Vector2(minimap.size.x-utility_width,minimap.size.y+4)
		character_button.position=menu_button.position+Vector2(0,60)
		interact_button.position.y=140+map_size
		target_label.position=Vector2(ui_size.x*.36,20);target_label.size=Vector2(ui_size.x*.34,52)
	if phone and ui_size.x>ui_size.y:
		var bottom:=ui_size.y-18
		attack_button.position=Vector2(ui_size.x-90,bottom-72)
		for i in range(2):
			ability_buttons[i].position=Vector2(ui_size.x-154-i*64,bottom-56)
		interact_button.size=Vector2(96,maxf(44,44/preferences.ui_scale))
		interact_button.position=Vector2(ui_size.x-322,bottom-interact_button.size.y)
		toast.position=Vector2(hud.position.x+hud.size.x+12,20)
		toast.size=Vector2(maxf(40,minimap.position.x-toast.position.x-20),64)
		target_label.position=Vector2(hud.position.x+hud.size.x+12,88)
		target_label.size=Vector2(maxf(40,minimap.position.x-target_label.position.x-20),48)
	minimap.refresh()

func configure_hud(phone: bool) -> void:
	status.add_theme_font_size_override("font_size",14 if phone else 16)
	status.add_theme_constant_override("line_spacing",-3 if phone else 3)
	hud_box.add_theme_constant_override("separation",4 if phone else 10)
	health.custom_minimum_size.y=6 if phone else 14
	if phone:
		var frame:=Palette.panel(Color("171a20d9"),8,Color("887447"));frame.content_margin_left=36;frame.set_border_width_all(1);frame.shadow_size=2;hud.add_theme_stylebox_override("panel",frame)
	else: hud.remove_theme_stylebox_override("panel")
	hud.queue_redraw()

func style_game_button(button: Button, phone: bool) -> void:
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if phone else TextServer.AUTOWRAP_OFF
	button.add_theme_font_size_override("font_size",14 if phone else 17)
	for state in ["normal","hover","pressed","disabled"]:
		if not phone: button.remove_theme_stylebox_override(state);continue
		var box: StyleBoxFlat=root.theme.get_stylebox(state,"Button").duplicate()
		box.set_corner_radius_all(10);box.content_margin_left=6;box.content_margin_right=6;box.content_margin_top=4;box.content_margin_bottom=4
		if button==attack_button or button in ability_buttons:
			box.set_corner_radius_all(36 if button==attack_button else 28)
			box.border_color=Color("b79a60");box.set_border_width_all(2)
			button.add_theme_font_size_override("font_size",14 if button==attack_button else 12)
		if button==attack_button and state=="normal": box.bg_color=Color("4a2921");box.border_color=Color("e0b969")
		button.add_theme_stylebox_override(state,box)

func add_combat_face(button: Button, slot: int) -> void:
	button.clip_text=true # Custom face draws the label; semantic text must not expand the locked hitbox.
	var face:=Control.new();face.set_script(load("res://scripts/combat_button_face.gd"));face.game=game;face.slot=slot;face.name="CombatFace";button.add_child(face)

func refresh_prompts() -> void:
	if is_instance_valid(settings_help):
		settings_help.text="Drag the left joystick to move. Walk through road exits to travel. Tap an enemy to target or a status icon to inspect it. Use nearby actions to Talk or Pick Up." if game.presentation.touch_mode else "WASD / arrows: move · Left click: travel / select\nSpace / right mouse: attack · Q / R: abilities\nE: interact · C / I: character · J: journal · Esc: menu"
	if not toast_action.is_empty() and toast_time>0:
		toast.text=toast_action[0]+game.presentation.action_prompt(toast_action[1],toast_action[2])
	if not is_instance_valid(game.hero): return
	var nearby: Dictionary=game.nearby_interaction()
	interact_button.text=game.presentation.action_prompt(game.presentation.interaction_action(nearby) if not nearby.is_empty() else "Interact","E")
	interact_button.tooltip_text=game.world_prompt(nearby,true) if not nearby.is_empty() else "Move closer to a person, item or entrance"
	interact_button.disabled=nearby.is_empty() or (nearby.get("kind","")=="exit" and game.elapsed<game.transition_until)
	interact_button.visible=not game.menu_open and not nearby.is_empty() and not interact_button.disabled
	for i in range(2):
		var full_name: String=game.abilities.DATA[game.selected][i].name
		var label: String=SHORT_ABILITIES[game.selected][i] if game.presentation.profile=="Phone" else full_name
		var suffix: String="\n%.1fs"%game.abilities.remaining[i] if game.abilities.remaining[i]>0 else ("" if game.presentation.profile=="Phone" else "\nReady")
		if game.presentation.profile=="Phone" and game.presentation.touch_mode and game.abilities.remaining[i]>0: suffix=" %ds"%ceili(game.abilities.remaining[i])
		ability_buttons[i].text=game.presentation.action_prompt(label,"Q" if i==0 else "R")+suffix
		ability_buttons[i].tooltip_text=game.presentation.action_prompt(full_name,"Q" if i==0 else "R")
		ability_buttons[i].disabled=game.abilities.remaining[i]>0 or game.abilities.active>=0
	var attack_name: String="Attack" if game.presentation.profile=="Phone" else {"knight":"Sword strike","mage":"Arcane bolt","rogue":"Throw dagger"}[game.selected]
	attack_button.text=game.presentation.action_prompt(attack_name,"Space")+("\n%.1fs"%game.cooldown if game.cooldown>0 else ("" if game.presentation.profile=="Phone" else "\nReady"))

	for button in [attack_button]+ability_buttons: button.get_node("CombatFace").refresh()

func text(value: String, size:=18, color: Color=Palette.PAPER) -> Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",color);content.add_child(label);return label
func option(value: String, action: Callable, disabled:=false) -> Button:
	var button:=Button.new();button.text=value;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=52;button.disabled=disabled;button.pressed.connect(action);content.add_child(button);return button
func footer_button(value: String, action: Callable) -> Button:
	var button:=Button.new();button.text=value;button.custom_minimum_size.y=52;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.pressed.connect(action);footer.add_child(button);return button
func clear(id: String) -> void:
	status_strip.dismiss()
	minimap.hide()
	hide_item_popup()
	if is_instance_valid(interact_button): interact_button.hide()
	page_id=id;menu_builds+=1;combat_touches.clear();game.abilities.cancel();game.menu_open=true;game.cancel_approach();game.attack_held=false;game.action_input_armed=false;game.joystick=Vector2.ZERO;game.touch_id=-1
	grid=null
	for parent in [content,footer]:
		for child in parent.get_children(): parent.remove_child(child);child.queue_free()
	scroll.scroll_vertical=0;veil.color=Color(.025,.03,.04,.9);tooltip_panel.hide();tooltip_label.text="";veil.show();window.show()
	for control in [hud,attack_button,controls,toast,objective_label,target_label,menu_button,character_button]+ability_buttons: control.hide()
	relayout()
func close() -> void:
	hide_item_popup()
	if game.fallen: return
	game.started=true;game.menu_open=false;window.hide();veil.hide();tooltip_panel.hide();combat_touches.clear();game.attack_held=false;game.action_input_armed=false;game.joystick=Vector2.ZERO;game.touch_id=-1
	for control in [hud,attack_button,toast,objective_label,target_label,menu_button,character_button]+ability_buttons: control.show()
	get_viewport().gui_release_focus();relayout()
func focus_first() -> void:
	for node in content.find_children("*","Button",true,false):
		if not node.disabled: node.grab_focus();return
func set_tooltip(id: String, target: String="", worn:=false) -> void:
	if not game.campaign.Gear.ITEMS.has(id): return
	var item: Dictionary=game.campaign.Gear.ITEMS[id];tooltip_updates+=1
	tooltip_label.text="%s · %s · %s\n%s"%[item.name,item.rarity,item.category,sheet_model().comparison(id)]
	tooltip_label.add_theme_color_override("font_color",Palette.rarity(item.rarity))
	if not popup_pinned: show_item_popup(id,target,worn,false)
func row_buttons(labels: Array, actions: Array) -> void:
	var row:=HFlowContainer.new();content.add_child(row)
	for i in range(labels.size()):
		var button:=Button.new();button.text=labels[i];button.custom_minimum_size=Vector2(128,52);button.pressed.connect(actions[i]);row.add_child(button)
func title_header(label: String, subtitle: String="") -> void:
	text(label,28,Palette.GOLD)
	if not subtitle.is_empty(): text(subtitle,15,Palette.MUTED)
func sorted_slots() -> Array:
	var slots: Array=game.campaign.slots()
	for entry in slots:
		var primary: String=game.campaign.directory+"/"+entry.id+".json"
		var source: String=primary if not game.campaign.read_record(primary).is_empty() else primary+".bak"
		entry.saved=FileAccess.get_modified_time(source) if FileAccess.file_exists(source) else 0
	slots.sort_custom(func(a,b):return a.saved>b.saved if a.saved!=b.saved else a.id>b.id)
	return slots
func continue_latest() -> void:
	for entry in sorted_slots():
		if not entry.record.is_empty(): game.continue_campaign(entry.id);return
	page("characters")
func return_title() -> void:
	game.persist()
	if game.campaign.error.is_empty(): page("title")
	else: text(game.campaign.error,16,Color("efa38c"))
func page(id: String) -> void:
	if id=="equipment": character("Equipment");return
	if id=="inventory": inventory("inventory");return
	if id=="stash": inventory("stash");return
	if id=="settings": settings_return="title" if page_id in ["title","slots","characters"] else "pause"
	clear(id)
	match id:
		"title":
			text("A G N E W   F O R G E",14,Palette.MUTED);text("MIRRORED DUNGEON · 11.5 RC8",32,Palette.PAPER);text("T H E   L A S T   V I G I L",16,Palette.GOLD)
			text("A refuge in the shadow of occupation.",18,Palette.MUTED)
			var has_save: bool=sorted_slots().any(func(e):return not e.record.is_empty())
			option("Continue",continue_latest,not has_save);option("New Campaign",func():page("characters"));option("Load Campaign",func():slot_page=0;page("slots"));option("Settings",func():page("settings"))
			footer_button("Quit",func():page("quit"))
		"pause":
			title_header("THE LAST VIGIL","World paused · your road can wait.")
			option("Resume",close);row_buttons(["Character","Inventory","Journal"],[func():character("Equipment"),func():inventory("inventory"),func():page("journal")])
			option("Party roster",party_menu);option("Settings",func():page("settings"));option("Save Campaign",func():game.persist();text("Saved at your safe refuge." if game.campaign.error.is_empty() else game.campaign.error,16))
			option("Return to Vigil",func():game.enter_area("vigil");close());footer_button("Return to Title",return_title);footer_button("Resume",close)
		"characters": build_creation()
		"slots": build_slots()
		"settings": build_settings()
		"journal":
			title_header("BREAD BEFORE BLADES",game.objective())
			var active_found:=false
			for entry in Journal.entries(game.campaign):
				var state: String="COMPLETE" if entry.done else ("ACTIVE" if not active_found else "AHEAD")
				if not entry.done: active_found=true
				text(state+" · "+entry.title,20,Palette.rarity("Improved") if entry.done else Palette.GOLD);text(entry.area,14,Palette.MUTED);text(entry.body,16)
			footer_button("Close",close)
		"quit":
			title_header("LEAVE THE VIGIL?","Your campaign resumes at its recorded safe refuge.")
			option("Quit game",func():
				if game.started: game.persist()
				if game.campaign.error.is_empty(): game.get_tree().quit()
				else: text(game.campaign.error))
			footer_button("Cancel",func():page("pause" if game.started else "title"))
		"defeat":
			title_header("THE ROAD TAKES ITS TOLL","XP, equipment and recorded quest progress are protected.")
			text("Unfinished fights reset. Claimed rewards cannot be claimed twice.")
			option("Recover at last safe refuge",game.recover);footer_button("Save and return to title",return_title)
	call_deferred("focus_first")
func build_creation() -> void:
	hero_name="";creation_class="knight";creation_cards.clear()
	text("NEW CAMPAIGN",24,Palette.GOLD);text("Create a separate hero. Existing saves stay intact.",14,Palette.MUTED)
	creation_name=LineEdit.new();creation_name.placeholder_text="Hero name (optional)";creation_name.max_length=24;creation_name.custom_minimum_size=Vector2(0,48);creation_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	creation_name.text_changed.connect(func(value):hero_name=value)
	creation_name.focus_entered.connect(func():scroll.ensure_control_visible(creation_name))
	creation_name.text_submitted.connect(func(_value):creation_name.release_focus())
	content.add_child(creation_name)
	for kind in ["knight","mage","rogue"]:
		var card:=Button.new();card.set_script(load("res://scripts/class_card.gd"));card.kind=kind;card.chosen=kind==creation_class;card.pressed.connect(func():choose_creation_class(kind));content.add_child(card);creation_cards.append(card)
	var back:=footer_button("Back",func():page("title"));back.add_theme_font_size_override("font_size",14)
	creation_begin=footer_button("Begin Campaign",begin_creation);creation_begin.add_theme_font_size_override("font_size",14);creation_begin.clip_text=true
	creation_begin.add_theme_stylebox_override("normal",Palette.panel(Color("403522"),8,Color("e5c47b")))
	call_deferred("relayout")

func choose_creation_class(kind: String) -> void:
	creation_class=kind
	for card in creation_cards: card.chosen=card.kind==kind;card.refresh()

func begin_creation() -> void:
	if page_id!="characters" or creation_begin.disabled: return
	creation_begin.disabled=true
	if is_instance_valid(creation_name): creation_name.release_focus()
	game.select_class(creation_class);close()

func build_slots() -> void:
	title_header("SAVED CAMPAIGNS","Separate heroes · Continue loads the most recently modified readable save.")
	var slots: Array=sorted_slots();slot_page=clampi(slot_page,0,maxi(0,ceili(slots.size()/3.0)-1))
	for entry in slots.slice(slot_page*3,slot_page*3+3):
		if entry.record.is_empty():
			option("Unreadable campaign · original file preserved",func():pass,true)
			if entry.has("problem"): text(entry.problem,14,Color("efa38c"))
			continue
		var model=game.campaign.get_script().new();model.data=entry.record
		var saved: String=Time.get_datetime_string_from_unix_time(entry.saved).replace("T"," ")+" UTC" if entry.saved>0 else "Save time unavailable"
		var refuge: String="Bannerfall" if entry.record.checkpoint=="bannerfall" else "Vigil"
		var progress: String={"meet_mara":"Meet Mara","patrol":"Mill patrol","flour":"Recover flour","deliver":"Return to Anja","done":"Bread delivered"}[entry.record.quest]
		option("%s · %s · Level %d\nSafe refuge: %s · %s\n%s"%[entry.record.name,entry.record["class"].capitalize(),model.progress().level,refuge,progress,saved],func():game.continue_campaign(entry.id))
	option("EMPTY · Create a new campaign",func():page("characters"))
	if slots.size()>3: pagination(slot_page,ceili(slots.size()/3.0),func(value):slot_page=value;page("slots"))
	footer_button("Back",func():page("title"))
func build_settings() -> void:
	title_header("SETTINGS","Interface preferences are stored separately from campaign saves.")
	text("Presentation profile",18)
	var profiles:=OptionButton.new();profiles.custom_minimum_size.y=52
	for label in game.presentation.PROFILES: profiles.add_item(label)
	profiles.selected=game.presentation.override_profile
	profiles.item_selected.connect(func(index):game.presentation.override_profile=index;preferences.profile=index;preferences.save();game.update_presentation();relayout())
	content.add_child(profiles)
	option("Enable / Test Sound",game.test_sound)
	text(game.audio_status,14,Palette.MUTED)
	text("Master volume",18)
	var volume:=HSlider.new();volume.min_value=0;volume.max_value=1;volume.step=.05;volume.value=preferences.master;volume.custom_minimum_size.y=52;volume.value_changed.connect(func(value):preferences.master=value;AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.0001,value)));AudioServer.set_bus_mute(0,value==0);preferences.save());content.add_child(volume)
	text("The current build has one audio bus; separate music/effects controls are unavailable.",14,Palette.MUTED)
	text("Display mode",18);var display:=OptionButton.new();display.custom_minimum_size.y=52
	for label in ["Windowed","Borderless window","Fullscreen"]: display.add_item(label)
	display.selected=preferences.display;display.item_selected.connect(func(index):preferences.display=index;preferences.apply_audio_display();preferences.save());content.add_child(display)
	text("UI scale",18);var scale_option:=OptionButton.new();scale_option.name="UIScale";scale_option.custom_minimum_size.y=52
	for label in ["Compact · 85%","Standard · 100%","Large · 115%"]: scale_option.add_item(label)
	scale_option.selected=[.85,1.0,1.15].find(preferences.ui_scale);scale_option.item_selected.connect(func(index):preferences.ui_scale=[.85,1.0,1.15][index];preferences.save();relayout());content.add_child(scale_option)
	var touch:=CheckButton.new();touch.text="Show touch joystick";touch.custom_minimum_size.y=52;touch.button_pressed=game.show_touch;touch.toggled.connect(func(on):game.show_touch=on;preferences.touch=on;preferences.save());content.add_child(touch)
	settings_help=text("",15,Palette.MUTED);refresh_prompts()
	footer_button("Back",func():page(settings_return))
func character(which: String="Equipment", owner_id: String="") -> void:
	if owner_id.is_empty(): owner_id=sheet_character_id
	var context: Dictionary=game.campaign.character_context(owner_id)
	if context.is_empty(): context=game.campaign.character_context(game.campaign.data.character_id)
	if context.is_empty(): return
	sheet_character_id=context.id;game.campaign.data.selected_character_id=context.id
	character_tab=which;clear("equipment")
	var model=sheet_model();var progress: Dictionary=model.progress()
	title_header("%s · %s · Lv %d"%[model.data.name,model.data["class"].capitalize(),progress.level])
	character_switcher()
	var tabs:=HFlowContainer.new();content.add_child(tabs)
	for label in ["Equipment","Inventory","Stats","Talents","Story"]:
		var button:=Button.new();button.text=label;button.custom_minimum_size=Vector2(100,52);button.toggle_mode=true;button.button_pressed=label==which;button.pressed.connect(func():inventory("inventory") if label=="Inventory" else character(label));tabs.add_child(button)
	if which=="Talents": build_talents();footer_button("Close",close);return
	if which=="Story": build_biography();footer_button("Close",close);return
	if which=="Inventory": build_inventory();return
	if which=="Stats":
		stats_snapshot=model.stats().duplicate();text("CURRENT ATTRIBUTES",20,Palette.GOLD)
		var baseline=game.campaign.get_script().new();baseline.data=model.data.duplicate(true);baseline.data.equipped={};baseline.effects=model.effects
		var without_gear: Dictionary=baseline.stats()
		text("Totals include worn gear. Base includes class, level and current effects; gear is the final contribution:",14,Palette.MUTED)
		for stat in ["hp","defense","damage","speed"]: text("%s: %s base + %s gear = %s total"%[ItemPresenter.LABELS[stat],ItemPresenter.number(without_gear[stat]),ItemPresenter.number(stats_snapshot[stat]-without_gear[stat]),ItemPresenter.number(stats_snapshot[stat])],15)
		for key in ["hp","damage","defense","cooldown","speed","range","windup"]:
			text("%s     %s"%[{"hp":"Maximum health","damage":"Attack damage","defense":"Defense","cooldown":"Attack interval (seconds)","speed":"Movement speed","range":"Attack range","windup":"Attack windup (seconds)"}[key],str(stats_snapshot[key])],18)
		for key in ["strength","agility","intellect","vitality"]: text(key.capitalize()+"     "+str(stats_snapshot[key]),18)
		text("Gear attributes: Vitality gives 3 health; Agility gives 0.5 speed. Mage: Intellect gives 0.75 damage. Knight/Rogue: Strength gives 0.5 and Agility 0.2 damage. Base combat values and level growth are included above.",15,Palette.MUTED)
	else: build_equipment()
	footer_button("Close",close)
func equipment_card(slot_name: String) -> Button:
	var model=sheet_model()
	var id: String=model.data.equipped.get(slot_name,"")
	var button:=Button.new();button.name="Slot_"+slot_name;button.custom_minimum_size=Vector2(100 if window.size.x<650 else 150,52);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size",13)
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	var quiet:=StyleBoxEmpty.new();quiet.content_margin_left=4;quiet.content_margin_right=4;button.add_theme_stylebox_override("normal",quiet)
	button.text=model.Gear.LABELS[slot_name]+"\n"+(model.Gear.ITEMS[id].name if not id.is_empty() else "Empty")
	if slot_name=="offhand" and model.data.equipped.has("weapon") and model.Gear.ITEMS[model.data.equipped.weapon].hands==2: button.text="Off Hand\nReserved · two hands"
	button.icon=Palette.item_icon(id) if not id.is_empty() else load("res://assets/pass10/socket.png");button.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;button.expand_icon=true;button.add_theme_constant_override("icon_max_width",52)
	if not id.is_empty():
		button.add_theme_color_override("font_color",Palette.rarity(model.Gear.ITEMS[id].rarity));button.mouse_entered.connect(func():set_tooltip(id,slot_name,true));button.focus_entered.connect(func():set_tooltip(id,slot_name,true))
	button.mouse_exited.connect(func():
		if not popup_pinned: item_popup.hide())
	button.pressed.connect(func():
		if not id.is_empty(): equipped_item(slot_name)
		else: bag_filter=slot_name;inventory("inventory"))
	return button
func build_equipment() -> void:
	var live: Dictionary=sheet_model().stats()
	text("HP %d / %d · Defense %s · Damage %s · Speed %s"%[ceili(sheet_health()),live.hp,ItemPresenter.number(live.defense),ItemPresenter.number(live.damage),ItemPresenter.number(live.speed)],16)
	text("Strength %s · Agility %s · Intellect %s · Vitality %s"%[live.strength,live.agility,live.intellect,live.vitality],14,Palette.MUTED)
	if window.size.x<650:
		content.add_child(character_preview(200))
		var sockets:=GridContainer.new();sockets.columns=2;content.add_child(sockets)
		for slot_name in game.campaign.Gear.SLOTS: sockets.add_child(equipment_card(slot_name))
		option("Loadouts",loadout_menu)
	else:
		var board:=HBoxContainer.new();board.name="EquipmentBoard";board.add_theme_constant_override("separation",6);content.add_child(board)
		var left:=VBoxContainer.new();left.add_theme_constant_override("separation",4);left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;board.add_child(left)
		for slot_name in ["head","armor","hands","legs","feet"]: left.add_child(equipment_card(slot_name))
		board.add_child(character_preview(332))
		var right:=VBoxContainer.new();right.add_theme_constant_override("separation",4);right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;board.add_child(right)
		for slot_name in ["neck","ring1","accessory","weapon","offhand"]: right.add_child(equipment_card(slot_name))
		var loadout_button:=Button.new();loadout_button.text="Loadouts";loadout_button.custom_minimum_size.y=52;loadout_button.pressed.connect(loadout_menu);right.add_child(loadout_button)
	stats_snapshot=sheet_model().stats().duplicate()
	text("HP %d / %d   ·   Damage %.1f   ·   Defense %d   ·   Speed %d"%[ceili(sheet_health()),stats_snapshot.hp,stats_snapshot.damage,stats_snapshot.defense,stats_snapshot.speed],17)
	text("10 functional slots · equipment changes statistics, not the character sprite.",13,Palette.MUTED)
	recovery_notice()
	text("CARRIED EQUIPMENT · select to compare",15,Palette.GOLD)
	var strip:=HFlowContainer.new();content.add_child(strip)
	for i in range(game.campaign.data.inventory.size()):
		var id: String=game.campaign.data.inventory[i].id
		var b:=Button.new();b.custom_minimum_size=Vector2(58,58);b.icon=Palette.item_icon(id);b.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;b.expand_icon=true;b.add_theme_constant_override("icon_max_width",52);b.tooltip_text=game.campaign.Gear.ITEMS[id].name;b.pressed.connect(func():bag_mode="inventory";inspect_item(id,i,"inventory"));strip.add_child(b)
func loadout_menu() -> void:
	clear("loadouts");title_header("EQUIPMENT LOADOUTS","Presets use carried and equipped items. Stash items must be withdrawn first.")
	var model=sheet_model();var expected: int=model.revision
	for i in range(model.data.loadouts.size()):
		var preset: Dictionary=model.data.loadouts[i]
		var label:=LineEdit.new();label.text=preset.name;label.max_length=24;label.custom_minimum_size.y=52;content.add_child(label)
		text("%d / 10 slots recorded"%preset.items.size(),14,Palette.MUTED)
		var references:=HFlowContainer.new();content.add_child(references)
		for slot_name in preset.items:
			var id: String=preset.items[slot_name];var item_button:=Button.new();item_button.text=model.Gear.LABELS[slot_name];item_button.custom_minimum_size.y=52;item_button.icon=Palette.item_icon(id);item_button.expand_icon=true;item_button.add_theme_constant_override("icon_max_width",32);references.add_child(item_button);item_button.pressed.connect(func():show_item_popup(id,slot_name,false,true))
		row_buttons(["Apply "+preset.name,"Save current gear","Rename"],[func():loadout_action(func():return model.apply_loadout(i),expected),func():loadout_action(func():return model.save_loadout(i,label.text),expected),func():loadout_action(func():return model.rename_loadout(i,label.text),expected)])
	footer_button("Back",func():character("Equipment"))
func loadout_action(action: Callable, expected: int) -> void:
	if expected!=game.campaign.revision: loadout_menu();return
	var ok: bool=action.call();game.refresh_stats();game.persist();loadout_menu()
	text("Loadout updated." if ok else game.campaign.gear_error,16,Palette.GOLD)
func inventory_controls() -> void:
	var row:=HFlowContainer.new();content.add_child(row)
	var sort:=OptionButton.new();sort.custom_minimum_size=Vector2(140,52)
	sort.tooltip_text="Power is a class-weighted sorting estimate. Compare actual derived stats before equipping."
	for label in ["name","category","rarity","power"]: sort.add_item("Sort: "+label.capitalize())
	sort.selected=["name","category","rarity","power"].find(bag_sort);sort.item_selected.connect(func(i):bag_sort=["name","category","rarity","power"][i];inventory(bag_mode));row.add_child(sort)
	var filter:=OptionButton.new();filter.custom_minimum_size=Vector2(140,52);filter.add_item("All slots")
	for slot_name in game.campaign.Gear.SLOTS: filter.add_item(game.campaign.Gear.LABELS[slot_name])
	filter.selected=game.campaign.Gear.SLOTS.find(bag_filter)+1;filter.item_selected.connect(func(i):bag_filter="" if i==0 else game.campaign.Gear.SLOTS[i-1];inventory(bag_mode));row.add_child(filter)
	var classes:=CheckButton.new();classes.text="Usable by class";classes.custom_minimum_size.y=52;classes.button_pressed=compatible_only;classes.toggled.connect(func(on):compatible_only=on;inventory(bag_mode));row.add_child(classes)
func inventory(mode: String, reset:=true) -> void:
	if mode in ["stash","shop","recovery"] and not game.at_camp_service(): mode="inventory"
	if reset: bag_page=0
	bag_mode=mode;character("Inventory")
func build_inventory() -> void:
	inventory_builds+=1;var model=sheet_model()
	recovery_notice()
	var built_revision: int=model.revision
	if game.at_camp_service(): row_buttons(["Backpack","Stash","Supplies"],[func():inventory("inventory"),func():inventory("stash"),func():inventory("shop")])
	else: text("Stash and trading are available at Vigil's chest and supply table.",14,Palette.MUTED)
	var list: Array=model.data.recovery if bag_mode=="recovery" else (model.data.stash if bag_mode=="stash" else (model.Gear.SHOP.filter(func(id):return model.Gear.allowed(id,model.data["class"])) if bag_mode=="shop" else model.data.inventory))
	inventory_controls()
	var view: Array=[]
	if bag_mode=="shop":
		var catalog: Dictionary=model.data.duplicate(false);catalog.inventory=list.map(func(id):return {"id":id,"count":1})
		view=model.Rules.indices(catalog,"inventory",bag_sort,bag_filter,compatible_only)
	else: view=model.Rules.indices(model.data,bag_mode,bag_sort,bag_filter,compatible_only)
	var capacity: int=model.Migration.RECOVERY_CAPACITY if bag_mode=="recovery" else (model.Gear.STASH_CAPACITY if bag_mode=="stash" else (list.size() if bag_mode=="shop" else model.Gear.CAPACITY))
	text({"inventory":"BACKPACK","stash":"PROTECTED STASH","shop":"CAMP SUPPLIES","recovery":"MIGRATION RECOVERY"}[bag_mode]+" · %d / %d · %d coins"%[list.size(),capacity,model.data.gold],18,Palette.GOLD)
	grid=GridContainer.new();grid.columns=2 if window.size.x<560 else (4 if window.size.x<850 else 6);grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);content.add_child(grid)
	var display_capacity: int=capacity if bag_filter.is_empty() and not compatible_only else view.size()
	bag_page=clampi(bag_page,0,maxi(0,ceili(display_capacity/12.0)-1))
	for cell in range(bag_page*12,mini(display_capacity,bag_page*12+12)):
		var button:=Button.new();button.custom_minimum_size=Vector2(98,84);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.add_theme_font_size_override("font_size",14);grid.add_child(button)
		if cell>=view.size(): button.text="—\nEmpty";button.disabled=true;continue
		var index: int=view[cell]
		var id: String=list[index] if bag_mode=="shop" else list[index].id;var item: Dictionary=model.Gear.ITEMS[id]
		button.text=item.name+"\n"+("%d coins"%(item.value*2) if bag_mode=="shop" else "×%d"%list[index].count)+(" · Equipped" if id in model.data.equipped.values() else "")
		button.text+=(" · F" if id in model.data.favorites else "")+(" · L" if id in model.data.locks else "")
		button.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;button.icon=Palette.item_icon(id);button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;button.expand_icon=true;button.add_theme_constant_override("icon_max_width",40);button.add_theme_color_override("font_color",Palette.rarity(item.rarity))
		button.mouse_entered.connect(func():set_tooltip(id));button.focus_entered.connect(func():set_tooltip(id));button.pressed.connect(func():inspect_item(id,index,bag_mode))
		button.mouse_exited.connect(func():
			if not popup_pinned: item_popup.hide())
		button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT and bag_mode=="inventory": apply_inventory(func():return model.equip(index),built_revision))
	if display_capacity>12: pagination(bag_page,ceili(display_capacity/12.0),func(value):bag_page=value;inventory(bag_mode,false))
	if game.at_camp_service(): footer_button("Rest",func():game.hero.health=game.hero.max_health;notify("Rested and ready.");close())
	ownership_list()
	tooltip_panel.show();tooltip_label.text="Hover or focus an item for comparison. Select for actions; right-click to Quick Equip.\nE = equipped copy · F = favorite · L = locked (all copies)."
	footer_button("Close",close)
func dialogue(p: Dictionary, body: String, choices: Array=[]) -> void:
	if choices.is_empty() and body.length()<130 and p.get("kind","")=="boy":
		bubble.text=str(p.name)+"\n"+body;bubble_position=p.pos;bubble_time=5;return
	clear("dialogue");veil.hide();relayout()
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);content.add_child(line)
	var portrait_path: String="res://assets/"+str(p.get("kind",""))+"_portrait.png"
	if ResourceLoader.exists(portrait_path):
		var portrait:=TextureRect.new();portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;portrait.texture=load(portrait_path);portrait.custom_minimum_size=Vector2(56,64);portrait.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(portrait)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(words)
	var speaker:=Label.new();speaker.text=p.name;speaker.add_theme_font_size_override("font_size",18);speaker.add_theme_color_override("font_color",Palette.GOLD);words.add_child(speaker)
	var speech:=Label.new();speech.text=body;speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;speech.add_theme_font_size_override("font_size",16);speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_child(speech)
	for choice in choices:
		var button:=option(choice.label,func():
			if choice.get("action") is Callable: choice.action.call()
			if choice.has("next"): dialogue(p,choice.next,choice.get("choices",[]))
			else: close(),choice.get("disabled",false))
		button.custom_minimum_size.y=44
	var done:=footer_button("Continue" if choices.is_empty() else "Leave",close)
	if choices.is_empty(): done.grab_focus()
	else: focus_first()
func notify(value: String) -> void: toast_action.clear();toast.text=value;toast_time=5
func notify_action(prefix: String, action: String, shortcut: String) -> void:
	toast_action.assign([prefix,action,shortcut]);toast_time=5;refresh_prompts()
func update_label(label: Label, value: String) -> void:
	if label.text!=value: label.text=value
func _process(delta: float) -> void:
	hud_clock+=delta
	if hud_clock<.05: return
	delta=hud_clock;hud_clock=0;hud_updates+=1
	if not is_instance_valid(game.hero): return
	status_strip.refresh()
	minimap.refresh()
	if game.presentation.profile!="Phone": objective_label.position.y=128 if status_strip.effects.is_empty() else status_strip.position.y+status_strip.size.y+4
	update_label(save_warning,game.campaign.error if not game.campaign.error.is_empty() else preferences.error)
	if is_instance_valid(bubble):
		bubble_time=maxf(0,bubble_time-delta);bubble.visible=bubble_time>0 and not game.menu_open
		bubble.size=Vector2(minf(260,ui_size.x-36),80)
		bubble.position=((get_viewport().get_canvas_transform()*bubble_position-root.position)/root.scale-Vector2(bubble.size.x/2,160)).clamp(Vector2(18,18),ui_size-bubble.size-Vector2(18,18))
		if Rect2(bubble.position,bubble.size).intersects(Rect2(hud.position,hud.size)):
			bubble.position.y=minf(ui_size.y-bubble.size.y-18,hud.position.y+hud.size.y+8)
	refresh_prompts()
	if game.menu_open: return
	for i in range(2):
		ability_buttons[i].visible=not game.menu_open
	if not game.menu_open:
		update_label(objective_label,game.objective());update_label(status,("%s · %s\n%d / %d" if game.presentation.profile=="Phone" else "%s · %s\n%d / %d health")%[game.campaign.data.name,game.selected.capitalize(),ceili(game.hero.health),game.hero.max_health])
		health.max_value=game.hero.max_health;health.value=game.hero.health
		update_label(target_label,(game.enemy_ai.DATA[game.target.role].name+"\n%d / %d"%[ceili(game.target.health),game.target.max_health]) if is_instance_valid(game.target) else "")
		var nearby: Dictionary=game.nearby_interaction()
		if not is_instance_valid(game.target) and nearby.get("kind","")=="exit": update_label(target_label,str(nearby.name)+"\n"+game.presentation.action_prompt("Travel","E"))
		toast_time=maxf(0,toast_time-delta)
	if toast_time<=0: toast.text=""
func occlusion_rects() -> Array[Rect2]:
	var result: Array[Rect2]=[]
	if minimap.visible: result.append(minimap.get_global_rect())
	for control in [hud,objective_label,target_label,menu_button,character_button,interact_button,attack_button,controls]+ability_buttons:
		if control.visible: result.append(control.get_global_rect().grow(4))
	if toast.visible and toast_time>0: result.append(toast.get_global_rect())
	if status_strip.visible:
		for button in status_strip.buttons.values():
			if button.visible: result.append(button.get_global_rect())
		if status_strip.detail.visible: result.append(status_strip.detail.get_global_rect())
	return result

func toggle_character() -> void:
	if not game.started or game.fallen: return
	if game.menu_open and page_id in ["equipment","loadouts"]: close()
	else: character("Equipment")
func _input(event: InputEvent) -> void:
	if game.presentation.observe(event): relayout()
	if status_strip.consume(event): get_viewport().set_input_as_handled();return
	if minimap.consume(event): get_viewport().set_input_as_handled();return
	if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch:
		last_pointer_position=event.position
		if event is InputEventMouseButton and event.pressed and not popup_pinned: hide_item_popup()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE and item_popup.visible:
			hide_item_popup();get_viewport().set_input_as_handled();return
		var typing: bool=get_viewport().gui_get_focus_owner() is LineEdit
		if event.keycode==KEY_C and not typing and game.started and not game.fallen:
			toggle_character();get_viewport().set_input_as_handled();return
	if event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION and not game.menu_open:
		get_viewport().set_input_as_handled();return
	if event is InputEventScreenDrag and (combat_touches.has(event.index) or event.index==game.touch_id):
		if event.index==game.touch_id: game.joystick=((event.position-game.touch_origin)/65).limit_length()
		get_viewport().set_input_as_handled();return
	# Combat controls explicitly support touch even on platforms without mouse emulation.
	if not event is InputEventScreenTouch: return
	if not event.pressed and combat_touches.has(event.index):
		var button: Button=combat_touches[event.index];combat_touches.erase(event.index)
		button.button_up.emit()
		if not event.canceled and not game.menu_open and not button.disabled and button.get_global_rect().has_point(event.position): button.pressed.emit()
		get_viewport().set_input_as_handled();return
	if game.menu_open or not event.pressed: return
	if event.index==game.touch_id: get_viewport().set_input_as_handled();return
	var buttons: Array[Button]=ability_buttons.duplicate();buttons.append(attack_button);buttons.append(character_button);buttons.append(menu_button);buttons.append(interact_button)
	for button in buttons:
		if button.visible and button.get_global_rect().has_point(event.position):
			if not button.disabled and not combat_touches.values().has(button): combat_touches[event.index]=button;button.button_down.emit()
			get_viewport().set_input_as_handled();return
	if hud.visible and hud.get_global_rect().has_point(event.position): get_viewport().set_input_as_handled()


func build_item_popup() -> void:
	popup_wrapper=Control.new();popup_wrapper.mouse_filter=Control.MOUSE_FILTER_IGNORE;window.add_child(popup_wrapper)
	item_popup=PanelContainer.new();item_popup.set_script(load("res://scripts/ui_frame.gd"));item_popup.add_theme_stylebox_override("panel",Palette.panel(Color("101820"),12,Palette.GOLD));popup_wrapper.add_child(item_popup)
	var frame:=StyleBoxTexture.new();frame.texture=load("res://assets/pass10/socket.png")
	frame.draw_center=false;frame.axis_stretch_horizontal=StyleBoxTexture.AXIS_STRETCH_MODE_TILE;frame.axis_stretch_vertical=StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: frame.set_texture_margin(side,12);frame.set_content_margin(side,14)
	item_popup.add_theme_stylebox_override("panel",frame)
	item_popup.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var backing:=ColorRect.new();backing.color=Color("101820");backing.mouse_filter=Control.MOUSE_FILTER_IGNORE;item_popup.add_child(backing)
	var box:=VBoxContainer.new();item_popup.add_child(box)
	popup_scroll=ScrollContainer.new();popup_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;popup_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(popup_scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;popup_scroll.add_child(body)
	popup_icon=TextureRect.new();popup_icon.custom_minimum_size=Vector2(64,64);popup_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;popup_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;popup_icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;body.add_child(popup_icon)
	popup_label=RichTextLabel.new();popup_label.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;popup_label.fit_content=true;popup_label.scroll_active=false;popup_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;popup_label.add_theme_font_size_override("normal_font_size",14);body.add_child(popup_label)
	for i in range(12):
		var button:=Button.new();button.custom_minimum_size.y=52;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.pressed.connect(func():popup_callbacks[i].call());body.add_child(button);popup_actions.append(button);popup_callbacks.append(func():pass);button.hide()
		if i==0: body.move_child(button,1)
	var dismiss:=Button.new();dismiss.text="Close item";dismiss.custom_minimum_size.y=52;dismiss.pressed.connect(hide_item_popup);box.add_child(dismiss)
	item_popup.hide()
func hide_item_popup() -> void:
	popup_pinned=false
	if is_instance_valid(item_popup): item_popup.hide()
func position_item_popup() -> void:
	item_popup.size=Vector2(minf(460,window.size.x-48),minf(560,window.size.y-48))
	var available: Vector2=window.size-Vector2(40,40)
	var candidate: Vector2=popup_anchor+Vector2(18,10)
	if candidate.x+item_popup.size.x>available.x: candidate.x=popup_anchor.x-item_popup.size.x-18
	item_popup.position=Vector2(clampf(candidate.x,0,maxf(0,available.x-item_popup.size.x)),clampf(candidate.y,0,maxf(0,available.y-item_popup.size.y)))
func show_item_popup(id: String, target: String, worn: bool, pinned: bool) -> void:
	popup_pinned=pinned;popup_count=0
	item_popup.mouse_behavior_recursive=Control.MOUSE_BEHAVIOR_ENABLED if pinned else Control.MOUSE_BEHAVIOR_DISABLED
	for b in popup_actions: b.hide()
	for i in range(1,popup_actions.size()): popup_actions[i].get_parent().move_child(popup_actions[i],-1)
	popup_anchor=popup_wrapper.get_global_transform_with_canvas().affine_inverse()*last_pointer_position if last_pointer_position.x>=0 else Vector2.ZERO
	popup_icon.texture=Palette.item_icon(id)
	var description: String=ItemPresenter.describe(sheet_model(),id,target,worn)
	popup_label.clear()
	var lines: PackedStringArray=description.split("\n")
	for i in range(lines.size()):
		var line: String=lines[i];var color: Color=Palette.PAPER
		if i==0: color=Palette.rarity(game.campaign.Gear.ITEMS[id].rarity)
		elif " → " in line: color=Color("8ecf9c") if "(+" in line else Color("ef9a91")
		elif line in ["DIRECT ITEM BONUSES","FINAL CHARACTER CHANGES"]: color=Palette.GOLD
		popup_label.push_color(color);popup_label.add_text(line+("\n" if i<lines.size()-1 else ""));popup_label.pop()
	popup_scroll.scroll_vertical=0;position_item_popup();item_popup.show()
func popup_option(label: String, action: Callable, disabled:=false) -> void:
	var button: Button=popup_actions[popup_count];button.text=label;button.disabled=disabled;popup_callbacks[popup_count]=action;button.show();popup_count+=1
	if label.begins_with("Compare in "): button.get_parent().move_child(button,2)
func inspect_item(id: String, index: int, mode: String, target: String="") -> void:
	bag_mode=mode
	var model=sheet_model();var item: Dictionary=model.Gear.ITEMS[id];var expected: int=model.revision
	if target.is_empty(): target=model.Rules.target_slot(id,model.data.equipped)
	show_item_popup(id,target,false,true)
	if mode=="shop":
		popup_option("Buy one · %d coins"%(item.value*2),func():confirm_transaction("Buy "+item.name+" for %d coins?"%(item.value*2),func():return model.buy(id),expected))
	elif mode=="recovery": popup_option("Recover one to backpack",func():apply_inventory(func():return model.recover_item(index),expected))
	elif mode=="stash": popup_option("Withdraw one",func():apply_inventory(func():return model.transfer(index,false),expected))
	else:
		if not item.slot.is_empty():
			popup_option("Equip · "+model.Gear.LABELS[target]+(" · Requires "+", ".join(item.classes) if not model.Gear.allowed(id,model.data["class"]) else ""),func():apply_inventory(func():return model.equip(index,target),expected),not model.Gear.allowed(id,model.data["class"]))
			for alternative in item.slots:
				if alternative!=target: popup_option("Compare in "+model.Gear.LABELS[alternative],func():inspect_item(id,index,mode,alternative))
		popup_option("Unfavorite" if id in model.data.favorites else "Favorite",func():apply_inventory(func():return model.toggle_flag(id,"favorites"),expected))
		popup_option("Unlock" if id in model.data.locks else "Lock against sale",func():apply_inventory(func():return model.toggle_flag(id,"locks"),expected))
		if id=="tonic" and sheet_character_id==game.campaign.data.character_id: popup_option("Drink · "+("Already at full health" if game.hero.health>=game.hero.max_health else "restore 60 health"),func():apply_inventory(func():return game.use_tonic(index),expected),game.hero.health>=game.hero.max_health)
		if game.at_camp_service():
			popup_option("Deposit one in stash",func():apply_inventory(func():return model.transfer(index,true),expected))
			popup_option("Sell one · %d coins"%item.value,func():confirm_transaction("Sell one "+item.name+" for %d coins?"%item.value,func():return model.sell(index),expected))
func equipped_item(slot_name: String) -> void:
	var model=sheet_model()
	if not model.data.equipped.has(slot_name): return
	bag_mode="inventory"
	var id: String=model.data.equipped[slot_name];var expected: int=model.revision
	show_item_popup(id,slot_name,true,true)
	popup_option("Unequip to backpack",func():apply_inventory(func():return model.unequip(slot_name),expected))

func confirm_transaction(message: String, action: Callable, expected: int) -> void:
	clear("transaction");text(message,24);text("Your balance: %d coins"%game.campaign.data.gold)
	option("Confirm",func():apply_inventory(action,expected))
	footer_button("Cancel",func():inventory(bag_mode,false))

func apply_inventory(action: Callable, expected: int) -> void:
	# A stale button/confirmation cannot operate on an index changed by another click.
	if expected!=game.campaign.revision: inventory(bag_mode,false);return
	if bag_mode in ["stash","shop","recovery"] and not game.at_camp_service(): inventory("inventory");return
	var was_equipment: bool=page_id=="equipment" and character_tab=="Equipment"
	var ok: bool=action.call()
	game.refresh_stats();game.persist()
	if was_equipment: character("Equipment")
	else: inventory(bag_mode,false)
	if ok: tooltip_label.text="Inventory updated. Select an item to inspect its current comparison."
	if not ok: text(game.campaign.gear_error if not game.campaign.gear_error.is_empty() else "Unable to complete: check space, ownership, class and coins.",16,Color("f1aa8b"))


func pagination(current: int, total: int, changed: Callable) -> void:
	var row:=HBoxContainer.new();content.add_child(row)
	var previous:=Button.new();previous.text="Previous";previous.custom_minimum_size=Vector2(120,52);previous.disabled=current==0;previous.pressed.connect(func():changed.call(current-1));row.add_child(previous)
	var label:=Label.new();label.text="%d / %d"%[current+1,total];label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
	var next:=Button.new();next.text="Next";next.custom_minimum_size=Vector2(120,52);next.disabled=current>=total-1;next.pressed.connect(func():changed.call(current+1));row.add_child(next)

func character_preview(height: float) -> Control:
	var center:=Control.new();center.mouse_filter=Control.MOUSE_FILTER_PASS;center.custom_minimum_size=Vector2(140,height);center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var alcove:=TextureRect.new();alcove.texture=load("res://assets/pass10/alcove.png");alcove.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;alcove.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;center.add_child(alcove);alcove.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);alcove.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var portrait:=TextureRect.new();portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;portrait.texture=load("res://assets/pass10/%s-preview.png"%(sheet_model().data["class"] if sheet_model().data["class"] in ["knight","mage","rogue"] else "knight"));portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;center.add_child(portrait);portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);portrait.offset_left=20;portrait.offset_right=-20;portrait.offset_top=height*.2;portrait.offset_bottom=-height*.1;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return center
func recovery_notice() -> void:
	var count: int=game.campaign.data.get("recovery",[]).size()
	if count==0: return
	text("Migration Recovery: %d protected items. Collect at Vigil; these provide no equipped stats."%count,14,Palette.GOLD)
	if game.at_camp_service(): option("Open Migration Recovery",func():inventory("recovery"))

func sheet_model() -> RefCounted:
	var context: Dictionary=game.campaign.character_context(sheet_character_id)
	return game.campaign if context.is_empty() else context.model
func sheet_health() -> float:
	return game.hero.health if sheet_character_id==game.campaign.data.character_id else float(sheet_model().data.health)
func character_switcher() -> void:
	var row:=HFlowContainer.new();content.add_child(row)
	var select:=OptionButton.new();select.name="CharacterSelector";select.fit_to_longest_item=false;select.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;select.custom_minimum_size=Vector2(minf(280,window.size.x-48),52);row.add_child(select)
	var identities: Array=game.campaign.Party.ids(game.campaign.data)
	for id in identities:
		var record: Dictionary=game.campaign.Party.record_for(game.campaign.data,id)
		select.add_item(record.name+(" · Protagonist" if id==game.campaign.data.character_id else " · Reserve" if id in game.campaign.data.reserve_roster else " · Active"))
	select.selected=identities.find(sheet_character_id);select.item_selected.connect(func(index):character(character_tab,identities[index]))
	var roster_button:=Button.new();roster_button.text="Party roster";roster_button.custom_minimum_size.y=52;roster_button.pressed.connect(party_menu);row.add_child(roster_button)
func party_menu() -> void:
	clear("party");title_header("THE COMPANY","Six active positions · shared backpack · individual journeys")
	text("Reorder and move companions at Vigil Camp." if party_safe() else "Inspect freely. Party changes require Vigil Camp.",15,Palette.MUTED)
	text("ACTIVE PARTY",20,Palette.GOLD)
	var positions:=GridContainer.new();positions.columns=3 if window.size.x>=900 else (2 if window.size.x>=600 else 1);positions.add_theme_constant_override("h_separation",10);positions.add_theme_constant_override("v_separation",10);content.add_child(positions)
	for i in range(6): roster_card(game.campaign.data.active_party[i],i,positions)
	text("RESERVE ROSTER",20,Palette.GOLD)
	if game.campaign.data.reserve_roster.is_empty(): text("No recruited reserve companions.",16,Palette.MUTED)
	for id in game.campaign.data.reserve_roster: roster_card(id,-1)
	text("Empty positions remain empty until companions are recruited. Mara is a camp story character, not an automatic combat companion.",14,Palette.MUTED)
	footer_button("Close",close)
func roster_card(identity: String,position: int,host: Node=null) -> void:
	var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	(host if host!=null else content).add_child(card)
	if identity.is_empty():
		var empty:=option("Position %d · Empty"%(position+1),func():pass,true);empty.name="PartyPosition_%d"%position;empty.reparent(card);empty.custom_minimum_size.y=108;return
	var model=game.campaign.character_context(identity).model;var record: Dictionary=model.data
	var evolved: Dictionary=game.campaign.Classes.evolution(record)
	var title: String=("Position %d"%(position+1) if position>=0 else "Reserve")+" · "+record.name
	title+=" · Protagonist" if identity==game.campaign.data.character_id else ""
	title+="\n%s · %s · Lv %d · HP %d/%d\n%s\n%s"%[record["class"].capitalize(),evolved.title,model.progress().level,game.hero.health if identity==game.campaign.data.character_id else record.health,model.stats().hp,game.campaign.Classes.CLASSES[record["class"]].role,"Available" if record.availability.available else record.availability.reason]
	var button:=option(title,func():character("Equipment",identity));button.name="PartyPosition_%d"%position if position>=0 else "Reserve_"+identity;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=108;button.toggle_mode=true;button.button_pressed=identity==sheet_character_id;button.reparent(card)
	if record["class"] in ["knight","mage","rogue"]: button.icon=load("res://assets/pass10/%s-preview.png"%record["class"]);button.expand_icon=true;button.add_theme_constant_override("icon_max_width",72)
	var manage:=option("Manage position · "+record.name,func():roster_positions(identity),not party_safe() or not record.availability.available);manage.reparent(card)
func roster_positions(identity: String) -> void:
	clear("party_positions");var record: Dictionary=game.campaign.Party.record_for(game.campaign.data,identity);title_header("POSITION · "+record.name,"Occupied positions swap with active members. Moving a reserve into an occupied position reserves its previous occupant.")
	for i in range(6):
		var occupant: String=game.campaign.data.active_party[i]
		option("Position %d · %s"%[i+1,"Empty" if occupant.is_empty() else game.campaign.Party.record_for(game.campaign.data,occupant).name],func():move_party(identity,i))
	option("Move to reserve",func():move_party(identity,-1),identity==game.campaign.data.character_id or identity in game.campaign.data.reserve_roster)
	footer_button("Back",party_menu)
func move_party(identity: String,position: int) -> void:
	var ok: bool=game.campaign.roster_change(identity,position,party_safe());game.persist();party_menu()
	if not ok: text(game.campaign.gear_error,16,Palette.GOLD)
func build_biography() -> void:
	var record: Dictionary=sheet_model().data
	text("BIOGRAPHY",20,Palette.GOLD);text(record.biography)
	text("PERSONAL QUESTS",20,Palette.GOLD)
	if record.personal_quests.is_empty(): text("No personal quest recorded.",16,Palette.MUTED)
	for id in record.personal_quests: text(str(id)+": "+str(record.personal_quests[id]),16)
	text("Availability: "+("Available" if record.availability.available else record.availability.reason),16)
	text("Dialogue foundations: "+", ".join(game.campaign.Classes.CLASSES[record["class"]].dialogue_proficiencies),16)
	text("Dialogue checks and companion recruitment stories are planned; no rolls or invented companion stories are active.",14,Palette.MUTED)
func build_talents() -> void:
	var classes=game.campaign.Classes;var record: Dictionary=sheet_model().data;var evolution: Dictionary=classes.evolution(record)
	text("%s · Stage %d · %d points available"%[evolution.title,evolution.stage,classes.points(record)],20,Palette.GOLD)
	text("Earn one point per level after level 1. Learn connected talents to develop your class identity. Highest eligible stage wins; hybrids take priority, then stable title ID breaks ties. Names are provisional.",14,Palette.MUTED)
	if not classes.nodes(record["class"]).is_empty():
		var graph:=Control.new();graph.set_script(load("res://scripts/talent_graph.gd"));graph.record=record;graph.learned=learn_talent;content.add_child(graph)
	for branch in ["a","b","cross"]:
		text(classes.CLASSES[record["class"]].branches.get(branch,"Connected branches"),20,Palette.GOLD)
		for entry in classes.nodes(record["class"]):
			if entry.branch!=branch: continue
			var rank:=int(record.talents.get(entry.id,0));var reason: String=classes.spend_error(record,entry.id);var req: PackedStringArray=[]
			for id in entry.requires: req.append("%s %d/%d"%[classes.node(record["class"],id).name,record.talents.get(id,0),entry.requires[id]])
			var effects: PackedStringArray=[]
			for key in entry.mods: effects.append(ItemPresenter.LABELS[key]+" "+ItemPresenter.signed(entry.mods[key])+" per rank")
			text(("Root" if req.is_empty() else "Requires → "+" + ".join(req))+"\n"+", ".join(effects),14,Palette.MUTED)
			var button:=option("%s · %d/%d · %s"%[entry.name,rank,entry.max_rank,"Learn rank" if reason.is_empty() else ("Learned" if rank==int(entry.max_rank) else "Locked: "+reason)],func():learn_talent(entry.id),not reason.is_empty());button.name="TalentDetail_"+entry.id;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text("EVOLUTION PROGRESS",20,Palette.GOLD)
	for entry in classes.CLASSES[record["class"]].evolutions:
		if entry.enabled: text("Stage %d · %s · %s\n%s"%[entry.stage,entry.title,"Eligible" if classes.qualifies(record,entry) else "Developing",classes.requirement_text(record,entry)],15,Palette.GOLD if classes.qualifies(record,entry) else Palette.MUTED)
	if party_safe(): option("Reset talents at Vigil",func():clear("respec");text("Refund all learned talent ranks? Class identity will be recalculated; equipment and XP stay owned.");option("Confirm reset",func():game.campaign.reset_talents(sheet_character_id,party_safe());game.refresh_stats();game.persist();character("Talents"));footer_button("Cancel",func():character("Talents")))
func learn_talent(id: String) -> void:
	game.campaign.spend_talent(sheet_character_id,id);game.refresh_stats();game.persist();character("Talents")
func ownership_list() -> void:
	var found:=false
	for id in game.campaign.Party.ids(game.campaign.data):
		if id==sheet_character_id: continue
		var record: Dictionary=game.campaign.Party.record_for(game.campaign.data,id)
		for slot_name in record.equipped:
			if not found: text("EQUIPPED BY OTHER CHARACTERS",16,Palette.GOLD);found=true
			var item: String=record.equipped[slot_name]
			option(record.name+" · "+game.campaign.Gear.ITEMS[item].name,func():owned_item_popup(id,slot_name))
func owned_item_popup(source_id: String,slot_name: String) -> void:
	var source: Dictionary=game.campaign.Party.record_for(game.campaign.data,source_id);var item: String=source.equipped[slot_name];var expected: int=game.campaign.revision
	show_item_popup(item,slot_name,false,true)
	popup_label.add_text("\nOwned equipment: currently worn by "+source.name+". Transfer removes it from that character.")
	popup_option("Transfer to "+sheet_model().data.name,func():apply_inventory(func():return game.campaign.transfer_equipped(source_id,sheet_character_id,slot_name),expected),not game.campaign.Rules.fits(item,slot_name,sheet_model().data["class"]))

func party_safe() -> bool:
	return is_instance_valid(game.area) and game.area.area_id=="vigil" and not game.fallen
