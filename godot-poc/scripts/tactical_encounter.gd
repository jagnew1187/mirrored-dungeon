extends Node2D
var game: Node
var active:=false
var paused:=false
var phase:="player"
var round_number:=0
var action_available:=true
var movement:=0.0
var mode:="target"
var selected_target:=true
var enemy: Dictionary={}
var config: Dictionary={}
var snapshot: Dictionary={}
var route:=PackedVector2Array()
var preview:=PackedVector2Array()
var reachable_cells: Array[Vector2]=[]
var navigation=preload("res://scripts/tactical_navigation.gd").new()
var hud: CanvasLayer
var feedback:=""
var turn_cooldowns: Array[int]=[0,0]
var used_skills: Array[bool]=[false,false]
var guarding:=false
var resolving:=false
var enemy_release:=false
var victory_pending:=false
var action_kind:=""
var action_clock:=0.0
var released:=false
var warden_state:="approach"
var danger_origin:=Vector2.ZERO
var danger_direction:=Vector2.RIGHT
var starts:=0
var enemy_releases:=0
var last_move_cost:=0.0
var spent_movement:=0.0
const Patterns=preload("res://scripts/tactical_patterns.gd")
var pattern:="heavy"
var planned_pattern:="heavy"
var enemy_actions:=0
var last_quick:=-100
var major_count:=0
var tracking_left:=0
var locked_left:=0
var hazard_center:=Vector2.ZERO
var hazards: Array[Dictionary]=[]
var metrics: Dictionary={}
func attack_data() -> Dictionary: return config.patterns[pattern]


func _ready() -> void:
	navigation.game=game;z_index=5
	hud=CanvasLayer.new();hud.set_script(load("res://scripts/tactical_hud.gd"));hud.encounter=self;hud.layer=20;hud.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;add_child(hud)

func begin(e: Dictionary) -> bool:
	if active or game.menu_open or game.fallen: return false
	config=game.tc_data.mirror_warden;navigation.center=Vector2(config.center[0],config.center[1]);navigation.radius=config.radius
	if not navigation.inside(game.hero.position) or not game.area.line_clear(game.hero.position,e.actor.position): game.overlay.notify("Move into the Warden clearing before engaging.");return false
	game.persist()
	snapshot={"data":game.campaign.data.duplicate(true),"revision":game.campaign.revision,"hero":game.hero.position,"health":game.hero.health,"enemy":e.actor.position,"enemy_health":e.actor.health,"remaining":game.abilities.remaining.duplicate(),"guard":game.abilities.guard,"initial_guard":game.abilities.guard}
	hud.skills_open=false;hud.touches.clear()
	pattern="heavy";planned_pattern="heavy";enemy_actions=0;last_quick=-100;major_count=0;hazards.clear();enemy_releases=0
	metrics={"attempted":0,"avoided":0,"hits":0,"damage":0.0,"guards":0,"movement":0.0,"interrupts":0,"patterns":[]}

	enemy=e;active=true;starts+=1;paused=false;victory_pending=false;warden_state="approach";round_number=0;used_skills.assign([false,false])
	for i in range(2):
		turn_cooldowns[i]=ceili(game.abilities.remaining[i]/game.tc_data.seconds_per_turn);used_skills[i]=game.abilities.remaining[i]>0
	guarding=game.abilities.guard>0
	game.abilities.cancel();game.cancel_approach();game.attack_clock=-1;game.attack_buffer=0;game.attack_held=false;game.projectiles.clear();game.hero.attacking=false
	game.target=enemy.actor;enemy.actor.velocity=Vector2.ZERO;selected_target=true
	new_player_turn(true);feedback="Choose Move, Attack or a skill. One action per turn."
	return true

func available() -> bool: return active and not paused and not game.menu_open and phase=="player" and route.is_empty()

