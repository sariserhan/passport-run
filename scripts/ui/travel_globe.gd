class_name TravelGlobe
extends Control
signal destination_selected(id: String)
var discoveries: Array[String] = []
var longitude := 0.0
var selected := "FR"
var dragging := false
var drag_distance := 0.0
var pins: Dictionary = {}
func _ready() -> void:
 custom_minimum_size.y = 320
 mouse_filter = Control.MOUSE_FILTER_STOP
 resized.connect(queue_redraw)
func projected(lon: float, lat: float) -> Vector3:
 var a := deg_to_rad(lon) + longitude
 var b := deg_to_rad(lat)
 return Vector3(cos(b) * sin(a), -sin(b), cos(b) * cos(a))
func screen_point(p: Vector3) -> Vector2:
 return size * 0.5 + Vector2(p.x, p.y) * minf(size.x, size.y) * 0.44
func _draw() -> void:
 var radius := minf(size.x, size.y) * 0.44
 draw_circle(size * 0.5, radius + 4, Color("f5d78e"))
 draw_circle(size * 0.5, radius, Color("286888"))
 for lat in [-60, -30, 0, 30, 60]:
  var previous := Vector3.ZERO
  for lon in range(-180, 181, 5):
   var p := projected(lon, lat)
   if p.z >= 0 and previous.z > 0: draw_line(screen_point(previous), screen_point(p), Color("4889a1"), 1)
   previous = p
 for lon in range(-180, 180, 30):
  var previous := Vector3.ZERO
  for lat in range(-90, 91, 5):
   var p := projected(lon, lat)
   if p.z >= 0 and previous.z > 0: draw_line(screen_point(previous), screen_point(p), Color("4889a1"), 1)
   previous = p
 for polygon in PassportWorldMap.GEOGRAPHY.polygons:
  var previous := Vector3.ZERO
  for point in polygon:
   var p := projected(float(point[0]), float(point[1]))
   if p.z > 0 and previous.z > 0: draw_line(screen_point(previous), screen_point(p), Color("b2c9a1"), 2)
   previous = p
 pins.clear()
 for id in PassportWorldMap.GEOGRAPHY.pins:
  var point: Array = PassportWorldMap.GEOGRAPHY.pins[id]
  var p := projected(point[1], point[0])
  if p.z < 0.08: continue
  pins[id] = screen_point(p)
  draw_circle(pins[id], 5 if id == selected else 3, Color("ffe185") if id in discoveries else Color("e8edf0"))
  if id == selected: draw_arc(pins[id], 9, 0, TAU, 20, Color.WHITE, 2)
func pick(point: Vector2) -> void:
 var nearest := ""
 var distance := 18.0
 for id in pins:
  var d: float = pins[id].distance_to(point)
  if d < distance: distance = d; nearest = id
 if not nearest.is_empty(): selected = nearest; destination_selected.emit(nearest); queue_redraw()
# Mouse only: phones also emit emulated mouse events for every touch, so handling
# ScreenTouch/ScreenDrag too rotated the globe twice per swipe.
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  dragging = event.pressed
  if event.pressed: drag_distance = 0
  elif drag_distance < 8: pick(event.position)
 elif event is InputEventMouseMotion and dragging: rotate_by(event.relative.x)
 accept_event()
func rotate_by(amount: float) -> void:
 drag_distance += absf(amount)
 longitude += amount / maxf(100, size.x) * 4
 queue_redraw()
