extends RefCounted
## Presentation depends on viewport; input mode depends on real events.
const PROFILES := ["Auto", "Phone", "Tablet", "Desktop"]
const ZOOM := {"Phone": 1.22, "Tablet": 1.15, "Desktop": 1.0}
var override_profile := 0
var profile := "Desktop"
var touch_mode := false
var mobile_web := OS.has_feature("web_ios") or OS.has_feature("web_android")
func configure(extent: Vector2, touch_capable: bool) -> void:
	if override_profile > 0: profile = PROFILES[override_profile]
	elif minf(extent.x, extent.y) <= 540: profile = "Phone"
	elif mobile_web or touch_capable: profile = "Tablet"
	else: profile = "Desktop"
func observe(event: InputEvent) -> bool:
	var before := touch_mode
	if event is InputEventScreenTouch or event is InputEventScreenDrag: touch_mode = true
	elif event is InputEventKey or ((event is InputEventMouseButton or event is InputEventMouseMotion) and event.device != InputEvent.DEVICE_ID_EMULATION): touch_mode = false
	return before != touch_mode
func action_prompt(action: String, shortcut: String = "") -> String:
	return action if touch_mode or shortcut.is_empty() else action+" ("+shortcut+")"
func interaction_action(point: Dictionary) -> String:
	match str(point.get("kind","")):
		"exit": return "Travel"
		"loot": return "Pick Up"
		"stash": return "Open Stash"
		"management": return "Shop"
		"quest": return "Inspect"
		"mara", "boy", "anja", "oren", "ves": return "Talk"
	return "Inspect"
func zoom_for(extent: Vector2, bounds: Vector2) -> float:
	return maxf(ZOOM[profile], maxf(extent.x / bounds.x, extent.y / bounds.y))

func safe_rect(extent: Vector2) -> Rect2:
	return menu_rect(extent)

func inset_rect(extent: Vector2) -> Rect2:
	# Browser-managed safe viewport is the default. Read CSS env insets when the host opts into viewport-fit=cover.
	var inset:=Vector4.ZERO
	if OS.has_feature("web"):
		var value=JavaScriptBridge.eval("""
			(function(){
				var probe=document.createElement('div');
				probe.style.cssText='position:fixed;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';
				document.body.appendChild(probe);
				var css=getComputedStyle(probe);
				var result=JSON.stringify([parseFloat(css.paddingLeft)||0,parseFloat(css.paddingTop)||0,parseFloat(css.paddingRight)||0,parseFloat(css.paddingBottom)||0,window.innerWidth,window.innerHeight]);
				probe.remove();return result;
			})()
		""")
		if value is String:
			var values=JSON.parse_string(value)
			if values is Array and values.size()==6:
				var ratio:=extent/Vector2(maxf(1,values[4]),maxf(1,values[5]))
				inset=Vector4(values[0]*ratio.x,values[1]*ratio.y,values[2]*ratio.x,values[3]*ratio.y)
	return Rect2(Vector2(inset.x,inset.y),extent-Vector2(inset.x+inset.z,inset.y+inset.w))

func sync_web_viewport(window: Window) -> void:
	if not OS.has_feature("web"): return
	# The Web canvas backing store includes DPR. Gameplay/UI use CSS pixels;
	# Godot's canvas-items scaling maps rendering and input together.
	var value=JavaScriptBridge.eval("JSON.stringify([document.getElementById('canvas').clientWidth,document.getElementById('canvas').clientHeight])")
	if not value is String: return
	var dimensions=JSON.parse_string(value)
	if not dimensions is Array or dimensions.size()!=2: return
	var logical:=Vector2i(maxi(1,int(dimensions[0])),maxi(1,int(dimensions[1])))
	if window.content_scale_mode!=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS:
		window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if window.content_scale_size!=logical: window.content_scale_size=logical

func menu_rect(extent: Vector2) -> Rect2:
	var available:=inset_rect(extent)
	if not OS.has_feature("web"): return available
	var raw=JavaScriptBridge.eval("JSON.stringify(window.visualViewport ? [visualViewport.offsetLeft,visualViewport.offsetTop,visualViewport.width,visualViewport.height,innerWidth,innerHeight] : null)")
	if raw is String:
		var v=JSON.parse_string(raw)
		if v is Array and v.size()==6:
			var ratio:=extent/Vector2(maxf(1,v[4]),maxf(1,v[5]))
			available=available.intersection(Rect2(Vector2(v[0],v[1])*ratio,Vector2(v[2],v[3])*ratio))
	return available
