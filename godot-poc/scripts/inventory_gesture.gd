extends RefCounted
## Inventory-only gesture recognition. Equipment transactions remain in campaign.equip.
const DOUBLE_MS:=360
const DRAG_DISTANCE:=12.0
var bindings: Array[Dictionary]=[]
var pending: Dictionary={}
var active: Dictionary={}
var fingers: Dictionary={}
var ignore_emulated_until:=0
var pass_emulated:=true

func button_inspection_allowed() -> bool:
	return Time.get_ticks_msec()>=ignore_emulated_until

func reset(clear_bindings:=false) -> void:
	pending.clear();active.clear();fingers.clear()
	if clear_bindings: bindings.clear()

func bind(button: Button,id: String,index: int,revision: int,owner: String) -> void:
	button.set_meta("inventory_item",id)
	button.mouse_filter=Control.MOUSE_FILTER_PASS # Native touch drags reach ScrollContainer.
	bindings.append({"button":weakref(button),"id":id,"index":index,"revision":revision,"owner":owner})

func valid(entry: Dictionary,ui: Node) -> bool:
	if entry.is_empty() or entry.revision!=ui.game.campaign.revision or entry.owner!=ui.sheet_character_id: return false
	var button=entry.button.get_ref()
	if not is_instance_valid(button) or not button.is_inside_tree() or not button.is_visible_in_tree(): return false
	var bag: Array=ui.game.campaign.data.inventory
	return entry.index>=0 and entry.index<bag.size() and bag[entry.index].id==entry.id

func hit(entry: Dictionary,point: Vector2,ui: Node) -> bool:
	if not valid(entry,ui): return false
	return entry.button.get_ref().get_global_rect().intersection(ui.scroll.get_global_rect()).has_point(point)

func pick(point: Vector2,ui: Node,now: int) -> Dictionary:
	# Inspection may cover its source tile; a second tap still refers to that tile.
	if not pending.is_empty() and now-pending.time<=DOUBLE_MS and hit(pending,point,ui): return pending
	if ui.item_popup.visible and ui.popup_pinned and ui.item_popup.get_global_rect().has_point(point): return {}
	for entry in bindings:
		if hit(entry,point,ui): return entry
	return {}

func begin(point: Vector2,pointer: int,ui: Node,now: int) -> bool:
	var entry:=pick(point,ui,now)
	if entry.is_empty(): pending.clear();active.clear();return false
	if pointer>=0 and not ui.popup_pinned: ui.hide_item_popup()
	active=entry.duplicate();active.merge({"origin":point,"pointer":pointer,"scroll":ui.scroll.scroll_vertical,"start":now,"dragged":false},true)
	ui.last_pointer_position=point
	return true

func drag(point: Vector2,ui: Node) -> void:
	if active.is_empty(): return
	if point.distance_to(active.origin)>DRAG_DISTANCE or abs(ui.scroll.scroll_vertical-active.scroll)>2:
		active.dragged=true;pending.clear()

func scrolled(_value: float) -> void:
	pending.clear()
	if not active.is_empty(): active.dragged=true

func finish(point: Vector2,pointer: int,ui: Node,now: int,canceled:=false) -> void:
	if active.is_empty() or active.pointer!=pointer: return
	drag(point,ui)
	var entry:=active.duplicate();active.clear()
	if canceled or entry.dragged or now-entry.start>500 or not hit(entry,point,ui): pending.clear();return
	var twice: bool=not pending.is_empty() and now-pending.time<=DOUBLE_MS and pending.button.get_ref()==entry.button.get_ref() and pending.revision==entry.revision and point.distance_to(pending.point)<=DRAG_DISTANCE
	pending.clear();ui.last_pointer_position=point
	if twice:
		ui.quick_equip(entry.id,entry.index,entry.revision)
	else:
		pending=entry;pending.time=now;pending.point=point
		ui.inspect_item(entry.id,entry.index,"inventory")

func consume(event: InputEvent,ui: Node) -> bool:
	var now:=Time.get_ticks_msec()
	if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION:
		# Godot can dispatch this copy BEFORE the corresponding ScreenTouch.
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and ui.game.menu_open and ui.page_id=="equipment" and ui.bag_mode=="inventory":
			if not pick(event.position,ui,now).is_empty():
				ignore_emulated_until=now+700
				pass_emulated=pending.is_empty() or now-pending.time>DOUBLE_MS or not ui.item_popup.get_global_rect().has_point(event.position)
			else: ignore_emulated_until=0
		return now<ignore_emulated_until and not pass_emulated
	if not ui.game.menu_open or ui.page_id!="equipment" or ui.bag_mode!="inventory": return false
	if event is InputEventKey: reset();ignore_emulated_until=0;return false
	if event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index]=true
			if fingers.size()>1: pending.clear();active.clear();return false
			pass_emulated=pending.is_empty() or now-pending.time>DOUBLE_MS or not ui.item_popup.get_global_rect().has_point(event.position)
			if begin(event.position,event.index,ui,now): ignore_emulated_until=now+700
			else: ignore_emulated_until=0
		else:
			if not active.is_empty() and active.pointer==event.index: ignore_emulated_until=now+700
			finish(event.position,event.index,ui,now,event.canceled);fingers.erase(event.index)
		# Button callbacks ignore owned touch copies; native touch events propagate
		# through the item to ScrollContainer, including release after a drag.
		return now<ignore_emulated_until and not pass_emulated
	if event is InputEventScreenDrag:
		if not active.is_empty() and active.pointer==event.index: drag(event.position,ui)
		return now<ignore_emulated_until and not pass_emulated
	if event is InputEventMouseMotion:
		if not active.is_empty() and active.pointer==-1: drag(event.position,ui)
		return false
	if event is InputEventMouseButton:
		if event.button_index!=MOUSE_BUTTON_LEFT: pending.clear();active.clear();return false
		if event.pressed: return begin(event.position,-1,ui,now)
		var owned: bool=not active.is_empty() and active.pointer==-1
		finish(event.position,-1,ui,now)
		return owned
	return false
