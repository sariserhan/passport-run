class_name GameHUD
extends CanvasLayer

signal start_requested
signal retry_requested
signal new_path_requested
signal pause_requested
signal resume_requested
signal menu_requested

const INK := Color("163c55")
const CREAM := Color("fff6df")
var root: Control
var safe_margin: MarginContainer
var instructions: VBoxContainer
var score: Label
var destination: Label
var phase_title: Label
var phase_hint: Label
var footer_panel: PanelContainer
var footer: VBoxContainer
var timer_bar: ProgressBar
var timer_label: Label
var begin_button: Button
var overlay: ColorRect
var modal_title: Label
var modal_body: Label
var modal_actions: VBoxContainer
var pause_button: Button
var modal_margin: MarginContainer
var modal_scroll: ScrollContainer
var modal_card: PanelContainer

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# A sky-colored scrim keeps instructions readable over the moving 3D path.
	var sky_scrim := TextureRect.new()
	sky_scrim.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	sky_scrim.offset_bottom = 220
	sky_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.04, 0.13, 0.25, 0.52))
	gradient.set_color(1, Color(0.04, 0.13, 0.25, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	sky_scrim.texture = texture
	root.add_child(sky_scrim)
	root.theme = Theme.new()
	root.theme.default_font_size = 18
	safe_margin = MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(safe_margin)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(content)
	var header := HBoxContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)
	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", -6)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	destination = label("PASSPORT RUN", 21, CREAM)
	destination.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	destination.add_theme_color_override("font_shadow_color", INK)
	destination.add_theme_constant_override("shadow_offset_y", 2)
	brand.add_child(destination)
	var score_panel := PanelContainer.new()
	score_panel.add_theme_stylebox_override("panel", panel_style(Color("153e57"), 14))
	score_panel.custom_minimum_size = Vector2(94, 58)
	header.add_child(score_panel)
	score = label("00 / 10", 20, CREAM)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_panel.add_child(score)
	pause_button = button("Ⅱ", false)
	pause_button.custom_minimum_size = Vector2(52, 58)
	pause_button.tooltip_text = "Pause"
	pause_button.pressed.connect(func(): pause_requested.emit())
	header.add_child(pause_button)
	instructions = VBoxContainer.new()
	instructions.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	instructions.offset_top = 104
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(instructions)
	phase_title = label("Ready for takeoff?", 28, CREAM)
	phase_title.add_theme_color_override("font_outline_color", INK)
	phase_title.add_theme_constant_override("outline_size", 5)
	phase_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_child(phase_title)
	phase_hint = label("Remember the path. Make the leap.", 17, CREAM)
	phase_hint.add_theme_color_override("font_outline_color", INK)
	phase_hint.add_theme_constant_override("outline_size", 3)
	phase_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_child(phase_hint)
	footer_panel = PanelContainer.new()
	footer_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_panel.offset_top = -158
	footer_panel.add_theme_stylebox_override("panel", panel_style(Color("153e57"), 20))
	content.add_child(footer_panel)
	var padding := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + edge, 18)
	footer_panel.add_child(padding)
	footer = VBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	padding.add_child(footer)
	timer_label = label("3 lanes  ·  10 steps  ·  One safe path", 17, CREAM)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(timer_label)
	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size.y = 10
	timer_bar.show_percentage = false
	timer_bar.max_value = 1.0
	timer_bar.add_theme_stylebox_override("background", panel_style(Color("0d2f45"), 5))
	timer_bar.add_theme_stylebox_override("fill", panel_style(Color("b3ec69"), 5))
	footer.add_child(timer_bar)
	begin_button = button("LET’S GO", true)
	begin_button.pressed.connect(func(): start_requested.emit())
	footer.add_child(begin_button)
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.035, 0.12, 0.2, 0.78)
	root.add_child(overlay)
	modal_margin = MarginContainer.new()
	modal_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(modal_margin)
	modal_scroll = ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_scroll.follow_focus = true
	modal_margin.add_child(modal_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_scroll.add_child(center)
	modal_card = PanelContainer.new()
	var card := modal_card
	card.add_theme_stylebox_override("panel", panel_style(CREAM, 24))
	center.add_child(card)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 26)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	margin.add_child(stack)
	modal_title = label("Great try!", 32, INK)
	modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(modal_title)
	modal_body = label("", 19, INK)
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(modal_body)
	modal_actions = VBoxContainer.new()
	modal_actions.add_theme_constant_override("separation", 12)
	stack.add_child(modal_actions)
	overlay.hide()
	root.resized.connect(update_safe_area)
	update_safe_area()
	update_safe_area.call_deferred()

func update_safe_area() -> void:
	var landscape := root.size.x > root.size.y
	instructions.offset_top = 64 if landscape else 104
	phase_title.add_theme_font_size_override("font_size", 22 if landscape else 28)
	phase_hint.add_theme_font_size_override("font_size", 14 if landscape else 17)
	SafeAreaMargins.apply(safe_margin, root.size, Vector4i(24, 24, 24, 26))
	SafeAreaMargins.apply(modal_margin, root.size, Vector4i(20, 24, 20, 26))
	var available_width := root.size.x - modal_margin.get_theme_constant("margin_left") - modal_margin.get_theme_constant("margin_right")
	modal_card.custom_minimum_size.x = maxf(1, minf(364, available_width))

