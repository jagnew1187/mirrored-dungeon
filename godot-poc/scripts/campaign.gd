extends RefCounted
const Gear = preload("res://scripts/items.gd")
var revision := 0
var effects: Dictionary = {}
## Godot-only campaign records. No browser storage is read or migrated.
const BASE = {"knight":{"hp":270.0,"speed":204.0,"range":85.0,"damage":34.0,"cooldown":0.53,"windup":0.16,"defense":2.0},"mage":{"hp":200.0,"speed":225.0,"range":315.0,"damage":23.0,"cooldown":0.60,"windup":0.16,"defense":0.0},"rogue":{"hp":165.0,"speed":280.0,"range":270.0,"damage":19.0,"cooldown":0.37,"windup":0.12,"defense":0.0}}
const GROWTH = {"knight":{"hp":12.0,"damage":2.0},"mage":{"hp":8.0,"damage":2.5},"rogue":{"hp":8.0,"damage":1.5}}
var data: Dictionary = {}
var directory := "user://campaigns"
var slot := ""
var error := ""

func fresh(kind: String, hero_name := "") -> void:
	data={"version":1,"class":kind,"name":hero_name if not hero_name.strip_edges().is_empty() else {"knight":"Alden","mage":"Seren","rogue":"Corvin"}[kind],"xp":0,"gold":30,"quest":"meet_mara","defeated":{},"claims":{},"checkpoint":"vigil","upgraded":false,"weapon_equipped":false}
	slot="%s_%s_%s"%[kind,Time.get_unix_time_from_system(),Time.get_ticks_usec()]
	data.version=2;data.inventory=[{"id":"tonic","count":2}];data.stash=[]
	data.equipped={"weapon":Gear.STARTER[kind],"armor":"coat"};data.loot={};revision+=1;effects.clear()
	data.cycle=0;data.respawn_remaining=0.0;data.random_dead=[];data.recovered=false

func progress() -> Dictionary:
	var level:=1
	var xp:=int(data.get("xp",0))
	while level<60 and xp>=80+40*(level-1)*(level-1):
		xp-=80+40*(level-1)*(level-1);level+=1
	return {"level":level,"xp":xp if level<60 else 0,"next":80+40*(level-1)*(level-1) if level<60 else 0}

func stats() -> Dictionary:
	var kind: String=data.get("class","knight")
	var result: Dictionary=BASE[kind].duplicate()
	for key in GROWTH[kind]: result[key]+=GROWTH[kind][key]*(progress().level-1)
	for id in data.get("equipped",{}).values():
		for key in Gear.ITEMS[id].mods: result[key]+=Gear.ITEMS[id].mods[key]
	for key in effects:
		if result.has(key): result[key]+=effects[key]
	result.hp=clampf(result.hp,1,5000);result.damage=clampf(result.damage,1,1000)
	result.defense=clampf(result.defense,0,50);result.cooldown=clampf(result.cooldown,0.18,3);result.speed=clampf(result.speed,100,340)
	return result

func award(id: String, xp: int, gold: int) -> bool:
	if data.claims.has(id): return false
	data.claims[id]=true;data.xp=mini(100000000,data.xp+maxi(0,xp));data.gold=mini(100000000,data.gold+maxi(0,gold));revision+=1
	return true

