extends Node2D

const MEMBERS := ["captain","escort"]
const ENCOUNTER := "mill-flour-patrol-v1"
var campaign = preload("res://scripts/campaign.gd").new()
var stats: Dictionary = {}
var fallen := false
var population_cycle := 0
var area: Node2D
var hero: CharacterBody2D
var camera: Camera2D
var selected := "knight"
var path := PackedVector2Array()
var pending: Dictionary = {}
var target: Node2D
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
	rng.seed=8026;abilities.game=self;enemy_ai.game=self
	campaign.fresh("knight");campaign.slot="";stats=campaign.stats()
	overlay=CanvasLayer.new();overlay.set_script(load("res://scripts/interface.gd"));overlay.game=self;add_child(overlay)
	for i in range(8):
		var sound:=AudioStreamPlayer.new();add_child(sound);sound_pool.append(sound)
	enter_area("vigil");overlay.page("title")
	var feedback:=Node2D.new();feedback.set_script(load("res://scripts/combat_overlay.gd"));feedback.game=self;feedback.z_index=10;add_child(feedback)

func play_sound(id: String) -> void:
	if volume<=0: return
	var sound:=sound_pool[sound_index%8];sound_index+=1
	sound.stop()
	sound.stream=load("res://assets/"+id+".wav");sound.volume_db=linear_to_db(volume*0.7);sound.play()

func _exit_tree() -> void:
	for sound in sound_pool:
		if is_instance_valid(sound): sound.stop();sound.stream=null

func select_class(kind: String) -> void:
	overlay.toast_time=0;abilities.cancel(true);campaign.fresh(kind,overlay.hero_name);selected=kind;defeated={};recovered=false;random_dead.clear();population_cycle=0;fallen=false;stats=campaign.stats();enter_area("vigil");persist()

func enter_area(id: String) -> void:
	var previous_health: float=hero.health if is_instance_valid(hero) else stats.hp
	abilities.cancel();cancel_approach();enemies.clear();projectiles.clear();numbers.clear();impacts.clear();attack_clock=-1;cooldown=0;attack_buffer=0;attack_held=false
	action_input_armed=false
	if is_instance_valid(area): remove_child(area);area.queue_free()
	area=load("res://scenes/"+id+".tscn").instantiate();add_child(area)
	hero=CharacterBody2D.new();hero.set_script(load("res://scripts/actor.gd"));hero.kind=selected;hero.position=area.spawn;hero.max_health=stats.hp;hero.health=stats.hp if id!="road" else minf(previous_health,stats.hp);area.actors.add_child(hero)
	camera=Camera2D.new();camera.position=hero.position;camera.limit_left=0;camera.limit_top=0;camera.limit_right=int(area.bounds.x);camera.limit_bottom=int(area.bounds.y);area.add_child(camera);camera.make_current()
	if id!="road": campaign.data.checkpoint=id
	persist()
	if id=="road":
		spawn_random()
		for i in range(MEMBERS.size()):
			if not defeated.has(MEMBERS[i]): spawn_enemy(Vector2(2600+i*140,590),MEMBERS[i],false,"shield" if i==0 else "militia")
		if not campaign.data.claims.has(ELITE): spawn_enemy(Vector2(2230,850),ELITE,false,"enforcer")

func spawn_enemy(p: Vector2, id: String, random_population: bool, role := "militia") -> void:
	var actor:=CharacterBody2D.new();actor.set_script(load("res://scripts/actor.gd"));actor.kind="enemy";actor.role=role;actor.health=enemy_ai.DATA[role].hp;actor.max_health=actor.health;actor.position=p;actor.authored=not random_population;area.actors.add_child(actor)
	enemies.append({"role":role,"aim":Vector2.RIGHT,"pattern":0,"actor":actor,"home":p,"id":id,"encounter":"" if random_population else ENCOUNTER,"random":random_population,"cooldown":0.6,"state":"idle","windup":0.0,"stagger":0.0,"wander":p,"wander_at":elapsed+2.0,"route":PackedVector2Array(),"repath":0.0})

