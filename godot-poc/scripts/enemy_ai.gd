extends RefCounted
const DATA = {
	"militia":{"name":"Militia Fighter","hp":72.0,"speed":78.0,"range":46.0,"windup":0.42,"recovery":0.55,"damage":9.0},
	"archer":{"name":"Archer","hp":58.0,"speed":70.0,"range":290.0,"windup":0.7,"recovery":1.0,"damage":10.0},
	"shield":{"name":"Shielded Soldier","hp":72.0,"speed":65.0,"range":50.0,"windup":0.65,"recovery":0.85,"damage":13.0},
	"raider":{"name":"Raider","hp":52.0,"speed":115.0,"range":46.0,"windup":0.3,"recovery":0.9,"damage":7.0},
	"enforcer":{"name":"Mill Enforcer","hp":300.0,"speed":72.0,"range":95.0,"windup":0.9,"recovery":1.2,"damage":20.0}
}
var game: Node

func separation(e: Dictionary) -> Vector2:
	var push:=Vector2.ZERO
	for other in game.enemies:
		if other==e: continue
		var offset: Vector2=e.actor.position-other.actor.position
		if offset.length()<44 and offset.length()>0.01: push+=offset.normalized()*(44-offset.length())/44
	return push.limit_length()*42

func update(delta: float) -> void:
	for e in game.enemies:
		var a: CharacterBody2D=e.actor
		var distance:=a.position.distance_to(game.hero.position)
		a.visible=distance<850;a.set_process(a.visible)
		if distance>900: a.moving=false;continue
		var config: Dictionary=DATA[e.role]
		e.cooldown=maxf(0,e.cooldown-delta);e.stagger=maxf(0,e.stagger-delta)
		a.modulate=Color.WHITE
		if e.stagger>0: a.moving=false;continue
		if e.state!="idle" and (game.hero.position.distance_to(e.home)>380 or a.position.distance_to(e.home)>330): e.state="return"
		var clear: bool=game.area.line_clear(a.position,game.hero.position)
		if e.state=="return":
			if a.position.distance_to(e.home)<44: e.state="idle";e.wander_at=game.elapsed+2
		elif e.state not in ["windup","recover","lunge","burst"] and distance<330 and clear: e.state="pursue"
		if e.state=="recover":
			e.windup-=delta;a.moving=false
			if e.windup<=0: e.state="pursue";e.cooldown=0.65 if e.role=="archer" else e.cooldown
			continue
		if e.state=="pursue" and distance<config.range and clear and e.cooldown<=0:
			e.state="windup";e.windup=config.windup;e.aim=a.position.direction_to(game.hero.position);a.face(e.aim)
			e.pattern=(e.pattern+1)%2
			if e.role=="enforcer": game.overlay.notify("Mill Enforcer · "+("BRACE / SWEEP" if e.pattern==0 else "LUNGE · sidestep!"))
		if e.state=="windup":
			a.moving=false;e.windup-=delta;a.modulate=Color("e5ac87")
			if e.windup<=0:
				a.release_flash=.16
				if e.role=="archer":
					if clear and distance<350: game.projectiles.append({"pos":a.position,"direction":e.aim,"travel":0.0,"kind":"arrow","damage":config.damage,"max":350.0,"hostile":true})
				elif e.role=="enforcer" and e.pattern==1:
					e.state="lunge";e.windup=0.22;e.hit=false;continue
				elif distance<config.range+12 and clear and e.aim.dot(a.position.direction_to(game.hero.position))>-0.15:
					game.damage_hero(config.damage)
					if e.role=="raider": e.state="burst";e.windup=0.18;continue
				e.state="recover";e.windup=config.recovery;e.cooldown=config.recovery
			continue
		if e.state=="lunge":
			game.move_actor(a,e.aim*360);e.windup-=delta
			if not e.hit and distance<45 and clear: game.damage_hero(config.damage);e.hit=true
			if e.windup<=0: e.state="recover";e.windup=config.recovery
			continue
		if e.state=="burst":
			a.moving=false;e.windup-=delta
			if e.windup<=0:
				if distance<58 and clear and e.aim.dot(a.position.direction_to(game.hero.position))>0: game.damage_hero(config.damage)
				e.state="recover";e.windup=config.recovery
			continue
		var goal: Vector2=e.home
		if e.state=="pursue":
			goal=game.hero.position
			if e.role=="archer":
				if distance<165: goal=a.position+game.hero.position.direction_to(a.position)*90
				elif distance<270 and clear: goal=a.position
		elif e.state=="idle":
			if game.elapsed>=e.wander_at:
				var candidate: Vector2=e.home+Vector2.from_angle(game.rng.randf()*TAU)*game.rng.randf_range(20,65)
				if game.area.clear(candidate): e.wander=candidate
				e.wander_at=game.elapsed+game.rng.randf_range(3,5)
			goal=e.wander
		if a.position.distance_to(goal)> (36 if e.state=="pursue" and e.role!="archer" else 8):
			e.repath-=delta
			if e.repath<=0: e.route=game.area.route(a.position,goal);e.repath=0.65
			var next: Vector2=goal
			if not e.route.is_empty():
				if a.position.distance_to(e.route[0])<10: e.route.remove_at(0)
				if not e.route.is_empty(): next=e.route[0]
			var desired: Vector2=a.position.direction_to(next)*(35.0 if e.state=="idle" else config.speed)+separation(e)
			if e.get("blocked",0.0)>0.3:
				desired=desired.rotated(0.9 if str(e.id).hash()%2==0 else -0.9)
			var old: Vector2=a.position
			game.move_actor(a,desired)
			e.blocked=float(e.get("blocked",0.0))+delta if a.position.distance_to(old)<0.2 else maxf(0,float(e.get("blocked",0.0))-delta*0.5)
			if e.blocked>1.2: e.blocked=0.0;e.repath=0.0
		else: a.moving=false
	if game.area.area_id=="road" and game.random_dead.size()==3 and game.elapsed>=game.respawn_time and game.hero.position.distance_to(Vector2(1140,1370))>950:
		game.random_dead.clear();game.population_cycle+=1;game.persist();game.spawn_random()

