class_name TravelPhoto
extends Control
var profile: PlayerProfile
var destination_id := "FR"
var caption := ""
var frame := "classic"
var pose := "wave"
var buddy := "bird"
var caption_label: Label
func _ready() -> void:
 custom_minimum_size.y = 600
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 caption_label = Label.new()
 caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 caption_label.add_theme_font_size_override("font_size", 19)
 caption_label.add_theme_color_override("font_color", Color("183f55"))
 add_child(caption_label)
 resized.connect(queue_redraw)
func _draw() -> void:
 if size.x <= 0 or size.y <= 0: return
 var border := Color("eecb73") if frame == "gold" else Color("fff2d6") if frame == "classic" else Color("89c7dd")
 draw_rect(Rect2(Vector2.ZERO, size), border)
 var photo := Rect2(12, 50, size.x - 24, size.y - 150)
 var texture := GameCatalog.backdrop(destination_id)
 draw_texture_rect_region(texture, photo, Rect2(0, texture.get_height() * 0.06, texture.get_width(), texture.get_width() * photo.size.y / photo.size.x))
 var explorer := preload("res://assets/realistic/memory-explorer.png")
 var pose_index: int = {"wave": 0, "jump": 4, "cheer": 8}.get(pose, 0)
 var bounds: Array = Traveler.pose_bounds.human[pose_index]
 var region := Rect2(bounds[0], bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1])
 var height := 230.0
 var width := height * region.size.x / region.size.y
 draw_texture_rect_region(explorer, Rect2(18, photo.end.y - height, width, height), region)
 if buddy in BuddyPersonality.FRIENDS:
  var center := Vector2(size.x - 65, photo.end.y - 140)
  draw_circle(center, 22, Color(BuddyPersonality.FRIENDS[buddy].color))
  for side in [-1, 1]:
   draw_line(center + Vector2(side * 15, 3), center + Vector2(side * 36, -7), Color(BuddyPersonality.FRIENDS[buddy].color), 6)
   draw_circle(center + Vector2(side * 7, -3), 3, Color("183f55"))
  draw_string(ThemeDB.fallback_font, center + Vector2(-30, -35), BuddyPersonality.FRIENDS[buddy].name, HORIZONTAL_ALIGNMENT_CENTER, 60, 17, Color("fff2d6"))
 if profile:
  var time: String = profile.activities.custom.time
  if time != "day": draw_rect(photo, Color(0.85, 0.37, 0.12, 0.17) if time in ["sunrise", "sunset"] else Color(0.02, 0.08, 0.2, 0.32))
  for i in 24:
   var point := photo.position + Vector2(fmod(i * 51.0, photo.size.x), fmod(i * 83.0, photo.size.y))
   if profile.activities.custom.weather == "rain": draw_line(point, point + Vector2(-4, 15), Color(0.8, 0.9, 1, 0.6), 2)
   elif profile.activities.custom.weather == "snow": draw_circle(point, 3, Color("e6f8ff"))
 draw_string(ThemeDB.fallback_font, Vector2(16, 33), "PASSPORT RUN · " + GameCatalog.country_name(destination_id), HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 20, Color("183f55"))
 if caption_label:
  caption_label.text = caption.left(80)
  caption_label.position = Vector2(16, size.y - 94)
  caption_label.size = Vector2(size.x - 32, 58)
 if profile: draw_string(ThemeDB.fallback_font, Vector2(16, size.y - 32), profile.activities.custom.nickname + " · " + GameCatalog.today_utc(), HORIZONTAL_ALIGNMENT_CENTER, size.x - 32, 15, Color("183f55"))
