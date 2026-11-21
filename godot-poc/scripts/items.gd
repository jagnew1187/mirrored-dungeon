extends RefCounted
const ClassCatalog=preload("res://scripts/class_progression.gd")
## Stable IDs are serialized; display names and balance remain editable here.
const CAPACITY = 16
const STASH_CAPACITY = 40
static var ITEMS: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/gear_registry.json"))
const SLOTS=["head","armor","hands","legs","feet","neck","ring1","accessory","weapon","offhand"]
const LABELS={"head":"Head","shoulders":"Shoulders","armor":"Chest","hands":"Hands","waist":"Waist","legs":"Legs","feet":"Feet","back":"Back","neck":"Neck","ring1":"Ring","ring2":"Ring 2","accessory":"Accessory","trinket2":"Trinket 2","weapon":"Main Hand","offhand":"Offhand"}
const RARITIES=["Common","Uncommon","Rare","Epic","Legendary"]
const STARTER = {"knight":"sword","mage":"staff","rogue":"daggers"}
const UPGRADE = {"knight":"steel_sword","mage":"ash_staff","rogue":"fine_daggers"}
static var SHOP: Array=ITEMS.keys().filter(func(id):return not ITEMS[id].get("legacy",false) and id not in ["sword","staff","daggers","coat","charm","enforcer_seal","pilgrim_cloak"])
const LOOT = ["tonic","padded_coat","boots"]

static func allowed(id: String, kind: String) -> bool:
	return ITEMS.has(id) and (ITEMS[id].classes.is_empty() or ITEMS[id].classes.any(func(tag):return tag in ClassCatalog.CLASSES.get(kind,{}).get("equipment_permissions",{}).get("class_tags",[])))

static func add(bag: Array, id: String, capacity: int) -> bool:
	if not ITEMS.has(id): return false
	var limit: int=ITEMS[id].get("stack",1)
	for entry in bag:
		if entry.id==id and entry.count<limit: entry.count+=1;return true
	if bag.size()>=capacity: return false
	bag.append({"id":id,"count":1});return true

static func remove(bag: Array, index: int) -> bool:
	if index<0 or index>=bag.size(): return false
	bag[index].count-=1
	if bag[index].count==0: bag.remove_at(index)
	return true

static func valid_bag(raw: Variant, capacity: int) -> bool:
	if not raw is Array or raw.size()>capacity: return false
	for entry in raw:
		if not entry is Dictionary or not ITEMS.has(entry.get("id","")): return false
		var count: Variant=entry.get("count",0)
		if not (count is int or count is float) or count!=int(count) or count<1 or count>ITEMS[entry.id].get("stack",1): return false
	return true
