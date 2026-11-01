extends SceneTree
const Model=preload("res://scripts/campaign.gd")
const Gear=preload("res://scripts/items.gd")
var failures:=0
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error("FAIL: "+message)
func tick(n:=3) -> void:
	for i in range(n): await physics_frame
func write(path: String, value: String) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(value);file.close()
func canonical(value: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)))
func run() -> void:
	var model=Model.new();model.directory="user://test-pass05-"+str(Time.get_ticks_usec());model.fresh("knight")
	check(model.award("enemy",79,3) and not model.award("enemy",79,3) and model.progress().level==1,"Enemy reward idempotency before threshold")
	model.award("next",1,0);check(model.progress().level==2 and model.progress().xp==0 and model.progress().next==120,"Increasing level thresholds")
	model.award("third",120,0);check(model.progress().level==3,"Second threshold consumed correctly")
	Gear.add(model.data.inventory,"steel_sword",16);var damage: float=model.stats().damage
	check(model.equip(1) and model.stats().damage==damage+4,"Equip applies central damage calculation")
	check(model.unequip("weapon") and model.stats().damage==damage,"Unequip removes modifier")
	Gear.add(model.data.inventory,"staff",16);check(not model.equip(model.data.inventory.size()-1),"Wrong-class gear rejected")
	model.data.inventory=[]
	for i in range(16): Gear.add(model.data.inventory,"coat",16)
	var before: String=JSON.stringify(model.data)
	check(not Gear.add(model.data.inventory,"tonic",16) and not model.unequip("armor") and JSON.stringify(model.data)==before,"Full inventory preserves all items")
	model.data.inventory=[{"id":"tonic","count":4}]
	check(Gear.add(model.data.inventory,"tonic",16) and model.data.inventory[0].count==5,"Consumable stacks to limit")
	Gear.add(model.data.inventory,"tonic",16);check(model.data.inventory.size()==2,"New stack after limit")
	check(model.transfer(0,true) and model.data.stash[0].count==1 and model.data.inventory[0].count==4,"Deposit transfers exactly one")
	check(model.transfer(0,false) and model.data.stash.is_empty() and model.data.inventory[0].count==5,"Withdraw transfers exactly one")
	model.data.gold=0;before=JSON.stringify(model.data)
	check(not model.buy("tonic") and JSON.stringify(model.data)==before,"Insufficient coins makes no mutation")
	model.data.gold=30
	check(model.buy("tonic") and model.data.gold==18,"Buy debits listed price")
	check(model.sell(0) and model.data.gold==24,"Sell credits owned unit only")
	before=JSON.stringify(model.data);check(not model.sell(99) and not model.buy("missing") and JSON.stringify(model.data)==before,"Invalid transactions preserve state")
	model.add_loot("a","padded_coat","road",Vector2(100,200));model.add_loot("a","tonic","road",Vector2.ZERO)
	check(model.data.loot.a.item=="padded_coat" and model.collect("a") and not model.collect("a"),"Loot generation and pickup cannot duplicate")
	model.add_loot("a","tonic","road",Vector2.ZERO);check(not model.data.loot.has("a"),"Reloaded kill cannot recreate collected loot")
	model.data.defeated={"captain":true,"escort":true};model.data.recovered=true
	check(model.claim_bread() and not model.claim_bread() and model.data.quest=="done","Quest reward and keepsake granted once")
	check(model.save(),"Versioned save writes successfully")
	var slot: String=model.slot;var snapshot: String=canonical(model.data)
	var loaded=Model.new();loaded.directory=model.directory
	check(loaded.load_slot(slot) and canonical(loaded.data)==snapshot,"Save/load round trip retains inventory, stash, quests and claims")
	model.save();var primary: String=model.directory+"/"+slot+".json"
	write(primary,"{ interrupted");check(loaded.load_slot(slot) and not loaded.error.is_empty(),"Corrupt primary recovers valid backup")
	var backup: String=FileAccess.get_file_as_string(primary+".bak")
	write(primary+".tmp","partial");check(loaded.load_slot(slot),"Interrupted temporary write cannot replace valid backup")
	loaded.save();check(FileAccess.get_file_as_string(primary+".bak")==backup,"Corrupt primary never overwrites valid backup")
	var invalid: Dictionary=model.data.duplicate(true);invalid.inventory=[{"id":"invalid","count":1}]
	check(model.validate(invalid).is_empty(),"Invalid item references rejected without deletion")
	invalid=model.data.duplicate(true);invalid.equipped.weapon="staff";check(model.validate(invalid).is_empty(),"Loaded cross-class equipment rejected")
	invalid=model.data.duplicate(true);invalid.version=1;invalid.erase("inventory");invalid.erase("stash");invalid.upgraded=true;invalid.weapon_equipped=true
	check(model.validate(invalid).equipped.weapon=="steel_sword","Pass 04 saves migrate without browser data")
	model.fresh("mage");check(model.slot!=slot and model.data.xp==0 and model.data.claims.is_empty(),"New Campaign isolates class and all progression")
	model.data.inventory=[{"id":"tonic","count":1}];model.data.stash=[]
	for i in range(40): Gear.add(model.data.stash,"coat",40)
	before=JSON.stringify(model.data)
	check(not model.transfer(0,true) and JSON.stringify(model.data)==before,"Full stash rejects deposit without losing item")
	model.data.inventory=[]
	for i in range(16): Gear.add(model.data.inventory,"coat",16)
	model.add_loot("full-test","tonic","road",Vector2.ZERO);before=JSON.stringify(model.data)
	check(not model.collect("full-test") and not model.transfer(0,false) and JSON.stringify(model.data)==before,"Full backpack retains ground loot and banked item")
	model.effects={"speed":9999,"cooldown":-999,"damage":-999,"hp":-9999}
	check(model.stats().speed==340 and model.stats().cooldown==0.18 and model.stats().damage==1 and model.stats().hp==1,"Temporary modifiers obey central safety clamps")
	model.effects.clear();model.award("cap",100000000,0);check(model.progress().level==60,"Level cap is sixty")
	var broken: String=model.directory+"/blocked-file";write(broken,"keep")
	model.directory=broken+"/child";check(not model.save() and not model.error.is_empty() and FileAccess.get_file_as_string(broken)=="keep","Save failure reports error and preserves existing file")
	model.directory=loaded.directory
	write(primary,"broken primary");write(primary+".bak","broken backup")
	check(not loaded.load_slot(slot) and FileAccess.get_file_as_string(primary)=="broken primary" and FileAccess.get_file_as_string(primary+".bak")=="broken backup","Unreadable primary and backup are preserved")
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await tick();game.volume=0;game.campaign.directory=model.directory
	for kind in ["knight","mage","rogue"]:
		game.select_class(kind);game.overlay.close();game.interact(game.area.points[0]);game.enter_area("road");game.overlay.close();await tick()
		var enemy: Dictionary=game.enemies[0];var hp: float=enemy.actor.health
		game.hero.position=enemy.actor.position-Vector2(60 if kind=="knight" else 150,0);game.target=enemy.actor;game.begin_attack()
		await tick(35);check(enemy.actor.health<hp,"Actual attack release damages enemy: "+kind)
		game.overlay.page("pause")
		for e in game.enemies.duplicate():
			if e.role!="enforcer": game.damage_enemy(e,999)
		var earned: int=game.campaign.data.xp
		check(earned==58 and game.campaign.data.loot.size()==5,"Real encounter deaths yield XP and persistent loot: "+kind)
		var upgrade: String=game.ENCOUNTER+":captain"
		check(game.campaign.collect(upgrade),"Collect class upgrade: "+kind)
		var index: int=game.campaign.data.inventory.size()-1;var base_damage: float=game.stats.damage
		game.campaign.equip(index);game.refresh_stats();check(game.stats.damage>base_damage,"Equipment modifies live hero stats: "+kind)
		game.interact(game.area.points[2]);game.enter_area("bannerfall");game.interact(game.area.points[0])
		check(game.campaign.data.quest=="done" and game.campaign.data.xp==158,"Quest integrates with real campaign: "+kind)
		game.enter_area("vigil");game.hero.position=Vector2(240,550);game.overlay.inventory("stash")
		await tick()
		check(game.overlay.window.size.y>=game.overlay.column.get_combined_minimum_size().y and game.overlay.window.position.y+game.overlay.window.size.y<=720,"Modal background encloses contents within viewport: "+kind)
		check(game.overlay.page_id=="equipment" and game.menu_open and not game.overlay.attack_button.visible,"Inventory modal hides combat controls: "+kind)
		var revision: int=game.campaign.revision
		game.overlay.apply_inventory(func():return game.campaign.transfer(0,true),revision)
		var count: int=game.campaign.data.stash[0].count
		game.overlay.apply_inventory(func():return game.campaign.transfer(0,true),revision)
		check(game.campaign.data.stash[0].count==count,"Stale rapid click cannot repeat transfer: "+kind)
		game.persist();var id: String=game.campaign.slot;var saved: String=canonical(game.campaign.data)
		game.select_class(kind);game.continue_campaign(id)
		check(canonical(game.campaign.data)==saved,"Continue integrated profile retains progression: "+kind)
		game.enter_area("road");game.hero.health=0;await tick()
		check(game.fallen and game.menu_open,"Defeat halts gameplay: "+kind)
		game.recover();check(game.campaign.data.xp==158 and game.campaign.data.stash[0].count==count,"Recovery protects stash and reward claims: "+kind)
	game.queue_free();await tick();print("RESULT: %d checks, %d failures"%[checks,failures]);quit(failures)
