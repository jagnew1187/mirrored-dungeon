extends Node2D
const Transitions=preload("res://scripts/map_transitions.gd")
var transition_until:=0.0
var arrival_exit_suppressed:=""
var movement_rearm:=false
var arrival_positions: Array[Vector2]=[]

const MEMBERS := ["captain","escort"]
const ENCOUNTER := "mill-flour-patrol-v1"
var campaign = preload("res://scripts/campaign.gd").new()
var stats: Dictionary = {}
var fallen := false
var population_cycle := 0
var area: Node2D
var hero: CharacterBody2D
var presentation = preload("res://scripts/presentation.gd").new()
var audio_status := "No playback requested"
var web_release_callback: JavaScriptObject
var camera: Camera2D
var selected := "knight"
var path := PackedVector2Array()
var pending: Dictionary = {}
var target: Node2D
var auto_attack:=false
var engaged_target: Node2D
var attack_target: Node2D
var web_layout_callback: JavaScriptObject
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var numbers: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var defeated: Dictionary = {}
var recovered := false
var random_dead: Array[int] = []
var respawn_time := 0.0
var elapsed := 0.0
var cooldown := 0.0
var attack_clock := -1.0
var attack_direction := Vector2.RIGHT
var attack_released := false
var attack_buffer := 0.0
var attack_held := false
var action_input_armed := false
var attacks_started := 0
var hits_landed := 0
var menu_open := true
var started := false
var joystick := Vector2.ZERO
var touch_origin := Vector2.ZERO
var touch_id := -1
var show_touch := false
var volume := 0.65
var overlay: CanvasLayer
var rng := RandomNumberGenerator.new()
var sound_pool: Array[AudioStreamPlayer] = []
var sound_index := 0
var ai_clock := 0.0
var abilities = preload("res://scripts/abilities.gd").new()
var enemy_ai = preload("res://scripts/enemy_ai.gd").new()
const ELITE := "mill-enforcer-v1"

func _ready() -> void:
	get_window().title="Mirrored Dungeon · Pass 11.5 RC9"
	presentation.sync_web_viewport(get_window())
	presentation.touch_mode=presentation.mobile_web or DisplayServer.is_touchscreen_available()
	get_viewport().size_changed.connect(update_presentation)
	get_window().focus_exited.connect(release_inputs)
	if OS.has_feature("web"):
		web_release_callback=JavaScriptBridge.create_callback(func(_arguments): release_inputs())
		JavaScriptBridge.get_interface("window").addEventListener("blur",web_release_callback)
		JavaScriptBridge.get_interface("window").addEventListener("pagehide",web_release_callback)
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange",web_release_callback)
		web_layout_callback=JavaScriptBridge.create_callback(func(_arguments):
			if is_instance_valid(overlay): overlay.request_relayout())
		var visual=JavaScriptBridge.get_interface("window").visualViewport
		if visual!=null: visual.addEventListener("resize",web_layout_callback);visual.addEventListener("scroll",web_layout_callback)
	rng.seed=8026;abilities.game=self;enemy_ai.game=self
	campaign.fresh("knight");campaign.slot="";stats=campaign.stats()
	overlay=CanvasLayer.new();overlay.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;overlay.set_script(load("res://scripts/interface.gd"));overlay.game=self;add_child(overlay)
	for i in range(8):
		var sound:=AudioStreamPlayer.new();add_child(sound);sound_pool.append(sound)
	enter_area("vigil");overlay.page("title")
	var feedback:=Node2D.new();feedback.set_script(load("res://scripts/combat_overlay.gd"));feedback.game=self;feedback.z_index=10;add_child(feedback)

func play_sound(id: String) -> void:
	if volume<=0: return
	var sound:=sound_pool[sound_index%8];sound_index+=1
	sound.stop()
	sound.stream=load("res://assets/"+id+".wav")
	if sound.stream==null: audio_status="Resource missing: "+id;return
	sound.volume_db=linear_to_db(volume*0.7);sound.play()
	audio_status="Loaded "+id+"; playback requested (audibility unconfirmed)"

func _exit_tree() -> void:
	if OS.has_feature("web") and web_release_callback!=null:
		JavaScriptBridge.get_interface("window").removeEventListener("blur",web_release_callback)
		JavaScriptBridge.get_interface("window").removeEventListener("pagehide",web_release_callback)
		JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange",web_release_callback)
		web_release_callback=null
		var visual=JavaScriptBridge.get_interface("window").visualViewport
		if visual!=null and web_layout_callback!=null: visual.removeEventListener("resize",web_layout_callback);visual.removeEventListener("scroll",web_layout_callback)
		web_layout_callback=null
	for sound in sound_pool:
		if is_instance_valid(sound): sound.stop();sound.stream=null

func select_class(kind: String) -> void:
	overlay.toast_time=0;abilities.cancel(true);campaign.fresh(kind,overlay.hero_name);selected=kind;defeated={};recovered=false;random_dead.clear();population_cycle=0;fallen=false;stats=campaign.stats();enter_area("vigil");persist()

