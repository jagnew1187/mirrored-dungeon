extends SceneTree
var game: Node
var failures:=0
var checks:=0
var captures:=false
func _initialize() -> void: call_deferred("run")
func tick(n:=3) -> void:
	for i in range(n): await physics_frame
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error("FAIL: "+message)
func shot(name: String) -> void:
	if not captures: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/pass06-captures/"+name+".png")
func clear_enemies() -> void:
	for e in game.enemies: e.actor.queue_free()
	game.enemies.clear();game.projectiles.clear();game.target=null;game.path.clear()
func fixture(kind: String) -> void:
	game.select_class(kind);game.overlay.close();game.enter_area("road");clear_enemies()
	game.hero.position=Vector2(650,750);game.hero.direction="right"
	game.abilities.cancel(true);game.attack_clock=-1;game.cooldown=0
	await tick()
func spawn(offset: Vector2, role: String, id: String) -> Dictionary:
	game.spawn_enemy(game.hero.position+offset,id,false,role)
	var e: Dictionary=game.enemies.back();e.cooldown=10
	return e
func run() -> void:
	captures=DisplayServer.get_name()!="headless"
	if captures: DirAccess.make_dir_recursive_absolute("res://tests/pass06-captures")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await tick();game.volume=0
	game.campaign.directory="user://pass06-tests-"+str(Time.get_ticks_usec())
	await fixture("knight")
	var hp: float=game.hero.health
	game.damage_hero(20);var unguarded: float=hp-game.hero.health;game.hero.health=hp
	check(game.abilities.activate(0) and not game.abilities.activate(0),"Guard activates once; rapid repetition rejected")
	game.damage_hero(20)
	check(is_equal_approx(hp-game.hero.health,unguarded*0.35),"Guard mitigates damage after equipped defense")
	await tick(3);await shot("knight-guard")
	await tick(155);check(game.abilities.guard==0 and game.abilities.remaining[0]>0,"Guard expires before cooldown")
	var a:=spawn(Vector2(65,0),"militia","a");var b:=spawn(Vector2(55,35),"militia","b");var behind:=spawn(Vector2(-65,0),"militia","c")
	game.target=a.actor;var hits: int=game.hits_landed
	check(game.abilities.activate(1),"Cleaving Strike starts")
	await tick(5);check(a.actor.health==72,"Cleave waits for windup")
	await tick(14);await shot("knight-cleave")
	check(a.actor.health<72 and b.actor.health<72 and behind.actor.health==72,"Cleave hits two forward enemies but excludes rear")
	check(game.hits_landed-hits==2,"Cleave damages each victim once")
	await tick(28)
	game.overlay.page("pause");var timer: float=game.abilities.remaining[1];await tick(30)
	check(game.abilities.remaining[1]==timer and not game.overlay.ability_buttons[0].visible,"Modal freezes cooldown and hides abilities")
	game.overlay.close();game.enter_area("vigil");check(game.abilities.remaining[1]==timer,"Travel cannot refresh ability cooldown")
	await fixture("mage")
	a=spawn(Vector2(65,0),"militia","a");b=spawn(Vector2(-65,0),"militia","b")
	game.abilities.activate(0);await tick(8);await shot("mage-burst-windup")
	check(a.actor.health==72,"Burst waits for windup")
	await tick(10);await shot("mage-burst")
	check(a.actor.health<72 and b.actor.health<72 and a.stagger>0.4,"Burst hits both sides and staggers")
	await tick(20);clear_enemies();a=spawn(Vector2(190,0),"militia","a");game.target=a.actor
	check(game.abilities.activate(1),"Focused Bolt starts")
	await tick(23);await shot("mage-focused-bolt")
	check(game.projectiles.size()==1 and game.projectiles[0].get("focused",false),"Focused projectile has distinct presentation")
	await tick(30);check(a.actor.health<20,"Focused Bolt applies equipment-scaled impact")
	game.abilities.cancel(true);game.hero.position=Vector2(2700,415);game.hero.direction="up";clear_enemies();game.abilities.activate(1)
	await tick(55);check(game.projectiles.is_empty(),"Focused Bolt blocked by mill cover")
	await fixture("rogue")
	game.hero.direction="right";var initial: Vector2=game.hero.position
	game.abilities.activate(0);await tick(5);await shot("rogue-evasive-step");await tick(15)
	check(game.hero.position.x-initial.x>100 and game.hero.position.x-initial.x<=150,"Evasive Step has controlled finite distance")
	game.enter_area("vigil");game.hero.position=Vector2(250,335);game.hero.direction="up";game.abilities.cancel(true);await tick()
	game.abilities.activate(0);await tick(20)
	check(game.hero.position.y>=306,"Evasive Step respects native tent collision")
	await fixture("rogue");a=spawn(Vector2(210,0),"militia","a");game.target=a.actor
	game.abilities.activate(1);await tick(8);check(game.projectiles.size()==1,"Twin Daggers first release")
	await tick(9);await shot("rogue-twin-daggers");check(game.projectiles.size()==2,"Twin Daggers separate second release")
	hits=game.hits_landed;await tick(30);check(game.hits_landed-hits==2,"Both daggers hit once each")
	await fixture("mage");game.abilities.activate(1);game.overlay.page("journal");await tick(30);game.overlay.close();await tick(40)
	check(game.projectiles.is_empty() and game.abilities.remaining[1]>0,"Dialogue cancels pending release without refund")
	await fixture("knight");a=spawn(Vector2(60,0),"shield","shield");a.actor.direction="left"
	await tick();await shot("shielded-soldier")
	game.damage_enemy(a,20);check(is_equal_approx(a.actor.health,64),"Shield reduces frontal hit to 40 percent")
	game.damage_enemy(a,20,a.actor.position+Vector2(50,0));check(is_equal_approx(a.actor.health,44),"Shield rear receives full damage")
	a.stagger=0;a.state="recover";game.damage_enemy(a,20);check(is_equal_approx(a.actor.health,24),"Shield recovery opens frontal defense")
	await fixture("mage");a=spawn(Vector2(200,0),"archer","archer");a.cooldown=0
	await tick(10);await shot("archer-windup");check(a.state=="windup","Archer selects ranged windup")
	await tick(35);check(game.projectiles.any(func(p):return p.get("hostile",false)),"Archer releases hostile arrow")
	clear_enemies();game.hero.position=Vector2(2700,420);a=spawn(Vector2(0,-220),"archer","archer");a.cooldown=0
	await tick(80);check(game.projectiles.is_empty() and a.state=="idle","Archer cannot acquire through solid mill")
	game.projectiles.append({"pos":Vector2(2700,200),"direction":Vector2.DOWN,"travel":0.0,"kind":"arrow","damage":20.0,"max":350.0,"hostile":true})
	hp=game.hero.health;await tick(35);check(game.projectiles.is_empty() and game.hero.health==hp,"Hostile arrows collide with cover")
	await fixture("knight");a=spawn(Vector2(65,0),"militia","a");b=spawn(Vector2(80,0),"raider","b")
	check(game.enemy_ai.separation(a).x<0 and game.enemy_ai.separation(b).x>0,"Group separation pushes neighbors apart")
	a.actor.position=a.home+Vector2(90,0);game.hero.position=a.home+Vector2(400,0);await tick(5)
	check(a.state=="return","Leash disengages pursuit")
	await tick(120);check(a.actor.position.distance_to(a.home)<48,"Disengaged fighter navigates back home")
	await fixture("knight");a=spawn(Vector2(40,0),"raider","raider");a.cooldown=0;await tick(10);await shot("raider-windup")
	await tick(12);check(a.state=="burst","Raider commits to second attack burst")
	await tick(14);check(a.state=="recover","Raider exposes recovery window")
	await fixture("knight");a=spawn(Vector2(70,0),"enforcer",game.ELITE);a.cooldown=0
	await tick(10);await shot("enforcer-lunge-telegraph")
	check(a.state=="windup" and a.pattern==1,"Enforcer telegraphs lunge")
	await tick(48);check(a.state=="lunge","Enforcer commits to collision-aware lunge")
	await tick(22);check(a.state=="recover","Enforcer recovery follows lunge")
	game.hero.position=a.actor.position+Vector2(65,0);await tick(80);await shot("enforcer-sweep-telegraph")
	check(a.pattern==0,"Enforcer alternates sweep pattern")
	var xp: int=game.campaign.data.xp;game.damage_enemy(a,10000);game.damage_enemy(a,10000)
	check(game.campaign.data.xp==xp+45 and game.campaign.data.loot.has(game.ELITE),"Elite reward and ground drop claimed once")
	check(game.defeated.is_empty() and not game.encounter_complete(),"Elite does not count toward flour patrol")
	game.enter_area("road");check(not game.enemies.any(func(e):return e.role=="enforcer"),"Defeated elite stays absent on travel")
	game.persist();var slot: String=game.campaign.slot;game.continue_campaign(slot);game.enter_area("road")
	check(not game.enemies.any(func(e):return e.role=="enforcer") and game.campaign.data.loot.has(game.ELITE),"Elite claim and uncollected loot survive Continue")
	await fixture("knight");a=spawn(Vector2(50,0),"militia","a");b=spawn(Vector2(68,25),"militia","b")
	game.target=a.actor;game.path.append(Vector2(900,900));game.damage_enemy(a,1000)
	check(game.target==null and game.path.is_empty(),"Target death clears target and approach immediately")
	game.action_input_armed=true;game.attack_held=true;await tick(25);game.attack_held=false
	check(b.actor.health<72 and game.hero.position.distance_to(Vector2(650,750))<4,"Held attack acquires nearby victim without distant auto-chase")
	game.abilities.activate(0);game.hero.health=0;await tick();check(game.fallen and game.abilities.guard==0,"Death cancels defensive effect")
	game.recover();check(not game.fallen and game.abilities.active==-1,"Recovery clears pending ability")
	game.enter_area("bannerfall");game.hero.position=Vector2(650,730)
	for i in range(4): game.campaign.add_loot("label"+str(i),"tonic","bannerfall",Vector2(650+i*3,730))
	await tick();var labels: Array=game.loot_labels();var overlaps:=false
	for i in range(labels.size()):
		for j in range(i+1,labels.size()):
			if labels[i].rect.intersects(labels[j].rect): overlaps=true
	check(labels.size()==4 and not overlaps,"Clustered loot label rectangles do not overlap")
	await tick();await shot("loot-labels")
	game.world_click(labels[0].rect.get_center());check(not game.campaign.data.loot.has(labels[0].id),"Offset label is a working pickup target")
	check(game.area.clear(game.safe_loot_position(Vector2(650,570)),18),"Ground drop placement finds clear geometry")
	await fixture("mage");game.begin_attack()
	check(game.abilities.activate(1),"Ability buffers during ordinary attack")
	await tick(24);check(game.abilities.active==1 and game.abilities.remaining[1]>4,"Buffered ability starts after attack recovery")
	game.overlay.page("pause");game.overlay.close();game.abilities.cancel(true);await tick()
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=game.overlay.ability_buttons[0].get_global_rect().get_center();touch.pressed=true
	root.push_input(touch,true);await tick(2);touch.pressed=false;root.push_input(touch,true);await tick(2)
	check(game.abilities.remaining[0]>0,"Touch press/release activates ability button")
	await fixture("knight");a=spawn(Vector2(100,0),"archer","archer");a.cooldown=1.0
	var archer_start: Vector2=a.actor.position;await tick(25)
	check(a.actor.position.distance_to(game.hero.position)>archer_start.distance_to(game.hero.position),"Archer repositions away from close hero")
	game.queue_free();await tick();print("RESULT: %d checks, %d failures"%[checks,failures]);quit(failures)




