class_name TravelArtwork
extends Control

var country_id := "FR"
var show_traveler := true
var revealed := true
var zoom := 1.0
var weather := "clear"
var time_of_day := "day"
static var BACKPACKER := RealisticArt.region(RealisticArt.EXPLORER, 0, Vector2i(4, 4))

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(720, 360))
	if not revealed:
		draw_rect(Rect2(0, 0, 720, 360), Color("102c43"))
		draw_colored_polygon(PackedVector2Array([Vector2(0, 360), Vector2(160, 145), Vector2(285, 270), Vector2(440, 110), Vector2(720, 360)]), Color("284a62"))
		draw_circle(Vector2(560, 80), 30, Color("456b80"))
		draw_string(ThemeDB.fallback_font, Vector2(323, 220), "?", HORIZONTAL_ALIGNMENT_CENTER, 74, 90, Color("ffdf80"))
		draw_set_transform(Vector2.ZERO)
		return
	var texture := GameCatalog.backdrop(country_id)
	var width := float(texture.get_width())
	# Crop the portrait scenery around its landmarks for wide travel cards.
	draw_texture_rect_region(texture, Rect2(0, 0, 720, 360), Rect2((width - width / zoom) / 2, texture.get_height() * 0.10, width / zoom, width / zoom / 2))
	if time_of_day != "day": draw_rect(Rect2(0, 0, 720, 360), Color(0.88, 0.38, 0.13, 0.18) if time_of_day in ["sunrise", "sunset"] else Color(0.02, 0.08, 0.22, 0.3))
	for i in 25:
		var point := Vector2(fmod(i * 83.0, 720), fmod(i * 61.0, 360))
		if weather == "rain": draw_line(point, point + Vector2(-5, 18), Color(0.8, 0.9, 1, 0.5), 2)
		elif weather == "snow": draw_circle(point, 3, Color("e4f7ff"))
	if show_traveler:
		draw_texture_rect(BACKPACKER, Rect2(15, 50, 185, 310), false)
	draw_set_transform(Vector2.ZERO)