func new_player_turn(first:=false) -> void:
	phase="player";round_number+=1;action_available=true;movement=game.tc_data.player_movement[game.selected];spent_movement=0;mode="target";preview.clear();reachable_cells.clear()
	if not first:
		guarding=false;snapshot.guard=0
		for i in range(2): turn_cooldowns[i]=maxi(0,turn_cooldowns[i]-1)
	game.hero.moving=false;game.hero.attacking=false;game.attack_clock=-1;resolving=false

func choose_move() -> void:
	if not available(): return
	mode="move";preview.clear();navigation.rebuild(game.hero);reachable_cells=navigation.reachable(game.hero.position,movement);feedback="Tap a destination, then Confirm. Cancel keeps your allowance."

func select_world(point: Vector2) -> void:
	if not available(): return
	if mode=="move":
		preview=navigation.route(game.hero.position,point,movement)
		feedback="Route %.0f / %.0f · Confirm to walk"%[navigation.cost(game.hero.position,preview),movement] if not preview.is_empty() else "Blocked, outside the boundary, or beyond remaining movement."
		return
	if is_instance_valid(enemy.get("actor")) and (point.distance_to(enemy.actor.position)<55 or point.distance_to(enemy.actor.position+Vector2(0,-45))<55):
		selected_target=true;game.target=enemy.actor
		if mode=="attack": attack()
		elif mode.begins_with("skill"): skill(int(mode.right(1)))
		else: feedback="Mirror Warden selected. Choose an action."

func confirm_move() -> bool:
	if not available() or preview.is_empty(): return false
	navigation.rebuild(game.hero)
	var checked: PackedVector2Array=navigation.route(game.hero.position,preview[-1],movement)
	if checked.is_empty(): preview.clear();feedback="Route changed. Choose a valid destination.";return false
	route=checked;preview.clear();reachable_cells.clear();phase="player_move";mode="target";last_move_cost=0
	return true

func clear_selection() -> void:
	if not available(): return
	preview.clear();reachable_cells.clear();selected_target=false;game.target=null;mode="target";feedback="Target cleared. Tap the Warden to select."

func attack() -> bool:
	if not available() or not action_available: return false
	preview.clear();reachable_cells.clear();mode="attack"
	if not valid_action(game.stats.range): return false
	action_available=false;phase="player_action";action_kind="basic";action_clock=0;released=false;resolving=true;game.target=enemy.actor
	game.begin_attack();return true

func valid_action(reach: float) -> bool:
	if not selected_target: feedback="Tap the Warden to choose your target.";return false
	if not is_instance_valid(enemy.get("actor")) or enemy.actor.health<=0: return false
	if game.hero.position.distance_to(enemy.actor.position)>reach: feedback="Out of range. Move closer; no action spent.";return false
	if not game.area.line_clear(game.hero.position,enemy.actor.position): feedback="Cover blocks line of sight; no action spent.";return false
	return true

func skill(index: int) -> bool:
	if not available() or not action_available or index<0 or index>1: return false
	if turn_cooldowns[index]>0: feedback="Skill ready in %d player turns."%turn_cooldowns[index];return false
	var ability: Dictionary=game.abilities.DATA[game.selected][index]
	preview.clear();reachable_cells.clear();mode="skill"+str(index)
	if ability.has("damage") and not valid_action(ability.range): return false
	if game.selected=="knight" and index==0:
		if not guard_action(): return false
		turn_cooldowns[index]=ceili(ability.cooldown/game.tc_data.seconds_per_turn);used_skills[index]=true;return true
	if game.selected=="rogue" and index==0:
		navigation.rebuild(game.hero)
		var aim:=Vector2.RIGHT.rotated(game.hero.DIRECTIONS.find(game.hero.direction)*PI/4)
		var goal: Vector2=game.hero.position+aim*minf(movement,ability.speed*ability.duration)
		if movement<1 or not navigation.segment(game.hero.position,goal): feedback="Evasive Step needs a clear route and movement allowance.";return false
		route=PackedVector2Array([goal])
	resolving=true;game.target=enemy.actor if selected_target else null;game.abilities.remaining[index]=0
	if not game.abilities.activate(index): resolving=false;route.clear();return false
	turn_cooldowns[index]=ceili(ability.cooldown/game.tc_data.seconds_per_turn);used_skills[index]=true;action_available=false;phase="player_action";action_kind="skill";action_clock=0
	return true

