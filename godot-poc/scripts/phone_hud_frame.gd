extends PanelContainer
## Small code-drawn bronze details; preserves the compact RC3 card footprint.
var game: Node
func _draw() -> void:
	if game.presentation.profile!="Phone": return
	var gold:=Color("b69b62")
	for p in [Vector2(3,3),Vector2(size.x-3,3),Vector2(3,size.y-3),size-Vector2(3,3)]:
		var inward: Vector2=(size/2-p).sign()
		draw_line(p,p+Vector2(inward.x*9,0),gold,1)
		draw_line(p,p+Vector2(0,inward.y*9),gold,1)
		var c: Vector2=p+inward*3
		draw_colored_polygon(PackedVector2Array([c+Vector2(0,-2),c+Vector2(2,0),c+Vector2(0,2),c+Vector2(-2,0)]),gold)
	var c:=Vector2(19,25)
	if game.selected=="knight":
		var shield:=PackedVector2Array([c+Vector2(-9,-12),c+Vector2(9,-12),c+Vector2(8,3),c+Vector2(0,12),c+Vector2(-8,3),c+Vector2(-9,-12)])
		draw_colored_polygon(shield,Color("253f66"));draw_polyline(shield,gold,1.5)
		draw_line(c+Vector2(0,-7),c+Vector2(0,5),gold,2);draw_line(c+Vector2(-4,-3),c+Vector2(4,-3),gold,2)
	elif game.selected=="mage":
		draw_polyline(PackedVector2Array([c+Vector2(0,-12),c+Vector2(9,0),c+Vector2(0,12),c+Vector2(-9,0),c+Vector2(0,-12)]),gold,1.5);draw_circle(c,3,Color("80bdd3"))
	else:
		draw_line(c+Vector2(-7,9),c+Vector2(7,-10),gold,3);draw_line(c+Vector2(7,9),c+Vector2(-7,-10),gold,3)
