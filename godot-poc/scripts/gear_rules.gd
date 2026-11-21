extends RefCounted
const Gear=preload("res://scripts/items.gd")
static func reject(message: String) -> Dictionary: return {"ok":false,"error":message}
static func legacy_footwear(raw: Variant) -> bool:
	if not raw is Dictionary: return false
	var assignments: Array=[raw.get("equipped",{})]
	if raw.get("loadouts") is Array:
		for preset in raw.loadouts:
			if preset is Dictionary: assignments.append(preset.get("items",{}))
	for worn in assignments:
		if worn is Dictionary:
			for slot in ["accessory","trinket2"]:
				if worn.get(slot)=="boots": return true
	return false
static func migrate_footwear(raw: Dictionary) -> Dictionary:
	var result: Dictionary=raw.duplicate(true)
	if not legacy_footwear(result): return {"ok":true,"record":result,"notice":""}
	if not result.get("inventory",[]) is Array or not result.get("equipped",{}) is Dictionary: return reject("Invalid legacy equipment record; original preserved.")
	if not Gear.valid_bag(result.get("inventory",[]),Gear.CAPACITY): return reject("Invalid legacy inventory; original preserved.")
	var bag: Array=result.get("inventory",[])
	for slot in ["accessory","trinket2"]:
		if result.equipped.get(slot)!="boots": continue
		if not result.equipped.has("feet"): result.equipped.feet="boots"
		elif not Gear.add(bag,"boots",Gear.CAPACITY): return reject("Legacy boots migration needs backpack space because Feet is occupied. Original save preserved; free a backpack slot in the previous build first.")
		result.equipped.erase(slot)
	result.inventory=bag
	var notice: String="Legacy boots moved to Feet or backpack without changing item quantities."
	if result.get("loadouts") is Array:
		for preset in result.loadouts:
			if not preset is Dictionary or not preset.get("items") is Dictionary: continue
			for slot in ["accessory","trinket2"]:
				if preset.items.get(slot)!="boots": continue
				if not preset.items.has("feet"): preset.items.feet="boots"
				else: notice+=" A preset retained its existing Feet assignment; extra boots remain owned."
				preset.items.erase(slot)
	return {"ok":true,"record":result,"notice":notice}
static func fits(id: String, slot: String, kind: String) -> bool:
	return Gear.allowed(id,kind) and slot in Gear.SLOTS and slot in Gear.ITEMS[id].slots and not (slot=="offhand" and Gear.ITEMS[id].hands==2)
static func equipment_error(equipped: Dictionary, kind: String) -> String:
	for slot in equipped:
		if not equipped[slot] is String or not fits(equipped[slot],slot,kind): return "Item does not fit this slot or class."
	if equipped.has("weapon") and Gear.ITEMS[equipped.weapon].hands==2 and equipped.has("offhand"): return "A two-handed weapon reserves the off hand."
	return ""
static func target_slot(id: String, equipped: Dictionary) -> String:
	if not Gear.ITEMS.has(id) or Gear.ITEMS[id].slot.is_empty(): return ""
	for slot in Gear.ITEMS[id].slots:
		if not equipped.has(slot): return slot
	return Gear.ITEMS[id].slot
static func equip(data: Dictionary, index: int, requested: String="") -> Dictionary:
	if index<0 or index>=data.inventory.size(): return reject("The selected item is no longer carried.")
	var id: String=data.inventory[index].id
	var slot:=target_slot(id,data.equipped) if requested.is_empty() else requested
	if not fits(id,slot,data["class"]): return reject("This item cannot be equipped in that slot by this class.")
	var bag: Array=data.inventory.duplicate(true);var worn: Dictionary=data.equipped.duplicate(true)
	Gear.remove(bag,index)
	var displaced: Array=[slot]
	if slot=="weapon" and Gear.ITEMS[id].hands==2: displaced.append("offhand")
	if slot=="offhand" and worn.has("weapon") and Gear.ITEMS[worn.weapon].hands==2: displaced.append("weapon")
	for field in displaced:
		if worn.has(field):
			if not Gear.add(bag,worn[field],Gear.CAPACITY): return reject("Not enough backpack space for displaced equipment. Nothing changed.")
			worn.erase(field)
	worn[slot]=id
	var error:=equipment_error(worn,data["class"])
	if not error.is_empty(): return reject(error)
	return {"ok":true,"inventory":bag,"equipped":worn}
