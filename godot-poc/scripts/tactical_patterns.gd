extends RefCounted
## Reusable position-aware selection and committed geometry. No timers or damage here.
static func choose(distance: float, turn: int, last_quick: int, majors: int, data: Dictionary) -> String:
 if majors==0: return "heavy"
 if majors%int(data.selection.denial_every)==0: return "denial"
 if distance<=data.selection.quick_pressure_distance and turn-last_quick>=data.quick.cooldown_actions: return "quick"
 if distance>data.selection.retreat_distance: return "tracking"
 return "heavy"
static func polygon(origin: Vector2, direction: Vector2, data: Dictionary) -> PackedVector2Array:
 var side:=direction.orthogonal()*float(data.width)/2
 var end:=origin+direction*float(data.range)
 return PackedVector2Array([origin-direction*15-side*.3,origin-direction*15+side*.3,end+side,end-side])
