class_name TravelArtwork
extends Control

var country_id := "FR"
var show_traveler := true
const BACKPACKER := preload("res://assets/backpacker.png")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(720, 360))
	var texture := GameCatalog.backdrop(country_id)
	var width := float(texture.get_width())
	# Crop the portrait painting around its landmarks for wide travel cards.
	draw_texture_rect_region(texture, Rect2(0, 0, 720, 360), Rect2(0, texture.get_height() * 0.10, width, width / 2))
	if show_traveler:
		draw_texture_rect(BACKPACKER, Rect2(15, 50, 185, 310), false)
	draw_set_transform(Vector2.ZERO)
