extends RefCounted
const Classes=preload("res://scripts/class_progression.gd")
const Party=preload("res://scripts/party_state.gd")
const Migration=preload("res://scripts/equipment_migration.gd")
const Rules=preload("res://scripts/gear_rules.gd")
var gear_error: String=""
var migration_notice: String=""
var stat_cache_key: int=0
var stat_cache: Dictionary={}
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
	migration_notice=""
	data={"version":1,"class":kind,"name":hero_name if not hero_name.strip_edges().is_empty() else {"knight":"Alden","mage":"Seren","rogue":"Corvin"}[kind],"xp":0,"gold":30,"quest":"meet_mara","defeated":{},"claims":{},"checkpoint":"vigil","upgraded":false,"weapon_equipped":false}
	slot="%s_%s_%s"%[kind,Time.get_unix_time_from_system(),Time.get_ticks_usec()]
	data.version=4;data.character_id="protagonist";data.recovery=[];data.legacy_loadouts=[];data.favorites=[];data.locks=[];data.loadouts=[{"name":"Travel","items":{}},{"name":"Battle","items":{}}];data.inventory=[{"id":"tonic","count":2}];data.stash=[]
	data.equipped={"weapon":Gear.STARTER[kind],"armor":"coat"};data.loot={};revision+=1;effects.clear()
	data.cycle=0;data.respawn_remaining=0.0;data.random_dead=[];data.recovered=false
	data=Party.migrate(data);data.health=stats().hp

func progress() -> Dictionary:
	var level:=1
	var xp:=int(data.get("xp",0))
	while level<60 and xp>=80+40*(level-1)*(level-1):
		xp-=80+40*(level-1)*(level-1);level+=1
	return {"level":level,"xp":xp if level<60 else 0,"next":80+40*(level-1)*(level-1) if level<60 else 0}

func stats() -> Dictionary:
	var kind: String=data.get("class","knight")
	var cache_key: int=hash([data.get("equipped",{}),progress().level,effects,kind,data.get("talents",{})])
	if not stat_cache.is_empty() and cache_key==stat_cache_key: return stat_cache.duplicate()
	var result: Dictionary=Classes.CLASSES[kind].base.duplicate()
	for key in ["strength","agility","intellect","vitality"]: result[key]=float(Classes.CLASSES[kind].attributes[key])
	for key in Classes.CLASSES[kind].growth: result[key]+=Classes.CLASSES[kind].growth[key]*(progress().level-1)
	for key in Classes.modifiers(data): result[key]+=Classes.modifiers(data)[key]
	for slot_name in data.get("equipped",{}):
		var id: String=data.equipped[slot_name]
		if not Rules.fits(id,slot_name,kind): continue
		for key in Gear.ITEMS[id].mods: result[key]+=Gear.ITEMS[id].mods[key]
	for key in Rules.bonuses(data.get("equipped",{})): result[key]+=Rules.bonuses(data.equipped)[key]
	result.hp+=result.vitality*3
	result.damage+=result.intellect*.75 if kind=="mage" else result.strength*.5+result.agility*.2
	result.speed+=result.agility*.5
	for key in effects:
		if result.has(key): result[key]+=effects[key]
	result.hp=clampf(result.hp,1,5000);result.damage=clampf(result.damage,1,1000)
	result.defense=clampf(result.defense,0,50);result.cooldown=clampf(result.cooldown,0.18,3);result.speed=clampf(result.speed,100,340)
	stat_cache_key=cache_key;stat_cache=result.duplicate()
	return result

func award(id: String, xp: int, gold: int) -> bool:
	if data.claims.has(id): return false
	data.claims[id]=true;data.xp=mini(100000000,data.xp+maxi(0,xp));data.gold=mini(100000000,data.gold+maxi(0,gold));revision+=1
	return true

