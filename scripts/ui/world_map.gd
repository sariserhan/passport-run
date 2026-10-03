class_name PassportWorldMap
extends Control

static var GEOGRAPHY: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/geography/world-map.json"))
var discoveries: Array[String] = []
var pins: Dictionary = {}
var selected_country := ""

func _ready() -> void:
	custom_minimum_size.y = 230
	resized.connect(func():
		custom_minimum_size.y = maxf(230, (size.x - 24) / 2 + 48)
		queue_redraw()
	)
	mouse_filter = Control.MOUSE_FILTER_STOP

func project(point: Array) -> Vector2:
	var rect := Rect2(12, 12, size.x - 24, (size.x - 24) / 2)
	return rect.position + Vector2((float(point[0]) + 180) / 360, (90 - float(point[1])) / 180) * rect.size

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("163d57"))
	for polygon in GEOGRAPHY.polygons:
		var points := PackedVector2Array()
		for point in polygon:
			points.append(project(point))
		if Geometry2D.triangulate_polygon(points).is_empty():
			continue
		draw_colored_polygon(points, Color("91bfa5"))
	pins.clear()
	for id in discoveries:
		if id not in GameCatalog.FREE_DESTINATIONS or not GEOGRAPHY.pins.has(id):
			continue
		var coordinate: Array = GEOGRAPHY.pins[id]
		var point := project([coordinate[1], coordinate[0]])
		pins[id] = point
		draw_line(point, point - Vector2(0, 9), Color("ffe8a4"), 2)
		draw_circle(point - Vector2(0, 11), 5, Color("ffcc58"))
		draw_circle(point - Vector2(0, 11), 2, Color("68451f"))
	draw_string(ThemeDB.fallback_font, Vector2(16, size.y - 16), "● Cleared countries · Tap a pin" if selected_country.is_empty() else GameCatalog.country_name(selected_country), HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 14, Color("fff4d6"))

func _gui_input(event: InputEvent) -> void:
	var point: Vector2
	if event is InputEventMouseButton and event.pressed:
		point = event.position
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
	else:
		return
	var closest := ""
	var distance := 22.0
	for id in pins:
		var current := point.distance_to(pins[id] - Vector2(0, 11))
		if current < distance:
			distance = current
			closest = id
	if not closest.is_empty():
		selected_country = closest
		queue_redraw()
