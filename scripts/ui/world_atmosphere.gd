class_name WorldAtmosphere
extends Control

var clock := 0.0
var frozen := false
var reduced_motion := false
var celebration_remaining := 0.0
var cosmic := false
var underwater := false

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
 if frozen or reduced_motion: return
 celebration_remaining = maxf(0, celebration_remaining - delta)
 clock += delta
 queue_redraw()

func _draw() -> void:
 if reduced_motion: return
 # Decorative motion stays behind the 3D path and never reveals safe tiles.
 for i in 7:
  var x := fmod(i * 0.153 + clock * 0.005, 1.2) - 0.1
  var point := Vector2(x * size.x, size.y * (0.08 + (i % 3) * 0.06))
  if cosmic:
   draw_line(point, point + Vector2(13, -5), Color(1, 0.9, 0.7, 0.25), 1.0, true)
  elif underwater:
   draw_arc(Vector2(point.x, fposmod(size.y - clock * 14 - i * 115, size.y)), 3 + i % 3, 0, TAU, 14, Color(0.8, 1, 1, 0.2), 1, true)
  else:
   var wing := sin(clock * 3 + i) * 3
   draw_polyline(PackedVector2Array([point + Vector2(-5, wing), point, point + Vector2(5, wing)]), Color(0.1, 0.2, 0.3, 0.35), 1.3, true)
 for i in 12:
  var point := Vector2(fmod(i * 0.083 + clock * 0.008, 1) * size.x, size.y * (0.48 + (i % 5) * 0.09))
  draw_line(point, point + Vector2(12 + sin(clock + i) * 5, 0), Color(1, 0.95, 0.8, 0.10), 1.5, true)
 if not cosmic and not underwater:
  for i in 3:
   var point := Vector2(fposmod(i * size.x * 0.4 + clock * 5, size.x + 100) - 50, size.y * (0.07 + i * 0.06))
   draw_circle(point, 24, Color(1, 1, 1, 0.045))
   draw_circle(point + Vector2(21, 3), 19, Color(1, 1, 1, 0.045))

 if celebration_remaining > 0:
  for i in 18:
   var point := Vector2(size.x * (0.05 + fmod(i * 0.137, 0.9)), size.y * (0.05 + fmod(i * 0.073 + (2 - celebration_remaining) * 0.12, 0.35)))
   draw_circle(point, 2.0 + i % 3, Color(1, 0.82, 0.25, minf(celebration_remaining, 0.7)))
