extends RefCounted
## Heroic foundations only. Unimplemented class and evolution names are proposals.
static var CLASSES: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
static func level(record: Dictionary) -> int:
	var value:=1;var xp:=int(record.get("xp",0))
	while value<60 and xp>=80+40*(value-1)*(value-1): xp-=80+40*(value-1)*(value-1);value+=1
	return value
static func nodes(kind: String) -> Array: return CLASSES.get(kind,{}).get("talents",[])
static func node(kind: String,id: String) -> Dictionary:
	for entry in nodes(kind):
		if entry.id==id: return entry
	return {}
static func spent(record: Dictionary) -> int:
	var total:=0
	for rank in record.get("talents",{}).values(): total+=int(rank)
	return total
static func points(record: Dictionary) -> int: return level(record)-1+int(record.get("story_talent_points",0))-spent(record)
static func requirements(record: Dictionary,req: Dictionary) -> bool:
	for id in req:
		if int(record.get("talents",{}).get(id,0))<int(req[id]): return false
	return true
static func branch_points(record: Dictionary,branch: String) -> int:
	var total:=0
	for entry in nodes(record["class"]):
		if entry.branch==branch: total+=int(record.get("talents",{}).get(entry.id,0))
	return total
static func spend_error(record: Dictionary,id: String) -> String:
	var entry:=node(record["class"],id)
	if entry.is_empty(): return "Talent is unavailable for this character."
	if int(record.get("talents",{}).get(id,0))>=int(entry.max_rank): return "Maximum rank learned."
	if not requirements(record,entry.requires): return "Prerequisites are not learned."
	if points(record)<=0: return "No talent points available."
	return ""
static func valid(record: Dictionary) -> bool:
	if not record.get("talents",{}) is Dictionary: return false
	var story: Variant=record.get("story_talent_points",0)
	if not (story is int or story is float) or story!=int(story) or story<0 or story>100: return false
	for id in record.get("talents",{}):
		var rank: Variant=record.talents[id];var entry:=node(record["class"],id)
		if entry.is_empty() or not (rank is int or rank is float) or rank!=int(rank) or rank<1 or rank>entry.max_rank : return false
	for id in record.get("talents",{}):
		if not requirements(record,node(record["class"],id).requires): return false
	return points(record)>=0
static func modifiers(record: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for entry in nodes(record.get("class","knight")):
		var rank:=int(record.get("talents",{}).get(entry.id,0))
		for key in entry.mods: result[key]=result.get(key,0.0)+entry.mods[key]*rank
	return result
static func qualifies(record: Dictionary,evolution: Dictionary) -> bool:
	if not evolution.enabled or not requirements(record,evolution.requires): return false
	for branch in evolution.branches:
		if branch_points(record,branch)<int(evolution.branches[branch]): return false
	return true
static func evolution(record: Dictionary) -> Dictionary:
	var choices: Array=[]
	for entry in CLASSES[record["class"]].evolutions:
		if qualifies(record,entry): choices.append(entry)
	# Highest stage, explicit hybrid priority, then stable alphabetical ID.
	choices.sort_custom(func(a,b):return a.stage>b.stage if a.stage!=b.stage else (a.priority>b.priority if a.priority!=b.priority else a.id<b.id))
	return {"id":record["class"],"title":CLASSES[record["class"]].name,"stage":1} if choices.is_empty() else choices[0].duplicate(true)
static func requirement_text(record: Dictionary,entry: Dictionary) -> String:
	var parts: PackedStringArray=[]
	for id in entry.requires: parts.append("%s %d/%d"%[node(record["class"],id).get("name",id),record.get("talents",{}).get(id,0),entry.requires[id]])
	for branch in entry.branches: parts.append("%s investment %d/%d"%[CLASSES[record["class"]].branches[branch],branch_points(record,branch),entry.branches[branch]])
	return "; ".join(parts)