func validate(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not BASE.has(raw.get("class","")): return {}
	if not (raw.get("version",0) is int or raw.get("version",0) is float): return {}
	if raw.version!=1 and raw.version!=2: return {}
	if not raw.get("claims",{}) is Dictionary or not raw.get("defeated",{}) is Dictionary: return {}
	if not raw.get("xp",0) is float and not raw.get("xp",0) is int: return {}
	if not raw.get("gold",0) is float and not raw.get("gold",0) is int: return {}
	var result: Dictionary=raw.duplicate(true)
	result.xp=clampi(int(raw.get("xp",0)),0,100000000);result.gold=clampi(int(raw.get("gold",0)),0,100000000)
	result.name=str(raw.get("name",raw["class"])).left(24)
	result.quest=raw.get("quest","meet_mara")
	if not result.quest in ["meet_mara","patrol","flour","deliver","done"]: return {}
	result.claims=raw.get("claims",{});result.defeated=raw.get("defeated",{})
	result.checkpoint=raw.get("checkpoint","vigil")
	if not result.checkpoint in ["vigil","bannerfall"]: result.checkpoint="vigil"
	if raw.version==1:
		result.inventory=[];result.stash=[];result.loot={}
		result.equipped={"weapon":Gear.STARTER[result["class"]],"armor":"coat"}
		if raw.get("upgraded",false):
			if raw.get("weapon_equipped",false): result.equipped.weapon=Gear.UPGRADE[result["class"]]
			else: Gear.add(result.inventory,Gear.UPGRADE[result["class"]],Gear.CAPACITY)
	result.version=2
	for field in ["inventory","stash"]:
		if not Gear.valid_bag(result.get(field,[]),Gear.CAPACITY if field=="inventory" else Gear.STASH_CAPACITY): return {}
		result[field]=result.get(field,[])
	if not result.get("equipped",{}) is Dictionary: return {}
	result.equipped=result.get("equipped",{})
	for field in result.equipped:
		var id: String=str(result.equipped[field])
		if not Gear.allowed(id,result["class"]) or Gear.ITEMS[id].slot!=field or field.is_empty(): return {}
	if not result.get("loot",{}) is Dictionary: return {}
	result.loot=result.get("loot",{})
	for id in result.loot:
		var drop: Variant=result.loot[id]
		if not drop is Dictionary or not Gear.ITEMS.has(drop.get("item","")) or not drop.get("area","") in ["road","bannerfall","vigil"]: return {}
		if not drop.get("x",0) is float and not drop.get("x",0) is int: return {}
		if not drop.get("y",0) is float and not drop.get("y",0) is int: return {}
	if not result.get("random_dead",[]) is Array: return {}
	if not (result.get("cycle",0) is int or result.get("cycle",0) is float): return {}
	if not (result.get("respawn_remaining",0) is int or result.get("respawn_remaining",0) is float): return {}
	result.cycle=clampi(int(result.get("cycle",0)),0,1000000)
	result.respawn_remaining=clampf(float(result.get("respawn_remaining",0)),0,30)
	for member in result.get("random_dead",[]):
		if not (member is int or member is float) or not int(member) in [0,1,2]: return {}
	for member in result.defeated:
		if not member in ["captain","escort"] or result.defeated[member]!=true: return {}
	if result.quest in ["deliver","done"] and (not result.defeated.has("captain") or not result.defeated.has("escort")): return {}
	if result.quest=="done" and not result.claims.has("bread"): return {}
	result.recovered=result.quest in ["deliver","done"]
	return result

func read_record(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
	return validate(parser.data)

func save() -> bool:
	error=""
	if slot.is_empty(): return true
	DirAccess.make_dir_recursive_absolute(directory)
	var path:=directory+"/"+slot+".json"
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: error="Could not write campaign. Progress remains in memory.";return false
	file.store_string(JSON.stringify(data));file.flush();file.close()
	if read_record(path+".tmp").is_empty(): error="Save validation failed.";return false
	# Never replace a valid backup with a corrupt primary.
	if not read_record(path).is_empty():
		if DirAccess.copy_absolute(path,path+".bak")!=OK: error="Could not preserve save backup.";return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK: error="Could not replace campaign save.";return false
	return true

func load_slot(id: String) -> bool:
	if id.get_file()!=id or id.contains("..") or id.contains(":"): return false
	var path:=directory+"/"+id+".json"
	var record:=read_record(path)
	error=""
	if record.is_empty():
		record=read_record(path+".bak")
		if not record.is_empty(): error="Recovered the last valid backup."
	if record.is_empty(): error="Unreadable campaign; original files preserved.";return false
	data=record;slot=id;revision+=1;effects.clear();return true

func slots() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not DirAccess.dir_exists_absolute(directory): return result
	for file in DirAccess.get_files_at(directory):
		if not file.ends_with(".json"): continue
		var record:=read_record(directory+"/"+file)
		if record.is_empty(): record=read_record(directory+"/"+file+".bak")
		result.append({"id":file.trim_suffix(".json"),"record":record})
	return result

func equip(index: int) -> bool:
	if index<0 or index>=data.inventory.size(): return false
	var id: String=data.inventory[index].id
	if not Gear.allowed(id,data["class"]) or Gear.ITEMS[id].slot.is_empty(): return false
	var slot_name: String=Gear.ITEMS[id].slot
	var bag: Array=data.inventory.duplicate(true)
	Gear.remove(bag,index)
	if data.equipped.has(slot_name) and not Gear.add(bag,data.equipped[slot_name],Gear.CAPACITY): return false
	data.inventory=bag;data.equipped[slot_name]=id;revision+=1;return true

func unequip(slot_name: String) -> bool:
	if not data.equipped.has(slot_name) or not Gear.add(data.inventory,data.equipped[slot_name],Gear.CAPACITY): return false
	data.equipped.erase(slot_name);revision+=1;return true

func transfer(index: int, deposit: bool) -> bool:
	var source: Array=data.inventory if deposit else data.stash
	var destination: Array=data.stash if deposit else data.inventory
	if index<0 or index>=source.size(): return false
	if not Gear.add(destination,source[index].id,Gear.STASH_CAPACITY if deposit else Gear.CAPACITY): return false
	Gear.remove(source,index);revision+=1;return true

func buy(id: String) -> bool:
	if not id in Gear.SHOP or not Gear.allowed(id,data["class"]): return false
	var price: int=Gear.ITEMS[id].value*2
	if data.gold<price or not Gear.add(data.inventory,id,Gear.CAPACITY): return false
	data.gold-=price;revision+=1;return true

func sell(index: int) -> bool:
	if index<0 or index>=data.inventory.size(): return false
	var price: int=Gear.ITEMS[data.inventory[index].id].value
	Gear.remove(data.inventory,index);data.gold+=price;revision+=1;return true

func collect(id: String) -> bool:
	if not data.loot.has(id): return false
	if not Gear.add(data.inventory,data.loot[id].item,Gear.CAPACITY): return false
	data.loot.erase(id);revision+=1;return true

func add_loot(id: String, item: String, area_id: String, pos: Vector2) -> void:
	if not Gear.ITEMS.has(item) or data.claims.has("drop:"+id): return
	data.claims["drop:"+id]=true
	data.loot[id]={"item":item,"area":area_id,"x":pos.x,"y":pos.y}
	revision+=1

func claim_bread() -> bool:
	if data.claims.has("bread") or not data.get("recovered",false): return false
	# A full backpack never destroys or delays the unique quest reward.
	award("bread",100,35);data.quest="done"
	add_loot("bread-charm","charm","bannerfall",Vector2(650,730))
	return true

func comparison(id: String) -> String:
	var item: Dictionary=Gear.ITEMS[id]
	var old: Dictionary=Gear.ITEMS[data.equipped[item.slot]].mods if data.equipped.has(item.slot) else {}
	var lines: PackedStringArray=[]
	for key in ["hp","damage","defense","cooldown","speed"]:
		var delta: float=item.mods.get(key,0)-old.get(key,0)
		if delta!=0: lines.append("%s %+.2f"%[key,delta])
	return ", ".join(lines) if not lines.is_empty() else "No stat change"
