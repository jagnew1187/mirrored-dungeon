extends SceneTree
## Engine-driven full routes with normal damage/HP, not desktop input.
var game: Node
var failures:=0
var checks:=0
func _initialize() -> void: call_deferred("run")
func tick(n:=3) -> void:
	for i in range(n): await physics_frame
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error("FAIL: "+message)
func walk(id: String, budget:=2400) -> void:
	for p in game.area.points:
		if p.id==id: game.approach(p);break
	for i in range(budget):
		await physics_frame
		if game.menu_open or game.pending.is_empty(): return
func battle() -> void:
	for frame in range(7200):
		if game.fallen or game.enemies.is_empty(): return
		if frame%12==0:
			var closest: Dictionary={};var distance:=INF
			for e in game.enemies:
				var d: float=game.hero.position.distance_to(e.actor.position)
				if d<distance: closest=e;distance=d
			if not closest.is_empty():
				game.world_click(closest.actor.position+Vector2(0,-25))
				if distance<game.stats.range and game.attack_clock<0:
					if game.selected=="knight" and game.abilities.remaining[0]<=0: game.abilities.activate(0)
					elif game.abilities.remaining[1]<=0: game.abilities.activate(1)
					elif game.selected=="mage" and distance<130: game.abilities.activate(0)
			if game.hero.health<game.hero.max_health*0.45:
				for index in range(game.campaign.data.inventory.size()):
					if game.campaign.data.inventory[index].id=="tonic": game.use_tonic(index);break
		await physics_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await tick();game.volume=0
	game.campaign.directory="user://pass06-campaign-"+str(Time.get_ticks_usec())
	for kind in ["knight","mage","rogue"]:
		game.select_class(kind);game.overlay.close();await tick()
		await walk("mara");check(game.campaign.data.quest=="patrol" and game.menu_open,kind+": walk to Mara and accept introduction")
		game.overlay.close();await walk("road");check(game.area.area_id=="road",kind+": walk out of Vigil")
		var began: float=game.elapsed;await battle()
		print("BALANCE ",kind," combat/travel seconds=",snappedf(game.elapsed-began,0.1)," HP=",snappedf(game.hero.health,0.1)," XP=",game.campaign.data.xp)
		check(not game.fallen and game.enemies.is_empty(),kind+": defeat all archetypes, guards and optional elite with real attacks")
		if game.fallen or not game.enemies.is_empty(): continue
		check(game.encounter_complete() and game.campaign.data.claims.has(game.ELITE),kind+": authored and elite ledgers complete independently")
		await walk("flour");check(game.recovered,kind+": walk to and recover flour")
		game.overlay.close();await walk("bannerfall",3600);check(game.area.area_id=="bannerfall",kind+": southeast route reaches town")
		await walk("anja");check(game.campaign.data.quest=="done" and game.campaign.data.xp==203,kind+": Anja rewards and leveling")
		game.overlay.close();game.world_click(Vector2(650,730));await tick(80)
		check(not game.campaign.data.loot.has("bread-charm"),kind+": quest reward pickup")
		await walk("vigil",3000);check(game.area.area_id=="vigil",kind+": walk to return exit")
		game.persist();var slot: String=game.campaign.slot;game.overlay.page("title");game.continue_campaign(slot)
		check(game.campaign.data.quest=="done" and game.campaign.data.xp==203 and game.area.area_id=="vigil",kind+": save/title/Continue retains completed quest and elite claim")
	game.queue_free();await tick();print("RESULT: %d campaign checks, %d failures"%[checks,failures]);quit(failures)
