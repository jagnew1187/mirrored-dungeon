extends CanvasLayer

var game: Node
var root: Control
var veil: ColorRect
var window: PanelContainer
var column: VBoxContainer
var hud: PanelContainer
var status: Label
var health: ProgressBar
var toast: Label
var attack_button: Button
var ability_buttons: Array[Button]=[]
var combat_touches: Dictionary={}

var page_id := "title"
var toast_time := 0.0
var controls: Label
var objective_label: Label
var hero_name := ""
var bag_mode := "inventory"
var bag_page := 0
var slot_page := 0
var save_warning: Label
var hud_clock := 0.0

func _input(event: InputEvent) -> void:
	# Combat controls explicitly support touch even on platforms without mouse emulation.
	if not event is InputEventScreenTouch: return
	if not event.pressed and combat_touches.has(event.index):
		var button: Button=combat_touches[event.index];combat_touches.erase(event.index)
		button.button_up.emit()
		if not game.menu_open and not button.disabled and button.get_global_rect().has_point(event.position): button.pressed.emit()
		get_viewport().set_input_as_handled();return
	if game.menu_open or not event.pressed: return
	var buttons: Array[Button]=ability_buttons.duplicate();buttons.append(attack_button)
	for button in buttons:
		if button.visible and button.get_global_rect().has_point(event.position):
			if not button.disabled: combat_touches[event.index]=button;button.button_down.emit()
			get_viewport().set_input_as_handled();return

func style(color: Color, margin := 18) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.border_color=Color("8d7348");s.set_border_width_all(1)
	s.content_margin_left=margin;s.content_margin_right=margin;s.content_margin_top=margin;s.content_margin_bottom=margin
	return s

func _ready() -> void:
	layer=20;root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
	var theme:=Theme.new();theme.default_font_size=17
	theme.set_stylebox("disabled","Button",style(Color("192b29"),12));theme.set_color("font_disabled_color","Button",Color("b8c1b4"));theme.set_stylebox("normal","Button",style(Color("26322d"),12));theme.set_stylebox("hover","Button",style(Color("465145"),12));theme.set_stylebox("pressed","Button",style(Color("65563c"),12));theme.set_color("font_color","Button",Color("ecddba"));root.theme=theme
	hud=PanelContainer.new();hud.position=Vector2(24,20);hud.size=Vector2(350,85);hud.add_theme_stylebox_override("panel",style(Color("13201eec"),12));root.add_child(hud)
	var box:=VBoxContainer.new();hud.add_child(box);status=Label.new();box.add_child(status)
	health=ProgressBar.new();health.custom_minimum_size=Vector2(320,16);health.show_percentage=false;health.add_theme_stylebox_override("fill",style(Color("9d423f"),0));box.add_child(health)
	var menu:=Button.new();menu.focus_mode=Control.FOCUS_NONE;menu.text="Menu  ·  Esc";menu.position=Vector2(1000,20);menu.size=Vector2(130,48);menu.pressed.connect(func():page("pause"));root.add_child(menu)
	attack_button=Button.new();attack_button.position=Vector2(925,620);attack_button.size=Vector2(205,72);attack_button.button_down.connect(func():game.attack_held=true;game.request_attack());attack_button.button_up.connect(func():game.attack_held=false);root.add_child(attack_button)
	attack_button.focus_mode=Control.FOCUS_NONE
	for i in range(2):
		var button:=Button.new();button.position=Vector2(705,544+i*76);button.size=Vector2(210,68);button.focus_mode=Control.FOCUS_NONE
		button.pressed.connect(func():game.abilities.activate(i));root.add_child(button);ability_buttons.append(button)
	controls=Label.new();controls.position=Vector2(24,656);controls.text="WASD / arrows  ·  Click to travel or target\nSpace / right mouse: attack  ·  E: interact / loot  ·  I: gear  ·  J: quest";controls.add_theme_color_override("font_shadow_color",Color.BLACK);controls.add_theme_constant_override("shadow_offset_x",2);controls.add_theme_constant_override("shadow_offset_y",2);root.add_child(controls)
	toast=Label.new();toast.position=Vector2(260,154);toast.size=Vector2(640,60);toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;toast.add_theme_color_override("font_color",Color("f3d69c"));toast.add_theme_color_override("font_shadow_color",Color.BLACK);toast.add_theme_constant_override("shadow_offset_x",2);toast.add_theme_constant_override("shadow_offset_y",2);root.add_child(toast)
	veil=ColorRect.new();veil.color=Color(0.025,0.045,0.05,0.92);veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(veil)
	window=PanelContainer.new();window.position=Vector2(270,100);window.size=Vector2(612,520);window.add_theme_stylebox_override("panel",style(Color("132320"),26));root.add_child(window)
	column=VBoxContainer.new();column.add_theme_constant_override("separation",12);window.add_child(column)
	objective_label=Label.new();objective_label.position=Vector2(24,116);objective_label.add_theme_font_size_override("font_size",16);root.add_child(objective_label)
	var pad:=Node2D.new();pad.set_script(load("res://scripts/touch_pad.gd"));pad.game=game;add_child(pad)
	save_warning=Label.new();save_warning.position=Vector2(20,0);save_warning.add_theme_color_override("font_color",Color("ffb9a2"));root.add_child(save_warning)

