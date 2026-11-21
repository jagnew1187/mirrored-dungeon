extends Control
## Read-only presentation of existing ability state. No effects or timers live here.
var game: Node
var buttons: Dictionary={}
var effects: Array[Dictionary]=[]
var detail: PanelContainer
var words: Label
var selected:=""
var pinned:=false
var fingers: Dictionary={}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for id in ["guard","dash"]:
		var button:=Button.new();button.set_script(load("res://scripts/status_symbol.gd"));button.effect_id=id
		button.focus_mode=Control.FOCUS_NONE;button.flat=true;button.size=Vector2(44,44);add_child(button);buttons[id]=button
		button.pressed.connect(func():inspect(id,true))
		button.hide()
	detail=PanelContainer.new();detail.mouse_filter=Control.MOUSE_FILTER_STOP
	var frame=preload("res://scripts/ui_theme.gd").panel(Color("151c20"),10);frame.set_border_width_all(1)
	detail.add_theme_stylebox_override("panel",frame);add_child(detail)
	words=Label.new();words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_theme_font_size_override("font_size",14);detail.add_child(words);detail.hide()

func snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if game.abilities.guard>0:
		var data: Dictionary=game.abilities.DATA.knight[0]
		result.append({"id":"guard","name":data.name,"description":"Incoming damage reduced by %d%%."%roundi(data.reduction*100),"remaining":game.abilities.guard,"source":"Knight · Shield Guard"})
	if game.abilities.dash>0:
		var data: Dictionary=game.abilities.DATA.rogue[0]
		result.append({"id":"dash","name":data.name,"description":"Directional movement at %d units/s."%data.speed,"remaining":game.abilities.dash,"source":"Rogue · Evasive Step"})
	return result

func refresh() -> void:
	effects=snapshot();visible=not game.menu_open
	for button in buttons.values(): button.hide()
	var index:=0
	var hit: float=44.0/game.overlay.preferences.ui_scale
	for effect in effects:
		var button: Button=buttons[effect.id];button.size=Vector2.ONE*maxf(44,hit);button.position=Vector2(index*(button.size.x+4),0);button.show();index+=1
	size=Vector2(index*(maxf(44,hit)+4),maxf(44,hit))
	if game.menu_open or not effects.any(func(effect):return effect.id==selected): dismiss()
	elif not selected.is_empty(): update_detail()

func inspect(id: String, pin: bool) -> void:
	effects=snapshot()
	if game.menu_open or not effects.any(func(effect):return effect.id==id): return
	selected=id;pinned=pin;update_detail();detail.show()

func update_detail() -> void:
	for effect in effects:
		if effect.id!=selected: continue
		words.text="%s\n%s\nRemaining: %.1fs\nSource: %s"%[effect.name,effect.description,effect.remaining,effect.source]
		var extent: Vector2=game.overlay.ui_size
		detail.size=Vector2(minf(270,extent.x-32),0)
		# Coordinates are relative to this strip, which already follows safe-area/UI scale.
		var desired:=position+Vector2(0,size.y+4)
		desired.x=clampf(desired.x,16,maxf(16,extent.x-detail.size.x-16))
		desired.y=clampf(desired.y,16,maxf(16,extent.y-detail.get_combined_minimum_size().y-16))
		detail.position=desired-position

func dismiss() -> void:
	selected="";pinned=false
	if is_instance_valid(detail): detail.hide()

func consume(event: InputEvent) -> bool:
	# Touch-generated mouse events must not dismiss the card before its real
	# touch event can claim the pointer and consume the eventual release.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION: return false
	if event is InputEventMouseMotion and not game.menu_open and not game.presentation.touch_mode:
		for id in buttons:
			if buttons[id].visible and buttons[id].get_global_rect().has_point(event.position): inspect(id,false);return false
		if not pinned: dismiss()
	if event is InputEventScreenTouch:
		if not event.pressed and fingers.has(event.index):
			var id: String=fingers[event.index];fingers.erase(event.index)
			if not event.canceled and buttons.has(id) and buttons[id].visible and buttons[id].get_global_rect().has_point(event.position): inspect(id,true)
			return true
		if not event.pressed or game.menu_open: return false
		for id in buttons:
			if visible and buttons[id].visible and buttons[id].get_global_rect().has_point(event.position): fingers[event.index]=id;return true
		if detail.visible and detail.get_global_rect().has_point(event.position): fingers[event.index]="";return true
		if detail.visible:
			dismiss()
			# A major-menu tap can still reach its UI control, never the world.
			for control in [game.overlay.menu_button,game.overlay.character_button]:
				if control.get_global_rect().has_point(event.position): return false
			fingers[event.index]="";return true
	if event is InputEventScreenDrag and fingers.has(event.index): return true
	if event is InputEventMouseButton and event.pressed and detail.visible:
		for button in buttons.values():
			if button.visible and button.get_global_rect().has_point(event.position): return false
		if detail.get_global_rect().has_point(event.position): return true
		dismiss()
		for control in [game.overlay.menu_button,game.overlay.character_button]:
			if control.get_global_rect().has_point(event.position): return false
		return true
	return false
