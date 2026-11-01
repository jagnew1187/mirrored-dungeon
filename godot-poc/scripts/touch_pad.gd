extends Node2D

var game: Node

func _process(_delta: float) -> void:
	visible=not game.menu_open and (game.show_touch or DisplayServer.is_touchscreen_available() or game.touch_id>=0)
	queue_redraw()

func _draw() -> void:
	var origin: Vector2=game.touch_origin if game.touch_id>=0 else Vector2(120,570)
	draw_circle(origin,65,Color(0.05,0.12,0.10,0.5))
	draw_arc(origin,65,0,TAU,40,Color("c5b380"),2)
	draw_circle(origin+game.joystick*50,23,Color(0.7,0.65,0.45,0.6))
