extends SceneTree
var game: Node
var failures:=0
var checks:=0

func _initialize() -> void: call_deferred("run")
func tick(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool, text: String) -> void:
	checks+=1
	if ok: print("PASS: "+text)
	else: failures+=1;push_error("FAIL: "+text)
func key(code: int, pressed: bool) -> void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed;Input.parse_input_event(e)

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await tick(3);game.overlay.close()
	game.volume=0
	game.hero.position=Vector2(250,320);await tick(2);key(KEY_W,true);await tick(25);key(KEY_W,false);await tick(3)
	check(game.hero.position.y>=306,"Native collision blocks tent footprint")
	check(not game.hero.moving,"Collision does not play sliding walk forever")
	game.hero.position=Vector2(510,575);game.approach(game.area.points[0]);key(KEY_D,true);await tick(2);key(KEY_D,false)
	check(game.pending.is_empty(),"Manual input cancels NPC approach")
	game.approach(game.area.points[0]);game.overlay.page("pause");check(game.pending.is_empty(),"Menu cancels NPC approach")
	game.overlay.close();game.enter_area("road");await tick(3)
	for e in game.enemies: e.actor.queue_free()
	game.enemies.clear();await tick(2)
	check(not game.encounter_complete(),"Absent enemies cannot complete authored encounter")
	game.hero.position=Vector2(650,700);game.spawn_enemy(Vector2(710,700),"captain",false);game.spawn_enemy(Vector2(590,700),"escort",false)
	await tick(2);game.target=game.enemies[0].actor
	var behind: Node2D=game.enemies[1].actor;var behind_hp: float=behind.health
	game.request_attack();await tick(2)
	check(game.enemies[0].actor.health==72,"Damage waits for strike frame")
	game.request_attack();await tick(13)
	check(behind.health==behind_hp,"Directional sword cannot hit behind its strike")
	await tick(20);check(game.attacks_started==2,"Early repeated command buffers exactly one next attack")
	game.overlay.page("pause");var timer: float=game.attack_clock;var hp: float=game.hero.health
	await tick(50);check(game.attack_clock==timer and game.hero.health==hp,"Pause freezes combat and damage")
	check(not game.overlay.hud.visible and not game.overlay.attack_button.visible,"Critical modal hides health and attack controls")
	game.overlay.close();await tick(25)
	game.enter_area("road");await tick(3)
	var e: Dictionary=game.enemies[0];e.actor.position=e.home+Vector2(80,0);game.hero.position=e.home+Vector2(400,0)
	await tick(4);check(e.state=="return","Leash enters explicit return state")
	game.hero.position=Vector2(200,1800);game.random_dead.assign([0,1,2]);game.respawn_time=game.elapsed+1
	for enemy in game.enemies.duplicate():
		if enemy.random: enemy.actor.queue_free();game.enemies.erase(enemy)
	await tick(15);check(game.enemies.filter(func(enemy):return enemy.role!="enforcer").size()==2,"Random population respects cooldown")
	await tick(60);check(game.enemies.filter(func(enemy):return enemy.role!="enforcer").size()==5,"Random population respawns only after distant cooldown")
	check(game.defeated.is_empty(),"Random population state leaves quest ledger untouched")
	game.hero.position=Vector2(650,750);await tick(3)
	var touch:=InputEventScreenTouch.new();touch.index=1;touch.position=root.get_canvas_transform()*Vector2(650,616);touch.pressed=true;game._unhandled_input(touch)
	check(game.pending.get("id","")=="cross","Touch NPC/landmark target respects scrolling camera")
	game.cancel_approach();touch.index=0;touch.position=Vector2(100,550);game._unhandled_input(touch)
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(150,550);game._unhandled_input(drag)
	check(game.joystick.x>0.7,"Touch joystick drag produces movement")
	touch.pressed=false;game._unhandled_input(touch);check(game.joystick==Vector2.ZERO,"Touch release stops joystick")
	game.select_class("mage");game.overlay.close();game.enter_area("road");await tick(3)
	game.hero.position=Vector2(2650,450);game.target=null;game.hero.direction="up";game.request_attack();await tick(25)
	check(game.projectiles.is_empty(),"Projectile collides with solid mill structure")
	print("RESULT: %d contract checks, %d failures"%[checks,failures]);game.queue_free();await tick(3);quit(1 if failures else 0)
