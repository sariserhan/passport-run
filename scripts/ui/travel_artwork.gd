class_name TravelArtwork
extends Control

var country_id := "FR"
var show_traveler := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(720, 360))
	var color := Color(GameCatalog.COUNTRIES.get(country_id, {"color": "6398bd"}).color)
	draw_rect(Rect2(0, 0, 720, 360), color.lightened(0.25))
	draw_circle(Vector2(590, 65), 34, Color("fff6df"))
	draw_rect(Rect2(0, 255, 720, 105), Color("28546b"))
	match country_id:
		"EG":
			draw_rect(Rect2(0, 235, 720, 125), Color("dcb475"))
			for i in 3:
				var x := 340.0 + i * 130
				draw_colored_polygon(PackedVector2Array([Vector2(x - 95, 275), Vector2(x, 105 + i * 30), Vector2(x + 95, 275)]), Color("fff6df"))
				draw_line(Vector2(x, 105 + i * 30), Vector2(x + 25, 275), color, 4)
		"FR":
			draw_polyline(PackedVector2Array([Vector2(350, 280), Vector2(400, 200), Vector2(455, 50), Vector2(510, 200), Vector2(560, 280)]), Color("153e57"), 18, true)
			for y in [160, 210, 250]:
				draw_line(Vector2(375, y), Vector2(535, y), Color("153e57"), 12)
			draw_line(Vector2(455, 50), Vector2(455, 20), Color("153e57"), 6)
		"TR":
			draw_rect(Rect2(350, 185, 220, 90), Color("fff6df"))
			draw_circle(Vector2(460, 185), 80, Color("fff6df"))
			draw_rect(Rect2(350, 185, 220, 90), Color("fff6df"))
			for x in [315, 605]:
				draw_rect(Rect2(x, 100, 15, 175), Color("fff6df"))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 100), Vector2(x + 7, 60), Vector2(x + 19, 100)]), Color("153e57"))
		"JP":
			for i in 3:
				var y := 220.0 - i * 60
				var width := 200.0 - i * 35
				draw_rect(Rect2(460 - width / 2, y, width, 48), Color("fff6df"))
				draw_colored_polygon(PackedVector2Array([Vector2(450 - width, y), Vector2(460, y - 48), Vector2(470 + width, y)]), Color("153e57"))
			for x in [300, 645]:
				draw_line(Vector2(x, 210), Vector2(x, 280), Color("624335"), 10)
				draw_circle(Vector2(x, 190), 45, Color("f4c1d3"))
		"US":
			for i in 6:
				var height := 95.0 + (i % 3) * 55
				var x := 300.0 + i * 58
				draw_rect(Rect2(x, 275 - height, 48, height), Color("153e57"))
				for y in range(285 - int(height), 265, 25):
					draw_rect(Rect2(x + 10, y, 26, 8), Color("fff6df"))
	if show_traveler:
		# Original illustrated backpacker. No downloaded or branded artwork.
		draw_rect(Rect2(140, 170, 85, 110), Color("d59433"))
		draw_line(Vector2(110, 255), Vector2(90, 325), Color("153e57"), 24)
		draw_line(Vector2(145, 255), Vector2(175, 325), Color("153e57"), 24)
		draw_line(Vector2(90, 193), Vector2(57, 251), Color("dca578"), 19)
		draw_line(Vector2(164, 193), Vector2(195, 235), Color("dca578"), 19)
		draw_rect(Rect2(85, 170, 85, 90), Color("fff6df"))
		draw_circle(Vector2(128, 130), 40, Color("dca578"))
		draw_circle(Vector2(128, 103), 40, Color("624335"))
		draw_rect(Rect2(87, 116, 82, 17), Color("624335"))
		draw_circle(Vector2(111, 145), 4, Color("153e57"))
		draw_circle(Vector2(145, 145), 4, Color("153e57"))
	draw_set_transform(Vector2.ZERO)
