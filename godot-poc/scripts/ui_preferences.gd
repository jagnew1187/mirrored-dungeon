extends RefCounted
var path: String="user://interface.cfg"
var master:=.8
var ui_scale:=1.0
var display:=0
var touch:=false
var profile:=0
var error: String=""
func read() -> void:
	var config:=ConfigFile.new()
	if config.load(path)!=OK: return
	master=clampf(float(config.get_value("ui","master",.8)),0,1)
	ui_scale=clampf(float(config.get_value("ui","scale",1.0)),.85,1.15)
	display=clampi(int(config.get_value("ui","display",0)),0,2)
	touch=bool(config.get_value("ui","touch",false))
	profile=clampi(int(config.get_value("ui","profile",0)),0,3)
func save() -> bool:
	var config:=ConfigFile.new()
	for key in {"master":master,"scale":ui_scale,"display":display,"touch":touch,"profile":profile}:
		config.set_value("ui",key,{"master":master,"scale":ui_scale,"display":display,"touch":touch,"profile":profile}[key])
	var result:=config.save(path);error="" if result==OK else "Interface settings could not be saved."
	return result==OK
func apply_audio_display() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.0001,master)))
	AudioServer.set_bus_mute(0,master==0)
	if DisplayServer.get_name()=="headless": return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,display==1)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if display==2 else DisplayServer.WINDOW_MODE_WINDOWED)
