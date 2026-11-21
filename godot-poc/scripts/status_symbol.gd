extends Button
## Small code-drawn symbols inside larger transparent hit areas.
var effect_id:="guard"
func _draw() -> void:
	var c:=size/2
	var color:=Color("a9c5ad") if effect_id=="guard" else Color("aacbd3")
	draw_style_box(preload("res://scripts/ui_theme.gd").panel(Color("172127dd"),0,color),Rect2(c-Vector2(14,14),Vector2(28,28)))
	if effect_id=="guard":
		draw_polyline(PackedVector2Array([c+Vector2(-8,-8),c+Vector2(8,-8),c+Vector2(6,3),c+Vector2(0,10),c+Vector2(-6,3),c+Vector2(-8,-8)]),color,2)
	else:
		for x in [-5,3]: draw_polyline(PackedVector2Array([c+Vector2(x-3,-7),c+Vector2(x+3,0),c+Vector2(x-3,7)]),color,2)
