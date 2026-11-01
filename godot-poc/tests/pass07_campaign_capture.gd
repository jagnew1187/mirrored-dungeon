extends "res://tests/pass06_campaign.gd"
## Same real-damage route helper, engine-driven screenshot evidence only.
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/pass07-captures/"+name+".png")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await tick();game.volume=0
	game.campaign.directory="user://pass07-capture-"+str(Time.get_ticks_usec())
	game.select_class("knight");game.overlay.close();await tick();await walk("mara")
	game.overlay.close();await walk("road");await battle()
	check(not game.fallen and game.enemies.is_empty(),"Capture route: all six enemies defeated with ordinary combat")
	if game.fallen or not game.enemies.is_empty(): quit(1);return
	await walk("flour");game.overlay.close();await tick();await capture("quest-flour-recovered")
	await walk("bannerfall",3600);await walk("anja");await tick();await capture("quest-anja-delivery")
	game.overlay.close();game.world_click(Vector2(650,730));await tick(80);await walk("vigil",3000)
	check(game.campaign.data.quest=="done" and game.area.area_id=="vigil","Capture route: completed quest and camp return")
	await tick();await capture("quest-camp-return")
	game.persist();var slot: String=game.campaign.slot;game.overlay.page("title");game.continue_campaign(slot)
	await tick();await capture("quest-continue")
	print("RESULT: ",checks," capture-route checks, ",failures," failures (duplicate coverage)")
	quit(failures)
