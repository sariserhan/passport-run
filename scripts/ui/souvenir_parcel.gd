class_name SouvenirParcel
extends CanvasLayer

signal finished
var active := false
var opened := false
var progress := 0.0
var reduced_motion := false
var destination_id := "FR"
var shade: ColorRect
var content: VBoxContainer
var gift: Control
var card: SouvenirCard
var button: Button
var tween: Tween

func setup(style: GameHUD) -> void:
 layer = 8
 shade = ColorRect.new()
 shade.color = Color(0.03, 0.09, 0.14, 0.94)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(shade)
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
 shade.add_child(margin)
 var center := CenterContainer.new()
 margin.add_child(center)
 content = VBoxContainer.new()
 content.add_theme_constant_override("separation", 16)
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.add_child(content)
 var heading := style.label("A LITTLE PIECE OF YOUR TRIP", 23, GameHUD.CREAM)
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(heading)
 gift = Control.new()
 gift.custom_minimum_size.y = 190
 gift.mouse_filter = Control.MOUSE_FILTER_IGNORE
 gift.draw.connect(draw_gift)
 content.add_child(gift)
 button = style.button("OPEN PARCEL", true)
 button.pressed.connect(open_or_finish)
 content.add_child(button)
 shade.resized.connect(fit_content)
 shade.hide()

func fit_content() -> void:
 if content: content.custom_minimum_size.x = maxf(120, minf(420, shade.size.x - 56))

func present(id: String, quantity: int, reduce: bool) -> void:
 cancel()
 if id not in GameCatalog.DESTINATIONS: return
 destination_id = id
 reduced_motion = reduce
 active = true
 opened = false
 progress = 0
 card = SouvenirCard.new()
 card.destination_id = id
 card.quantity = quantity
 content.add_child(card)
 content.move_child(card, content.get_child_count() - 2)
 card.hide()
 button.text = "OPEN PARCEL"
 shade.show()
 fit_content()
 gift.show()
 gift.queue_redraw()
 button.grab_focus()

func open_or_finish() -> void:
 if not active: return
 if opened:
  cancel()
  finished.emit()
  return
 opened = true
 button.disabled = true
 if reduced_motion:
  reveal()
 else:
  tween = create_tween()
  tween.tween_method(func(value: float): progress = value; gift.queue_redraw(), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  tween.tween_callback(reveal)

func reveal() -> void:
 if not active: return
 card.show()
 gift.hide()
 button.text = "KEEP SOUVENIR"
 button.disabled = false
 button.grab_focus()

func draw_gift() -> void:
 var center := gift.size / 2
 gift.draw_rect(Rect2(center + Vector2(-84, -36), Vector2(168, 108)), Color("c4935c"))
 gift.draw_rect(Rect2(center + Vector2(-10, -36), Vector2(20, 108)), Color("dc6c57"))
 var lid_y := -48 - progress * 65
 gift.draw_set_transform(center + Vector2(0, lid_y), -progress * 0.12)
 gift.draw_rect(Rect2(-94, -13, 188, 26), Color("e5ba7c"))
 gift.draw_rect(Rect2(-10, -13, 20, 26), Color("e78067"))
 gift.draw_arc(Vector2(-15, -15), 18, 0, TAU, 24, Color("e78067"), 7, true)
 gift.draw_arc(Vector2(15, -15), 18, 0, TAU, 24, Color("e78067"), 7, true)
 gift.draw_set_transform(Vector2.ZERO)
 gift.draw_string(ThemeDB.fallback_font, Vector2(8, gift.size.y - 2), GameCatalog.country_name(destination_id), HORIZONTAL_ALIGNMENT_CENTER, gift.size.x - 16, 21, Color("fff2d6"))
 if progress > 0:
  for index in 8:
   var point := center + Vector2.from_angle(index * TAU / 8) * (30 + progress * 80)
   gift.draw_circle(point, 3, Color("ffdc80"))

func cancel() -> void:
 if tween and tween.is_valid(): tween.kill()
 active = false
 opened = false
 if card:
  content.remove_child(card)
  card.queue_free()
  card = null
 if shade: shade.hide()
 if button: button.disabled = false

func _notification(what: int) -> void:
 # Dismiss presentation on app suspension; the earned reward was saved first.
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] and active:
  cancel()
  finished.emit()