func spawn_random() -> void:
	for i in range(3):
		if not random_dead.has(i): spawn_enemy(Vector2(1040+i*100,1370+rng.randf_range(-25,25)),str(i),true,["militia","archer","raider"][i])

func encounter_complete() -> bool:
	for id in MEMBERS:
		if not defeated.has(id): return false
	return not MEMBERS.is_empty()

func cancel_approach() -> void:
	path.clear();pending.clear();target=null;joystick=Vector2.ZERO

func move_actor(actor: CharacterBody2D, velocity: Vector2) -> void:
	var old:=actor.position;actor.velocity=velocity;actor.move_and_slide()
	actor.position=actor.position.clamp(Vector2(15,15),area.bounds-Vector2(15,15))
	actor.moving=actor.position.distance_to(old)>0.04
	if actor.moving and not actor.attacking: actor.face(actor.position-old)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero): return
	hero.paused=menu_open
	for e in enemies: e.actor.paused=menu_open
	if menu_open: hero.moving=false;return
	abilities.update(delta)
	if target!=null and (not is_instance_valid(target) or target.health<=0): target=null;path.clear()
	elapsed+=delta;cooldown=maxf(0,cooldown-delta);attack_buffer=maxf(0,attack_buffer-delta)
	var direction:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	direction+=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	if direction.length()>0.1: cancel_approach()
	else: direction=joystick
	if is_instance_valid(target):
		if hero.position.distance_to(target.position)>stats.range*0.9:
			if path.is_empty() or int(elapsed*5)!=int((elapsed-delta)*5): path=area.route(hero.position,target.position)
		else:
			path.clear();attack_buffer=maxf(attack_buffer,0.12)
	if direction==Vector2.ZERO and not path.is_empty():
		if hero.position.distance_to(path[0])<9: path.remove_at(0)
		if not path.is_empty(): direction=hero.position.direction_to(path[0])
	if not pending.is_empty() and hero.position.distance_to(pending.pos)<72:
		var p:=pending.duplicate();cancel_approach();interact(p);return
	if path.is_empty() and not pending.is_empty(): pending.clear()
	var movement_factor:=0.45 if attack_clock>=0 and selected=="knight" else 1.0
	if abilities.active>=0 and abilities.dash<=0: movement_factor*=0.55
	if abilities.dash>0: move_actor(hero,abilities.aim*abilities.DATA.rogue[0].speed)
	else: move_actor(hero,direction.limit_length()*stats.speed*movement_factor)
	camera.position=hero.position
	if not attack_held and not Input.is_physical_key_pressed(KEY_SPACE): action_input_armed=true
	if action_input_armed and (attack_held or Input.is_physical_key_pressed(KEY_SPACE)): attack_buffer=maxf(attack_buffer,0.15)
	if attack_buffer>0 and cooldown<=0 and attack_clock<0 and abilities.active<0: begin_attack()
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
		fallen=true;abilities.cancel();cancel_approach();attack_clock=-1;attack_buffer=0;attack_held=false;projectiles.clear();hero.attacking=false;hero.health=0;persist();overlay.page("defeat")
	queue_redraw()

func request_attack() -> void:
	if menu_open: return
	path.clear();pending.clear()
	# Keep one deliberate command until the current cooldown ends.
	attack_buffer=maxf(0.22,cooldown+0.05)

func begin_attack() -> void:
	attack_buffer=0;cooldown=stats.cooldown;attack_clock=0;attack_released=false;attacks_started+=1
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
		if is_instance_valid(target):
			var flight: float=hero.position.distance_to(target.position)/(440.0 if selected=="mage" else 545.0)
			aim=hero.position.direction_to(target.position+target.velocity*flight)
		projectiles.append({"pos":hero.position,"direction":aim,"travel":0.0,"kind":selected,"damage":stats.damage,"max":stats.range,"muzzle":hero.visual_muzzle()})