func enter_area(id: String, restored_health: float=-1.0, entrance: String="", lateral: float=0.0) -> void:
	var previous_health: float=hero.health if is_instance_valid(hero) else stats.hp
	if is_instance_valid(overlay): overlay.bubble_time=0
	abilities.cancel();cancel_approach();enemies.clear();projectiles.clear();numbers.clear();impacts.clear();attack_clock=-1;cooldown=0;attack_buffer=0;attack_held=false
	action_input_armed=false
	if is_instance_valid(area): remove_child(area);area.queue_free()
	area=load("res://scenes/"+id+".tscn").instantiate();add_child(area)
	hero=CharacterBody2D.new();hero.set_script(load("res://scripts/actor.gd"));hero.kind=selected;hero.position=area.spawn;hero.max_health=stats.hp;hero.health=stats.hp if id!="road" else minf(previous_health,stats.hp);area.actors.add_child(hero)
	# Restore before the area-entry autosave can replace persisted health.
	if restored_health>=0: hero.health=minf(restored_health,hero.max_health)
	arrival_positions.clear();transition_until=0.0
	arrival_exit_suppressed=entrance;movement_rearm=not entrance.is_empty()
	if is_instance_valid(overlay.status_strip): overlay.status_strip.dismiss()
	if not entrance.is_empty():
		var arrival: Dictionary=Transitions.arrival(area,entrance,lateral)
		if arrival.ok:
			hero.position=arrival.position;hero.face(arrival.facing);arrival_positions=arrival.party_positions
		else:
			push_warning(arrival.warning);overlay.notify(arrival.warning)
			var fallback: Array[Vector2]=Transitions.placements(area,area.spawn,Vector2.DOWN)
			if not fallback.is_empty(): hero.position=fallback[0];arrival_positions=fallback
		transition_until=elapsed+.6
	camera=Camera2D.new();camera.process_callback=Camera2D.CAMERA2D_PROCESS_PHYSICS;camera.process_physics_priority=100;camera.position_smoothing_enabled=false;camera.position=hero.position;camera.limit_left=0;camera.limit_top=0;camera.limit_right=int(area.bounds.x);camera.limit_bottom=int(area.bounds.y);area.add_child(camera);camera.make_current();update_presentation()
	if id!="road": campaign.data.checkpoint=id
	if id=="bannerfall": campaign.add_loot("pilgrim-cache","pilgrim_boots",id,safe_loot_position(Vector2(980,740)))
	persist()
	if id=="road":
		spawn_random()
		for i in range(MEMBERS.size()):
			if not defeated.has(MEMBERS[i]): spawn_enemy(Vector2(2600+i*140,590),MEMBERS[i],false,"shield" if i==0 else "militia")
		if not campaign.data.claims.has(ELITE): spawn_enemy(Vector2(2230,850),ELITE,false,"enforcer")
	area.reset_physics_interpolation()
	camera.reset_smoothing();camera.force_update_scroll()
	if is_instance_valid(overlay.minimap): overlay.minimap.refresh()

func spawn_enemy(p: Vector2, id: String, random_population: bool, role := "militia") -> void:
	var actor:=CharacterBody2D.new();actor.set_script(load("res://scripts/actor.gd"));actor.kind="enemy";actor.role=role;actor.health=enemy_ai.DATA[role].hp;actor.max_health=actor.health;actor.position=p;actor.authored=not random_population;area.actors.add_child(actor);actor.reset_physics_interpolation()
	enemies.append({"role":role,"aim":Vector2.RIGHT,"pattern":0,"actor":actor,"home":p,"id":id,"encounter":"" if random_population else ENCOUNTER,"random":random_population,"cooldown":0.6,"state":"idle","windup":0.0,"stagger":0.0,"wander":p,"wander_at":elapsed+2.0,"route":PackedVector2Array(),"repath":0.0})

func spawn_random() -> void:
	for i in range(3):
		if not random_dead.has(i): spawn_enemy(Vector2(1040+i*100,1370+rng.randf_range(-25,25)),str(i),true,["militia","archer","raider"][i])

func encounter_complete() -> bool:
	for id in MEMBERS:
		if not defeated.has(id): return false
	return not MEMBERS.is_empty()

func stop_auto_attack() -> void:
	if auto_attack: attack_buffer=0;attack_held=false
	auto_attack=false;engaged_target=null;target=null;path.clear()

func cancel_approach(preserve_auto:=false) -> void:
	path.clear();pending.clear();joystick=Vector2.ZERO
	if not preserve_auto: stop_auto_attack()

