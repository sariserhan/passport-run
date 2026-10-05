class_name RemoveAdsOffer
extends CanvasLayer

# One-time card after the second full-screen ad: buy Remove Ads (behind ParentGate) or not now.
var purchase: RoutePurchase

static func present(host: Node, remove_ads: RoutePurchase) -> RemoveAdsOffer:
	var offer := RemoveAdsOffer.new()
	offer.purchase = remove_ads
	host.get_tree().root.add_child(offer)
	return offer

func _ready() -> void:
	layer = 19
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.07, 0.12, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 320
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	for line in [["ENJOYING THE TRIP?", 26], ["Remove every ad for good with a one-time purchase. Kids Mode never shows ads either way.", 18]]:
		var label := Label.new()
		label.text = line[0]
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", GameHUD.CREAM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	for choice in [["REMOVE ADS · " + purchase.price, buy, Color("cdb07c")], ["NOT NOW", queue_free, Color("263a43")]]:
		var button := Button.new()
		button.text = choice[0]
		button.custom_minimum_size.y = 56
		button.add_theme_font_size_override("font_size", 19)
		var ink: Color = GameHUD.INK if choice[1] == buy else GameHUD.CREAM
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: button.add_theme_color_override(state, ink)
		var surface := StyleBoxFlat.new()
		surface.bg_color = choice[2]
		surface.set_corner_radius_all(12)
		for state in ["normal", "hover", "pressed", "focus"]: button.add_theme_stylebox_override(state, surface)
		button.pressed.connect(choice[1])
		box.add_child(button)

func buy() -> void:
	if await ParentGate.ask(self): purchase.purchase()
	queue_free()
