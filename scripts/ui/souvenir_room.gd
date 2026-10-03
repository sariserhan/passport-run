class_name SouvenirRoom
extends Control

signal arrangement_changed(positions: Dictionary)
var destinations: Array[String] = []
var postcards: Array[String] = []
var decor: Dictionary = RoomDecor.DEFAULTS.duplicate()
var positions: Dictionary = {}
var dragging: Control
var drag_origin := Vector2.ZERO

func _ready() -> void:
 custom_minimum_size.y = 640
 mouse_filter = Control.MOUSE_FILTER_PASS
 resized.connect(layout)
 for id in destinations.slice(0, 6):
  var card := SouvenirCard.new()
  card.destination_id = id
  card.compact = true
  add_child(card)
 layout.call_deferred()

func bounds_for_cards() -> Rect2:
 return Rect2(12, 106, maxf(1, size.x / 2 - 12), 314)

func layout() -> void:
 var bounds := bounds_for_cards()
 for index in get_child_count():
  var card: SouvenirCard = get_child(index)
  card.size = Vector2(size.x / 2 - 24, 132)
  if card.destination_id in positions:
   var point: Array = positions[card.destination_id]
   card.position = bounds.position + Vector2(point[0], point[1]) * bounds.size
  else:
   var slot := destinations.find(card.destination_id)
   card.position = Vector2(12 + slot % 2 * size.x / 2, 110 + slot / 2 * 148)
 queue_redraw()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed: begin_drag(event.position)
  else: finish_drag()
 elif event is InputEventScreenTouch and event.index == 0:
  if event.pressed: begin_drag(event.position)
  else: finish_drag()
 elif (event is InputEventMouseMotion or (event is InputEventScreenDrag and event.index == 0)) and dragging:
  var bounds := bounds_for_cards()
  var point: Vector2 = event.position - drag_origin
  dragging.position = Vector2(clampf(point.x, bounds.position.x, bounds.end.x), clampf(point.y, bounds.position.y, bounds.end.y))
  accept_event()

func begin_drag(point: Vector2) -> void:
 for index in range(get_child_count() - 1, -1, -1):
  var child: Control = get_child(index)
  if Rect2(child.position, child.size).has_point(point):
   dragging = child
   move_child(child, get_child_count() - 1)
   drag_origin = point - child.position
   accept_event()
   break

func finish_drag() -> void:
 if not dragging: return
 var bounds := bounds_for_cards()
 var normalized := (dragging.position - bounds.position) / bounds.size
 positions[dragging.destination_id] = [clampf(normalized.x, 0, 1), clampf(normalized.y, 0, 1)]
 dragging = null
 arrangement_changed.emit(positions.duplicate(true))
 accept_event()

