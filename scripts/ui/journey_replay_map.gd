class_name JourneyReplayMap
extends PassportWorldMap
var progress := 1.0

func route_segments() -> Array[PackedVector2Array]:
 var lines := super.route_segments()
 if route.size() < 2: return lines
 var a: String = route[-2]
 var b: String = route[-1]
 if a not in GEOGRAPHY.pins or b not in GEOGRAPHY.pins: return lines
 var count := 2 if absf(pin_point(a).x - pin_point(b).x) > (size.x - 24) / 2 else 1
 count = mini(count, lines.size())
 var length := 0.0
 for i in range(lines.size() - count, lines.size()): length += lines[i][0].distance_to(lines[i][1])
 var remaining := length * progress
 var result: Array[PackedVector2Array] = []
 for i in lines.size():
  var line := lines[i]
  if i < lines.size() - count: result.append(line); continue
  var distance := line[0].distance_to(line[1])
  if remaining > 0:
   result.append(PackedVector2Array([line[0], line[0].lerp(line[1], minf(1, remaining / maxf(distance, 0.001)))]))
   remaining -= distance
 return result

func _draw() -> void:
 super._draw()
 if not route.is_empty() and route.back() not in GEOGRAPHY.pins:
  draw_rect(Rect2(0, size.y - 34, size.x, 34), Color("163d57"))
  draw_string(ThemeDB.fallback_font, Vector2(16, size.y - 16), "Special expedition · Beyond the world map", HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 14, Color("fff4d6"))
  return
 var lines := route_segments()
 var point := Vector2.ZERO
 if not lines.is_empty(): point = lines.back()[1]
 elif not route.is_empty() and route[0] in GEOGRAPHY.pins: point = pin_point(route[0])
 else: return
 draw_circle(point, 7, Color("ffffff"))
 draw_arc(point, 12, 0, TAU, 24, Color("ffcc58"), 2)