func validate(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not BASE.has(raw.get("class","")): return {}
	if not (raw.get("version",0) is int or raw.get("version",0) is float): return {}
	if raw.version!=int(raw.version) or int(raw.version) not in [1,2,3,4,5]: return {}
	var migration:=Migration.convert(raw)
	if not migration.ok: return {}
	raw=migration.record
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
	result.version=4
	for field in ["inventory","stash"]:
		if not Gear.valid_bag(result.get(field,[]),Gear.CAPACITY if field=="inventory" else Gear.STASH_CAPACITY): return {}
		result[field]=result.get(field,[])
	if not Gear.valid_bag(result.get("recovery",[]),Migration.RECOVERY_CAPACITY): return {}
	result.recovery=result.get("recovery",[])
	if not result.get("character_id","protagonist") is String: return {}
	result.character_id=result.get("character_id","protagonist")
	if not result.get("legacy_loadouts",[]) is Array: return {}
	result.legacy_loadouts=result.get("legacy_loadouts",[])
	if Rules.unknown_items(result): return {}
	if not result.get("equipped",{}) is Dictionary: return {}
	result.equipped=result.get("equipped",{})
	if not Rules.equipment_error(result.equipped,result["class"]).is_empty(): return {}
	for flag in ["favorites","locks"]:
		result[flag]=raw.get(flag,[]) if raw.version>=3 else []
		if not result[flag] is Array: return {}
		for id in result[flag]:
			if not id is String or not Gear.ITEMS.has(id): return {}
	result.loadouts=raw.get("loadouts",[]) if raw.version>=3 else [{"name":"Travel","items":result.equipped.duplicate()},{"name":"Battle","items":{}}]
	if not result.loadouts is Array or result.loadouts.size()>8: return {}
	for preset in result.loadouts:
		if not preset is Dictionary or not preset.get("name") is String or preset.name.length()>24 or not preset.get("items") is Dictionary: return {}
		if not Rules.equipment_error(preset.items,result["class"]).is_empty(): return {}
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
	result.version=int(raw.version)
	result=Party.migrate(result)
	if result.is_empty(): return {}
	if not result.get("roster") is Dictionary: return {}
	for id in Party.ids(result):
		if not id is String or (id!=result.character_id and not result.roster[id] is Dictionary): return {}
		var record: Dictionary=Party.record_for(result,id)
		if not Classes.CLASSES.has(record.get("class","")): return {}
		if not Classes.valid(record): return {}
		var probe=get_script().new();probe.data=record
		if record.get("health",-1)==-1 and int(raw.version)<5: record.health=probe.stats().hp
		record.evolution=Classes.evolution(record)
	if not Party.valid(result): return {}
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
	if FileAccess.file_exists(path):
		var original=JSON.parse_string(FileAccess.get_file_as_string(path))
		if Rules.unknown_items(original): error="Unknown item records preserved; save replacement refused.";return false
		if original is Dictionary and int(original.get("version",0))==5 and validate(original).is_empty(): error="Invalid or unsupported party data preserved; save replacement refused.";return false
		if original is Dictionary and int(original.get("version",0)) in [1,2,3,4]:
			if validate(original).is_empty(): error="Unsafe party migration; original preserved.";return false
			if not FileAccess.file_exists(path+".pre-v5.bak") and DirAccess.copy_absolute(path,path+".pre-v5.bak")!=OK: error="Could not back up pre-party save.";return false
		if original is Dictionary and int(original.get("version",0)) in [1,2,3]:
			var migration:=Migration.convert(original)
			if not migration.ok: error=migration.error;return false
			if not FileAccess.file_exists(path+".pre-v4.bak") and DirAccess.copy_absolute(path,path+".pre-v4.bak")!=OK: error="Could not back up original fifteen-slot save.";return false
		if original is Dictionary and int(original.get("version",0)) in [1,2] and not read_record(path).is_empty() and not FileAccess.file_exists(path+".pre-v3.bak"):
			if DirAccess.copy_absolute(path,path+".pre-v3.bak")!=OK: error="Could not back up legacy save before migration.";return false
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
	migration_notice=""
	if FileAccess.file_exists(path):
		var parser:=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path))==OK and parser.data is Dictionary:
			var migration:=Migration.convert(parser.data)
			if not migration.ok: error=migration.error;return false
			migration_notice=migration.notice
	if FileAccess.file_exists(path) and Rules.unknown_items(JSON.parse_string(FileAccess.get_file_as_string(path))):
		error="Unknown items in campaign; original file preserved. Load refused.";return false
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
		var parser:=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(directory+"/"+file))==OK and parser.data is Dictionary:
			var migration:=Migration.convert(parser.data)
			if not migration.ok:
				result.append({"id":file.trim_suffix(".json"),"record":{},"problem":migration.error});continue
		var record:=read_record(directory+"/"+file)
		if record.is_empty(): record=read_record(directory+"/"+file+".bak")
		result.append({"id":file.trim_suffix(".json"),"record":record})
	return result

func commit_gear(plan: Dictionary) -> bool:
	gear_error=plan.get("error","")
	if not plan.ok: return false
	data.inventory=plan.inventory;data.equipped=plan.equipped;revision+=1
	if data.has("health"): data.health=minf(data.health,stats().hp)
	return true