func move_actor(actor: CharacterBody2D, velocity: Vector2) -> void:
	var old:=actor.position;actor.velocity=velocity;actor.move_and_slide()
	actor.position=actor.position.clamp(Vector2(15,15),area.bounds-Vector2(15,15))
	actor.moving=actor.position.distance_to(old)>0.04
	if actor.moving and not actor.attacking: actor.face(actor.position-old)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero): return
	hero.paused=menu_open
	for i in range(enemies.size()-1,-1,-1):
		if is_instance_valid(enemies[i].actor): enemies[i].actor.paused=menu_open
		else: enemies.remove_at(i)
	if menu_open: hero.moving=false;return
	abilities.update(delta)
	if auto_attack and not valid_combat_target(engaged_target): stop_auto_attack()
	if target!=null and not valid_combat_target(target): target=null
	elapsed+=delta;cooldown=maxf(0,cooldown-delta);attack_buffer=maxf(0,attack_buffer-delta)
	var direction:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	direction+=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	if movement_rearm:
		if direction.length()<=.1: movement_rearm=false
		else: direction=Vector2.ZERO
	if direction.length()>0.1: cancel_approach(true)
	else: direction=joystick
	if auto_attack:
		# Engagement never creates movement. A target outside range pauses attacks.
		if basic_target_in_range(): attack_buffer=maxf(attack_buffer,0.12)
		else: attack_buffer=0
	if direction==Vector2.ZERO and not path.is_empty():
		if hero.position.distance_to(path[0])<9: path.remove_at(0)
		if not path.is_empty(): direction=hero.position.direction_to(path[0])
	if not pending.is_empty() and not Transitions.automatic(area.area_id,pending) and hero.position.distance_to(pending.pos)<72:
		var p:=pending.duplicate();cancel_approach();interact(p);return
	if path.is_empty() and not pending.is_empty(): pending.clear()
	var movement_factor:=0.45 if attack_clock>=0 and selected=="knight" else 1.0
	var previous_position: Vector2=hero.position
	if abilities.active>=0 and abilities.dash<=0: movement_factor*=0.55
	if abilities.dash>0: move_actor(hero,abilities.aim*abilities.DATA.rogue[0].speed)
	else: move_actor(hero,direction.limit_length()*stats.speed*movement_factor)
	if update_auto_travel(previous_position): return
	camera.position=hero.position
	if not attack_held and not Input.is_physical_key_pressed(KEY_SPACE): action_input_armed=true
	if action_input_armed and (attack_held or Input.is_physical_key_pressed(KEY_SPACE)): attack_buffer=maxf(attack_buffer,0.15)
	var auto_in_range: bool=not auto_attack or basic_target_in_range()
	if attack_buffer>0 and cooldown<=0 and attack_clock<0 and abilities.active<0 and auto_in_range: begin_attack()
	if attack_clock>=0:
		attack_clock+=delta
		if not attack_released and attack_clock>=stats.windup: release_attack();attack_released=true
		if attack_clock>=0.32: attack_clock=-1
	update_projectiles(delta);update_enemies(delta)
	for n in numbers: n.time-=delta;n.pos.y-=delta*24
	numbers=numbers.filter(func(n):return n.time>0)
	for impact in impacts: impact.time-=delta
	impacts=impacts.filter(func(i):return i.time>0)
	if hero.health<=0:
		fallen=true;abilities.cancel();cancel_approach();attack_clock=-1;attack_buffer=0;attack_held=false;projectiles.clear();hero.attacking=false;hero.health=0;hero.begin_death(false);persist();overlay.page("defeat")
	queue_redraw()

func valid_combat_target(actor) -> bool:
	return is_instance_valid(actor) and actor.is_inside_tree() and actor.health>0

func basic_target_in_range() -> bool:
	return valid_combat_target(engaged_target) and hero.position.distance_to(engaged_target.position)<=stats.range and area.line_clear(hero.position,engaged_target.position)

func engage_combat(reach: float) -> bool:
	# Search only on deliberate offensive input, using the existing nearest/LOS rule.
	var chosen: Node2D=target if valid_combat_target(target) else null
	if chosen==null and valid_combat_target(engaged_target): chosen=engaged_target
	if chosen==null:
		var distance:=reach
		for enemy in enemies:
			if not valid_combat_target(enemy.actor): continue
			var candidate: float=hero.position.distance_to(enemy.actor.position)
			if candidate<=distance and area.line_clear(hero.position,enemy.actor.position):
				chosen=enemy.actor;distance=candidate
	if chosen==null: return false
	target=chosen;engaged_target=chosen;auto_attack=true
	path.clear();pending.clear();attack_buffer=0;attack_held=false
	return true

func request_attack() -> void:
	if menu_open or fallen: return
	if engage_combat(stats.range): return
	path.clear();pending.clear()
	# Preserve deliberate empty-space swings and desktop held attacks.
	attack_buffer=maxf(0.22,cooldown+0.05)

func begin_attack() -> void:
	attack_buffer=0;cooldown=stats.cooldown;attack_clock=0;attack_released=false;attacks_started+=1
	attack_target=engaged_target if auto_attack else target
	var aim: Vector2=aim_direction()
	attack_direction=aim;hero.attack_duration=0.32;hero.attack_impact=stats.windup;hero.start_attack(aim)
	play_sound({"knight":"sword-swing","mage":"arcane-cast","rogue":"dagger-throw"}[selected])

func release_attack() -> void:
	if selected=="knight":
		for e in enemies.duplicate():
			var difference: Vector2=e.actor.position-hero.position
			if difference.length()<=stats.range and (difference.length()<20 or attack_direction.dot(difference.normalized())>=0.35) and area.line_clear(hero.position,e.actor.position): damage_enemy(e,stats.damage)
	else:
		var aim:=attack_direction
		if valid_combat_target(attack_target):
			var flight: float=hero.position.distance_to(attack_target.position)/(440.0 if selected=="mage" else 545.0)
			aim=hero.position.direction_to(attack_target.position+attack_target.velocity*flight)
		projectiles.append({"pos":hero.position,"direction":aim,"travel":0.0,"kind":selected,"damage":stats.damage,"max":stats.range,"muzzle":hero.visual_muzzle()})

