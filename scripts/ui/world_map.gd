class_name PassportWorldMap
extends Control

static var GEOGRAPHY: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/geography/world-map.json"))
var discoveries: Array[String] = []
var pins: Dictionary = {}
var route: Array[String] = []
var current_country := ""
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
	for line in route_segments():
		draw_line(line[0], line[1], Color("f8e4aa"), 2, true)
	pins.clear()
	var visible_ids := discoveries.duplicate()
	for id in route:
		if id not in visible_ids: visible_ids.append(id)
	for id in visible_ids:
		if id not in GameCatalog.FREE_DESTINATIONS or not GEOGRAPHY.pins.has(id): continue
		var point := pin_point(id)
		pins[id] = point + Vector2(0, 11)
		var color := Color("ffcc58") if id in discoveries else Color("8199ac")
		if id == current_country: color = Color("80efac")
		draw_line(point + Vector2(0, 11), point + Vector2(0, 2), color, 2)
		draw_circle(point, 5, color)
		draw_circle(point, 2, Color("163d57"))
		if id == current_country or id == selected_country:
			draw_arc(point, 9, 0, TAU, 32, Color("fff4d6"), 2, true)
	draw_string(ThemeDB.fallback_font, Vector2(16, size.y - 16), "Gold: cleared · Lines: travel route" if selected_country.is_empty() else GameCatalog.country_name(selected_country), HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 14, Color("fff4d6"))

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

func pin_point(id: String) -> Vector2:
	var coordinate: Array = GEOGRAPHY.pins[id]
	return project([coordinate[1], coordinate[0]]) - Vector2(0, 11)

func route_segments() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var eligible: Array[String] = []
	for id in route:
		if GEOGRAPHY.pins.has(id) and id in GameCatalog.FREE_DESTINATIONS: eligible.append(id)
	var width := size.x - 24
	for index in range(1, eligible.size()):
		if eligible[index] == eligible[index - 1]: continue
		var a := pin_point(eligible[index - 1])
		var b := pin_point(eligible[index])
		if absf(b.x - a.x) <= width / 2:
			result.append(PackedVector2Array([a, b]))
		else:
			# Split at the date line rather than drawing across the whole map.
			var direction := -1.0 if b.x > a.x else 1.0
			b.x += width * direction
			var edge := 12.0 if direction < 0 else size.x - 12
			var crossing := a.lerp(b, (edge - a.x) / (b.x - a.x))
			result.append(PackedVector2Array([a, crossing]))
			result.append(PackedVector2Array([crossing - Vector2(width * direction, 0), b - Vector2(width * direction, 0)]))
	return result
