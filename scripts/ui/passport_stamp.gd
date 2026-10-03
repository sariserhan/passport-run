class_name PassportStamp
extends CanvasLayer

# Hold the drawn backdrop: GameCatalog's bounded cache may evict it before this frame renders.
var drawn_backdrop: Texture2D
signal stamped
signal finished
var ink_color := Color("a24c40")
var active := false
var book: Control
var tween: Tween
var mark := 0.0
var country_id := "FR"
var style: GameHUD

func setup(hud: GameHUD) -> void:
	style = hud
	layer = 2
	book = Control.new()
	book.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(book)
	book.draw.connect(draw_book)
	book.hide()

func _process(_delta: float) -> void:
	if active:
		book.queue_redraw()

func draw_book() -> void:
	var paper := style.panel_style(Color("fff3d7"), 12)
	book.draw_style_box(paper, Rect2(0, 0, 340, 230))
	book.draw_line(Vector2(170, 12), Vector2(170, 218), Color("c8bda7"), 3)
	var font := ThemeDB.fallback_font
	book.draw_string(font, Vector2(20, 36), "MY PASSPORT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GameHUD.INK)
	var texture: Texture2D = GameCatalog.backdrop(country_id)
	drawn_backdrop = texture
	book.draw_texture_rect(texture, Rect2(20, 52, 132, 126), false)
	book.draw_string(font, Vector2(20, 207), GameCatalog.country_name(country_id), HORIZONTAL_ALIGNMENT_LEFT, 135, 16, GameHUD.INK)
	for index in 6:
		book.draw_line(Vector2(188, 45 + index * 27), Vector2(320, 45 + index * 27), Color("e8dcc2"), 1)
	if mark > 0:
		var ink := Color(ink_color, mark)
		book.draw_set_transform(Vector2(252, 122), -0.14, Vector2.ONE * lerpf(1.25, 1.0, mark))
		book.draw_arc(Vector2.ZERO, 62, 0, TAU, 48, ink, 4, true)
		book.draw_arc(Vector2.ZERO, 55, 0, TAU, 48, ink, 1, true)
		book.draw_string(font, Vector2(-47, -14), GameCatalog.stamp_code(country_id), HORIZONTAL_ALIGNMENT_CENTER, 94, 31, ink)
		book.draw_string(font, Vector2(-49, 17), "VISITED", HORIZONTAL_ALIGNMENT_CENTER, 98, 18, ink)
		book.draw_line(Vector2(-24, 32), Vector2(-8, 44), ink, 4, true)
		book.draw_line(Vector2(-8, 44), Vector2(25, 27), ink, 4, true)
		book.draw_set_transform(Vector2.ZERO)

func present(id: String, from: Vector2, reduced_motion: bool) -> void:
	cancel()
	if id not in GameCatalog.DESTINATIONS:
		finished.emit()
		return
	country_id = id
	active = true
	mark = 0
	book.show()
	var screen := get_viewport().get_visible_rect().size
	var fit: float = minf(1.0, (screen.x - 36) / 340)
	var target := (screen - Vector2(340, 230) * fit) / 2
	target.y = minf(target.y, 220)
	book.position = target if reduced_motion else from - Vector2(20, 25)
	book.scale = Vector2.ONE * (fit if reduced_motion else 0.12)
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(book, "position", target, 0.12 if reduced_motion else 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(book, "scale", Vector2.ONE * fit, 0.12 if reduced_motion else 0.45)
	tween.chain().tween_interval(0.2)
	tween.chain().tween_callback(func(): stamped.emit())
	tween.chain().tween_property(self, "mark", 1.0, 0.12)
	tween.chain().tween_interval(0.55)
	tween.chain().tween_callback(func():
		active = false
		book.hide()
		finished.emit()
	)

func set_paused(paused: bool) -> void:
	if not active:
		return
	book.visible = not paused
	if tween and tween.is_valid():
		if paused:
			tween.pause()
		else:
			tween.play()

func cancel() -> void:
	if tween and tween.is_valid():
		tween.kill()
	active = false
	if book:
		book.hide()
