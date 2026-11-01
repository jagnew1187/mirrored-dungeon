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
static var library: Dictionary = {}
const DIRECTIONS := ["right","southeast","down","southwest","left","northwest","up","northeast"]

func _ready() -> void:
	sprite=AnimatedSprite2D.new();sprite.centered=false;add_child(sprite)
	shape=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=12;shape.shape=circle;add_child(shape)
	configure()

func add_animation(frames: SpriteFrames, id: String, keys: Array, fps: float, loop: bool) -> void:
	frames.add_animation(id);frames.set_animation_speed(id,fps);frames.set_animation_loop(id,loop)
	for key in keys: frames.add_frame(id,load("res://assets/"+key+".png"))

func configure() -> void:
	configured=kind
	var is_hero:=kind in ["knight","mage","rogue"]
	collision_layer=2 if is_hero else (4 if kind=="enemy" else 0)
	collision_mask=5 if is_hero else (7 if kind=="enemy" else 0)
	var library_key: String=kind+"_"+role if kind=="enemy" else kind
	if not library.has(library_key):
		var frames:=SpriteFrames.new();frames.remove_animation("default")
		if is_hero:
			for d in DIRECTIONS:
				var keys: Array=[]
				for i in range(8): keys.append("%s_%s_%d"%[kind,d,i])
				add_animation(frames,"walk_"+d,keys,12,true)
				var idle_key: String=("knight_idle_"+d) if kind=="knight" and d in ["right","left","up","down"] else ("%s_%s_8"%[kind,d])
				add_animation(frames,"idle_"+d,[idle_key],2,true)
			var atlas: Texture2D=load("res://assets/pass07/"+kind+"_attacks.png")
			for row in range(8):
				var id: String="attack_"+DIRECTIONS[row]
				frames.add_animation(id);frames.set_animation_speed(id,25);frames.set_animation_loop(id,false)
				for i in range(8):
					var texture:=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2(i*160,row*128,160,128);texture.filter_clip=true
					frames.add_frame(id,texture)
		elif kind=="enemy":
			var atlas: Texture2D=load("res://assets/pass07/enemy_"+role+".png")
			var indices: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/pass07/enemy_"+role+".json"))
			var states: Array=["idle","walk","windup","attack","recover","hurt","death"]
			for row in range(states.size()):
				var id: String=states[row]
				frames.add_animation(id);frames.set_animation_speed(id,12 if id=="walk" else 16);frames.set_animation_loop(id,id in ["idle","walk"])
				for i in range(8):
					var index: int=int(indices[id][i])
					var texture:=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2((index%4)*128,(index/4)*128,128,128);texture.filter_clip=true
					frames.add_frame(id,texture)
		else:
			add_animation(frames,"idle",["mara_0","mara_1","mara_2","mara_3"] if kind=="mara" else [kind],3,true)
		library[library_key]=frames
	sprite.sprite_frames=library[library_key]
	sprite.position=Vector2(-80,-112) if is_hero else (Vector2(-64,-116) if kind=="enemy" else Vector2(-sprite.sprite_frames.get_frame_texture("idle",0).get_width()/2.0,-sprite.sprite_frames.get_frame_texture("idle",0).get_height()))
	sprite.play("idle_"+direction if is_hero else "idle")

func face(v: Vector2) -> void:
	if v.length_squared()<0.01: return
	direction=DIRECTIONS[posmod(roundi(v.angle()/(PI/4)),8)]

func visual_muzzle() -> Vector2:
	# Measured release-pose tips relative to the fixed foot anchor. Rendering only;
	# projectile ground trajectories and cover checks remain unchanged.
	var index:=DIRECTIONS.find(direction)
	var mage_tips: Array[Vector2]=[Vector2(48,-40),Vector2(28,-12),Vector2(0,-12),Vector2(-28,-12),Vector2(-48,-40),Vector2(-42,-70),Vector2(0,-96),Vector2(42,-70)]
	var dagger_tips: Array[Vector2]=[Vector2(32,-38),Vector2(22,-22),Vector2(0,-20),Vector2(-22,-22),Vector2(-32,-38),Vector2(-30,-63),Vector2(0,-76),Vector2(30,-63)]
	return mage_tips[index] if kind=="mage" else dagger_tips[index]

func start_attack(aim: Vector2) -> void:
	face(aim);attacking=true;attack_age=0
	sprite.flip_h=false
	sprite.speed_scale=0.32/attack_duration;sprite.play("attack_"+direction);sprite.set_frame_and_progress(0,0)

func _process(delta: float) -> void:
	if configured!=kind: configure()
	if paused: sprite.pause();return
	if dying:
		death_age+=delta;sprite.play("death");modulate.a=clampf((.8-death_age)/.3,0,1)
		if death_age>=.8: queue_free()
		return
	hurt=maxf(0,hurt-delta)
	release_flash=maxf(0,release_flash-delta)
	sprite.modulate=Color(1.5,0.65,0.45) if hurt>0 else Color.WHITE
	if attacking:
		attack_age+=delta
		var release_frame:=3 if kind=="rogue" else 4
		var frame_index:=mini(release_frame-1,int(attack_age/maxf(.001,attack_impact)*release_frame)) if attack_age<attack_impact else mini(7,release_frame+int((attack_age-attack_impact)/maxf(.001,attack_duration-attack_impact)*(8-release_frame)))
		sprite.set_frame_and_progress(frame_index,0)
		if attack_age>=attack_duration: attacking=false
	if not attacking:
		sprite.flip_h=kind=="enemy" and direction in ["left","northwest","southwest"];sprite.speed_scale=1.0
		var animation: String=("walk_" if moving else "idle_")+direction if kind in ["knight","mage","rogue"] else ("walk" if kind=="enemy" and moving else "idle")
		if kind=="enemy":
			if hurt>0: animation="hurt"
			elif release_flash>0 or visual_state in ["lunge","burst"]: animation="attack"
			elif visual_state=="windup": animation="windup"
			elif visual_state=="recover": animation="recover"
		# Replaying the same name preserves the animation cursor.
		sprite.play(animation)
	elif not sprite.is_playing(): sprite.play()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0,2),0,Vector2(1,0.3));draw_circle(Vector2.ZERO,18,Color(0.02,0.05,0.04,0.4));draw_set_transform(Vector2.ZERO)
	if kind=="enemy" and not dying:
		if authored: draw_arc(Vector2.ZERO,23,0,TAU,24,Color("c69850"),2)
		draw_rect(Rect2(-21,-80,42,5),Color("251c21"));draw_rect(Rect2(-20,-79,40*maxf(health,0)/max_health,3),Color("ba6450"))
