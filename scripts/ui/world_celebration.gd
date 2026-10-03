class_name WorldCelebration
extends Control
var reduced_motion := false
var elapsed := 0.0
func _ready() -> void:
 custom_minimum_size.y = 150
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 if reduced_motion: return
 elapsed += delta
 queue_redraw()
func _draw() -> void:
 var center := Vector2(size.x / 2, 75)
 draw_circle(center, 48, Color("ecc35a"))
 draw_circle(center, 40, Color("153e57"))
 draw_string(ThemeDB.fallback_font, center + Vector2(-24, 14), "★", HORIZONTAL_ALIGNMENT_CENTER, 48, 42, Color("ecc35a"))
 for i in 44:
  var point := Vector2(fmod(i * 61.0, maxf(size.x, 1)), fmod(i * 31.0 + elapsed * (18 + i % 5 * 5), 145))
  draw_rect(Rect2(point, Vector2(4, 7)), [Color("ecc35a"), Color("a6e771"), Color("86d7ed"), Color("f39b8e")][i % 4])