func guard_action() -> bool:
	if not available() or not action_available: return false
	preview.clear();reachable_cells.clear();mode="target"
	metrics.guards+=1
	action_available=false;guarding=true;game.hero.guard_time=2.5;game.hero.start_attack(Vector2.RIGHT.rotated(game.hero.DIRECTIONS.find(game.hero.direction)*PI/4),"guard")
	feedback="Guard: 65% reduction on next strike; expires next player turn.";return true

func tonic() -> bool:
	if not available() or not action_available: return false
	if game.hero.health>=game.hero.max_health: feedback="Already at full health; no action spent.";return false
	for i in range(game.campaign.data.inventory.size()):
		if game.campaign.data.inventory[i].id=="tonic":
			if game.use_tonic(i): game.campaign.error="";action_available=false;feedback="Restored up to 60 health. One tonic consumed.";return true
	feedback="No restorative tonic in the backpack.";return false

func end_turn() -> bool:
	if not available(): return false
	preview.clear();reachable_cells.clear();mode="target";action_available=false;phase="enemy_plan";feedback="Mirror Warden's turn";return true

func pause() -> void:
	if active: paused=true;preview.clear();reachable_cells.clear();feedback="Paused. Saving disabled. Withdraw restores the pre-fight checkpoint."

func resume() -> void:
	paused=false;feedback="Resumed · "+("your turn" if phase.begins_with("player") else "Warden's turn")

func tick(delta: float) -> void:
	if not active: return
	if game.menu_open and game.overlay.page_id in ["title","slots","characters"]: withdraw(false);return
	var stopped: bool=paused or game.menu_open
	game.hero.paused=stopped
	for e in game.enemies:
		if is_instance_valid(e.actor): e.actor.paused=stopped or e!=enemy;e.actor.moving=false;e.actor.velocity=Vector2.ZERO
	if stopped: game.hero.moving=false;return
	if warden_state=="tracking":
		danger_direction=danger_origin.direction_to(game.hero.position);enemy.actor.face(danger_direction)

	game.hero.guard_time=2.5 if guarding else 0
	match phase:
		"player_move":
			advance_route(game.hero,delta,game.stats.speed,true)
			if route.is_empty(): phase="player";feedback="Movement %.0f remaining. Action %s."%[movement,"ready" if action_available else "spent"]
		"player_action":
			action_clock+=delta;enemy.stagger=maxf(0,enemy.stagger-delta)
			if action_kind=="basic":
				if not released and action_clock>=game.stats.windup: released=true;game.release_attack();game.attack_released=true
				if action_clock>=.32: game.attack_clock=-1
			else:
				var frozen: Array=game.abilities.remaining.duplicate();game.abilities.update(delta);game.abilities.remaining.assign(frozen)
				if not route.is_empty(): advance_route(game.hero,delta,game.abilities.DATA.rogue[0].speed,true)
			game.update_projectiles(delta)
			if victory_pending and game.abilities.active<0 and game.attack_clock<0 and game.projectiles.is_empty(): finish_victory();return
			if action_clock>=.32 and game.abilities.active<0 and game.attack_clock<0 and game.projectiles.is_empty() and route.is_empty():
				enemy["tactical_stagger"]=enemy.stagger>.3;enemy.stagger=0
				resolving=false;phase="player";game.hero.moving=false;game.abilities.rings.clear();game.abilities.echoes.clear();feedback="Action spent. You may still move or End Turn."
		"enemy_plan": plan_enemy()
		"enemy_move":
			advance_route(enemy.actor,delta,130,false)
			if route.is_empty(): prepare_enemy()
		"enemy_wait":
			action_clock+=delta
			if action_clock>=.35: new_player_turn()
		"enemy_strike":
			action_clock+=delta
			var data:=attack_data()
			if action_clock>=data.windup and not released: release_pattern()
			if game.hero.health<=0: finish_defeat();return
			if action_clock>=data.windup+data.recovery:
				warden_state="approach" if pattern=="quick" else "recovery";enemy.state="recover";enemy.actor.visual_state="recover"
				feedback="Quick strike resolved. Space or Guard before the next close exchange." if pattern=="quick" else "Recovery opening: +50% damage this player turn."
				new_player_turn()
	game.camera.position=game.hero.position
	if hud.root.visible and hud.panel.global_position.y>0:
		var half: float=game.get_viewport_rect().size.y*.5
		var desired: float=minf(half,hud.panel.global_position.y-50)
		game.camera.position.y+=(half-desired)/game.camera.zoom.y
	for n in game.numbers: n.time-=delta;n.pos.y-=delta*24
	game.numbers=game.numbers.filter(func(n):return n.time>0)
	for impact in game.impacts: impact.time-=delta
	game.impacts=game.impacts.filter(func(i):return i.time>0)
	game.queue_redraw();queue_redraw()