func text(value: String, size := 18, color := Color("e5d8bc")) -> Label:
	var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.custom_minimum_size.x=550;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);column.add_child(l);return l

func option(value: String, action: Callable, disabled := false) -> Button:
	var b:=Button.new();b.text=value;b.custom_minimum_size.y=44;b.disabled=disabled;b.pressed.connect(action);column.add_child(b);return b

func clear(id: String) -> void:
	page_id=id;combat_touches.clear();game.abilities.cancel();game.menu_open=true;game.cancel_approach();game.attack_held=false
	column.add_theme_constant_override("separation",12)
	veil.color=Color(0.025,0.045,0.05,0.92)
	for child in column.get_children(): column.remove_child(child);child.queue_free()
	window.position=Vector2(270,100);window.size=Vector2(612,0);veil.show();window.show();hud.hide();attack_button.hide();controls.hide();toast.hide();objective_label.hide()

func close() -> void:
	if game.fallen: return
	game.started=true;game.menu_open=false;window.hide();veil.hide();hud.show();attack_button.show();controls.show();toast.show();objective_label.show()

func page(id: String) -> void:
	clear(id)
	match id:
		"title":
			text("A G N E W   F O R G E",15,Color("b29966"));text("MIRRORED\nDUNGEON",42);text("THE LAST VIGIL",15,Color("9aa899"))
			option("New Campaign",func():page("characters"));option("Continue · saved campaigns",func():page("slots"))
			option("Settings",func():page("settings"))
			option("Competitive Arena  ·  unavailable",func():pass,true);option("Endless Descent  ·  unavailable",func():pass,true)
			option("Exit",func():page("quit"))
		"pause":
			text("THE LAST VIGIL",28);text("Rest a moment. The world is paused.")
			option("Resume",close);option("Character & equipment",func():page("equipment"));option("Quest journal",func():page("journal"));option("Settings",func():page("settings"));option("Return to Vigil",func():game.enter_area("vigil");close());option("Main Menu",func():page("title"))
		"characters":
			hero_name=""
			text("NEW CAMPAIGN",28);text("Creates a separate save; existing heroes remain available.",15)
			var name_input:=LineEdit.new();name_input.placeholder_text="Hero name (optional)";name_input.max_length=24;name_input.custom_minimum_size.y=44;name_input.text_changed.connect(func(value):hero_name=value);column.add_child(name_input)
			for kind in ["knight","mage","rogue"]:
				var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);column.add_child(row)
				var portrait:=TextureRect.new();portrait.texture=load("res://assets/%s_right_0.png"%kind);portrait.custom_minimum_size=Vector2(120,96);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(portrait)
				var b:=Button.new();b.text={"knight":"KNIGHT  ·  Sword & shield\nSubstantial melee · 270 health","mage":"MAGE  ·  Arcane bolt\nRanged magic · 200 health","rogue":"ROGUE  ·  Thrown daggers\nFast and mobile · 165 health"}[kind];b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.pressed.connect(func():game.select_class(kind);close());row.add_child(b)
			option("Back",func():page("title"))
		"settings":
			text("SETTINGS",28);text("Effects volume")
			var volume:=HSlider.new();volume.min_value=0;volume.max_value=1;volume.step=0.05;volume.value=game.volume;volume.custom_minimum_size.y=36;volume.value_changed.connect(func(v):game.volume=v);column.add_child(volume)
			var fullscreen:=CheckButton.new();fullscreen.text="Fullscreen";fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;fullscreen.toggled.connect(func(on):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED));column.add_child(fullscreen)
			var touch:=CheckButton.new();touch.text="Show touch joystick";touch.button_pressed=game.show_touch;touch.toggled.connect(func(on):game.show_touch=on);column.add_child(touch)
			text("Settings apply to this session. Landscape touch layout; physical iPhone testing is still required.",15)
			option("Back",func():page("pause" if game.started else "title"))
		"quit":
			text("LEAVE THE VIGIL?",28);text("Campaign progress is saved locally. Continue resumes at your last safe refuge.")
			option("Keep playing",close);option("Exit prototype",func():game.persist();game.get_tree().quit())
		"stash":
			inventory("stash")

		"slots":
			text("CONTINUE CAMPAIGN",28)
			var slots: Array=game.campaign.slots()
			if slots.is_empty(): text("No saved campaigns yet. New Campaign starts a separate hero.")
			for entry in slots.slice(slot_page*5,slot_page*5+5):
				option("Unreadable · preserved · "+entry.id if entry.record.is_empty() else "%s · %s · %d XP · %d coins\nSlot %s"%[entry.record.name,entry.record["class"],entry.record.xp,entry.record.gold,entry.id.get_slice("_",1)],func():game.continue_campaign(entry.id),entry.record.is_empty())
			if slots.size()>5: option("More campaigns",func():slot_page=(slot_page+1)%ceili(slots.size()/5.0);page("slots"))
			option("Back",func():page("title"))
		"journal":
			text("BREAD BEFORE BLADES",28);text(game.objective())
			text("The occupation seized Anja's flour. Take Old Mill Road east from Vigil, then follow the main road northeast to the mill. The two marked guards belong to the patrol; roaming enemies do not count. Recover the sacks after the fight, then take the southeast fork to Bannerfall and speak to Anja at the bakery.")
			text("Reward once: 100 XP, 35 coins and a baker's keepsake. The mill captain drops a class weapon upgrade.")
			option("Close",close)
		"equipment":
			inventory("inventory")
		"defeat":
			text("THE ROAD TAKES ITS TOLL",28);text("You have fallen. XP, equipment and recorded quest progress are protected. Unfinished fights reset; rewards cannot be claimed twice.")
			option("Recover at last safe refuge",game.recover)
			option("Save and return to title",func():game.persist();page("title"))