func damage_enemy(e: Dictionary, amount: float, source := Vector2.INF) -> void:
	if not is_instance_valid(e.actor) or e.actor.health<=0: return
	var blocked:=false
	if source==Vector2.INF: source=hero.position
	if e.get("armor_role",e.role) in ["shield","enforcer"] and e.state not in ["recover","lunge"] and e.stagger<=0:
		var facing:=Vector2.RIGHT.rotated(e.actor.DIRECTIONS.find(e.actor.direction)*PI/4)
		if facing.dot(e.actor.position.direction_to(source))>0.55: amount*=0.4;blocked=true
	e.actor.modulate=Color.WHITE
	e.actor.health-=amount;e.actor.show_hit(source,blocked);hits_landed+=1
	impacts.append({"pos":e.actor.position+Vector2(0,-36),"time":.2,"magic":selected=="mage","blocked":blocked})
	if not blocked:
		e.stagger=0.16
		if e.state in ["windup","lunge","burst"]: e.state="recover";e.windup=0.5
	var number_origin: Vector2=e.actor.position+Vector2(0,-76)
	var stack:=mini(3,numbers.filter(func(n):return n.pos.distance_to(number_origin)<56).size())
	numbers.append({"pos":number_origin-Vector2(0,stack*22),"text":("BLOCK " if blocked else "")+overlay.ItemPresenter.number(amount),"time":0.8,"blocked":blocked})
	play_sound("hit-arcane" if selected=="mage" else "hit-metal")
	if e.actor.health>0: return
	enemy_defeated(e)

func enemy_defeated(e: Dictionary) -> void:
	if e.random:
		random_dead.append(int(e.id))
		if random_dead.size()==3: respawn_time=elapsed+30
	elif e.encounter==ENCOUNTER and e.id in MEMBERS: defeated[e.id]=true
	var old_level: int=campaign.progress().level
	var reward_id: String=("wild:%d:%s"%[population_cycle,e.id]) if e.random else (ELITE if e.role=="enforcer" else ENCOUNTER+":"+e.id)
	if campaign.award(reward_id,45 if e.role=="enforcer" else (6 if e.random else 20),15 if e.role=="enforcer" else (3 if e.random else 6)):
		var item: String=campaign.Gear.LOOT[(population_cycle+int(e.id))%3] if e.random else (campaign.Gear.UPGRADE[selected] if e.id=="captain" else "tonic")
		if e.role=="enforcer": item="enforcer_seal"
		campaign.add_loot(reward_id,item,area.area_id,safe_loot_position(e.actor.position))
		overlay.notify("+%d XP · +%d coins · Loot dropped nearby"%[45 if e.role=="enforcer" else (6 if e.random else 20),15 if e.role=="enforcer" else (3 if e.random else 6)])
	refresh_stats();persist()
	if campaign.progress().level>old_level: overlay.notify("Level %d · stronger for the road ahead."%campaign.progress().level)
	if engaged_target==e.actor: stop_auto_attack()
	elif target==e.actor: stop_auto_attack()
	e.actor.collision_layer=0;e.actor.collision_mask=0;e.actor.begin_death();e.actor.moving=false;enemies.erase(e)
	if encounter_complete() and not recovered: overlay.notify("The mill patrol is defeated. Recover the flour at the mill.")

