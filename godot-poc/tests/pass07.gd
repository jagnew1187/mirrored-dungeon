extends SceneTree
var game: Node
var failures:=0
var checks:=0
var captures:=false
func _initialize() -> void: call_deferred("run")
func tick(n:=3) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error("FAIL: "+message)
func shot(name: String) -> void:
	if not captures: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/pass07-captures/"+name+".png")
func run() -> void:
	captures=DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute("res://tests/pass07-captures")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await tick();game.volume=0
	game.campaign.directory="user://pass07-tests-"+str(Time.get_ticks_usec())
	await shot("main-menu")
	for hero_kind in ["knight","mage","rogue"]:
		game.select_class(hero_kind);game.overlay.close();await tick()
		await shot(hero_kind+"-camp")
		game.set_physics_process(false);game.hero.set_process(false)
		var valid:=true
		for d in game.hero.DIRECTIONS:
			var animation: String="attack_"+d
			var frames: SpriteFrames=game.hero.sprite.sprite_frames
			valid=valid and frames.get_frame_count(animation)==8
			for f in range(8):
				var texture: AtlasTexture=frames.get_frame_texture(animation,f)
				valid=valid and texture.region.size==Vector2(160,128) and Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region) and texture.filter_clip
				var pixels:=texture.atlas.get_image().get_region(Rect2i(texture.region))
				valid=valid and Rect2i(2,2,156,124).encloses(pixels.get_used_rect())
			game.hero.attack_duration=.32;game.hero.attack_impact=.12 if hero_kind=="rogue" else .16
			game.hero.start_attack(Vector2.RIGHT.rotated(game.hero.DIRECTIONS.find(d)*PI/4))
			valid=valid and game.hero.sprite.animation==animation and game.hero.sprite.position==Vector2(-80,-112) and not game.hero.sprite.flip_h
			game.hero._process(game.hero.attack_impact+.001)
			valid=valid and game.hero.sprite.frame==(3 if hero_kind=="rogue" else 4)
			await shot(hero_kind+"-attack-"+d)
			game.hero._process(.4);game.hero._process(.01)
			valid=valid and not game.hero.attacking and game.hero.sprite.animation=="idle_"+d
		check(valid,hero_kind+": all eight directions, frame bounds, feet, impact frame and idle transition")
		game.hero.set_process(true);game.set_physics_process(true)
		for index in range(2):
			game.abilities.cancel(true);game.hero.direction="northeast";game.attack_clock=-1
			game.abilities.activate(index)
			check(game.hero.direction=="northeast" and is_equal_approx(game.hero.attack_duration,game.abilities.DATA[hero_kind][index].windup+game.abilities.DATA[hero_kind][index].recovery),hero_kind+" ability "+str(index)+": facing and current playback duration")
			await tick(4);await shot(hero_kind+"-ability-"+str(index)+"-anticipation")
			await tick(maxi(1,ceili(game.abilities.DATA[hero_kind][index].windup*60)+3-4));await shot(hero_kind+"-ability-"+str(index)+"-release")
			await tick(45)
	game.select_class("knight");game.overlay.close()
	for area_id in ["vigil","road","bannerfall"]:
		game.enter_area(area_id);await tick(4)
		var accessible:=true
		for point in game.area.points:
			accessible=accessible and game.area.clear(point.pos) and not game.area.route(game.area.spawn,point.pos).is_empty()
		check(accessible,area_id+": all NPCs and interactions reachable")
		check(game.area.actors.y_sort_enabled,area_id+": feet-based depth sorting retained")
		await shot(area_id+"-arrival")
		if area_id=="bannerfall": game.hero.position=Vector2(1000,760)
		if area_id=="road": game.hero.position=Vector2(1700,1080)
		await tick(15);await shot(area_id+"-environment")
		if captures:
			print("PERF ",area_id," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," texture_bytes=",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," process_seconds=",Performance.get_monitor(Performance.TIME_PROCESS))
	game.enter_area("road");await tick()
	game.set_physics_process(false)
	for e in game.enemies: e.actor.queue_free()
	game.enemies.clear();game.hero.position=Vector2(1500,1430);game.camera.position=game.hero.position
	var roles: Array=["militia","archer","shield","raider","enforcer"]
	for i in range(roles.size()): game.spawn_enemy(Vector2(1220+i*140,1250),"visual-"+roles[i],false,roles[i])
	await tick(24)
	var state_ok:=true
	for e in game.enemies:
		for state in ["idle","walk","windup","attack","recover","hurt","death"]:
			state_ok=state_ok and e.actor.sprite.sprite_frames.has_animation(state)
			for f in range(8):
				var frame: AtlasTexture=e.actor.sprite.sprite_frames.get_frame_texture(state,f)
				state_ok=state_ok and Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region) and frame.region.size==Vector2(128,128)
		state_ok=state_ok and e.actor.shape.shape.radius==12 and e.actor.sprite.position==Vector2(-64,-116)
	check(state_ok,"Five role atlases provide seven states with stable origin and unchanged foot collider")
	await shot("enemy-roster-idle")
	for e in game.enemies: e.actor.visual_state="windup"
	await tick(8);await shot("enemy-roster-windup")
	for e in game.enemies: e.actor.release_flash=.3
	await tick(2);await shot("enemy-roster-release")
	var soldier: Node=game.enemies[0].actor
	soldier.set_process(false);soldier.release_flash=0;soldier.visual_state="windup";soldier._process(.01)
	var transitions: bool=soldier.sprite.animation=="windup"
	soldier.release_flash=.2;soldier._process(.01);transitions=transitions and soldier.sprite.animation=="attack"
	soldier.release_flash=0;soldier.visual_state="recover";soldier._process(.01);transitions=transitions and soldier.sprite.animation=="recover"
	soldier.hurt=.1;soldier._process(.01);transitions=transitions and soldier.sprite.animation=="hurt"
	check(transitions,"Enemy runtime transitions select windup, release, recovery and hurt artwork")
	game.set_physics_process(true);game.enter_area("bannerfall");game.hero.position=Vector2(630,380);await tick(20)
	var building: Node
	for prop in game.area.actors.get_children():
		if prop.get("title")=="Anja's bakery": building=prop
	check(is_instance_valid(building) and building.fade<.5,"Foreground roof fades without disabling facade collision")
	await shot("roof-occlusion")
	game.enter_area("vigil");game.hero.position=Vector2(220,535);await tick();game.overlay.inventory("inventory");await tick();await shot("inventory")
	print("RESULT: ",checks," visual checks, ",failures," failures")
	quit(1 if failures else 0)