func equip(index: int, requested: String="") -> bool: return commit_gear(Rules.equip(data,index,requested))

func unequip(slot_name: String) -> bool:
	gear_error=""
	if not data.equipped.has(slot_name): gear_error="That slot is empty.";return false
	var bag: Array=data.inventory.duplicate(true)
	if not Gear.add(bag,data.equipped[slot_name],Gear.CAPACITY): gear_error="Backpack full. Nothing changed.";return false
	data.inventory=bag;data.equipped.erase(slot_name);revision+=1
	if data.has("health"): data.health=minf(data.health,stats().hp)
	return true

func toggle_flag(id: String, flag: String) -> bool:
	if not flag in ["favorites","locks"] or not Gear.ITEMS.has(id): return false
	if id in data[flag]: data[flag].erase(id)
	else: data[flag].append(id)
	revision+=1;return true

func save_loadout(index: int, label: String) -> bool:
	if index<0 or index>=data.loadouts.size() or label.strip_edges().is_empty(): gear_error="Choose a preset and a name.";return false
	data.loadouts[index]={"name":label.strip_edges().left(24),"items":data.equipped.duplicate()};revision+=1;return true

func rename_loadout(index: int, label: String) -> bool:
	if index<0 or index>=data.loadouts.size() or label.strip_edges().is_empty(): gear_error="Choose a preset and a nonempty name.";return false
	data.loadouts[index].name=label.strip_edges().left(24);revision+=1;return true

func apply_loadout(index: int) -> bool:
	if index<0 or index>=data.loadouts.size(): gear_error="Preset unavailable.";return false
	return commit_gear(Rules.loadout(data,data.loadouts[index].items))

func transfer(index: int, deposit: bool) -> bool:
	gear_error=""
	var source: Array=data.inventory if deposit else data.stash
	var destination: Array=data.stash if deposit else data.inventory
	if index<0 or index>=source.size(): gear_error="Selected item is no longer available.";return false
	if not Gear.add(destination,source[index].id,Gear.STASH_CAPACITY if deposit else Gear.CAPACITY): gear_error="Destination is full. Nothing changed.";return false
	Gear.remove(source,index);revision+=1;return true

func buy(id: String) -> bool:
	gear_error=""
	if not id in Gear.SHOP or not Gear.allowed(id,data["class"]): gear_error="This merchant item is not available to your class.";return false
	var gate: String=Gear.ITEMS[id].get("gate","")
	if (gate in ["bread","both"] and not data.claims.has("bread")) or (gate=="both" and not data.claims.has("mill-enforcer-v1")): gear_error="Requires returning Anja's flour"+(" and defeating the Enforcer." if gate=="both" else ".");return false
	var price: int=Gear.ITEMS[id].value*2
	if data.gold<price: gear_error="Not enough coins.";return false
	if not Gear.add(data.inventory,id,Gear.CAPACITY): gear_error="Backpack is full. No coins spent.";return false
	data.gold-=price;revision+=1;return true

func sell(index: int) -> bool:
	gear_error=""
	if index<0 or index>=data.inventory.size(): gear_error="Selected item is no longer carried.";return false
	if data.inventory[index].id in data.get("locks",[]): gear_error="Locked item: unlock it before selling. Nothing changed.";return false
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

func comparison_data(id: String, requested: String="") -> Dictionary:
	if not Gear.ITEMS.has(id) or Gear.ITEMS[id].slot.is_empty(): return {"error":"No stat change"}
	var target: String=Rules.target_slot(id,data.equipped) if requested.is_empty() else requested
	if not Rules.fits(id,target,data["class"]): return {"error":"Incompatible class or slot","slot":target}
	var probe: Dictionary=data.duplicate(true);probe.inventory=[{"id":id,"count":1}]
	var plan: Dictionary=Rules.equip(probe,0,target)
	if not plan.ok: return {"error":plan.error,"slot":target}
	var before:=stats()
	var preview=get_script().new();preview.data=data.duplicate(false);preview.data.equipped=plan.equipped;preview.effects=effects
	var after: Dictionary=preview.stats()
	var deltas: Dictionary={}
	for key in before: deltas[key]=after[key]-before[key]
	return {"slot":target,"before":before,"after":after,"deltas":deltas,"equipped":plan.equipped}