func show_ready(lanes: int, rows: int) -> void:
	footer_panel.offset_top = -158
	overlay.hide()
	phase_title.text = "Ready for takeoff?"
	phase_hint.text = "Remember the path. Make the leap."
	timer_label.text = "%d lanes  ·  %d steps  ·  One safe path" % [lanes, rows]
	timer_bar.value = 0
	begin_button.show()
	pause_button.disabled = false

func show_preview() -> void:
	footer_panel.offset_top = -104
	begin_button.hide()
	pause_button.disabled = false
	phase_title.text = "Watch the path…"
	phase_hint.text = "Remember the tiles with a checkmark."

func update_preview(remaining: float, total: float) -> void:
	timer_bar.value = remaining / total
	timer_label.text = "MEMORIZE   ·   %d" % ceili(remaining)

func show_play(completed: int, total: int) -> void:
	phase_title.text = "…and go!"
	phase_hint.text = "Tap a tile in the next row."
	timer_label.text = "STEP %02d OF %02d" % [mini(completed + 1, total), total]
	timer_bar.value = float(completed) / total
	update_score(completed, total)

func update_score(completed: int, total: int) -> void:
	score.text = "%02d / %02d" % [completed, total]

func update_decision(remaining: float, total: float) -> void:
	timer_label.text = "CHOOSE YOUR TILE   ·   %ds" % ceili(remaining)
	timer_bar.value = remaining / total
	timer_bar.add_theme_stylebox_override("fill", panel_style(Color("ff956e") if remaining <= 3 else Color("b3ec69"), 5))

func show_celebration() -> void:
	phase_title.text = "You made it!"
	phase_hint.text = "One more destination for your passport."
	timer_label.text = "COUNTRY COMPLETE"
	timer_bar.value = 1

func show_falling() -> void:
	phase_title.text = "Whoops!"
	phase_hint.text = "One more step to remember."

func show_result(success: bool, completed: int, total: int) -> void:
	modal_title.text = "Path complete!" if success else "Great try!"
	modal_body.text = ("%d / %d steps remembered\nReady for another adventure?" % [completed, total]) if success else ("%d / %d safe steps\nYou fell at step %d.\nRemember it and try again." % [completed, total, completed + 1])
	clear_actions()
	add_action("PLAY AGAIN" if success else "TRY AGAIN", true, func(): retry_requested.emit())
	add_action("NEW PATH", false, func(): new_path_requested.emit())
	add_action("MAIN MENU", false, func(): menu_requested.emit())
	overlay.show()

func show_pause() -> void:
	modal_title.text = "Take a breather"
	modal_body.text = "Your journey can wait."
	clear_actions()
	add_action("KEEP GOING", true, func(): resume_requested.emit())
	add_action("END RUN", false, func(): menu_requested.emit())
	overlay.show()

func clear_actions() -> void:
	modal_scroll.scroll_vertical = 0
	for child in modal_actions.get_children():
		modal_actions.remove_child(child)
		child.queue_free()

func add_action(text: String, primary: bool, callback: Callable) -> void:
	var action := button(text, primary)
	action.pressed.connect(callback)
	modal_actions.add_child(action)
	if modal_actions.get_child_count() == 1:
		action.grab_focus.call_deferred()

func label(text: String, size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func button(text: String, primary: bool) -> Button:
	var node := Button.new()
	node.text = text
	node.clip_text = true
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.custom_minimum_size.y = 56
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 19)
	node.add_theme_color_override("font_color", Color("18262c") if primary else CREAM)
	node.add_theme_color_override("font_focus_color", Color("18262c") if primary else CREAM)
	node.add_theme_color_override("font_hover_color", Color("18262c") if primary else CREAM)
	node.add_theme_color_override("font_pressed_color", Color("18262c") if primary else CREAM)
	var base := Color("cdb07c") if primary else Color("263a43")
	node.add_theme_stylebox_override("normal", panel_style(base, 12))
	node.add_theme_stylebox_override("hover", panel_style(base.lightened(0.08), 12))
	node.add_theme_stylebox_override("pressed", panel_style(base.darkened(0.08), 12))
	var focus := panel_style(Color(0, 0, 0, 0), 12)
	focus.border_color = Color("fff4cc")
	focus.set_border_width_all(3)
	node.add_theme_stylebox_override("focus", focus)
	return node

func panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if color.a > 0:
		style.border_color = color.lightened(0.24)
		style.set_border_width_all(1)
		style.shadow_color = Color(0.02, 0.06, 0.14, 0.30)
		style.shadow_size = 3
		style.shadow_offset = Vector2(0, 3)
	return style

func show_journey_result(title: String, body: String, actions: Array) -> void:
	modal_title.text = title
	modal_body.text = body
	clear_actions()
	for item in actions:
		add_action(item.text, item.get("primary", false), item.callback)
	overlay.show()
