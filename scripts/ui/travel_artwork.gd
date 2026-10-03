class_name TravelArtwork
extends Control

var country_id := "FR"
var show_traveler := true
var revealed := true
var zoom := 1.0
const BACKPACKER := preload("res://assets/backpacker.png")

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
	# Crop the portrait painting around its landmarks for wide travel cards.
	draw_texture_rect_region(texture, Rect2(0, 0, 720, 360), Rect2((width - width / zoom) / 2, texture.get_height() * 0.10, width / zoom, width / zoom / 2))
	if show_traveler:
		draw_texture_rect(BACKPACKER, Rect2(15, 50, 185, 310), false)
	draw_set_transform(Vector2.ZERO)