func damage_enemy(e: Dictionary, amount: float, source := Vector2.INF) -> void:
	if not is_instance_valid(e.actor) or e.actor.health<=0: return
	var blocked:=false
	if source==Vector2.INF: source=hero.position
	if e.role in ["shield","enforcer"] and e.state not in ["recover","lunge"] and e.stagger<=0:
		var facing:=Vector2.RIGHT.rotated(e.actor.DIRECTIONS.find(e.actor.direction)*PI/4)
		if facing.dot(e.actor.position.direction_to(source))>0.55: amount*=0.4;blocked=true
	e.actor.modulate=Color.WHITE
	e.actor.health-=amount;e.actor.hurt=0.16;hits_landed+=1
	impacts.append({"pos":e.actor.position+Vector2(0,-36),"time":.2,"magic":selected=="mage"})
	if not blocked:
		e.stagger=0.16
		if e.state in ["windup","lunge","burst"]: e.state="recover";e.windup=0.5
	numbers.append({"pos":e.actor.position+Vector2(0,-76),"text":str(int(amount)),"time":0.8})
	play_sound("hit-arcane" if selected=="mage" else "hit-metal")
	if e.actor.health>0: return
	if e.random:
		random_dead.append(int(e.id))
		if random_dead.size()==3: respawn_time=elapsed+30
	elif e.encounter==ENCOUNTER and e.id in MEMBERS: defeated[e.id]=true
	var old_level: int=campaign.progress().level
	var reward_id: String=("wild:%d:%s"%[population_cycle,e.id]) if e.random else (ELITE if e.role=="enforcer" else ENCOUNTER+":"+e.id)
	if campaign.award(reward_id,45 if e.role=="enforcer" else (6 if e.random else 20),15 if e.role=="enforcer" else (3 if e.random else 6)):
		var item: String=campaign.Gear.LOOT[(population_cycle+int(e.id))%3] if e.random else (campaign.Gear.UPGRADE[selected] if e.id=="captain" else "tonic")
		if e.role=="enforcer": item="padded_coat"
		campaign.add_loot(reward_id,item,area.area_id,safe_loot_position(e.actor.position))
		overlay.notify("+%d XP · +%d coins · Loot dropped nearby"%[45 if e.role=="enforcer" else (6 if e.random else 20),15 if e.role=="enforcer" else (3 if e.random else 6)])
	refresh_stats();persist()
	if campaign.progress().level>old_level: overlay.notify("Level %d · stronger for the road ahead."%campaign.progress().level)
	if target==e.actor: target=null;path.clear()
	e.actor.collision_layer=0;e.actor.collision_mask=0;e.actor.dying=true;e.actor.moving=false;enemies.erase(e)
	if encounter_complete() and not recovered: overlay.notify("The mill patrol is defeated. Recover the flour at the mill.")

