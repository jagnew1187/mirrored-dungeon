extends CanvasLayer
var encounter: Node
var root:=Control.new()
var panel:=PanelContainer.new()
var box:=VBoxContainer.new()
var status:=Label.new()
var message:=Label.new()
var grid:=GridContainer.new()
var buttons: Dictionary={}
var skills_open:=false
var touches: Dictionary={}
var was_active:=false
var last_layout:=Vector2.ZERO
const Palette=preload("res://scripts/ui_theme.gd")
func _ready() -> void:
 add_child(root);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(panel);panel.add_theme_stylebox_override("panel",Palette.panel(Color("101820ef"),8,Color("ab925b")));panel.add_child(box)
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",14);status.add_theme_color_override("font_color",Color("ecd397"));box.add_child(status)
 message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message.add_theme_font_size_override("font_size",12);box.add_child(message);box.add_child(grid)
 for id in ["Move","Confirm","Cancel","Attack","Skills","Guard","Tonic","Clear","End Turn","Pause","Skill 1","Skill 2","Resume","Withdraw","Floor"]:
  var b:=Button.new();b.text=id;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size=Vector2(0,46);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",14);b.add_theme_stylebox_override("normal",Palette.panel(Color("20282c"),4,Color("756344")));b.pressed.connect(func():command(id));grid.add_child(b);buttons[id]=b
 root.hide()
func command(id: String) -> void:
 match id:
  "Floor": encounter.game.cycle_floor()
  "Move": skills_open=false;encounter.choose_move()
  "Confirm": encounter.confirm_move()
  "Cancel": encounter.preview.clear();encounter.reachable_cells.clear();encounter.mode="target";encounter.feedback="Preview cancelled. No movement spent."
  "Attack": encounter.attack()
  "Skills": skills_open=not skills_open
  "Guard": encounter.guard_action()
  "Tonic": encounter.tonic()
  "Clear": encounter.clear_selection()
  "End Turn": encounter.end_turn()
  "Pause": encounter.pause()
  "Resume": encounter.resume()
  "Withdraw": encounter.withdraw()
  "Skill 1": encounter.skill(0)
  "Skill 2": encounter.skill(1)
 refresh()
func refresh() -> void:
 var game: Node=encounter.game
 root.visible=encounter.active
 if not encounter.active:
  if was_active: game.overlay.request_relayout();was_active=false;touches.clear()
  return
 was_active=true
 # Keep the original health/minimap; suppress only real-time controls while tactical.
 for b in [game.overlay.attack_button,game.overlay.interact_button,game.overlay.menu_button,game.overlay.character_button,game.overlay.controls,game.overlay.target_label,game.overlay.objective_label,game.overlay.toast]+game.overlay.ability_buttons: b.hide()
 var safe: Rect2=game.presentation.safe_rect(game.get_viewport().get_visible_rect().size)
 var compact: bool=safe.size.x<650
 root.position=safe.position;root.size=safe.size;grid.columns=3 if compact else (10 if safe.size.y<500 else 5)
 status.text="TC-02 · %s · Round %d · Move %.0f · Action %s\nMirror Warden %d / %d · %s"%["PAUSED" if encounter.paused else ("YOUR TURN" if encounter.phase.begins_with("player") else "WARDEN"),encounter.round_number,encounter.movement,"ready" if encounter.action_available else "spent",maxi(0,ceili(encounter.enemy.actor.health)),ceili(encounter.enemy.actor.max_health),encounter.warden_state.to_upper()]
 message.text=encounter.feedback
 var usable: bool=encounter.available()
 for id in buttons:
  var b: Button=buttons[id];var font_size:=12 if id.begins_with("Skill ") or (not compact and safe.size.y<500) else 14
  if b.get_theme_font_size("font_size")!=font_size: b.add_theme_font_size_override("font_size",font_size)
  b.visible=not encounter.paused and not id in ["Resume","Withdraw","Floor"]
  if skills_open and id in ["Confirm","Cancel"]: b.visible=false
  b.disabled=not usable
  if id in ["Attack","Guard","Tonic","Skill 1","Skill 2"]: b.disabled=b.disabled or not encounter.action_available
  if id=="Confirm": b.disabled=b.disabled or encounter.preview.is_empty()
  if id=="Pause": b.disabled=false
  if id in ["Skill 1","Skill 2"]:
   var index:=0 if id=="Skill 1" else 1;b.visible=skills_open and not encounter.paused
   b.text=game.abilities.DATA[game.selected][index].name+(" · %dT"%encounter.turn_cooldowns[index] if encounter.turn_cooldowns[index]>0 else "")
   b.disabled=b.disabled or encounter.turn_cooldowns[index]>0
  if id in ["Resume","Withdraw","Floor"]: b.visible=encounter.paused;b.disabled=false
 panel.size=Vector2(maxf(300,safe.size.x-24),0);panel.size.y=panel.get_combined_minimum_size().y
 panel.position=Vector2(12,maxf(96,safe.size.y-panel.size.y-8))
 # Label wrapping must use the available width, not a previous viewport width.
 status.custom_minimum_size.x=0;message.custom_minimum_size.x=0
func hit(point: Vector2) -> String:
 for id in buttons:
  var b: Button=buttons[id]
  if b.is_visible_in_tree() and b.get_global_rect().has_point(point): return id
 return ""
func select(point: Vector2) -> void:
 var id:=hit(point)
 if not id.is_empty():
  if not buttons[id].disabled: command(id)
  return
 if panel.get_global_rect().has_point(point): return
 var ui: Node=encounter.game.overlay
 if ui.hud.get_global_rect().has_point(point) or ui.minimap.get_global_rect().has_point(point): return
 encounter.select_world(encounter.game.get_viewport().get_canvas_transform().affine_inverse()*point)
func _input(event: InputEvent) -> void:
 if not encounter.active: return
 # This CanvasLayer is later in the tree than the real-time interface. Own every
 # tactical input before it can reach joystick, auto-attack, menus or world travel.
 if event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION: get_viewport().set_input_as_handled();return
 if event is InputEventScreenTouch:
  if event.pressed: touches[event.index]={"origin":event.position,"dragged":false}
  elif touches.has(event.index):
   var entry: Dictionary=touches[event.index];touches.erase(event.index)
   if not event.canceled and not entry.dragged and entry.origin.distance_to(event.position)<14: select(event.position)
 elif event is InputEventScreenDrag:
  if touches.has(event.index) and touches[event.index].origin.distance_to(event.position)>14: touches[event.index].dragged=true
 elif event is InputEventMouseButton and event.pressed:
  if event.button_index==MOUSE_BUTTON_LEFT: select(event.position)
  elif event.button_index==MOUSE_BUTTON_RIGHT: command("Cancel")
 elif event is InputEventKey and event.pressed and not event.echo:
  match event.physical_keycode:
   KEY_M: command("Move")
   KEY_ENTER: command("Confirm" if encounter.mode=="move" else "End Turn")
   KEY_SPACE: command("Attack")
   KEY_G: command("Guard")
   KEY_Q: command("Skill 1")
   KEY_R: command("Skill 2")
   KEY_ESCAPE: command("Resume" if encounter.paused else "Pause")
   KEY_C: command("Clear")
 get_viewport().set_input_as_handled()
func _process(_delta: float) -> void: refresh()