func advance_route(actor: CharacterBody2D,delta: float,speed: float,player: bool) -> void:
	if route.is_empty(): actor.moving=false;return
	var dest: Vector2=route[0];var distance: float=actor.position.distance_to(dest)
	if distance<.05: route.remove_at(0);return
	var step: float=minf(distance,speed*delta)
	if player: step=minf(step,movement)
	var old: Vector2=actor.position;navigation.mover=actor
	var next: Vector2=old.move_toward(dest,step)
	if step<.001 or not navigation.segment(old,next): route.clear();feedback="Movement stopped at an obstacle.";return
	game.move_actor(actor,(next-old)/delta)
	var traveled: float=old.distance_to(actor.position)
	if player: movement=maxf(0,movement-traveled);spent_movement+=traveled;last_move_cost+=traveled;metrics.movement+=traveled
	if traveled<.001: route.clear()
	elif actor.position.distance_to(dest)<.1: route.remove_at(0)

func plan_enemy() -> void:
	enemy_actions+=1
	# Hazards pulse only on turn boundaries, never on render/physics ticks.
	for zone in hazards:
		if game.hero.position.distance_to(zone.center)<=zone.radius and game.area.line_clear(zone.origin,game.hero.position): apply_enemy_damage(zone.damage)
		zone.turns-=1
	hazards=hazards.filter(func(zone):return zone.turns>0)
	if game.hero.health<=0: finish_defeat();return
	if enemy.get("tactical_stagger",false):
		enemy.tactical_stagger=false;metrics.interrupts+=1;warden_state="recovery";enemy.actor.visual_state="recover";phase="enemy_wait";action_clock=0;feedback="Interrupted! Charge cancelled; recovery opening.";return
	if warden_state=="tracking":
		tracking_left-=1
		if tracking_left<=0:
			warden_state="locked";locked_left=int(config.patterns.tracking.locked_response_turns);feedback="LOCKED charge: cyan direction is fixed. Full response turn before release."
		phase="enemy_wait";action_clock=0;return
	if warden_state in ["prepare","locked","denial"]:
		if warden_state=="locked":
			locked_left-=1
			if locked_left>0: phase="enemy_wait";action_clock=0;return
		start_release();return
	planned_pattern=Patterns.choose(enemy.actor.position.distance_to(game.hero.position),enemy_actions,last_quick,major_count,config.patterns)
	warden_state="approach";enemy.state="pursue";enemy.actor.visual_state="idle";navigation.rebuild(enemy.actor)
	var best:=PackedVector2Array();var best_cost:=INF
	for i in range(24):
		var goal: Vector2=game.hero.position+Vector2.from_angle(i*TAU/24)*95
		if not game.area.line_clear(goal,game.hero.position): continue
		var candidate: PackedVector2Array=navigation.route(enemy.actor.position,goal,INF)
		var distance: float=navigation.cost(enemy.actor.position,candidate)
		if not candidate.is_empty() and distance<best_cost: best=candidate;best_cost=distance
	route.clear();var remaining: float=config.movement;var previous: Vector2=enemy.actor.position
	for point in best:
		var length: float=previous.distance_to(point)
		if length>=remaining:
			route.append(previous.move_toward(point,remaining));break
		route.append(point);remaining-=length;previous=point
	if route.is_empty(): prepare_enemy()
	else: phase="enemy_move"

