extends SceneTree
var game: Node
func _initialize() -> void: call_deferred("run")
func ticks(n: int) -> void:
	for i in range(n): await process_frame
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await ticks(3);game.volume=0
	game.campaign.directory="user://pass07-performance-"+str(Time.get_ticks_usec())
	for kind in ["knight","mage","rogue"]: game.select_class(kind);game.overlay.close();await ticks(3)
	for id in ["vigil","road","bannerfall"]:
		game.enter_area(id);game.overlay.close()
		if id=="road": game.hero.position=Vector2(1700,1080)
		if id=="bannerfall": game.hero.position=Vector2(1000,760)
		var warm:=Time.get_ticks_usec()
		while Time.get_ticks_usec()-warm<1200000: await process_frame
		var began:=Time.get_ticks_usec();var total:=0.0;var high:=0.0;var calls:=0.0
		var samples:=0
		var node_start:=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		while Time.get_ticks_usec()-began<2000000:
			await process_frame
			samples+=1
			var sample:=Performance.get_monitor(Performance.TIME_PROCESS)
			total+=sample;high=maxf(high,sample);calls=maxf(calls,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		print("PROFILE ",id," sampled_frames=",samples," mean_frame_ms=",(Time.get_ticks_usec()-began)/float(samples)/1000," process_monitor_mean_ms=",total/samples*1000," process_monitor_max_ms=",high*1000," max_draw_calls=",calls," texture_bytes=",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)," nodes=",node_start," node_growth=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)-node_start)
	game.queue_free();await ticks(3);quit()