func comparison(id: String, requested: String="") -> String:
	var result:=comparison_data(id,requested)
	if result.has("error"): return result.error
	var lines: PackedStringArray=[]
	for key in ["hp","damage","defense","cooldown","speed","strength","agility","intellect","vitality","range","windup"]:
		var delta: float=result.deltas[key]
		if not is_zero_approx(delta): lines.append("%s %+.2f"%[key,delta])
	return ", ".join(lines) if not lines.is_empty() else "No stat change"

func recover_item(index: int) -> bool:
	gear_error=""
	if index<0 or index>=data.recovery.size(): gear_error="Recovery item is no longer available.";return false
	var bag: Array=data.inventory.duplicate(true)
	if not Gear.add(bag,data.recovery[index].id,Gear.CAPACITY): gear_error="Backpack full. Recovery item remains protected.";return false
	data.inventory=bag;Gear.remove(data.recovery,index);revision+=1;return true

func character_context(identity: String="protagonist") -> Dictionary:
	var record: Dictionary=Party.record_for(data,identity)
	if record.is_empty(): return {}
	if identity==data.character_id: return {"id":identity,"record":data,"model":self}
	var view=load("res://scripts/character_view.gd").new();view.setup(self,identity)
	return {"id":identity,"record":record,"model":view}

func roster_change(identity: String,position: int,at_vigil: bool) -> bool:
	gear_error=""
	if not at_vigil: gear_error="Party changes require Vigil Camp.";return false
	var record: Dictionary=Party.record_for(data,identity)
	if record.is_empty() or position < -1 or position>=6: return false
	if not record.availability.available: gear_error=record.availability.reason;return false
	if identity==data.character_id and position==-1: gear_error="The protagonist must remain active.";return false
	var active: Array=data.active_party.duplicate();var reserve: Array=data.reserve_roster.duplicate()
	var old:=active.find(identity)
	if position==-1:
		if old<0: return false
		active[old]="";reserve.append(identity)
	else:
		var displaced: String=active[position]
		if not displaced.is_empty() and not Party.record_for(data,displaced).availability.available: gear_error="That position is story-restricted.";return false
		if old>=0: active[old]=displaced
		elif not displaced.is_empty():
			if displaced==data.character_id: gear_error="Move the protagonist to another active position first.";return false
			reserve.append(displaced)
		active[position]=identity;reserve.erase(identity)
	data.active_party=active;data.reserve_roster=reserve;revision+=1;return true

func transfer_equipped(source_id: String,target_id: String,slot_name: String) -> bool:
	if source_id==target_id: return false
	var source: Dictionary=Party.record_for(data,source_id);var target_record: Dictionary=Party.record_for(data,target_id)
	if source.is_empty() or target_record.is_empty() or not source.equipped.has(slot_name): return false
	var probe: Dictionary=data.duplicate(true)
	probe.equipped=target_record.equipped.duplicate();probe["class"]=target_record["class"]
	probe.inventory.append({"id":source.equipped[slot_name],"count":1})
	var plan: Dictionary=Rules.equip(probe,probe.inventory.size()-1,slot_name)
	if not plan.ok: gear_error=plan.error;return false
	source.equipped.erase(slot_name);target_record.equipped=plan.equipped;data.inventory=plan.inventory;revision+=1;clamp_character_health(source_id);clamp_character_health(target_id);return true

func spend_talent(identity: String,talent: String) -> bool:
	var record: Dictionary=Party.record_for(data,identity)
	if record.is_empty(): return false
	gear_error=Classes.spend_error(record,talent)
	if not gear_error.is_empty(): return false
	record.talents[talent]=int(record.talents.get(talent,0))+1;record.evolution=Classes.evolution(record);revision+=1;return true

func reset_talents(identity: String,at_vigil: bool) -> bool:
	var record: Dictionary=Party.record_for(data,identity)
	if not at_vigil or record.is_empty(): return false
	record.talents={};record.evolution=Classes.evolution(record);revision+=1;clamp_character_health(identity);return true

func recruit_character(record: Dictionary) -> bool:
	# Story integration seam. This pass has no gameplay recruitment event.
	# Recruitment cannot mint owned gear: equipment must come from shared inventory.
	var id: Variant=record.get("character_id")
	if not id is String or id in Party.ids(data) or not Party.valid_character(record,id) or not record.equipped.is_empty(): return false
	for field in Party.SHARED:
		if record.has(field): return false
	data.roster[id]=record.duplicate(true);data.reserve_roster.append(id);revision+=1;return true

func clamp_character_health(identity: String) -> void:
	var record: Dictionary=Party.record_for(data,identity)
	record.health=minf(record.health,character_context(identity).model.stats().hp)
