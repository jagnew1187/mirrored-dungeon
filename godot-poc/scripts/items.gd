extends RefCounted
## Stable IDs are serialized; display names and balance remain editable here.
const CAPACITY = 16
const STASH_CAPACITY = 40
const ITEMS = {
	"sword":{"name":"Arbiter's worn sword","slot":"weapon","category":"sword","classes":["knight"],"mods":{},"value":8,"rarity":"Common","description":"A familiar blade, kept sharp through exile."},
	"staff":{"name":"Travel staff","slot":"weapon","category":"focus","classes":["mage"],"mods":{},"value":8,"rarity":"Common","description":"A simple focus for an arcane bolt."},
	"daggers":{"name":"Balanced daggers","slot":"weapon","category":"dagger","classes":["rogue"],"mods":{},"value":8,"rarity":"Common","description":"Light blades suited to a moving target."},
	"coat":{"name":"Travel coat","slot":"armor","category":"cloth","classes":[],"mods":{},"value":5,"rarity":"Common","description":"Worn protection against weather and road dust."},
	"steel_sword":{"name":"Serviceable steel sword","slot":"weapon","category":"sword","classes":["knight"],"mods":{"damage":4.0},"value":26,"rarity":"Improved","description":"A sound edge with more weight behind each strike."},
	"ash_staff":{"name":"Ashwood focus","slot":"weapon","category":"focus","classes":["mage"],"mods":{"damage":4.0},"value":26,"rarity":"Improved","description":"Steadies the release of an arcane bolt."},
	"fine_daggers":{"name":"Fine throwing daggers","slot":"weapon","category":"dagger","classes":["rogue"],"mods":{"damage":3.0,"cooldown":-0.02},"value":26,"rarity":"Improved","description":"Balanced for a fast, precise release."},
	"padded_coat":{"name":"Padded coat","slot":"armor","category":"light armor","classes":[],"mods":{"hp":12.0,"defense":1.0},"value":18,"rarity":"Common","description":"A little extra protection without slowing the wearer."},
	"charm":{"name":"Baker's keepsake","slot":"accessory","category":"charm","classes":[],"mods":{"hp":16.0},"value":15,"rarity":"Improved","description":"A small reminder of the people who share their bread."},
	"boots":{"name":"Traveler's clasp","slot":"accessory","category":"clasp","classes":[],"mods":{"speed":8.0},"value":12,"rarity":"Common","description":"Keeps a travel cloak clear of the wearer's stride."},
	"tonic":{"name":"Restorative tonic","slot":"","category":"consumable","classes":[],"mods":{},"value":6,"stack":5,"heal":60,"rarity":"Common","description":"Restores 60 health. Cannot be used at full health or after defeat."}
}
const STARTER = {"knight":"sword","mage":"staff","rogue":"daggers"}
const UPGRADE = {"knight":"steel_sword","mage":"ash_staff","rogue":"fine_daggers"}
const SHOP = ["tonic","padded_coat","boots","steel_sword","ash_staff","fine_daggers"]
const LOOT = ["tonic","padded_coat","boots"]

static func allowed(id: String, kind: String) -> bool:
	return ITEMS.has(id) and (ITEMS[id].classes.is_empty() or kind in ITEMS[id].classes)

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
