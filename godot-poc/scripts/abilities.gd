extends RefCounted
## Combat timings are simulation seconds; all damage uses current equipment stats.
const DATA = {
	"knight":[{"name":"Shield Guard","cooldown":8.0,"windup":0.0,"recovery":0.15,"duration":2.5,"reduction":0.65}, {"name":"Cleaving Strike","cooldown":5.0,"windup":0.28,"recovery":0.34,"range":112.0,"damage":1.5,"arc":-0.3}],
	"mage":[{"name":"Arcane Burst","cooldown":7.0,"windup":0.24,"recovery":0.22,"range":135.0,"damage":1.6,"stagger":0.65}, {"name":"Focused Bolt","cooldown":4.5,"windup":0.32,"recovery":0.22,"range":410.0,"damage":2.4}],
	"rogue":[{"name":"Evasive Step","cooldown":4.0,"windup":0.0,"recovery":0.20,"duration":0.20,"speed":720.0}, {"name":"Twin Daggers","cooldown":3.5,"windup":0.09,"recovery":0.27,"range":310.0,"damage":0.95,"second":0.13}]
}
var game: Node
var remaining: Array[float] = [0.0,0.0]
var active := -1
var age := 0.0
var released := false
var second_released := false
var aim := Vector2.RIGHT
var queued := -1
var queue_time := 0.0
var guard := 0.0
var dash := 0.0
var rings: Array[Dictionary] = []
var echoes: Array[Dictionary] = []
var echo_clock := 0.0

func cancel(reset_cooldowns := false) -> void:
	if active>=0 and is_instance_valid(game.hero): game.hero.attacking=false
	active=-1;queued=-1;queue_time=0;guard=0;dash=0;rings.clear();echoes.clear();echo_clock=0
	if reset_cooldowns: remaining.assign([0.0,0.0])

func activate(index: int) -> bool:
	if index<0 or index>1 or game.menu_open or game.fallen or remaining[index]>0 or active>=0: return false
	if game.attack_clock>=0:
		queued=index;queue_time=0.4;return true
	var config: Dictionary=DATA[game.selected][index]
	remaining[index]=config.cooldown;active=index;age=0;released=false;second_released=false
	aim=Vector2.RIGHT.rotated(game.hero.DIRECTIONS.find(game.hero.direction)*PI/4) if game.selected=="rogue" and index==0 else game.aim_direction();game.cancel_approach();game.attack_buffer=0
	game.hero.attack_duration=config.windup+config.recovery;game.hero.attack_impact=config.windup;game.hero.start_attack(aim)
	if game.selected=="knight" and index==0: guard=config.duration;game.overlay.notify("Shield Guard · damage reduced")
	if game.selected=="rogue" and index==0: dash=config.duration;aim=Vector2.RIGHT.rotated(game.hero.DIRECTIONS.find(game.hero.direction)*PI/4)
	game.play_sound("arcane-cast" if game.selected=="mage" else "sword-swing")
	return true

func update(delta: float) -> void:
	for i in range(2): remaining[i]=maxf(0,remaining[i]-delta)
	if queued>=0:
		queue_time-=delta
		if game.attack_clock<0:
			var request:=queued;queued=-1;activate(request)
		elif queue_time<=0: queued=-1
	var guarded:=guard>0
	for echo in echoes: echo.time-=delta
	echoes=echoes.filter(func(e):return e.time>0)
	if dash>0:
		echo_clock-=delta
		if echo_clock<=0:
			echo_clock=.035
			var sprite: AnimatedSprite2D=game.hero.sprite
			echoes.append({"pos":game.hero.position+sprite.position,"texture":sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame),"time":.18})
	guard=maxf(0,guard-delta);dash=maxf(0,dash-delta)
	if guarded and guard<=0: game.overlay.notify("Shield Guard expired")
	for ring in rings: ring.time-=delta
	rings=rings.filter(func(r):return r.time>0)
	if active<0: return
	var config: Dictionary=DATA[game.selected][active]
	age+=delta
	if not released and age>=config.windup: release(config);released=true
	if game.selected=="rogue" and active==1 and not second_released and age>=config.windup+config.second:
		bolt(config,aim.rotated(0.035));second_released=true
	if age>=config.windup+config.recovery: active=-1

