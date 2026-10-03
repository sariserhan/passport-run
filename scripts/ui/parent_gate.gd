class_name ParentGate
extends CanvasLayer

# Apple Kids Category gate: an adult answers a multiplication question before a
# purchase or a share sheet that leaves the app. Asked every time; nothing is remembered.
signal answered(passed: bool)

var answer := 0
var field: LineEdit

static func ask(host: Node) -> bool:
	var gate := ParentGate.new()
	host.get_tree().root.add_child(gate)
	var passed: bool = await gate.answered
	gate.queue_free()
	return passed

func _ready() -> void:
	layer = 20
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var a := rng.randi_range(6, 9)
	var b := rng.randi_range(6, 9)
	answer = a * b
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.07, 0.12, 0.98)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 300
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	for line in [["FOR GROWN-UPS", 26], ["To continue, type the answer:\nWhat is %d × %d?" % [a, b], 19]]:
		var label := Label.new()
		label.text = line[0]
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", GameHUD.CREAM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	field = LineEdit.new()
	field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.custom_minimum_size.y = 56
	field.add_theme_font_size_override("font_size", 24)
	field.text_submitted.connect(func(_text): submit())
	box.add_child(field)
	for choice in [["CONTINUE", submit, Color("cdb07c")], ["CANCEL", func(): answered.emit(false), Color("263a43")]]:
		var button := Button.new()
		button.text = choice[0]
		button.custom_minimum_size.y = 56
		button.add_theme_font_size_override("font_size", 19)
		var ink: Color = GameHUD.INK if choice[0] == "CONTINUE" else GameHUD.CREAM
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: button.add_theme_color_override(state, ink)
		var surface := StyleBoxFlat.new()
		surface.bg_color = choice[2]
		surface.set_corner_radius_all(12)
		for state in ["normal", "hover", "pressed", "focus"]: button.add_theme_stylebox_override(state, surface)
		button.pressed.connect(choice[1])
		box.add_child(button)
	field.grab_focus.call_deferred()

func submit() -> void:
	answered.emit(field.text.strip_edges() == str(answer))