func dialogue(p: Dictionary, body: String) -> void:
	clear("dialogue");veil.color=Color(0.025,0.045,0.05,0.65)
	text(p.name,27)
	if p.kind in ["mara","boy","anja","oren","ves"]:
		var portrait:=TextureRect.new();portrait.texture=load("res://assets/"+p.kind+"_portrait.png");portrait.custom_minimum_size=Vector2(160,170);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;column.add_child(portrait)
	text(body);option("Continue",close)

func notify(value: String) -> void:
	toast.text=value;toast_time=5

func _process(delta: float) -> void:
	hud_clock+=delta
	if hud_clock<.05: return
	delta=hud_clock;hud_clock=0
	if not is_instance_valid(game.hero): return
	save_warning.text=game.campaign.error
	for i in range(2):
		ability_buttons[i].visible=not game.menu_open
		ability_buttons[i].text=("%s · "%["Q" if i==0 else "R"])+game.abilities.DATA[game.selected][i].name+("\nReady" if game.abilities.remaining[i]<=0 else "\n%.1fs"%game.abilities.remaining[i])
		ability_buttons[i].disabled=game.abilities.remaining[i]>0 or game.abilities.active>=0
	if window.visible: window.size=Vector2(612,column.get_combined_minimum_size().y+52)
	objective_label.text=game.objective()
	status.text="%s  ·  %s\n%d / %d"%[game.area.name,game.selected.capitalize(),ceili(game.hero.health),game.hero.max_health]
	health.max_value=game.hero.max_health;health.value=game.hero.health
	attack_button.text={"knight":"Sword strike","mage":"Arcane bolt","rogue":"Throw dagger"}[game.selected]+("  ·  ready" if game.cooldown<=0 else "  ·  %.1fs"%game.cooldown)
	if not game.menu_open: toast_time=maxf(0,toast_time-delta)
	if toast_time<=0: toast.text=""

func row_buttons(labels: Array, actions: Array) -> void:
	var row:=HBoxContainer.new();column.add_child(row)
	for i in range(labels.size()):
		var button:=Button.new();button.text=labels[i];button.custom_minimum_size.y=44;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.pressed.connect(actions[i]);row.add_child(button)