static func loadout(data: Dictionary, desired: Dictionary) -> Dictionary:
	var error:=equipment_error(desired,data["class"])
	if not error.is_empty(): return reject(error)
	# Ownership pool includes only this hero's equipped and carried items, never stash.
	var bag: Array=data.inventory.duplicate(true)
	for id in data.equipped.values():
		if not Gear.add(bag,id,Gear.CAPACITY+Gear.SLOTS.size()): return reject("Invalid ownership pool.")
	for id in desired.values():
		var found: int=-1
		for i in range(bag.size()):
			if bag[i].id==id: found=i;break
		if found<0: return reject("Missing carried item: "+Gear.ITEMS[id].name+". Stored or sold gear is not available.")
		Gear.remove(bag,found)
	if bag.size()>Gear.CAPACITY: return reject("Loadout needs more backpack space. Nothing changed.")
	return {"ok":true,"inventory":bag,"equipped":desired.duplicate(true)}
static func bonuses(equipped: Dictionary) -> Dictionary:
	var counts: Dictionary={};var mods: Dictionary={}
	for slot_name in equipped:
		var id: String=equipped[slot_name]
		if not slot_name in Gear.SLOTS or not Gear.ITEMS.has(id) or not slot_name in Gear.ITEMS[id].slots: continue
		var set_id: String=Gear.ITEMS[id].get("set","")
		if not set_id.is_empty(): counts[set_id]=counts.get(set_id,0)+1
	for set_id in counts:
		if counts[set_id]>=2: mods.hp=mods.get("hp",0)+6
		if counts[set_id]>=3: mods.defense=mods.get("defense",0)+1
	return mods
static func power(id: String, kind: String) -> float:
	var m: Dictionary=Gear.ITEMS[id].mods
	return m.get("damage",0)*3+m.get("hp",0)*.2+m.get("defense",0)*2+m.get("speed",0)*.2-m.get("cooldown",0)*40+m.get("vitality",0)*.6+m.get("agility",0)*.7+m.get("intellect",0)*(2.25 if kind=="mage" else 0)+m.get("strength",0)*(1.5 if kind!="mage" else 0)
static func indices(data: Dictionary, mode: String, sort: String, slot: String="", compatible:=false) -> Array[int]:
	var bag: Array=data.get("recovery",[]) if mode=="recovery" else (data.stash if mode=="stash" else data.inventory)
	var result: Array[int]=[]
	for i in range(bag.size()):
		var id: String=bag[i].id
		if compatible and not Gear.allowed(id,data["class"]): continue
		if not slot.is_empty() and not slot in Gear.ITEMS[id].slots: continue
		result.append(i)
	result.sort_custom(func(a,b):
		var x: Dictionary=Gear.ITEMS[bag[a].id];var y: Dictionary=Gear.ITEMS[bag[b].id]
		if sort=="rarity" and x.rarity!=y.rarity: return Gear.RARITIES.find(x.rarity)>Gear.RARITIES.find(y.rarity)
		if sort=="category" and x.slot!=y.slot: return x.slot<y.slot
		if sort=="power":
			var px:=power(bag[a].id,data["class"]);var py:=power(bag[b].id,data["class"])
			if not is_equal_approx(px,py): return px>py
		return x.name<y.name if x.name!=y.name else a<b)
	return result
static func unknown_items(raw: Variant) -> bool:
	if not raw is Dictionary: return false
	if raw.get("roster") is Dictionary:
		for record in raw.roster.values():
			if unknown_items(record): return true
	if raw.get("version",0) is float or raw.get("version",0) is int:
		if raw.get("version",0)>5: return true
	for flag in ["favorites","locks"]:
		if raw.get(flag) is Array:
			for id in raw[flag]:
				if id is String and not Gear.ITEMS.has(id): return true
	for field in ["loadouts","legacy_loadouts"]:
		if raw.get(field) is Array:
			for preset in raw[field]:
				if preset is Dictionary and preset.get("items") is Dictionary:
					for id in preset.items.values():
						if id is String and not Gear.ITEMS.has(id): return true
	for field in ["inventory","stash","recovery"]:
		if raw.get(field) is Array:
			for entry in raw[field]:
				if entry is Dictionary and entry.get("id") is String and not Gear.ITEMS.has(entry.id): return true
	if raw.get("equipped") is Dictionary:
		for id in raw.equipped.values():
			if id is String and not Gear.ITEMS.has(id): return true
	if raw.get("loot") is Dictionary:
		for entry in raw.loot.values():
			if entry is Dictionary and entry.get("item") is String and not Gear.ITEMS.has(entry.item): return true
	return false
