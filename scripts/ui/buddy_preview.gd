class_name BuddyPreview
extends Control
var weather := "clear"
var kind := "bird"
var reduced_motion := false
var elapsed := 0.0
func _ready() -> void:
 custom_minimum_size.y = 130
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 if reduced_motion: return
 elapsed += delta
 queue_redraw()
func _draw() -> void:
 var state := "celebrate" if fmod(elapsed, 10) > 6 else "thinking"
 var offset := BuddyPersonality.offset(kind, state, elapsed)
 var center := Vector2(size.x / 2, 57) + Vector2(offset.x, -offset.y) * 35
 var color := Color(BuddyPersonality.FRIENDS[kind].color)
 draw_circle(center + Vector2(0, 32), 27, Color(0, 0, 0, 0.12))
 if kind == "robot":
  draw_style_box(panel(color), Rect2(center - Vector2(23, 20), Vector2(46, 40)))
  draw_line(center + Vector2(0, -20), center + Vector2(0, -32), color, 3)
  draw_circle(center + Vector2(0, -33), 4, Color("fff2d6"))
 else:
  draw_circle(center, 23, color)
  if kind == "bird": draw_colored_polygon(PackedVector2Array([center + Vector2(20, -4), center + Vector2(36, 2), center + Vector2(20, 8)]), Color("e98c45"))
  else:
   for side in [-1, 1]: draw_colored_polygon(PackedVector2Array([center + Vector2(side * 8, -15), center + Vector2(side * 17, -34), center + Vector2(side * 20, -13)]), Color("ffe0a0"))
 for side in [-1, 1]:
  draw_circle(center + Vector2(side * 7, -4), 3, Color("153e57"))
  draw_line(center + Vector2(side * 20, 5), center + Vector2(side * 42, 5 + sin(elapsed * (9 if kind == "bird" else 2)) * 10), color, 7)
 if kind == "dragon" and state == "celebrate":
  for i in 3: draw_circle(center + Vector2(30 + i * 10, -6 - i * 5), 3, Color("f6c968"))
 draw_string(ThemeDB.fallback_font, Vector2(0, 112), BuddyPersonality.FRIENDS[kind].name + " · " + (BuddyPersonality.FRIENDS[kind].cheer if state == "celebrate" else ("Snow!" if weather == "snow" else "Drip!" if weather == "rain" else BuddyPersonality.FRIENDS[kind].idle)), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color("fff2d6"))
func panel(color: Color) -> StyleBoxFlat:
 var result := StyleBoxFlat.new()
 result.bg_color = color
 result.set_corner_radius_all(8)
 return result
