extends "res://scripts/main.gd"
var floor_variant:=0
var tactical=preload("res://scripts/tactical_encounter.gd").new()
var tc_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/tactical_encounters.json"))
func _ready() -> void:
 tactical.game=self;abilities=preload("res://scripts/tactical_abilities.gd").new()
 campaign.directory="user://tc01-campaigns"
 super._ready();add_child(tactical);get_window().title="Mirrored Dungeon · TC-02 (RC9 baseline)"
func enter_area(id: String, restored_health: float=-1.0, entrance: String="", lateral: float=0.0) -> void:
 if tactical.active: tactical.withdraw(false)
 super.enter_area(id,restored_health,entrance,lateral)
 var config: Dictionary=tc_data.mirror_warden
 if id==config.area and not campaign.data.claims.has(config.id):
  var pos:=safe_loot_position(Vector2(config.position[0],config.position[1]));spawn_enemy(pos,config.id,false,"enforcer")
  var e: Dictionary=enemies.back();e.combat_mode=config.combat_mode;e.role="mirror_warden";e.armor_role="enforcer";e.encounter=config.id;e.actor.health=config.hp;e.actor.max_health=config.hp;e.actor.set_meta("tactical_name",config.name)
func update_enemies(delta: float) -> void:
 var ordinary: Array[Dictionary]=[];var special: Array[Dictionary]=[]
 for e in enemies:
  if e.get("combat_mode","realtime")=="tactical": special.append(e);e.actor.moving=false;e.actor.velocity=Vector2.ZERO
  else: ordinary.append(e)
 enemies=ordinary;super.update_enemies(delta);enemies.append_array(special)
func try_tactical(reach: float) -> bool:
 if menu_open or fallen or tactical.active: return false
 var chosen: Node2D=target if valid_combat_target(target) else null
 if chosen==null:
  var distance:=reach
  for e in enemies:
   var d: float=hero.position.distance_to(e.actor.position)
   if valid_combat_target(e.actor) and d<=distance and area.line_clear(hero.position,e.actor.position): chosen=e.actor;distance=d
 for e in enemies:
  if e.actor==chosen and e.get("combat_mode","realtime")=="tactical":
   tactical.begin(e);return true # Consume even a rejected out-of-arena request.
 return false
func request_attack() -> void:
 if tactical.active: tactical.attack();return
 if try_tactical(stats.range): return
 super.request_attack()
func engage_combat(reach: float) -> bool:
 if tactical.active: return true
 return super.engage_combat(reach)
func _physics_process(delta: float) -> void:
 if tactical.active: tactical.tick(delta);return
 super._physics_process(delta)
func world_click(pos: Vector2) -> void:
 if tactical.active: tactical.select_world(pos);return
 super.world_click(pos)
func persist() -> void:
 if tactical.active:
  campaign.error="Tactical saving is disabled. Withdraw to restore the pre-encounter checkpoint.";return
 super.persist()
func continue_campaign(id: String) -> void:
 if tactical.active: tactical.withdraw(false)
 super.continue_campaign(id)
func release_inputs() -> void:
 super.release_inputs()
 if tactical.active: tactical.pause()
func damage_enemy(e: Dictionary,amount: float,source:=Vector2.INF) -> void:
 if tactical.active and e!=tactical.enemy: return
 if e.get("combat_mode","realtime")!="tactical": super.damage_enemy(e,amount,source);return
 if not tactical.active or not tactical.resolving: return
 super.damage_enemy(e,amount*(tc_data.mirror_warden.recovery_multiplier if tactical.warden_state=="recovery" else 1.0),source)
func enemy_defeated(e: Dictionary) -> void:
 if tactical.active and e==tactical.enemy: tactical.victory_pending=true
 else: super.enemy_defeated(e)
func damage_hero(amount: float) -> void:
 if tactical.active and not tactical.enemy_release: return
 var old: float=abilities.guard
 if tactical.active and tactical.guarding: abilities.guard=1.0
 super.damage_hero(amount)
 abilities.guard=old
 if tactical.active: tactical.guarding=false
func prototype_visit() -> void:
 # A deliberate local testing shortcut; creates a separate new campaign only.
 if started: return
 select_class("knight")
 started=true;overlay.close();enter_area("road");hero.position=Vector2(620,1530);hero.reset_physics_interpolation();camera.position=hero.position;camera.reset_physics_interpolation()

func cycle_floor() -> void:
 floor_variant=(floor_variant+1)%4
 area.ground_material.set_shader_parameter("floor_variant",floor_variant)
 tactical.hud.buttons["Floor"].text="Floor: "+["Original","A +25%","B +50%","C Irregular"][floor_variant]
