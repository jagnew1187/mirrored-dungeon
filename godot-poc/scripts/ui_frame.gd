extends PanelContainer
## Original low-contrast stone flecks and iron corner fittings, drawn behind content.
## Retained canvas commands: redraw only when the frame resizes.
func _ready() -> void: resized.connect(queue_redraw)
func _draw() -> void:
	for y in range(12,int(size.y)-12,18):
		for x in range(12,int(size.x)-12,22):
			var code:=posmod(x*13+y*7,19)
			if code<3: draw_rect(Rect2(x,y,4+code*2,2),Color(.62,.64,.66,.025))
	for corner in [Vector2(7,7),Vector2(size.x-13,7),Vector2(7,size.y-13),size-Vector2(13,13)]:
		draw_rect(Rect2(corner,Vector2(6,6)),Color("72654b"))
		draw_rect(Rect2(corner+Vector2.ONE,Vector2(2,2)),Color("b6a071"))
	draw_line(Vector2(18,5),Vector2(size.x-18,5),Color("414039"),1)
	draw_line(Vector2(5,18),Vector2(5,size.y-18),Color("414039"),1)
