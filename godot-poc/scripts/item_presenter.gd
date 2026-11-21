extends RefCounted
const Gear=preload("res://scripts/items.gd")
const LABELS={"hp":"Health","damage":"Attack damage","defense":"Defense","cooldown":"Attack interval (s)","speed":"Movement speed","strength":"Strength","agility":"Agility","intellect":"Intellect","vitality":"Vitality","range":"Attack range","windup":"Attack windup (s)"}
static func number(value: float) -> String:
	return ("%.4f"%value).trim_suffix("0").trim_suffix("0").trim_suffix("0").trim_suffix(".")
static func signed(value: float) -> String: return ("+" if value>=0 else "")+number(value)
static func set_status(items: Dictionary, set_id: String) -> String:
	var count:=0
	for slot_name in items:
		var id: String=items[slot_name]
		if slot_name in Gear.SLOTS and slot_name in Gear.ITEMS[id].slots and Gear.ITEMS[id].get("set","")==set_id: count+=1
	return "%d pieces: %s"%[count,"+6 Health, +1 Defense" if count>=3 else ("+6 Health" if count>=2 else "no active bonus")]
static func describe(model: RefCounted, id: String, target: String="", worn:=false) -> String:
	var item: Dictionary=Gear.ITEMS[id]
	if item.get("legacy",false): return item.name+" · "+item.rarity+"\nLegacy cloak · owned, unequippable\nHistorical modifiers (inactive): "+str(item.mods)+"\nNo equipment or set bonuses. Keep, stash or sell; locked copies remain protected."
	if target.is_empty(): target=model.Rules.target_slot(id,model.data.equipped)
	var lines: PackedStringArray=[item.name+" · "+item.rarity,", ".join(item.slots.map(func(s):return Gear.LABELS.get(s,"Consumable")))+" · "+item.category]
	if item.slot in ["weapon","offhand"]: lines.append("Two-handed" if item.hands==2 else "One-handed")
	lines.append("Classes: "+("All" if item.classes.is_empty() else ", ".join(item.classes)))
	lines.append("DIRECT ITEM BONUSES")
	var mods: Dictionary=item.mods.duplicate()
	if item.slot in ["weapon","offhand"] and not mods.has("damage"): mods.damage=0
	if item.slot in ["head","shoulders","armor","hands","waist","legs","feet","back"] and not mods.has("defense"): mods.defense=0
	for key in LABELS:
		if mods.has(key): lines.append(LABELS[key]+" "+signed(mods[key]))
	if mods.is_empty(): lines.append("No direct stat bonuses")
	var set_id: String=item.get("set","")
	if not set_id.is_empty():
		lines.append("Set: "+set_id.capitalize()+" · 2 pieces +6 Health; 3 pieces +1 Defense")
		lines.append("Active now: "+set_status(model.data.equipped,set_id))
	if not target.is_empty():
		var current: String=model.data.equipped.get(target,"")
		lines.append("Currently in "+Gear.LABELS[target]+": "+(Gear.ITEMS[current].name if not current.is_empty() else "Empty"))
	lines.append("FINAL CHARACTER CHANGES"+(" (already equipped)" if worn else ""))
	var result: Dictionary=model.comparison_data(id,target)
	if result.has("error"): lines.append(result.error)
	else:
		var changed:=false
		for key in LABELS:
			if not is_zero_approx(result.deltas[key]):
				changed=true;lines.append("%s %s → %s (%s)"%[LABELS[key],number(result.before[key]),number(result.after[key]),signed(result.deltas[key])])
		if not changed: lines.append("No stat change")
		for slot in model.data.equipped:
			if slot!=target and not result.equipped.has(slot): lines.append("Also displaced: "+Gear.ITEMS[model.data.equipped[slot]].name)
		if not set_id.is_empty(): lines.append("Set after equip: "+set_status(result.equipped,set_id))
	lines.append("Comparison: "+model.comparison(id,target))
	lines.append("Lower attack interval is faster. Values include attributes, sets and clamps.")
	return "\n".join(lines)
