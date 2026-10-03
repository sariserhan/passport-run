class_name SouvenirRoom
extends Control

# Hold the drawn backdrop: GameCatalog's bounded cache may evict it before this frame renders.
var drawn_backdrops: Array[Texture2D] = []
signal souvenir_selected(id: String)
var profile: PlayerProfile
var card_origin := Vector2.ZERO
signal arrangement_changed(positions: Dictionary)
var destinations: Array[String] = []
var postcards: Array[String] = []
var decor: Dictionary = RoomDecor.DEFAULTS.duplicate()
var positions: Dictionary = {}
var rare_keepsakes: Dictionary = {}
var buddy_kind := "none"
var dragging: Control
var drag_origin := Vector2.ZERO

func _ready() -> void:
 custom_minimum_size.y = 850
 mouse_filter = Control.MOUSE_FILTER_PASS
 resized.connect(layout)
 for id in destinations.slice(0, 6):
  var card := SouvenirCard.new()
  card.destination_id = id
  card.compact = true
  card.rare_variants = rare_keepsakes.get(id, [])
  add_child(card)
 layout.call_deferred()

func bounds_for_cards() -> Rect2:
 return Rect2(12, 196 if decor.get("map", "none") == "world" else 106, maxf(1, size.x / 2 - 12), 314)

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
   card.position = Vector2(12 + slot % 2 * size.x / 2, (200 if decor.get("map", "none") == "world" else 110) + slot / 2 * 148)
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
   card_origin = child.position
   move_child(child, get_child_count() - 1)
   drag_origin = point - child.position
   accept_event()
   break

func finish_drag() -> void:
 if not dragging: return
 var bounds := bounds_for_cards()
 var normalized := (dragging.position - bounds.position) / bounds.size
 positions[dragging.destination_id] = [clampf(normalized.x, 0, 1), clampf(normalized.y, 0, 1)]
 var selected: String = dragging.destination_id if dragging.position.distance_to(card_origin) < 6 else ""
 dragging = null
 arrangement_changed.emit(positions.duplicate(true))
 if not selected.is_empty(): souvenir_selected.emit(selected)
 accept_event()

