extends RefCounted
const Classes=preload("res://scripts/class_progression.gd")
const Rules=preload("res://scripts/gear_rules.gd")
const PERSONAL=["class","name","xp","equipped","loadouts","legacy_loadouts","talents","story_talent_points","evolution","health","biography","personal_quests","relationships","story_decisions","dialogue_flags","availability","unique_talent_unlocks","recruitment_state","background","character_id"]
const SHARED=["inventory","stash","recovery","gold","favorites","locks"]
static func defaults(record: Dictionary) -> void:
	for field in ["talents","personal_quests","relationships","story_decisions","dialogue_flags"]:
		if not record.has(field): record[field]={}
	if not record.has("unique_talent_unlocks"): record.unique_talent_unlocks=[]
	if not record.has("story_talent_points"): record.story_talent_points=0
	if not record.has("biography"): record.biography={"knight":"A former arbiter and one of the three central protagonists.","mage":"One of the three central protagonists. A student of arcane magic.","rogue":"The Necromancer's fraternal twin brother. His brother's forbidden magic is a profound personal conflict."}.get(record["class"],"")
	if not record.has("background"): record.background=record.biography
	if not record.has("availability"): record.availability={"available":true,"reason":""}
	if not record.has("recruitment_state"): record.recruitment_state="recruited"
	if not record.has("health"): record.health=-1.0
	if not record.has("evolution"): record.evolution=Classes.evolution(record)
static func migrate(record: Dictionary) -> Dictionary:
	var result:=record.duplicate(true)
	if int(result.version)==5: return result
	# Do not overwrite unexpected party ownership in an older schema.
	if result.get("roster",{})!={} or result.get("reserve_roster",[])!=[]: return {}
	if not result.get("active_party",[]) is Array: return {}
	for id in result.get("active_party",[]):
		if id not in ["",result.character_id]: return {}
	defaults(result);result.roster={};result.active_party=[result.character_id,"","","","",""];result.reserve_roster=[];result.selected_character_id=result.character_id;result.version=5
	return result
static func record_for(data: Dictionary,id: String) -> Dictionary:
	if id==data.get("character_id","protagonist"): return data
	return data.get("roster",{}).get(id,{})
static func ids(data: Dictionary) -> Array:
	var result: Array=[data.get("character_id","protagonist")];result.append_array(data.get("roster",{}).keys());return result
static func valid_character(record: Dictionary,id: String) -> bool:
	for field in PERSONAL:
		if not record.has(field): return false
	if not record.get("talents") is Dictionary or not record.get("legacy_loadouts") is Array: return false
	if not id is String or id.is_empty() or id.length()>80 or record.get("character_id")!=id: return false
	if not Classes.CLASSES.has(record.get("class","")) or not record.get("name") is String or not record.get("xp") is float and not record.get("xp") is int: return false
	if record.xp!=int(record.xp) or record.xp<0 or record.xp>100000000: return false
	if not record.get("equipped") is Dictionary or not Rules.equipment_error(record.equipped,record["class"]).is_empty(): return false
	if not record.get("loadouts") is Array or record.loadouts.size()>8: return false
	for preset in record.loadouts:
		if not preset is Dictionary or not preset.get("name") is String or not preset.get("items") is Dictionary or not Rules.equipment_error(preset.items,record["class"]).is_empty(): return false
	if not Classes.valid(record): return false
	if not (record.get("health") is float or record.get("health") is int) or not is_finite(float(record.health)) or record.health<0 or record.health>5000: return false
	if not record.get("biography") is String or not record.get("background") is String: return false
	for field in ["personal_quests","relationships","story_decisions","dialogue_flags"]:
		if not record.get(field) is Dictionary: return false
	if not record.get("unique_talent_unlocks") is Array or record.get("recruitment_state")!="recruited": return false
	if not record.get("availability") is Dictionary or not record.availability.get("available") is bool or not record.availability.get("reason") is String: return false
	return true
static func valid(data: Dictionary) -> bool:
	if not data.get("roster") is Dictionary or not data.get("active_party") is Array or data.active_party.size()!=6 or not data.get("reserve_roster") is Array: return false
	var all_ids:=ids(data);var seen: Array=[]
	if data.roster.has(data.character_id) or not data.get("selected_character_id") in all_ids: return false
	for id in all_ids:
		if not id is String or (id!=data.character_id and not data.roster[id] is Dictionary): return false
		var record:=record_for(data,id)
		if not valid_character(record,id): return false
		if id!=data.character_id:
			for field in SHARED:
				if record.has(field): return false
		if Rules.unknown_items(record): return false
	for id in data.active_party+data.reserve_roster:
		if not id is String: return false
		if id.is_empty(): continue
		if not id in all_ids or id in seen: return false
		seen.append(id)
	return seen.size()==all_ids.size() and data.character_id in data.active_party and not "" in data.reserve_roster