func prepare_enemy() -> void:
	pattern=planned_pattern
	var data:=attack_data()
	if enemy.actor.position.distance_to(game.hero.position)<=data.range and game.area.line_clear(enemy.actor.position,game.hero.position):
		danger_origin=enemy.actor.position;danger_direction=enemy.actor.position.direction_to(game.hero.position);enemy.actor.face(danger_direction);enemy.actor.visual_state="windup"
		if pattern=="quick":
			last_quick=enemy_actions;feedback="QUICK STRIKE: close-range counter. Guard or space before ending your turn.";start_release();return
		major_count+=1
		match pattern:
			"tracking": warden_state="tracking";tracking_left=int(data.tracking_turns);feedback="TRACKING (amber): follows during this turn. End Turn locks aim; then you get a response turn."
			"denial": warden_state="denial";hazard_center=game.hero.position;feedback="GROUND WARNING (violet): leave the circle. After release it pulses at your next two End Turns."
			_: warden_state="prepare";feedback="HEAVY (red): direction locked. Move outside the wedge or Guard."
	else: feedback="Warden repositions. Range or cover prevents a clear attack."
	phase="enemy_wait";action_clock=0

func start_release() -> void:
	phase="enemy_strike";action_clock=0;released=false;enemy.actor.attacking=false;enemy.actor.visual_state="windup"

func apply_enemy_damage(amount: float) -> void:
	var hp: float=game.hero.health
	enemy_release=true;game.damage_hero(amount);enemy_release=false
	metrics.damage+=hp-game.hero.health

func release_pattern() -> void:
	released=true;enemy_releases+=1;metrics.attempted+=1;metrics.patterns.append(pattern)
	enemy.actor.release_flash=.25;enemy.actor.visual_state="recover";game.play_sound("sword-swing")
	if pattern=="denial":
		var data:=attack_data()
		hazards.append({"center":hazard_center,"origin":danger_origin,"radius":data.radius,"turns":int(data.lifetime),"damage":data.pulse_damage})
		feedback="Hazard active: violet ground pulses on End Turn; cross it freely, finish outside."
	elif threatened(game.hero.position) and game.area.line_clear(danger_origin,game.hero.position):
		metrics.hits+=1;apply_enemy_damage(attack_data().damage)
		game.impacts.append({"pos":game.hero.position+Vector2(0,-36),"time":.20,"magic":false,"blocked":guarding})
	else: metrics.avoided+=1;feedback="Miss: you were outside the committed strike or behind cover."

func danger_polygon() -> PackedVector2Array:
	return Patterns.polygon(danger_origin,danger_direction,attack_data())

func threatened(p: Vector2) -> bool: return Geometry2D.is_point_in_polygon(p,danger_polygon())

func restore_controls() -> void:
	hazards.clear()
	active=false;paused=false;resolving=false;route.clear();preview.clear();reachable_cells.clear();game.abilities.cancel();game.attack_clock=-1;game.cancel_approach();game.projectiles.clear();game.hero.moving=false;game.hero.attacking=false;game.release_inputs();game.movement_rearm=true
	for i in range(2): game.abilities.remaining[i]=minf(game.abilities.DATA[game.selected][i].cooldown,turn_cooldowns[i]*game.tc_data.seconds_per_turn) if used_skills[i] else snapshot.remaining[i]
	game.abilities.guard=snapshot.guard
	for e in game.enemies:
		if is_instance_valid(e.actor): e.actor.paused=game.menu_open;e.actor.moving=false
	game.hero.paused=game.menu_open;game.campaign.error="";game.overlay.request_relayout();queue_redraw()

