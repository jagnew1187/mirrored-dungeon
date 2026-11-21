extends RefCounted
## A revision-checked transaction view. No private backpack or copied saved ownership.
const Gear=preload("res://scripts/items.gd")
const Rules=preload("res://scripts/gear_rules.gd")
const Migration=preload("res://scripts/equipment_migration.gd")
const Party=preload("res://scripts/party_state.gd")
var campaign: RefCounted
var identity: String
var model: RefCounted
var expected: int
var data: Dictionary:
	get: return model.data
var revision: int:
	get: return expected
var effects: Dictionary:
	get: return model.effects
var gear_error: String:
	get: return model.gear_error
func setup(owner: RefCounted,id: String) -> void:
	campaign=owner;identity=id;expected=owner.revision;model=owner.get_script().new()
	model.data=owner.data.duplicate(true)
	var record: Dictionary=Party.record_for(owner.data,id)
	for key in Party.PERSONAL:
		if record.has(key): model.data[key]=record[key].duplicate(true) if record[key] is Dictionary or record[key] is Array else record[key]
	model.effects={}
func stats() -> Dictionary: return model.stats()
func progress() -> Dictionary: return model.progress()
func comparison(id: String,target: String="") -> String: return model.comparison(id,target)
func comparison_data(id: String,target: String="") -> Dictionary: return model.comparison_data(id,target)
func invoke(method: String,args: Array) -> bool:
	if campaign.revision!=expected: model.gear_error="Party inventory changed. Inspect the item again.";return false
	if not model.callv(method,args): return false
	var record: Dictionary=Party.record_for(campaign.data,identity)
	for key in Party.PERSONAL:
		if model.data.has(key): record[key]=model.data[key]
	for key in Party.SHARED: campaign.data[key]=model.data[key]
	record.health=minf(record.health,model.stats().hp)
	campaign.revision+=1;expected=campaign.revision;return true
func equip(index: int,target: String="") -> bool: return invoke("equip",[index,target])
func unequip(slot_name: String) -> bool: return invoke("unequip",[slot_name])
func transfer(index: int,deposit: bool) -> bool: return invoke("transfer",[index,deposit])
func buy(id: String) -> bool: return invoke("buy",[id])
func sell(index: int) -> bool: return invoke("sell",[index])
func toggle_flag(id: String,flag: String) -> bool: return invoke("toggle_flag",[id,flag])
func recover_item(index: int) -> bool: return invoke("recover_item",[index])
func save_loadout(index: int,label: String) -> bool: return invoke("save_loadout",[index,label])
func rename_loadout(index: int,label: String) -> bool: return invoke("rename_loadout",[index,label])
func apply_loadout(index: int) -> bool: return invoke("apply_loadout",[index])