func _draw() -> void:
 for key in RoomDecor.DEFAULTS:
  if not decor.has(key): decor[key] = RoomDecor.DEFAULTS[key]
 var floor_y := 644 if decor.map == "world" else 554
 var shift := floor_y - 554
 var wall: Color = Color(RoomDecor.ITEMS.wallpaper[decor.wallpaper].color)
 var shelf: Color = Color(RoomDecor.ITEMS.shelves[decor.shelves].color)
 draw_rect(Rect2(Vector2.ZERO, size), wall)
 for x in range(0, int(size.x), 22): draw_line(Vector2(x, 0), Vector2(x, floor_y), Color(1, 1, 1, 0.08), 1)
 if decor.wallpaper == "night":
  for index in 28:
   draw_circle(Vector2(fmod(index * 47.0 + 13, size.x), 18 + fmod(index * 79.0, 530)), 2, Color("ffe2a0"))
 if profile and profile.extras.ornament in TravelExtras.RECIPES:
  var key: String = profile.extras.ornament
  var center := Vector2(size.x - 42, floor_y - 34)
  var color := Color(TravelExtras.RECIPES[key].color)
  draw_line(center + Vector2(0, -36), center + Vector2(0, 14), Color("785743"), 3)
  if key == "lantern":
   draw_rect(Rect2(center - Vector2(17, 22), Vector2(34, 40)), color)
   for x in [-10, 0, 10]: draw_line(center + Vector2(x, -22), center + Vector2(x, 18), Color("b99155"), 2)
  elif key == "mobile":
   for x in [-18, 0, 18]:
    draw_line(center + Vector2(0, -28), center + Vector2(x, -10), color, 2)
    draw_circle(center + Vector2(x, -6), 5, color)
  else:
   draw_circle(center, 24, Color(0.7, 0.9, 0.8, 0.6))
   for x in [-10, 0, 10]: draw_circle(center + Vector2(x, -6), 7, color)
 draw_rect(Rect2(0, floor_y, size.x, maxf(0, size.y - floor_y)), Color("b8916e"))
 for y in range(floor_y + 11, int(size.y), 18): draw_line(Vector2(0, y), Vector2(size.x, y), Color("9c795c"), 1)
 draw_rect(Rect2(0, 0, size.x, 5), Color("8f6945"))
 for x in [size.x * 0.25, size.x * 0.75]:
  draw_circle(Vector2(x, 10), 38, Color(1, 0.86, 0.56, 0.12))
  draw_circle(Vector2(x, 7), 4, Color("ffdf8a"))
 drawn_backdrops.clear()
 for index in postcards.size():
  var frame := Rect2(12 + index * (size.x - 24) / 3, 18, (size.x - 36) / 3, 70)
  draw_rect(frame.grow(3), Color("fff2d6"))
  var texture := GameCatalog.backdrop(postcards[index])
  drawn_backdrops.append(texture)
  var crop := Vector2(texture.get_width(), texture.get_width() * frame.size.y / frame.size.x)
  draw_texture_rect_region(texture, frame, Rect2((Vector2(texture.get_size()) - crop) / 2, crop))
  draw_line(Vector2(frame.get_center().x, 6), Vector2(frame.get_center().x, 15), Color("b49155"), 2)
 if postcards.is_empty():
  draw_string(ThemeDB.fallback_font, Vector2(12, 60), "Hang your country postcards here", HORIZONTAL_ALIGNMENT_CENTER, size.x - 24, 15, wall.darkened(0.5))
 if decor.display != "none":
  var base := Vector2(size.x * 0.5, floor_y + 46)
  draw_rect(Rect2(base.x - 85, floor_y + 6, 170, 60), Color("263e60"))
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
  draw_string(ThemeDB.fallback_font, Vector2(10, floor_y + 82), TravelCollections.SETS[decor.display].name, HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, 16, Color("263e60"))
 if decor.map == "world":
  var rect := Rect2(16, 100, size.x - 32, 80)
  draw_rect(rect.grow(4), Color("785743"))
  draw_rect(rect, Color("163d57"))
  for polygon in PassportWorldMap.GEOGRAPHY.polygons:
   var points := PackedVector2Array()
   for point in polygon: points.append(rect.position + Vector2((float(point[0]) + 180) / 360, (90 - float(point[1])) / 180) * rect.size)
   if not Geometry2D.triangulate_polygon(points).is_empty(): draw_colored_polygon(points, Color("91bfa5"))
 for row in 3:
  draw_rect(Rect2(5, 243 + shift + row * 148, size.x - 10, 9), shelf)
  draw_rect(Rect2(16, 252 + shift + row * 148, 12, 9), shelf.darkened(0.2))
  draw_rect(Rect2(size.x - 28, 252 + shift + row * 148, 12, 9), shelf.darkened(0.2))
 if decor.rug != "none":
  var color := Color(RoomDecor.ITEMS.rug[decor.rug].color)
  draw_style_box(room_style(color, 22), Rect2(40, floor_y + 19, size.x - 80, 48))
  draw_rect(Rect2(48, floor_y + 27, size.x - 96, 32), color.lightened(0.25), false, 2)
 if decor.plant != "none":
  var origin := Vector2(size.x - 29, floor_y + 43)
  draw_style_box(room_style(Color("b87553"), 5), Rect2(origin + Vector2(-13, -5), Vector2(26, 31)))
  var height := 58.0 if decor.plant == "palm" else 38.0
  draw_line(origin, origin + Vector2(0, -height), Color("42633b"), 3)
  for index in 6:
   var angle := PI + index * PI / 5
   var tip := origin + Vector2(0, -height) + Vector2.from_angle(angle) * (35 if decor.plant == "palm" else 24)
   draw_line(origin + Vector2(0, -height), tip, Color("54865a"), 7, true)

 if decor.furniture != "none":
  var pos := Vector2(20, floor_y + 105)
  if decor.furniture == "desk":
   draw_rect(Rect2(pos, Vector2(size.x * 0.42, 12)), shelf)
   for x in [0, size.x * 0.42 - 10]: draw_rect(Rect2(pos + Vector2(x, 12), Vector2(10, 54)), shelf.darkened(0.2))
   draw_rect(Rect2(pos + Vector2(12, -10), Vector2(38, 10)), Color("f6e6bb"))
  else:
   draw_style_box(room_style(Color("bc866e"), 15), Rect2(pos + Vector2(8, -26), Vector2(90, 82)))
   draw_style_box(room_style(Color("d6a386"), 12), Rect2(pos + Vector2(0, 5), Vector2(106, 28)))
 if decor.buddy_bed != "none":
  var pos := Vector2(size.x * 0.74, floor_y + 143)
  var color := Color("a77c51") if decor.buddy_bed == "nest" else Color("74bacd") if decor.buddy_bed == "dock" else Color("ce927a")
  draw_style_box(room_style(color, 18), Rect2(pos - Vector2(52, 0), Vector2(104, 36)))
  draw_arc(pos + Vector2(0, 10), 35, 0, PI, 24, color.lightened(0.35), 4)
  if buddy_kind in BuddyPersonality.FRIENDS:
   draw_circle(pos + Vector2(0, -3), 17, Color(BuddyPersonality.FRIENDS[buddy_kind].color))
   draw_string(ThemeDB.fallback_font, pos + Vector2(-13, -25), "Zzz" if not profile or profile.activities.room.resting else "Hi!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("263e60"))
 if decor.trophy != "none":
  var pos := Vector2(size.x * 0.74, floor_y + 101)
  draw_rect(Rect2(pos + Vector2(-5, -27), Vector2(10, 30)), Color("f4cc66"))
  draw_circle(pos + Vector2(0, -35), 13, Color("f4cc66"))
  draw_rect(Rect2(pos + Vector2(-20, 0), Vector2(40, 8)), Color("785743"))
  draw_string(ThemeDB.fallback_font, Vector2(10, floor_y + 199), decor.trophy + " explorer trophy", HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, 15, Color("263e60"))
 if profile:
  var state: Dictionary = profile.activities.room
  if not state.lamp: draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.13, 0.25))
  if state.seated and decor.furniture == "armchair":
   draw_circle(Vector2(70, floor_y + 103), 14, Color("ddbb94"))
   draw_rect(Rect2(55, floor_y + 117, 30, 25), Color("426e86"))
  if state.space == "balcony":
   draw_rect(Rect2(12, 14, size.x - 24, 73), Color("94cbdc"))
   for x in range(20, int(size.x), 26): draw_line(Vector2(x, 20), Vector2(x, 85), Color("f3e4c8"), 3)
   draw_string(ThemeDB.fallback_font, Vector2(20, 66), "My travel balcony", HORIZONTAL_ALIGNMENT_CENTER, size.x - 40, 20, Color("183f55"))
  elif state.space == "nook":
   draw_rect(Rect2(14, 17, size.x - 28, 68), Color("785743"))
   for i in 14: draw_rect(Rect2(24 + i * (size.x - 48) / 14, 27, (size.x - 48) / 18, 48), [Color("9bb991"), Color("ca9a76"), Color("dcc47d")][i % 3])
  elif state.space == "gallery":
   draw_string(ThemeDB.fallback_font, Vector2(18, 65), "EXPEDITION GALLERY · %d treasures" % profile.discoveries.size(), HORIZONTAL_ALIGNMENT_CENTER, size.x - 36, 18, Color("183f55"))
 if decor.lighting != "day":
  draw_rect(Rect2(Vector2.ZERO, size), Color(0.75, 0.35, 0.06, 0.1) if decor.lighting == "warm" else Color(0.03, 0.1, 0.3, 0.22))
  for x in [size.x * 0.25, size.x * 0.75]: draw_circle(Vector2(x, 16), 62, Color(1, 0.83, 0.45, 0.12) if decor.lighting == "warm" else Color(0.7, 0.86, 1, 0.13))

func room_style(color: Color, radius: int) -> StyleBoxFlat:
 var result := StyleBoxFlat.new()
 result.bg_color = color
 result.set_corner_radius_all(radius)
 return result
