extends CharacterBody2D

var kind := "knight"
var direction := "right"
var moving := false
var health := 270.0
var max_health := 270.0
var hurt := 0.0
var authored := false
var attacking := false
var attack_age := 0.0
var attack_duration := 0.32
var attack_impact := 0.16
var paused := false
var sprite: AnimatedSprite2D
var configured := ""
var role := "militia"
var visual_state := "idle"
var release_flash := 0.0
var dying := false
var death_age := 0.0
var shape: CollisionShape2D
const Bank = preload("res://scripts/animation_bank.gd")
var action_id := "basic"
var presentation_state := "idle"
var second_impact := -1.0
var guard_time := 0.0
var remove_after_death := true
var sprite_rest := Vector2.ZERO
var hit_offset := Vector2.ZERO
var notice_time := 0.0
const DIRECTIONS := ["right","southeast","down","southwest","left","northwest","up","northeast"]

func _ready() -> void:
	sprite=AnimatedSprite2D.new();sprite.centered=false;add_child(sprite)
	shape=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=12;shape.shape=circle;add_child(shape)
	configure()

func configure() -> void:
	configured=kind
	var is_hero:=kind in ["knight","mage","rogue"]
	collision_layer=2 if is_hero else (4 if kind=="enemy" else 0)
	collision_mask=5 if is_hero else (7 if kind=="enemy" else 0)
	sprite.sprite_frames=Bank.frames_for(kind,role)
	sprite.position=Vector2(-80,-112) if is_hero else (Vector2(-64,-116) if kind=="enemy" else Vector2(-sprite.sprite_frames.get_frame_texture("idle",0).get_width()/2.0,-sprite.sprite_frames.get_frame_texture("idle",0).get_height()))
	sprite_rest=sprite.position
	sprite.play("idle_"+direction if is_hero else "idle")

func face(v: Vector2) -> void:
	if v.length_squared()<0.01: return
	direction=DIRECTIONS[posmod(roundi(v.angle()/(PI/4)),8)]

func visual_muzzle() -> Vector2:
	# Measured release-pose tips relative to the fixed foot anchor. Rendering only;
	# projectile ground trajectories and cover checks remain unchanged.
	var index:=DIRECTIONS.find(direction)
	var mage_tips: Array[Vector2]=[Vector2(48,-40),Vector2(51,-53),Vector2(-7,-74),Vector2(-45,-54),Vector2(-48,-40),Vector2(34,-54),Vector2(34,-54),Vector2(40,-53)]
	var dagger_tips: Array[Vector2]=[Vector2(32,-38),Vector2(50,-44),Vector2(41,-39),Vector2(-50,-44),Vector2(-32,-38),Vector2(-53,-39),Vector2(49,-35),Vector2(44,-41)]
	return mage_tips[index] if kind=="mage" else dagger_tips[index]

func start_attack(aim: Vector2, cue: String = "basic", second: float = -1.0) -> void:
	face(aim);attacking=true;attack_age=0;action_id=cue;second_impact=second;presentation_state="windup"
	sprite.flip_h=false
	sprite.speed_scale=0.32/attack_duration;sprite.play("attack_"+direction);sprite.set_frame_and_progress(0,0)

func show_hit(source_position: Vector2, blocked:=false) -> void:
	# Presentation only: never move collision bodies or alter attack timing.
	hurt=.16;hit_offset=source_position.direction_to(position)*(2.0 if blocked else 4.0)

func begin_death(remove_after := true) -> void:
	sprite.position=sprite_rest;hit_offset=Vector2.ZERO
	dying=true;death_age=0;remove_after_death=remove_after;attacking=false;moving=false
	collision_layer=0;collision_mask=0;set_process(true)
	presentation_state="death"

func _process(delta: float) -> void:
	if configured!=kind: configure()
	# Defeat presentation may finish under the defeat overlay; simulation stays paused.
	if dying:
		death_age+=delta;sprite.modulate=Color.WHITE
		var death_animation: String="death" if kind=="enemy" else "death_"+direction
		sprite.play(death_animation);sprite.pause()
		sprite.frame=mini(7,int(death_age*16)) if kind=="enemy" else 0
		modulate.a=clampf((.8-death_age)/.3,0,1) if remove_after_death else 1.0
		if remove_after_death and death_age>=.8: queue_free()
		return
	if paused: sprite.pause();return
	notice_time=maxf(0,notice_time-delta)
	hurt=maxf(0,hurt-delta);release_flash=maxf(0,release_flash-delta);guard_time=maxf(0,guard_time-delta)
	sprite.position=sprite_rest+(hit_offset*(hurt/.16)).round()
	sprite.modulate=Color(1.6,1.4,1.2) if hurt>.12 else (Color(1.15,.85,.75) if hurt>0 else Color.WHITE)
	if attacking:
		attack_age+=delta
		var release_frame:=3 if kind=="rogue" else 4
		var phase_age:=attack_age
		var impact:=attack_impact
		var duration:=attack_duration
		if second_impact>0 and attack_age>=second_impact-.045:
			phase_age=attack_age-(second_impact-.045);impact=.045;duration=attack_duration-(second_impact-.045)
		var frame_index:=mini(release_frame-1,int(phase_age/maxf(.001,impact)*release_frame)) if phase_age<impact else mini(7,release_frame+int((phase_age-impact)/maxf(.001,duration-impact)*(8-release_frame)))
		presentation_state="windup" if phase_age<impact else ("release" if phase_age<impact+.06 else "recover")
		if action_id=="step":
			sprite.play("step_"+direction);sprite.speed_scale=1;presentation_state="step"
		elif action_id=="guard":
			sprite.play("guard_"+direction);presentation_state="guard"
		else:
			sprite.play("attack_"+direction);sprite.pause();sprite.set_frame_and_progress(frame_index,0)
		if attack_age>=attack_duration: attacking=false
	if not attacking:
		sprite.flip_h=kind=="enemy" and direction in ["left","northwest","southwest"];sprite.speed_scale=1.0
		var animation: String=("walk_" if moving else "idle_")+direction if kind in ["knight","mage","rogue"] else ("walk" if kind=="enemy" and moving else "idle")
		presentation_state="walk" if moving else "idle"
		if kind=="enemy":
			if hurt>0: animation="hurt"
			elif release_flash>0 or visual_state in ["lunge","burst"]: animation="attack"
			elif visual_state=="windup": animation="windup"
			elif visual_state=="recover": animation="recover"
			presentation_state=animation
		elif guard_time>0 and not moving:
			animation="guard_"+direction;presentation_state="guard"
		sprite.play(animation)
	# Hurt overrides presentation, never the combat clock or queued release.
	if hurt>0 and kind in ["knight","mage","rogue"]:
		sprite.play("hurt_"+direction);presentation_state="hurt"
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0,2),0,Vector2(1,0.3));draw_circle(Vector2.ZERO,18,Color(0.02,0.05,0.04,0.4));draw_set_transform(Vector2.ZERO)
	if kind=="enemy" and not dying:
		if notice_time>0: draw_string(ThemeDB.fallback_font,Vector2(-4,-94),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ffe3a1"))
		if authored: draw_arc(Vector2.ZERO,23,0,TAU,24,Color("c69850"),2)
		draw_rect(Rect2(-21,-80,42,5),Color("251c21"));draw_rect(Rect2(-20,-79,40*maxf(health,0)/max_health,3),Color("ba6450"))