func finish_victory() -> void:
	var actor: Node2D=enemy.actor;restore_controls();game.enemies.erase(enemy);actor.begin_death();actor.moving=false
	if game.campaign.award(config.id,config.xp,config.gold): game.campaign.add_loot(config.id,config.loot,game.area.area_id,game.safe_loot_position(actor.position))
	game.refresh_stats();game.persist();game.overlay.notify("Mirror Warden defeated · +45 XP · +15 coins · Loot nearby")

func finish_defeat() -> void:
	restore_controls();game.fallen=true;game.hero.health=0;game.hero.begin_death(false);game.persist();game.overlay.page("defeat")

func withdraw(close_menu:=true) -> void:
	if not active: return
	game.campaign.data=snapshot.data.duplicate(true);game.campaign.revision=snapshot.revision+1;game.hero.position=snapshot.hero;game.hero.health=snapshot.health;game.hero.reset_physics_interpolation()
	if is_instance_valid(enemy.get("actor")): enemy.actor.position=snapshot.enemy;enemy.actor.health=snapshot.enemy_health;enemy.actor.reset_physics_interpolation();enemy.state="idle";enemy.actor.visual_state="idle";enemy.stagger=0
	used_skills.assign([false,false]);snapshot.guard=snapshot.initial_guard
	restore_controls();game.refresh_stats();game.camera.position=game.hero.position;game.camera.reset_physics_interpolation()
	if close_menu: game.overlay.close()
	game.persist();game.overlay.notify("Withdrew safely. Pre-encounter health, inventory and world restored.")

func _draw() -> void:
	if not active:
		for e in game.enemies:
			if e.get("combat_mode","")=="tactical" and is_instance_valid(e.actor):
				draw_arc(e.actor.position,32,0,TAU,48,Color("d4ae66"),2);draw_string(ThemeDB.fallback_font,e.actor.position+Vector2(-80,-122),"Mirror Warden · Tactical",HORIZONTAL_ALIGNMENT_CENTER,160,14,Color("efce82"))
		return
	draw_arc(navigation.center,navigation.radius,0,TAU,96,Color(.8,.68,.4,.4),2)
	if mode=="move":
		for point in reachable_cells: draw_rect(Rect2(point-Vector2.ONE*12,Vector2.ONE*24),Color(.3,.75,.7,.12))
	if not preview.is_empty():
		var line:=PackedVector2Array([game.hero.position]);line.append_array(preview);draw_polyline(line,Color(.6,1,.85,.9),3);draw_circle(preview[-1],10,Color(.6,1,.85,.5))
	if warden_state in ["prepare","tracking","locked"] or (phase=="enemy_strike" and pattern!="denial"):
		var color:=Color(1,.27,.16,.24)
		if warden_state=="tracking": color=Color(1,.72,.16,.22)
		elif warden_state=="locked": color=Color(.25,.85,1,.24)
		elif pattern=="quick": color=Color(1,.93,.65,.24)
		var poly:=danger_polygon();draw_colored_polygon(poly,color);poly.append(poly[0]);color.a=.85;draw_polyline(poly,color,2)
		draw_line(danger_origin,danger_origin+danger_direction*attack_data().range,color,3)
	if warden_state=="denial": draw_circle(hazard_center,config.patterns.denial.radius,Color(.8,.45,1,.16));draw_arc(hazard_center,config.patterns.denial.radius,0,TAU,48,Color(.8,.5,1,.9),2)
	for zone in hazards:
		draw_circle(zone.center,zone.radius,Color(.6,.25,.9,.22));draw_arc(zone.center,zone.radius,0,TAU,48,Color(.85,.55,1,.9),3)
		draw_string(ThemeDB.fallback_font,zone.center+Vector2(-35,8),"%d turns"%zone.turns,HORIZONTAL_ALIGNMENT_CENTER,70,14,Color(.95,.8,1))
	if warden_state=="recovery": draw_arc(enemy.actor.position,36,0,TAU,48,Color(.5,.9,1,.9),3)
	if guarding: draw_arc(game.hero.position,27,0,TAU,40,Color(.5,.8,1,.9),2)

func _process(_delta: float) -> void: queue_redraw()