func inventory(mode: String, reset := true) -> void:
	if mode in ["stash","shop"] and not game.at_camp_service(): mode="inventory"
	if reset: bag_page=0
	bag_mode=mode;clear("equipment");window.position.y=30;column.add_theme_constant_override("separation",6)
	var model=game.campaign
	var progress: Dictionary=model.progress()
	text("%s · %s · Level %d"%[model.data.name,game.selected.capitalize(),progress.level],24)
	text("XP %d / %d · %d coins · Backpack %d/%d\nHP %d/%d · Damage %.1f · Defense %d · Attack %.2fs · Speed %d"%[progress.xp,progress.next,model.data.gold,model.data.inventory.size(),model.Gear.CAPACITY,ceili(game.hero.health),game.stats.hp,game.stats.damage,game.stats.defense,game.stats.cooldown,game.stats.speed],16)
	if game.at_camp_service(): row_buttons(["Backpack","Stash","Supplies"],[func():inventory("inventory"),func():inventory("stash"),func():inventory("shop")])
	else: text("Stash and trading: approach the chest or supply table at Vigil.",15)
	var labels: Array=[];var actions: Array=[]
	for slot_name in ["weapon","armor","accessory"]:
		labels.append(slot_name.capitalize()+ (" ✓" if model.data.equipped.has(slot_name) else " —"))
		actions.append(func():equipped_item(slot_name))
	row_buttons(labels,actions)
	var list: Array=model.data.stash if mode=="stash" else (model.Gear.SHOP.filter(func(id):return model.Gear.allowed(id,game.selected)) if mode=="shop" else model.data.inventory)
	text({"inventory":"BACKPACK · select an item","stash":"PROTECTED STASH · %d/%d slots"%[model.data.stash.size(),model.Gear.STASH_CAPACITY],"shop":"CAMP SUPPLIES · buy at listed price"}[mode],16)
	bag_page=clampi(bag_page,0,maxi(0,ceili(list.size()/3.0)-1))
	if list.is_empty(): text("No items here.",16)
	for index in range(bag_page*3,mini(list.size(),bag_page*3+3)):
		var id: String=list[index] if mode=="shop" else list[index].id
		var item: Dictionary=model.Gear.ITEMS[id]
		var label: String=item.name+(" · %d coins"%(item.value*2) if mode=="shop" else " ×%d"%list[index].count)
		var button:=option(label,func():inspect_item(id,index,mode))
		if item.rarity=="Improved": button.add_theme_color_override("font_color",Color("88cda9"))
	if list.size()>3: row_buttons(["← Previous","%d / %d"%[bag_page+1,ceili(list.size()/3.0)],"Next →"],[func():bag_page-=1;inventory(mode,false),func():pass,func():bag_page+=1;inventory(mode,false)])
	if game.at_camp_service(): row_buttons(["Rest · restore health","Close"],[func():game.hero.health=game.hero.max_health;notify("Rested and ready.");close(),close])
	else: option("Close",close)

func inspect_item(id: String, index: int, mode: String) -> void:
	clear("item");var model=game.campaign;var item: Dictionary=model.Gear.ITEMS[id]
	var expected: int=model.revision
	text(item.name,26);text("%s · %s · Sell %d coins"%[item.rarity,item.category,item.value],16)
	text(item.description);text("Comparison: "+model.comparison(id),17)
	if not model.Gear.allowed(id,game.selected): text("Requires: "+", ".join(item.classes),16)
	if mode=="shop":
		option("Buy one · %d coins"%(item.value*2),func():confirm_transaction("Buy "+item.name+" for %d coins?"%(item.value*2),func():return model.buy(id),expected))
	elif mode=="stash":
		option("Withdraw one",func():apply_inventory(func():return model.transfer(index,false),expected))
	else:
		if not item.slot.is_empty(): option("Equip",func():apply_inventory(func():return model.equip(index),expected),not model.Gear.allowed(id,game.selected))
		if id=="tonic": option("Drink · restore 60 health",func():apply_inventory(func():return game.use_tonic(index),expected),game.hero.health>=game.hero.max_health)
		if game.at_camp_service():
			option("Deposit one in stash",func():apply_inventory(func():return model.transfer(index,true),expected))
			option("Sell one · %d coins"%item.value,func():confirm_transaction("Sell one "+item.name+" for %d coins?"%item.value,func():return model.sell(index),expected))
	option("Back",func():inventory(bag_mode,false))

func equipped_item(slot_name: String) -> void:
	var model=game.campaign
	if not model.data.equipped.has(slot_name): return
	var id: String=model.data.equipped[slot_name];var item: Dictionary=model.Gear.ITEMS[id]
	var expected: int=model.revision
	clear("item");text(item.name,26);text("Equipped · "+slot_name+" · "+item.rarity);text(item.description)
	text("Modifiers: "+str(item.mods),16)
	option("Unequip to backpack",func():apply_inventory(func():return model.unequip(slot_name),expected))
	option("Back",func():inventory(bag_mode,false))

func confirm_transaction(message: String, action: Callable, expected: int) -> void:
	clear("transaction");text(message,24);text("Your balance: %d coins"%game.campaign.data.gold)
	option("Confirm",func():apply_inventory(action,expected))
	option("Cancel",func():inventory(bag_mode,false))

func apply_inventory(action: Callable, expected: int) -> void:
	# A stale button/confirmation cannot operate on an index changed by another click.
	if expected!=game.campaign.revision: inventory(bag_mode,false);return
	if bag_mode in ["stash","shop"] and not game.at_camp_service(): inventory("inventory");return
	var ok: bool=action.call()
	game.refresh_stats();game.persist();inventory(bag_mode,false)
	if not ok: text("Unable to complete: check space, ownership, class and coins.",16,Color("f1aa8b"))