func update_projectiles(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var p:=projectiles[i];var travel: float=(440 if p.kind=="mage" else 545)*delta
		var steps:=maxi(1,ceili(travel/6));var alive:=true
		for j in range(steps):
			p.pos+=p.direction*travel/steps;p.travel+=travel/steps
			if p.travel>p.max or not area.clear(p.pos,3):
				impacts.append({"pos":p.pos+Vector2(0,-36),"time":.16,"magic":p.kind=="mage","blocked":true});alive=false;break
			if p.get("hostile",false):
				if p.pos.distance_to(hero.position)<19: damage_hero(p.damage);alive=false
				if not alive: break
				continue
			for e in enemies.duplicate():
				if p.pos.distance_to(e.actor.position)<19: damage_enemy(e,p.damage,p.pos-p.direction*24);alive=false;break
			if not alive: break
		if not alive: projectiles.remove_at(i)

func update_enemies(delta: float) -> void:
	enemy_ai.update(delta)
	for e in enemies:
		if e.actor.visual_state in ["idle","return"] and e.state not in ["idle","return"]: e.actor.notice_time=.45
		e.actor.visual_state=e.state

func approach(p: Dictionary) -> void:
	cancel_approach()
	if Transitions.automatic(area.area_id,p):
		if Transitions.trigger_rect(area.area_id,p).has_point(hero.position): interact(p);return
		path=area.route(hero.position,p.pos);pending=p.duplicate();return
	if hero.position.distance_to(p.pos)<72: interact(p);return
	var best:=PackedVector2Array();var cost:=INF
	for i in range(16):
		var goal: Vector2=p.pos+Vector2.from_angle(i*TAU/16)*38
		if not area.clear(goal): continue
		var candidate: PackedVector2Array=area.route(hero.position,goal)
		if not candidate.is_empty() and candidate.size()<cost: best=candidate;cost=candidate.size()
	if best.is_empty(): overlay.notify("No clear approach. Try the open path beside the obstacle.");return
	path=best;pending=p.duplicate()

func interact(p: Dictionary) -> void:
	cancel_approach()
	if p.kind=="loot":
		var item_id: String=campaign.data.loot.get(p.id,{}).get("item","")
		if campaign.collect(p.id): persist();overlay.notify_action("Acquired "+campaign.Gear.ITEMS[item_id].name+" · ","Open Inventory","I")
		else: overlay.notify("Backpack full. Loot stays here; make space and return.")
		return
	if p.kind=="exit":
		if elapsed<transition_until: return
		var link: Dictionary=Transitions.LINKS.get(area.area_id,{}).get(p.id,{})
		if link.is_empty() or p.get("destination_entrance","").is_empty():
			push_warning("Broken transition reference: "+p.id);overlay.notify("This route has a missing entrance reference.");return
		var tangent:=Vector2.DOWN if absf(link.inward.x)>.5 else Vector2.RIGHT
		var lateral: float=(hero.position-p.pos).dot(tangent)
		enter_area(link.map,-1.0,p.destination_entrance,lateral);return
	if p.kind=="stash": overlay.inventory("stash");return
	if p.kind=="management": overlay.inventory("shop");return
	var body: String=p.text
	if p.kind=="quest":
		if encounter_complete(): recovered=true;campaign.data.quest="deliver" if campaign.data.quest!="done" else "done";body="The patrol is defeated. You recover the flour for Anja in Bannerfall. Follow the southeast road."
		else: body="Defeat both mill guards before recovering the flour. Roaming enemies do not count."
	if p.id=="mara" and campaign.data.quest=="meet_mara": campaign.data.quest="patrol"
	if p.id=="anja" and recovered:
		campaign.data.recovered=recovered
		var previous_level: int=campaign.progress().level
		if campaign.claim_bread():
			refresh_stats()
			body="You brought the flour. Tonight everyone gets bread. Thank you.\nReward: 100 XP, 35 coins and a baker's keepsake. Collect it beside Anja. The captain drops a class weapon upgrade."
			if campaign.progress().level>previous_level: body+="\nLevel %d reached."%campaign.progress().level
		else: body="The flour you brought is feeding our neighbors. There is bread to share again."
	if p.id=="mara" and campaign.data.quest=="done": body="Anja has bread to share again. Rest here with us before your next outing."
	persist()
	overlay.dialogue(p,body)

func world_click(pos: Vector2) -> void:
	for label in loot_labels():
		if label.rect.has_point(pos): approach({"id":label.id,"kind":"loot","pos":label.pos});return
	for id in campaign.data.loot:
		var drop: Dictionary=campaign.data.loot[id]
		var location:=Vector2(drop.x,drop.y)
		if drop.area==area.area_id and pos.distance_to(location)<26:
			approach({"id":id,"kind":"loot","pos":location});return
	# Choose the closest hit, rather than the first overlapping NPC in a list.
	var nearest: Dictionary={};var distance:=48.0
	for p in area.points:
		var d:=pos.distance_to(p.pos+Vector2(0,-24))
		if d<distance: nearest=p;distance=d
	if not nearest.is_empty(): approach(nearest);return
	var picked: Node2D=pick_enemy(get_viewport().get_canvas_transform()*pos)
	if picked!=null:
		cancel_approach(true);target=picked
		return
	# Near-body misses consume combat intent without starting travel.
	if presentation.touch_mode and pick_enemy(get_viewport().get_canvas_transform()*pos,22)!=null: return
	cancel_approach();path=area.route(hero.position,pos)
	if path.is_empty(): overlay.notify("Blocked ground. Choose the path beside the obstacle.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device==InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			if menu_open and started and not fallen: overlay.close()
			else: overlay.page("defeat" if fallen else ("pause" if started else "title"))
			return
		if menu_open: return
		if event.keycode==KEY_Q: abilities.activate(0);return
		if event.keycode==KEY_R: abilities.activate(1);return
		if event.keycode==KEY_I: overlay.page("equipment");return
		if event.keycode==KEY_J: overlay.page("journal");return
		if event.keycode==KEY_SPACE: request_attack()
		if event.keycode==KEY_E: interact_nearest()
	if menu_open: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			attack_held=event.pressed
			if event.pressed: request_attack()
		elif event.pressed and event.button_index==MOUSE_BUTTON_LEFT: world_click(get_global_mouse_position())
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_id<0 and movement_region().has_point(event.position): cancel_approach(true);touch_id=event.index;touch_origin=event.position
			elif not (movement_region().has_point(event.position)): world_click(get_viewport().get_canvas_transform().affine_inverse()*event.position)
		elif event.index==touch_id: touch_id=-1;joystick=Vector2.ZERO
	if event is InputEventScreenDrag and event.index==touch_id: joystick=((event.position-touch_origin)/65).limit_length()

func draw_feedback(canvas: Node2D) -> void:
	abilities.draw(canvas);enemy_ai.draw(canvas)
	if is_instance_valid(area) and not menu_open:
		for p in area.points:
			if hero.position.distance_to(p.pos)<95 or (not presentation.touch_mode and get_global_mouse_position().distance_to(p.pos+Vector2(0,-24))<45):
				var ready: bool=hero.position.distance_to(p.pos)<interaction_radius(p)
				var prompt: String=world_prompt(p,ready)
				if p.kind=="quest" and not encounter_complete(): prompt=p.name+" · Defeat mill guards"
				canvas.draw_arc(p.pos,18,0,TAU,20,Color("d8b16a") if ready else Color("7e887d"),1)
				var label_offset:=Vector2(-125,56 if p.kind=="exit" else 24)
				if p.kind=="exit": prompt="Walk through to travel" if Transitions.automatic(area.area_id,p) else (presentation.action_prompt("Travel","E") if ready else "Move closer to travel")
				canvas.draw_string_outline(ThemeDB.fallback_font,p.pos+label_offset,prompt,HORIZONTAL_ALIGNMENT_CENTER,250,16,3,Color("111918"))
				canvas.draw_string(ThemeDB.fallback_font,p.pos+label_offset,prompt,HORIZONTAL_ALIGNMENT_CENTER,250,16,Color("ecd5a2"))
	if not menu_open:
		for id in campaign.data.loot:
			var drop: Dictionary=campaign.data.loot[id]
			if drop.area!=area.area_id: continue
			var location:=Vector2(drop.x,drop.y)
			var color: Color=overlay.Palette.rarity(campaign.Gear.ITEMS[drop.item].rarity)
			canvas.draw_circle(location,13,Color("172821"));canvas.draw_arc(location,13,0,TAU,20,color,1)
			var item: Dictionary=campaign.Gear.ITEMS[drop.item]
			if item.category=="consumable":
				canvas.draw_rect(Rect2(location+Vector2(-3,-8),Vector2(6,4)),Color("b9a783"));canvas.draw_rect(Rect2(location+Vector2(-5,-4),Vector2(10,11)),Color("a9574e"));canvas.draw_line(location+Vector2(-3,-2),location+Vector2(-3,4),Color("f4c2a0"),2)
			elif item.slot=="armor":
				canvas.draw_colored_polygon(PackedVector2Array([location+Vector2(-4,-7),location+Vector2(-9,-2),location+Vector2(-6,2),location+Vector2(-4,0),location+Vector2(-5,8),location+Vector2(5,8),location+Vector2(4,0),location+Vector2(6,2),location+Vector2(9,-2),location+Vector2(4,-7)]),Color("b59b70"));canvas.draw_line(location+Vector2(0,-5),location+Vector2(0,6),Color("5e5140"),2)
			elif item.slot=="weapon":
				canvas.draw_line(location+Vector2(-5,7),location+Vector2(6,-8),Color("d4dfdb"),3);canvas.draw_line(location+Vector2(-6,1),location+Vector2(1,6),Color("b9935b"),2)
			else: canvas.draw_arc(location,6,0,TAU,12,Color("d8be78"),3)
		for label in loot_labels():
			var item: Dictionary=campaign.Gear.ITEMS[label.item]
			canvas.draw_line(label.pos,label.rect.get_center(),Color("9e956f"),1)
			canvas.draw_rect(label.rect,Color("14221ff0"))
			canvas.draw_string(ThemeDB.fallback_font,label.rect.position+Vector2(4,18),loot_prompt(item),HORIZONTAL_ALIGNMENT_CENTER,242,14,overlay.Palette.rarity(item.rarity))
	for p in projectiles:
		var pos: Vector2=p.pos+Vector2(0,-36)
		if p.has("muzzle"): pos+=(p.muzzle-Vector2(0,-36))*maxf(0,1-p.travel/70.0)
		if p.kind=="mage":
			var focused: bool=p.get("focused",false)
			canvas.draw_line(pos-p.direction*(36 if focused else 22),pos,Color(.4,.65,.9,.5),5 if focused else 3)
			var side: Vector2=p.direction.orthogonal()
			canvas.draw_colored_polygon(PackedVector2Array([pos+p.direction*10,pos+side*(6 if focused else 3),pos-p.direction*9,pos-side*(6 if focused else 3)]),Color("bdeef5"))
			canvas.draw_line(pos-p.direction*5,pos+p.direction*7,Color("fff4d6"),2)
		else:
			var color:=Color("e6ac76") if p.get("hostile",false) else (Color("b6d7dc") if p.get("second",false) else Color("e9dec0"))
			canvas.draw_line(pos-p.direction*18,pos,color,2);canvas.draw_line(pos-p.direction*23,pos-p.direction*17,Color("916d49"),3)
			canvas.draw_line(pos-p.direction*7+p.direction.orthogonal()*3,pos,color,1)
	for impact in impacts:
		if impact.get("blocked",false):
			var shield:=PackedVector2Array([impact.pos+Vector2(-7,-9),impact.pos+Vector2(7,-9),impact.pos+Vector2(6,3),impact.pos+Vector2(0,9),impact.pos+Vector2(-6,3),impact.pos+Vector2(-7,-9)])
			canvas.draw_polyline(shield,Color(.65,.88,1,impact.time*5),2)
			continue
		for i in range(5):
			var ray:=Vector2.from_angle(i*TAU/5+.3)
			canvas.draw_line(impact.pos+ray*3,impact.pos+ray*(6+(1-impact.time/.2)*10),Color(.6,.85,1,impact.time*5) if impact.magic else Color(1,.8,.45,impact.time*5),2)
	for n in numbers:
		var alpha:=minf(1,n.time/.2)
		var ink:=Color("a6dcff") if n.get("blocked",false) else Color("f7db9b");ink.a=alpha
		canvas.draw_string_outline(ThemeDB.fallback_font,n.pos,n.text,HORIZONTAL_ALIGNMENT_CENTER,-1,21,3,Color(0.04,0.06,0.06,alpha))
		canvas.draw_string(ThemeDB.fallback_font,n.pos,n.text,HORIZONTAL_ALIGNMENT_CENTER,-1,21,ink)
	if valid_combat_target(target): canvas.draw_arc(target.position,24,0,TAU,32,Color("e8bd6f"),1)
	if auto_attack and valid_combat_target(engaged_target):
		canvas.draw_arc(engaged_target.position,28,0,TAU,32,Color("8fbd98") if basic_target_in_range() else Color("b5a47c"),2)

func refresh_stats() -> void:
	stats=campaign.stats()
	if is_instance_valid(hero): hero.max_health=stats.hp;hero.health=minf(hero.health,hero.max_health)

func persist() -> void:
	if is_instance_valid(hero): campaign.data.health=hero.health
	campaign.data.defeated=defeated.duplicate();campaign.data.recovered=recovered
	campaign.data.random_dead=random_dead.duplicate();campaign.data.cycle=population_cycle
	campaign.data.respawn_remaining=maxf(0,respawn_time-elapsed)
	if not campaign.save() and is_instance_valid(overlay): overlay.notify(campaign.error)

func continue_campaign(id: String) -> void:
	if not campaign.load_slot(id): overlay.text(campaign.error,16,Color("efa38c"));return
	abilities.cancel(true);selected=campaign.data["class"];defeated=campaign.data.defeated.duplicate();recovered=campaign.data.get("recovered",false)
	random_dead.clear()
	for member in campaign.data.get("random_dead",[]): random_dead.append(int(member))
	population_cycle=int(campaign.data.get("cycle",0));respawn_time=elapsed+float(campaign.data.get("respawn_remaining",30))
	fallen=false;refresh_stats();enter_area(campaign.data.checkpoint,float(campaign.data.health));overlay.close()
	if hero.health<=0: fallen=true;overlay.page("defeat")
	if not campaign.migration_notice.is_empty(): overlay.notify(campaign.migration_notice)

func recover() -> void:
	fallen=false;enter_area(campaign.data.checkpoint);overlay.close();overlay.notify("Recovered safely. Equipment, XP and quest progress retained.")

func objective() -> String:
	if campaign.data.quest=="done": return "Bread Before Blades complete · Rest and resupply" if area.area_id=="vigil" else "Bread Before Blades complete · Return to Vigil"
	if recovered: return "Deliver the flour to Anja · Bannerfall bakery"
	if encounter_complete(): return "Recover the flour · northeast mill"
	if campaign.data.quest=="meet_mara": return "Speak to Mara at Vigil Camp"
	return "Defeat the mill patrol · northeast Old Mill Road (%d/2)"%defeated.size()

func use_tonic(index: int) -> bool:
	if fallen or hero.health>=hero.max_health or index<0 or index>=campaign.data.inventory.size(): return false
	if campaign.data.inventory[index].id!="tonic": return false
	campaign.Gear.remove(campaign.data.inventory,index);campaign.revision+=1
	hero.health=minf(hero.max_health,hero.health+60);persist();return true

func at_camp_service() -> bool:
	return area.area_id=="vigil" and (hero.position.distance_to(Vector2(220,535))<90 or hero.position.distance_to(Vector2(350,620))<90)

func aim_direction() -> Vector2:
	if auto_attack and valid_combat_target(engaged_target): return hero.position.direction_to(engaged_target.position)
	if is_instance_valid(target): return hero.position.direction_to(target.position)
	var nearest: Node2D
	var distance: float=stats.range
	for e in enemies:
		if hero.position.distance_to(e.actor.position)<distance and area.line_clear(hero.position,e.actor.position):
			nearest=e.actor;distance=hero.position.distance_to(e.actor.position)
	return hero.position.direction_to(nearest.position) if is_instance_valid(nearest) else Vector2.RIGHT.rotated(hero.DIRECTIONS.find(hero.direction)*PI/4)

func damage_hero(amount: float) -> void:
	if fallen or menu_open: return
	var damage: float=maxf(1,amount-stats.defense)
	if abilities.guard>0: damage*=1.0-abilities.DATA.knight[0].reduction
	hero.health=maxf(0,hero.health-damage);hero.hurt=0.18
	numbers.append({"pos":hero.position+Vector2(0,-80),"text":("GUARD " if abilities.guard>0 else "")+"-%d"%ceili(damage),"time":0.8});play_sound("hit-flesh")

func safe_loot_position(origin: Vector2) -> Vector2:
	if area.clear(origin,18): return origin
	for radius in [24,48,72,96]:
		for i in range(16):
			var candidate: Vector2=origin+Vector2.from_angle(i*TAU/16)*radius
			if area.clear(candidate,18): return candidate
	return hero.position

func loot_labels() -> Array[Dictionary]:
	var labels: Array[Dictionary]=[]
	var inverse:=get_viewport().get_canvas_transform().affine_inverse()
	var viewport_rect: Rect2=inverse*Rect2(Vector2(8,8),get_viewport_rect().size-Vector2(16,16))
	var occupied: Array[Rect2]=[Rect2(hero.position+Vector2(-45,-90),Vector2(90,100))]
	for e in enemies:
		if e.actor.visible: occupied.append(Rect2(e.actor.position+Vector2(-40,-110),Vector2(80,120)))
	for rect in overlay.occlusion_rects(): occupied.append(inverse*rect.grow(1))
	for p in area.points:
		if p.kind!="exit": occupied.append(Rect2(p.pos+Vector2(-90,-100),Vector2(180,135)))
	for id in campaign.data.loot:
		var drop: Dictionary=campaign.data.loot[id]
		var location:=Vector2(drop.x,drop.y)
		if drop.area!=area.area_id or hero.position.distance_to(location)>150: continue
		var rect:=Rect2(location+Vector2(-125,-48),Vector2(250,25))
		var found:=false
		for attempt in range(80):
			var row: int=attempt%20
			var column: int=attempt/20
			rect.position=location+Vector2(-125+(260 if column%2==1 else -260)*(column/2+1) if column>0 else -125,-48+(-27 if row%2==0 else 27)*ceili(row/2.0))
			var overlap:=not viewport_rect.encloses(rect)
			for used in occupied:
				if used.intersects(rect): overlap=true;break
			if not overlap: found=true;break
		if not found: continue
		occupied.append(rect)
		labels.append({"id":id,"rect":rect,"pos":location,"item":drop.item})
	return labels


func interaction_radius(point: Dictionary) -> float:
	# Travel requires deliberately standing in the entrance region and confirming.
	# Arrival remains 96 units inside the new map, outside this 72-unit region.
	return 72.0 if point.get("kind","") in ["exit","loot"] else 90.0

func update_auto_travel(previous_position: Vector2) -> bool:
	if hero.position.distance_to(previous_position)<.01: return false
	for gate in area.points:
		if not Transitions.automatic(area.area_id,gate): continue
		var region:=Transitions.trigger_rect(area.area_id,gate)
		if gate.id==arrival_exit_suppressed:
			if not region.grow(12).has_point(hero.position): arrival_exit_suppressed=""
			continue
		if elapsed>=transition_until and region.has_point(hero.position):
			interact(gate);return true
	return false

func world_prompt(point: Dictionary, ready: bool) -> String:
	if Transitions.automatic(area.area_id,point): return str(point.get("name",""))+" · Walk through to travel"
	var action: String=presentation.action_prompt(presentation.interaction_action(point),"E") if ready else ("Move closer" if presentation.touch_mode else "Click to approach")
	return str(point.get("name",""))+" · "+action

func loot_prompt(item: Dictionary) -> String:
	return item.name+" · "+presentation.action_prompt("Pick Up","E")

func nearby_interaction() -> Dictionary:
	for id in campaign.data.loot:
		var drop: Dictionary=campaign.data.loot[id]
		if drop.area==area.area_id and hero.position.distance_to(Vector2(drop.x,drop.y))<72:
			return {"id":id,"kind":"loot","pos":Vector2(drop.x,drop.y)}
	var nearest: Dictionary={};var distance:=90.0
	for p in area.points:
		if Transitions.automatic(area.area_id,p): continue
		var gap: float=hero.position.distance_to(p.pos)
		if gap<distance and gap<interaction_radius(p): nearest=p;distance=gap
	return nearest

func interact_nearest() -> void:
	var nearest:=nearby_interaction()
	if not nearest.is_empty(): interact(nearest)
	else: overlay.notify("Move closer to a person, chest or loot to interact.")

func update_presentation() -> void:
	# Defer scaling until Godot finishes the physical-window resize notification.
	presentation.call_deferred("sync_web_viewport",get_window())
	release_inputs()
	presentation.configure(get_viewport_rect().size,DisplayServer.is_touchscreen_available())
	if is_instance_valid(camera): camera.zoom=Vector2.ONE*presentation.zoom_for(get_viewport_rect().size,area.bounds)
func release_inputs() -> void:
	cancel_approach()
	touch_id=-1;joystick=Vector2.ZERO;attack_held=false;attack_buffer=0;action_input_armed=false
	if is_instance_valid(overlay):
		overlay.combat_touches.clear()
		if is_instance_valid(overlay.status_strip): overlay.status_strip.fingers.clear()
		if is_instance_valid(overlay.minimap): overlay.minimap.fingers.clear()
func _input(event: InputEvent) -> void:
	if presentation.observe(event) and is_instance_valid(overlay): overlay.relayout()
	if event is InputEventScreenTouch and not event.pressed and event.index==touch_id:
		touch_id=-1;joystick=Vector2.ZERO
func movement_region() -> Rect2:
	var safe: Rect2=Rect2(overlay.root.position,overlay.ui_size*overlay.root.scale)
	return Rect2(safe.position+Vector2(0,safe.size.y*.58),Vector2(minf(220,safe.size.x*.40),safe.size.y*.42))

func resting_stick_origin() -> Vector2:
	var safe: Rect2=Rect2(overlay.root.position,overlay.ui_size*overlay.root.scale)
	return safe.position+Vector2(minf(120,safe.size.x*.22),safe.size.y-85)

func pick_enemy(screen: Vector2, padding: float=0) -> Node2D:
	var best: Node2D=null
	var score:=INF
	var best_id:=""
	var transform:=get_viewport().get_canvas_transform()
	for enemy in enemies:
		if not is_instance_valid(enemy.actor) or enemy.actor.health<=0: continue
		# Visible body, not transparent atlas bounds or foot collision. Selection only.
		var center: Vector2=transform*(enemy.actor.position+Vector2(0,-57))
		var radius:=Vector2(24,48)*camera.zoom+Vector2.ONE*(12 if presentation.touch_mode else 0)+Vector2.ONE*padding
		var distance: float=((screen-center)/radius).length_squared()
		if distance<=1 and (distance<score or (is_equal_approx(distance,score) and str(enemy.id)<best_id)):
			best=enemy.actor;score=distance;best_id=str(enemy.id)
	return best
func test_sound() -> void:
	volume=.65
	AudioServer.set_bus_mute(0,false)
	if overlay.preferences.master<=0:
		overlay.preferences.master=.8
		AudioServer.set_bus_volume_db(0,linear_to_db(.8))
	play_sound("sword-swing")
	if menu_open and overlay.page_id=="settings": overlay.page("settings")
	else: overlay.notify(audio_status)