func _draw() -> void:
 if not decor.has("display"): decor["display"] = "none"
 var wall: Color = Color(RoomDecor.ITEMS.wallpaper[decor.wallpaper].color)
 var shelf: Color = Color(RoomDecor.ITEMS.shelves[decor.shelves].color)
 draw_rect(Rect2(Vector2.ZERO, size), wall)
 for x in range(0, int(size.x), 22): draw_line(Vector2(x, 0), Vector2(x, 554), Color(1, 1, 1, 0.08), 1)
 if decor.wallpaper == "night":
  for index in 28:
   draw_circle(Vector2(fmod(index * 47.0 + 13, size.x), 18 + fmod(index * 79.0, 530)), 2, Color("ffe2a0"))
 draw_rect(Rect2(0, 554, size.x, size.y - 554), Color("b8916e"))
 for y in range(565, int(size.y), 18): draw_line(Vector2(0, y), Vector2(size.x, y), Color("9c795c"), 1)
 draw_rect(Rect2(0, 0, size.x, 5), Color("8f6945"))
 for x in [size.x * 0.25, size.x * 0.75]:
  draw_circle(Vector2(x, 10), 38, Color(1, 0.86, 0.56, 0.12))
  draw_circle(Vector2(x, 7), 4, Color("ffdf8a"))
 for index in postcards.size():
  var frame := Rect2(12 + index * (size.x - 24) / 3, 18, (size.x - 36) / 3, 70)
  draw_rect(frame.grow(3), Color("fff2d6"))
  var texture := GameCatalog.backdrop(postcards[index])
  var crop := Vector2(texture.get_width(), texture.get_width() * frame.size.y / frame.size.x)
  draw_texture_rect_region(texture, frame, Rect2((Vector2(texture.get_size()) - crop) / 2, crop))
  draw_line(Vector2(frame.get_center().x, 6), Vector2(frame.get_center().x, 15), Color("b49155"), 2)
 if postcards.is_empty():
  draw_string(ThemeDB.fallback_font, Vector2(12, 60), "Hang your country postcards here", HORIZONTAL_ALIGNMENT_CENTER, size.x - 24, 15, wall.darkened(0.5))
 if decor.display != "none":
  var base := Vector2(size.x * 0.5, 600)
  draw_rect(Rect2(base.x - 85, 560, 170, 60), Color("263e60"))
  if decor.display == "space":
   for i in 4:
    draw_circle(base + Vector2(-60 + i * 40, -12), 9 + i * 2, Color("d6b8ef"))
    draw_arc(base + Vector2(-60 + i * 40, -12), 17, 0, TAU, 24, Color("f7d88c"), 2)
  elif decor.display == "winter":
   draw_rect(Rect2(base.x - 80, base.y + 9, 160, 8), Color("e2f8ff"))
   for offset in [-55, 55]:
    var tree := PackedVector2Array([base + Vector2(offset, -35), base + Vector2(offset - 22, 12), base + Vector2(offset + 22, 12)])
    draw_colored_polygon(tree, Color("8fc7b1"))
   draw_circle(base, 14, Color("e2f8ff"))
   draw_circle(base + Vector2(0, -20), 10, Color("e2f8ff"))
   for offset in [-3, 3]: draw_circle(base + Vector2(offset, -22), 1.5, Color("263e60"))
   draw_line(base + Vector2(-10, -10), base + Vector2(10, -10), Color("d48165"), 4)
  else:
   for i in 3: draw_rect(Rect2(base + Vector2(-65 + i * 45, -30), Vector2(35, 40)), Color("f6d59d"))
  draw_string(ThemeDB.fallback_font, Vector2(10, 636), TravelCollections.SETS[decor.display].name, HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, 16, Color("263e60"))
 for row in 3:
  draw_rect(Rect2(5, 243 + row * 148, size.x - 10, 9), shelf)
  draw_rect(Rect2(16, 252 + row * 148, 12, 9), shelf.darkened(0.2))
  draw_rect(Rect2(size.x - 28, 252 + row * 148, 12, 9), shelf.darkened(0.2))
 if decor.rug != "none":
  var color := Color(RoomDecor.ITEMS.rug[decor.rug].color)
  draw_style_box(room_style(color, 22), Rect2(40, 573, size.x - 80, 48))
  draw_rect(Rect2(48, 581, size.x - 96, 32), color.lightened(0.25), false, 2)
 if decor.plant != "none":
  var origin := Vector2(size.x - 29, 597)
  draw_style_box(room_style(Color("b87553"), 5), Rect2(origin + Vector2(-13, -5), Vector2(26, 31)))
  var height := 58.0 if decor.plant == "palm" else 38.0
  draw_line(origin, origin + Vector2(0, -height), Color("42633b"), 3)
  for index in 6:
   var angle := PI + index * PI / 5
   var tip := origin + Vector2(0, -height) + Vector2.from_angle(angle) * (35 if decor.plant == "palm" else 24)
   draw_line(origin + Vector2(0, -height), tip, Color("54865a"), 7, true)

func room_style(color: Color, radius: int) -> StyleBoxFlat:
 var result := StyleBoxFlat.new()
 result.bg_color = color
 result.set_corner_radius_all(radius)
 return result
