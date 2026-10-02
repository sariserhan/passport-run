class_name SafeAreaMargins
extends RefCounted

# Order: left, top, right, bottom. Convert physical display pixels into UI units.
static func calculate(ui_size: Vector2, screen_size: Vector2i, safe: Rect2i, defaults: Vector4i) -> Vector4i:
	if screen_size.x <= 0 or screen_size.y <= 0 or not safe.has_area():
		return defaults
	return Vector4i(
		maxi(defaults.x, ceili(maxi(0, safe.position.x) * float(ui_size.x) / screen_size.x) + 12),
		maxi(defaults.y, ceili(maxi(0, safe.position.y) * float(ui_size.y) / screen_size.y) + 12),
		maxi(defaults.z, ceili(maxi(0, screen_size.x - safe.end.x) * float(ui_size.x) / screen_size.x) + 12),
		maxi(defaults.w, ceili(maxi(0, screen_size.y - safe.end.y) * float(ui_size.y) / screen_size.y) + 12)
	)

static func apply(container: MarginContainer, ui_size: Vector2, defaults: Vector4i) -> void:
	var margins := defaults
	if OS.has_feature("mobile"):
		margins = calculate(ui_size, DisplayServer.screen_get_size(), DisplayServer.get_display_safe_area(), defaults)
	for index in 4:
		container.add_theme_constant_override("margin_" + ["left", "top", "right", "bottom"][index], margins[index])
