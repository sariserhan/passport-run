class_name PassportPage
extends Control

var destination_id := "FR"
var page_number := 1
var cover_id := "classic"

func _ready() -> void:
	custom_minimum_size.y = 410
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var paper := Rect2(8, 5, size.x - 16, size.y - 10)
	var cover := Color(TravelGoals.TRIPS[cover_id].color) if cover_id in TravelGoals.TRIPS else Color("142e45")
	draw_rect(Rect2(Vector2.ZERO, size), cover)
	draw_rect(paper, Color("fff3d5"))
	draw_rect(paper.grow(-5), Color("c8b897"), false, 1)
	draw_line(Vector2(22, 14), Vector2(22, size.y - 14), Color("baaa8b"), 2)
	for y in range(25, int(size.y - 15), 18):
		draw_line(Vector2(17, y), Vector2(24, y), Color("877555"), 1)
	var width := size.x - 66
	draw_string(font, Vector2(36, 38), "PASSPORT", HORIZONTAL_ALIGNMENT_LEFT, width, 22, Color("233f50"))
	draw_string(font, Vector2(36, 58), "TRAVEL VISAS · %03d" % page_number, HORIZONTAL_ALIGNMENT_LEFT, width, 12, Color("7c705d"))
	var name := GameCatalog.country_name(destination_id)
	var font_size := 21
	while font_size > 12 and font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		font_size -= 1
	draw_string(font, Vector2(36, 91), name, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, Color("233f50"))
	var texture := GameCatalog.backdrop(destination_id)
	var photo := Rect2(36, 108, width, 155)
	draw_texture_rect_region(texture, photo, Rect2(0, texture.get_height() * 0.1, texture.get_width(), texture.get_width() * photo.size.y / photo.size.x))
	draw_rect(photo, Color("b7a887"), false, 2)
	var center := Vector2(size.x * 0.58, 326)
	draw_set_transform(center, -0.13)
	var ink := Color("a24c40")
	draw_arc(Vector2.ZERO, 49, 0, TAU, 64, ink, 3, true)
	draw_arc(Vector2.ZERO, 43, 0, TAU, 64, ink, 1, true)
	draw_string(font, Vector2(-41, -4), GameCatalog.stamp_code(destination_id), HORIZONTAL_ALIGNMENT_CENTER, 82, 27, ink)
	draw_string(font, Vector2(-43, 19), "COMPLETED", HORIZONTAL_ALIGNMENT_CENTER, 86, 12, ink)
	draw_line(Vector2(-12, 26), Vector2(-4, 33), ink, 2, true)
	draw_line(Vector2(-4, 33), Vector2(15, 25), ink, 2, true)
	draw_set_transform(Vector2.ZERO)
	draw_string(font, Vector2(36, size.y - 20), "PASSPORT RUN                         %03d" % page_number, HORIZONTAL_ALIGNMENT_LEFT, width, 11, Color("7c705d"))
