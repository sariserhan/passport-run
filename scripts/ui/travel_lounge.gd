class_name TravelLounge
extends Control
var profile: PlayerProfile
func _ready() -> void:
 custom_minimum_size.y = 250
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO, size), Color("163d57"))
 var window := Rect2(12, 12, maxf(1, size.x - 24), 130)
 draw_rect(window, Color("9bcbdf"))
 draw_line(Vector2(12, 120), Vector2(size.x - 12, 120), Color("e8dfc3"), 8)
 draw_line(Vector2(size.x * 0.5, 12), Vector2(size.x * 0.5, 142), Color("e8dfc3"), 5)
 draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.65, 40), Vector2(size.x * 0.85, 65), Vector2(size.x * 0.6, 60), Vector2(size.x * 0.48, 90), Vector2(size.x * 0.53, 55)]), Color("fff2d6"))
 draw_rect(Rect2(20, 157, 70, 68), Color("be855a"))
 draw_rect(Rect2(42, 146, 27, 12), Color("e5c89d"), false, 3)
 draw_string(ThemeDB.fallback_font, Vector2(110, 180), "DEPARTURES", HORIZONTAL_ALIGNMENT_LEFT, size.x - 122, 24, Color("ffda65"))
 draw_string(ThemeDB.fallback_font, Vector2(110, 214), profile.activities.custom.nickname + " · Ready to explore", HORIZONTAL_ALIGNMENT_LEFT, size.x - 122, 16, Color("fff2d6"))
