class_name SouvenirCard
extends Control

var destination_id := "FR"
var compact := false
var quantity := 1

func _ready() -> void:
 custom_minimum_size.y = 132
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 if compact:
  resized.connect(queue_redraw)
  return
 var text := VBoxContainer.new()
 text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 text.offset_left = 120
 text.offset_top = 21
 text.offset_right = -16
 text.offset_bottom = -12
 add_child(text)
 for line in [GameCatalog.country_name(destination_id), DestinationTheme.souvenir(destination_id) + " ×%d" % quantity]:
  var label := Label.new()
  label.text = line
  label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  label.add_theme_font_size_override("font_size", 18 if text.get_child_count() == 0 else 15)
  label.add_theme_color_override("font_color", Color("203d4d"))
  text.add_child(label)
 text.minimum_size_changed.connect(func(): custom_minimum_size.y = maxf(132, text.get_combined_minimum_size().y + 33))
 resized.connect(queue_redraw)

func _draw() -> void:
 var frame := StyleBoxFlat.new()
 frame.bg_color = Color("fff1d4")
 frame.set_corner_radius_all(12)
 draw_style_box(frame, Rect2(Vector2.ZERO, size))
 var texture := GameCatalog.backdrop(destination_id)
 var photo := Rect2(6, 6, size.x - 12, 60) if compact else Rect2(6, 6, 100, size.y - 12)
 var source_size := Vector2(texture.get_size())
 var crop := source_size
 var aspect := photo.size.x / photo.size.y
 if crop.x / crop.y > aspect: crop.x = crop.y * aspect
 else: crop.y = crop.x / aspect
 draw_texture_rect_region(texture, photo, Rect2((source_size - crop) / 2, crop))
 var center := Vector2(size.x / 2, 65) if compact else Vector2(53, 75)
 var color := DestinationTheme.color(destination_id).darkened(0.2)
 var theme := DestinationTheme.style(destination_id)
 var keepsake := DestinationTheme.souvenir(destination_id).to_lower()
 draw_circle(center, 39, color.lightened(0.65))
 draw_arc(center, 39, 0, TAU, 48, color, 2, true)
 draw_set_transform(center)
 if "postcard" in keepsake:
  draw_rect(Rect2(-29, -21, 58, 42), Color("fff4dc"))
  draw_texture_rect_region(texture, Rect2(-26, -18, 32, 36), Rect2((source_size - crop) / 2, crop))
  for y in [-4, 4, 12]: draw_line(Vector2(10, y), Vector2(24, y), color, 2)
 elif destination_id == "TR":
  draw_circle(Vector2.ZERO, 28, Color("255eb4"))
  draw_circle(Vector2.ZERO, 19, Color("ffffff"))
  draw_circle(Vector2.ZERO, 12, Color("55bfdf"))
  draw_circle(Vector2.ZERO, 6, Color("142941"))
 elif "torch" in keepsake:
  draw_colored_polygon(PackedVector2Array([Vector2(-7, 27), Vector2(-11, -9), Vector2(11, -9), Vector2(7, 27)]), Color("639b7d"))
  draw_colored_polygon(PackedVector2Array([Vector2(-12, -10), Vector2(-8, -24), Vector2(0, -32), Vector2(5, -18), Vector2(13, -25), Vector2(12, -10)]), Color("e6a94c"))
 elif destination_id == "FR":
  draw_polyline(PackedVector2Array([Vector2(-20, 25), Vector2(0, -30), Vector2(20, 25)]), color, 4, true)
  for y in [-7, 8, 22]: draw_line(Vector2(-13, y), Vector2(13, y), color, 3, true)
 elif "mask" in keepsake:
  draw_colored_polygon(PackedVector2Array([Vector2(-29, -12), Vector2(-10, -20), Vector2(0, -10), Vector2(10, -20), Vector2(29, -12), Vector2(20, 13), Vector2(0, 22), Vector2(-20, 13)]), color)
  for side in [-1, 1]: draw_ellipse(Vector2(side * 12, -1), Vector2(7, 4), color.lightened(0.75))
 elif "fan" in keepsake:
  draw_arc(Vector2(0, 22), 42, PI * 1.15, PI * 1.85, 32, color, 5, true)
  for i in 9: draw_line(Vector2(0, 22), Vector2(0, 22) + Vector2.from_angle(PI * (1.15 + i * 0.7 / 8)) * 42, color, 2, true)
 elif "clock" in keepsake or "watch" in keepsake:
  draw_circle(Vector2.ZERO, 25, color)
  draw_circle(Vector2.ZERO, 20, color.lightened(0.75))
  draw_line(Vector2.ZERO, Vector2(0, -13), color, 3, true)
  draw_line(Vector2.ZERO, Vector2(12, 5), color, 3, true)
  draw_arc(Vector2(0, -30), 6, 0, TAU, 16, color, 2, true)
 elif "crane" in keepsake:
  draw_colored_polygon(PackedVector2Array([Vector2(-30, -20), Vector2(-4, 6), Vector2(0, -4), Vector2(29, -26), Vector2(11, 15), Vector2(-14, 18)]), color)
  draw_polyline(PackedVector2Array([Vector2(8, 14), Vector2(18, -6), Vector2(29, -2)]), color, 3, true)
 elif "flower" in keepsake or "rose" in keepsake or "lotus" in keepsake or "protea" in keepsake:
  for i in 6: draw_circle(Vector2.from_angle(i * TAU / 6) * 15, 10, color)
  draw_circle(Vector2.ZERO, 8, color.lightened(0.65))
 elif theme == "ice":
  for i in 6:
   var tip := Vector2.from_angle(i * TAU / 6) * 27
   draw_line(Vector2.ZERO, tip, color, 3, true)
   draw_line(tip * 0.6, tip * 0.75 + tip.rotated(PI / 2) * 0.22, color, 2, true)
   draw_line(tip * 0.6, tip * 0.75 + tip.rotated(-PI / 2) * 0.22, color, 2, true)
 elif theme == "sand":
  draw_colored_polygon(PackedVector2Array([Vector2(-26, 23), Vector2(0, -26), Vector2(26, 23)]), color)
  draw_line(Vector2(0, -26), Vector2(9, 23), color.lightened(0.5), 2, true)
 elif theme == "lantern":
  draw_rect(Rect2(-19, -21, 38, 40), color)
  draw_arc(Vector2(0, -21), 19, PI, TAU, 20, color, 2, true)
  for x in [-10, 0, 10]: draw_line(Vector2(x, -17), Vector2(x, 14), color.lightened(0.5), 2, true)
  draw_line(Vector2(0, 19), Vector2(0, 31), color, 3, true)
 elif theme == "space":
  draw_circle(Vector2.ZERO, 18, color)
  draw_arc(Vector2.ZERO, 28, 0.15, PI + 0.15, 32, color.lightened(0.25), 4, true)
  draw_arc(Vector2.ZERO, 28, PI + 0.15, TAU + 0.15, 32, color, 4, true)
 elif theme in ["magic", "lava"]:
  draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(19, -5), Vector2(12, 26), Vector2(-12, 26), Vector2(-19, -5)]), color)
  draw_polyline(PackedVector2Array([Vector2(0, -29), Vector2(-4, -5), Vector2(12, 26)]), color.lightened(0.5), 2, true)
 elif theme == "ocean":
  draw_arc(Vector2(0, 17), 31, PI, TAU, 32, color, 4, true)
  for i in 7: draw_line(Vector2(0, 17), Vector2(0, 17) + Vector2.from_angle(PI + i * PI / 6) * 30, color, 2, true)
  draw_circle(Vector2(0, 17), 5, color)
 elif theme == "jungle":
  draw_colored_polygon(PackedVector2Array([Vector2(-5, 27), Vector2(-24, 1), Vector2(-8, -24), Vector2(24, -27), Vector2(22, 7)]), color)
  draw_line(Vector2(-17, 28), Vector2(17, -20), color.lightened(0.6), 3, true)
 else:
  for x in [-23, -5, 13]:
   draw_rect(Rect2(x, -4 - abs(x) * 0.4, 14, 30 + abs(x) * 0.4), color)
   draw_rect(Rect2(x + 4, 4, 5, 6), color.lightened(0.6))
 draw_set_transform(Vector2.ZERO)
 if compact:
  var font := ThemeDB.fallback_font
  var name := GameCatalog.country_name(destination_id)
  var font_size := 16
  while font_size > 9 and font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - 12: font_size -= 1
  draw_string(font, Vector2(6, 111), name, HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, font_size, Color("203d4d"))

 if compact:
  var title := DestinationTheme.souvenir(destination_id)
  var title_size := 11
  while title_size > 8 and ThemeDB.fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > size.x - 12: title_size -= 1
  draw_string(ThemeDB.fallback_font, Vector2(6, 126), title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, title_size, Color("61482e"))

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
 var points := PackedVector2Array()
 for i in 24: points.append(center + Vector2.from_angle(i * TAU / 24) * radii)
 draw_colored_polygon(points, color)