func draw(canvas: Node2D) -> void:
	if game.menu_open: return
	var labels: Array[Rect2]=[]
	for e in game.enemies:
		if not e.actor.visible: continue
		var p: Vector2=e.actor.position
		var transform: Transform2D=canvas.get_viewport().get_canvas_transform()
		var screen: Vector2=transform*p
		if not Rect2(0,0,1152,720).has_point(screen): continue
		var label_pos:=screen+Vector2(-80,-106)
		label_pos.x=clampf(label_pos.x,8,984);label_pos.y=maxf(8,label_pos.y)
		if label_pos.x<380 and label_pos.y<150: label_pos.y=150
		if label_pos.x>830 and label_pos.y<75: label_pos.y=75
		var rect:=Rect2(transform.affine_inverse()*label_pos,Vector2(160,20))
		for attempt in range(12):
			if not labels.any(func(other):return other.intersects(rect)): break
			rect.position.y+=22
		labels.append(rect)
		canvas.draw_rect(rect,Color(.06,.1,.08,.75))
		canvas.draw_string(ThemeDB.fallback_font,rect.position+Vector2(0,16),DATA[e.role].name,HORIZONTAL_ALIGNMENT_CENTER,160,14,Color("dfc9a0"))
		if e.role in ["shield","enforcer"] and e.state not in ["recover","lunge"]:
			var facing: float=Vector2.RIGHT.rotated(e.actor.DIRECTIONS.find(e.actor.direction)*PI/4).angle()
			canvas.draw_arc(p,26,facing-0.7,facing+0.7,12,Color("b5bfc3"),4)
		if e.state=="windup":
			if e.role=="archer" or (e.role=="enforcer" and e.pattern==1): canvas.draw_line(p,p+e.aim*(150 if e.role=="enforcer" else 85),Color("dda06b"),2)
			else: canvas.draw_arc(p,DATA[e.role].range,e.aim.angle()-1.7,e.aim.angle()+1.7,28,Color("dda06b"),2)

