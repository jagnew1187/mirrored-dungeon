extends RefCounted
## Presentation-only catalog. Combat supplies timing; this resource owns no damage or AI.
const DIRECTIONS := ["right","southeast","down","southwest","left","northwest","up","northeast"]
static var library: Dictionary = {}
static var builds := 0

static func add(frames: SpriteFrames, id: String, textures: Array, fps:=12.0, loop:=false) -> void:
	frames.add_animation(id);frames.set_animation_speed(id,fps);frames.set_animation_loop(id,loop)
	for texture in textures: frames.add_frame(id,texture)

static func cell(atlas: Texture2D, x: int, y: int, size: Vector2) -> AtlasTexture:
	var texture:=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2(Vector2(x,y)*size,size);texture.filter_clip=true
	return texture

static func frames_for(kind: String, role: String) -> SpriteFrames:
	var key:=kind+"_"+role if kind=="enemy" else kind
	if library.has(key): return library[key]
	var frames:=SpriteFrames.new();frames.remove_animation("default")
	if kind in ["knight","mage","rogue"]:
		var atlas: Texture2D=load("res://assets/pass08/"+kind+"_poses.png")
		for column in range(8):
			var d: String=DIRECTIONS[column]
			var walk: Array=[]
			for i in range(8): walk.append(load("res://assets/%s_%s_%d.png"%[kind,d,i]))
			add(frames,"walk_"+d,walk,12,true)
			var idle: Texture2D=load("res://assets/"+(("knight_idle_"+d) if kind=="knight" and d in ["right","left","up","down"] else ("%s_%s_8"%[kind,d]))+".png")
			add(frames,"idle_"+d,[idle],2,true)
			var poses: Array=[]
			for row in range(5): poses.append(cell(atlas,column,row,Vector2(160,128)))
			for row in range(5): add(frames,["windup_","release_","recover_","hurt_","death_"][row]+d,[poses[row]])
			# Guard holds a shield-forward flinch key; a dedicated guard cycle is still pending.
			add(frames,"guard_"+d,[poses[3]])
			add(frames,"step_"+d,walk,24,true)
			var sequence: Array=[poses[0],poses[0],poses[0],poses[0],poses[1],poses[1],poses[2],poses[2]]
			if kind=="rogue": sequence=[poses[0],poses[0],poses[0],poses[1],poses[1],poses[2],poses[2],poses[2]]
			# Preserve the existing authored eight-frame side attacks, including their gutters.
			if d in ["left","right"]:
				var side_row:=5 if d=="right" else 6
				sequence=[]
				for i in range(8): sequence.append(cell(atlas,i,side_row,Vector2(160,128)))
			add(frames,"attack_"+d,sequence,25)
	elif kind=="enemy":
		var atlas: Texture2D=load("res://assets/pass08/enemy_"+role+".png")
		var poses: Array=[]
		for i in range(6): poses.append(cell(atlas,i%4,i/4,Vector2(128,128)))
		var sequences: Dictionary={"idle":[0,0,0,0,0,0,0,0],"walk":[0,0,1,1,0,0,1,1],"windup":[2,2,2,2,2,2,2,2],"attack":[3,3,3,3,3,3,3,3],"recover":[3,3,0,0,0,0,0,0],"hurt":[4,4,4,4,4,4,4,4],"death":[4,4,5,5,5,5,5,5]}
		for state in sequences:
			var textures: Array=[]
			for index in sequences[state]: textures.append(poses[index])
			add(frames,state,textures,12 if state=="walk" else 16,state in ["idle","walk"])
	else:
		var textures: Array=[]
		for name in (["mara_0","mara_1","mara_2","mara_3"] if kind=="mara" else [kind]): textures.append(load("res://assets/"+name+".png"))
		add(frames,"idle",textures,3,true)
	library[key]=frames;builds+=1
	return frames
