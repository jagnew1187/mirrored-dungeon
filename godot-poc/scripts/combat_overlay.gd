extends Node2D
var game: Node
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	if is_instance_valid(game.hero): game.draw_feedback(self)
