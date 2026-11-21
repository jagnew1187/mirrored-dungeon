extends RefCounted
const Gear=preload("res://scripts/items.gd")
const OLD_SLOTS=["head","armor","hands","legs","feet","neck","ring1","accessory","weapon","offhand","shoulders","waist","ring2","trinket2","back"]
const MERGED={"shoulders":"armor","waist":"legs","ring2":"ring1","trinket2":"accessory"}
const RECOVERY_CAPACITY=15
static func fail(message: String) -> Dictionary: return {"ok":false,"error":message}
static func assignment(slot: String,id: String) -> String:
	if Gear.ITEMS[id].get("legacy",false): return ""
	if id=="boots" and slot in ["accessory","trinket2"]: return "feet"
	return MERGED.get(slot,slot)
static func convert(raw: Dictionary) -> Dictionary:
	var record: Dictionary=raw.duplicate(true)
	if not Gear.STARTER.has(raw.get("class","")): return fail("Unknown character class; original preserved.")
	if not raw.get("version",0) in [1,2,3,4,5] and not int(raw.get("version",0)) in [1,2,3,4,5]: return fail("Unsupported save version; original preserved.")
	if int(raw.version)>=4: return {"ok":true,"record":record,"notice":""}
	if raw.get("recovery",[]) is Array and not raw.get("recovery",[]).is_empty(): return fail("Unexpected recovery ownership in a legacy schema; original preserved.")
	if int(raw.version)==1:
		record.inventory=[];record.stash=[];record.equipped={"weapon":Gear.STARTER[record["class"]],"armor":"coat"};record.loot={}
		if raw.get("upgraded",false):
			if raw.get("weapon_equipped",false): record.equipped.weapon=Gear.UPGRADE[record["class"]]
			else: Gear.add(record.inventory,Gear.UPGRADE[record["class"]],16)
	if not Gear.valid_bag(record.get("inventory",[]),16) or not Gear.valid_bag(record.get("stash",[]),40) or not record.get("equipped",{}) is Dictionary: return fail("Invalid legacy ownership; original preserved.")
	var worn: Dictionary=record.get("equipped",{});var converted: Dictionary={};var displaced: Array=[]
	for slot in worn:
		if not slot in OLD_SLOTS or not worn[slot] is String or not Gear.allowed(worn[slot],record["class"]): return fail("Unknown or incompatible legacy equipment; original preserved.")
	# Existing primary slots win; Boots misfiled as accessories are deferred until Feet.
	for slot in OLD_SLOTS:
		if not worn.has(slot): continue
		var id: String=worn[slot];var target:=assignment(slot,id)
		if target.is_empty(): displaced.append(id);continue
		if not target in Gear.ITEMS[id].slots: return fail("Legacy item does not fit its consolidated slot: "+id)
		if converted.has(target): displaced.append(id)
		else: converted[target]=id
	if converted.has("weapon") and Gear.ITEMS[converted.weapon].hands==2 and converted.has("offhand"):
		displaced.append(converted.offhand);converted.erase("offhand")
	record.inventory=record.get("inventory",[]);record.stash=record.get("stash",[]);record.recovery=[]
	for id in displaced:
		if Gear.add(record.inventory,id,16): continue
		if Gear.add(record.stash,id,40): continue
		if not Gear.add(record.recovery,id,RECOVERY_CAPACITY): return fail("Migration recovery capacity exceeded; original preserved.")
	record.equipped=converted
	var presets: Variant=record.get("loadouts",[{"name":"Travel","items":worn.duplicate()},{"name":"Battle","items":{}}])
	if not presets is Array: return fail("Invalid loadouts; original preserved.")
	record.legacy_loadouts=presets.duplicate(true);record.loadouts=[]
	for preset in presets:
		if not preset is Dictionary or not preset.get("items") is Dictionary: return fail("Invalid legacy preset; original preserved.")
		var mapping: Dictionary={}
		for slot in preset.items:
			if not slot in OLD_SLOTS or not preset.items[slot] is String or not Gear.ITEMS.has(preset.items[slot]): return fail("Unknown legacy loadout reference; original preserved.")
		for slot in OLD_SLOTS:
			if not preset.items.has(slot): continue
			var id: String=preset.items[slot];var target:=assignment(slot,id)
			if target.is_empty() or mapping.has(target): continue
			if not Gear.allowed(id,record["class"]) or not target in Gear.ITEMS[id].slots: return fail("Incompatible legacy loadout reference; original preserved.")
			mapping[target]=id
		if mapping.has("weapon") and Gear.ITEMS[mapping.weapon].hands==2: mapping.erase("offhand")
		var updated: Dictionary=preset.duplicate(true);updated.items=mapping;record.loadouts.append(updated)
	record.version=4;record.character_id=record.get("character_id","protagonist");record.favorites=record.get("favorites",[]);record.locks=record.get("locks",[])
	return {"ok":true,"record":record,"notice":"Equipment migrated to ten slots. Displaced items remain in backpack, stash or Migration Recovery at Vigil."}