func bolt(config: Dictionary, direction: Vector2) -> void:
	game.projectiles.append({"pos":game.hero.position,"direction":direction,"travel":0.0,"kind":game.selected,"damage":game.stats.damage*config.damage,"max":config.range,"focused":game.selected=="mage","second":second_released or age>config.windup+.05,"muzzle":game.hero.visual_muzzle()})

func release(config: Dictionary) -> void:
	if active==1 and game.selected!="knight":
		bolt(config,aim.rotated(-0.035) if game.selected=="rogue" else aim);return
	if (game.selected=="knight" and active==1) or (game.selected=="mage" and active==0):
		rings.append({"pos":game.hero.position,"range":config.range,"time":0.3,"aim":aim,"burst":game.selected=="mage"})
		for e in game.enemies.duplicate():
			var offset: Vector2=e.actor.position-game.hero.position
			if offset.length()>config.range or not game.area.line_clear(game.hero.position,e.actor.position): continue
			if game.selected=="knight" and offset.length()>20 and aim.dot(offset.normalized())<config.arc: continue
			game.damage_enemy(e,game.stats.damage*config.damage)
			if is_instance_valid(e.actor) and e.actor.health>0: e.stagger=config.get("stagger",0.3)

func draw(canvas: Node2D) -> void:
	if game.menu_open: return
	for echo in echoes: canvas.draw_texture(echo.texture,echo.pos,Color(.55,.85,.76,echo.time*.85))
	if guard>0:
		var facing:=Vector2.RIGHT.rotated(game.hero.DIRECTIONS.find(game.hero.direction)*PI/4)
		var opacity:=minf(1,guard*3)
		var center: Vector2=game.hero.position+Vector2(0,-32)+facing*22
		canvas.draw_arc(game.hero.position,28,facing.angle()-.85,facing.angle()+.85,18,Color(.8,.83,.64,opacity),2)
		var shield:=PackedVector2Array([center+Vector2(-10,-15),center+Vector2(10,-15),center+Vector2(9,6),center+Vector2(0,14),center+Vector2(-9,6),center+Vector2(-10,-15)])
		canvas.draw_colored_polygon(shield,Color(.25,.48,.64,.18*opacity));canvas.draw_polyline(shield,Color(.7,.86,.9,.65*opacity),2)
		canvas.draw_line(center+Vector2(0,-10),center+Vector2(0,7),Color(.9,.83,.58,opacity),2)
	if active==1 and game.selected=="knight" and not released:
		canvas.draw_arc(game.hero.position,112,aim.angle()-1.85,aim.angle()+1.85,32,Color(.9,.75,.4,.25+age),1)
	if active>=0 and game.selected=="mage":
		var radius: float=135.0 if active==0 else 28.0
		canvas.draw_arc(game.hero.position,radius,0,TAU,48,Color(.5,.8,.9,.28),1)
		for i in range(8):
			var rune: Vector2=game.hero.position+Vector2.from_angle(i*TAU/8+age*.5)*radius
			canvas.draw_polyline(PackedVector2Array([rune+Vector2(0,-4),rune+Vector2(3,0),rune+Vector2(0,4)]),Color(.65,.85,.9,.65),1)
		var hand: Vector2=game.hero.position+Vector2(0,-36)+aim*18
		canvas.draw_circle(hand,3+minf(age*12,4),Color(.6,.86,.95,.65))
	for ring in rings:
		var angle: float=ring.aim.angle()
		var progress: float=1-ring.time/.3
		var radius: float=ring.range*(.65+progress*.35) if ring.burst else ring.range
		canvas.draw_arc(ring.pos,radius,0 if ring.burst else angle-1.85,TAU if ring.burst else angle+1.85,48,Color(.65,.85,.9,ring.time/.3),2)
		if not ring.burst: canvas.draw_arc(ring.pos+Vector2(0,-30),radius*.8,angle-1.85+progress*2.4,angle-.9+progress*2.4,20,Color(1,.9,.65,ring.time/.3),4)