func update_projectiles(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var p:=projectiles[i];var travel: float=(440 if p.kind=="mage" else 545)*delta
		var steps:=maxi(1,ceili(travel/6));var alive:=true
		for j in range(steps):
			p.pos+=p.direction*travel/steps;p.travel+=travel/steps
			if p.travel>p.max or not area.clear(p.pos,3):
				impacts.append({"pos":p.pos+Vector2(0,-36),"time":.16,"magic":p.kind=="mage"});alive=false;break
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
	for e in enemies: e.actor.visual_state=e.state

func approach(p: Dictionary) -> void:
	cancel_approach()
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
		if campaign.collect(p.id): persist();overlay.notify("Collected. Open inventory (I) to inspect or equip.")
		else: overlay.notify("Backpack full. Loot stays here; make space and return.")
		return
	if p.kind=="exit": enter_area(p.target);return
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
	for e in enemies:
		if pos.distance_to(e.actor.position+Vector2(0,-25))<43:
			cancel_approach();target=e.actor;request_attack() if hero.position.distance_to(target.position)<=stats.range else 0;return
	cancel_approach();path=area.route(hero.position,pos)
	if path.is_empty(): overlay.notify("Blocked ground. Choose the path beside the obstacle.")

func _unhandled_input(event: InputEvent) -> void:
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
		if event.keycode==KEY_E:
			for id in campaign.data.loot:
				var drop: Dictionary=campaign.data.loot[id]
				if drop.area==area.area_id and hero.position.distance_to(Vector2(drop.x,drop.y))<72:
					interact({"id":id,"kind":"loot"});return
			var nearest: Dictionary={};var distance:=90.0
			for p in area.points:
				if hero.position.distance_to(p.pos)<distance: nearest=p;distance=hero.position.distance_to(p.pos)
			if not nearest.is_empty(): interact(nearest)
	if menu_open: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT:
			attack_held=event.pressed
			if event.pressed: request_attack()
		elif event.pressed and event.button_index==MOUSE_BUTTON_LEFT: world_click(get_global_mouse_position())
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x<300 and event.position.y>420: cancel_approach();touch_id=event.index;touch_origin=event.position
			else: world_click(get_viewport().get_canvas_transform().affine_inverse()*event.position)
		elif event.index==touch_id: touch_id=-1;joystick=Vector2.ZERO
	if event is InputEventScreenDrag and event.index==touch_id: joystick=((event.position-touch_origin)/65).limit_length()

func draw_feedback(canvas: Node2D) -> void:
	abilities.draw(canvas);enemy_ai.draw(canvas)
	if is_instance_valid(area) and not menu_open:
		for p in area.points:
			if p.kind=="exit": continue
			if hero.position.distance_to(p.pos)<95 or get_global_mouse_position().distance_to(p.pos+Vector2(0,-24))<45:
				canvas.draw_string(ThemeDB.fallback_font,p.pos+Vector2(-85,24),p.name+"  ·  E",HORIZONTAL_ALIGNMENT_CENTER,170,16,Color("ecd5a2"))
	if not menu_open:
		for id in campaign.data.loot:
			var drop: Dictionary=campaign.data.loot[id]
			if drop.area!=area.area_id: continue
			var location:=Vector2(drop.x,drop.y)
			var color:=Color("88cda9") if campaign.Gear.ITEMS[drop.item].rarity=="Improved" else Color("e0c98b")
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
			canvas.draw_string(ThemeDB.fallback_font,label.rect.position+Vector2(4,18),item.rarity+" · "+item.name+" · E",HORIZONTAL_ALIGNMENT_CENTER,242,14,Color("e6d7b1"))
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
		for i in range(5):
			var ray:=Vector2.from_angle(i*TAU/5+.3)
			canvas.draw_line(impact.pos+ray*3,impact.pos+ray*(6+(1-impact.time/.2)*10),Color(.6,.85,1,impact.time*5) if impact.magic else Color(1,.8,.45,impact.time*5),2)
	for n in numbers: canvas.draw_string(ThemeDB.fallback_font,n.pos,n.text,HORIZONTAL_ALIGNMENT_CENTER,-1,21,Color("f7db9b"))
	if is_instance_valid(target): canvas.draw_arc(target.position,24,0,TAU,32,Color("e8bd6f"),2)

func refresh_stats() -> void:
	stats=campaign.stats()
	if is_instance_valid(hero): hero.max_health=stats.hp;hero.health=minf(hero.health,hero.max_health)

func persist() -> void:
	campaign.data.defeated=defeated.duplicate();campaign.data.recovered=recovered
	campaign.data.random_dead=random_dead.duplicate();campaign.data.cycle=population_cycle
	campaign.data.respawn_remaining=maxf(0,respawn_time-elapsed)
	if not campaign.save() and is_instance_valid(overlay): overlay.notify(campaign.error)

func continue_campaign(id: String) -> void:
	if not campaign.load_slot(id): overlay.notify(campaign.error);return
	abilities.cancel(true);selected=campaign.data["class"];defeated=campaign.data.defeated.duplicate();recovered=campaign.data.get("recovered",false)
	random_dead.clear()
	for member in campaign.data.get("random_dead",[]): random_dead.append(int(member))
	population_cycle=int(campaign.data.get("cycle",0));respawn_time=elapsed+float(campaign.data.get("respawn_remaining",30))
	fallen=false;refresh_stats();enter_area(campaign.data.checkpoint);overlay.close()

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
	numbers.append({"pos":hero.position+Vector2(0,-80),"text":"-%d"%ceili(damage),"time":0.8});play_sound("hit-flesh")

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
	for control in [overlay.hud,overlay.toast,overlay.controls,overlay.attack_button,overlay.objective_label]+overlay.ability_buttons:
		if control.visible: occupied.append(inverse*control.get_global_rect().grow(5))
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

