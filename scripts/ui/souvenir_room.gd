class_name SouvenirRoom
extends Control

var destinations: Array[String] = []

func _ready() -> void:
	custom_minimum_size.y = 460
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(layout)
	for id in destinations.slice(0, 6):
		var card := SouvenirCard.new()
		card.destination_id = id
		card.compact = true
		add_child(card)
	layout.call_deferred()

func layout() -> void:
	for index in get_child_count():
		var card: Control = get_child(index)
		card.position = Vector2(12 + index % 2 * size.x / 2, 14 + index / 2 * 148)
		card.size = Vector2(size.x / 2 - 24, 132)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("e6d8bf"))
	for x in range(0, int(size.x), 22): draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.08), 1)
	# Warm ceiling light and brass display fittings.
	draw_rect(Rect2(0, 0, size.x, 5), Color("8f6945"))
	for x in [size.x * 0.25, size.x * 0.75]:
		draw_circle(Vector2(x, 10), 38, Color(1, 0.86, 0.56, 0.12))
		draw_circle(Vector2(x, 7), 4, Color("ffdf8a"))
	for row in 3:
		draw_rect(Rect2(5, 145 + row * 148, size.x - 10, 9), Color("785743"))
		draw_rect(Rect2(16, 154 + row * 148, 12, 9), Color("543e33"))
		draw_rect(Rect2(size.x - 28, 154 + row * 148, 12, 9), Color("543e33"))
