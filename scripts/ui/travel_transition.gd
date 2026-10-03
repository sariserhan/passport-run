class_name TravelTransition
extends CanvasLayer

signal arrived
var profile: PlayerProfile
var buddy: BuddyPreview
var active := false
var root: ColorRect
var artwork: TravelArtwork
var flight: ProgressBar
var animation: Tween
var skip_button: Button
var margins: MarginContainer

func setup(style: GameHUD) -> void:
	layer = 4
	root = ColorRect.new()
	root.color = Color("153e57")
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	margins = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(margins)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stack.add_theme_constant_override("separation", 22)
	scroll.add_child(stack)
	var heading := style.label("WELCOME TO YOUR NEXT ADVENTURE", 20, Color("a6e771"))
	stack.add_child(heading)
	var destination := style.label("", 36, GameHUD.CREAM)
	destination.name = "Destination"
	destination.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(destination)
	artwork = TravelArtwork.new()
	artwork.custom_minimum_size.y = 220
	stack.add_child(artwork)
	buddy = BuddyPreview.new()
	buddy.custom_minimum_size.y = 130
	stack.add_child(buddy)
	var route := style.label("", 19, GameHUD.CREAM)
	route.name = "Route"
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(route)
	flight = ProgressBar.new()
	flight.custom_minimum_size.y = 12
	flight.max_value = 1
	flight.show_percentage = false
	flight.add_theme_stylebox_override("fill", style.panel_style(Color("a6e771"), 6))
	stack.add_child(flight)
	skip_button = style.button("LAND NOW", true)
	skip_button.pressed.connect(finish)
	stack.add_child(skip_button)
	root.resized.connect(func(): SafeAreaMargins.apply(margins, root.size, Vector4i(28, 48, 28, 38)))
	root.hide()

func begin(from: String, to: String, reduced_motion: bool, cinematic: bool = false, mystery: bool = false) -> void:
	cancel()
	active = true
	root.show()
	SafeAreaMargins.apply(margins, root.size, Vector4i(28, 48, 28, 38))
	if profile:
		artwork.weather = profile.activities.custom.weather
		artwork.time_of_day = profile.activities.custom.time
		buddy.weather = profile.activities.custom.weather
		buddy.kind = profile.travel_buddy if profile.travel_buddy in BuddyPersonality.FRIENDS else "bird"
		buddy.visible = profile.travel_buddy != "none"
		buddy.reduced_motion = reduced_motion
		buddy.elapsed = 7
	artwork.revealed = not mystery
	artwork.country_id = to
	artwork.show_traveler = not cinematic
	artwork.custom_minimum_size.y = 310 if cinematic else 220
	artwork.zoom = 1.0 if reduced_motion else 1.2 if cinematic else 1.0
	artwork.queue_redraw()
	root.find_child("Destination", true, false).text = "MYSTERY DESTINATION" if mystery else GameCatalog.country_name(to)
	root.find_child("Route", true, false).text = "Your next adventure is waiting…" if mystery else CountryRewards.fact(to) if cinematic else "%s → %s" % [GameCatalog.country_name(from), GameCatalog.country_name(to)]
	skip_button.text = "REVEAL NOW" if mystery else "LAND NOW"
	flight.value = 0
	skip_button.grab_focus.call_deferred()
	animation = create_tween()
	animation.tween_method(func(progress: float):
		flight.value = progress
		if mystery and progress >= 0.75 and not artwork.revealed:
			artwork.revealed = true
			root.find_child("Destination", true, false).text = GameCatalog.country_name(to)
			root.find_child("Route", true, false).text = "WELCOME · " + CountryRewards.fact(to)
			artwork.queue_redraw()
		if cinematic and not reduced_motion:
			artwork.zoom = lerpf(1.2, 1.0, progress)
			artwork.queue_redraw()
	, 0.0, 1.0, 0.15 if reduced_motion else 1.6 if mystery else 3.0 if cinematic else 2.0)
	animation.tween_callback(finish)

func finish() -> void:
	if not active:
		return
	cancel()
	arrived.emit()

func cancel() -> void:
	active = false
	if animation and animation.is_valid():
		animation.kill()
	if root:
		root.hide()

func set_paused(value: bool) -> void:
	if not active:
		return
	if value:
		animation.pause()
		root.hide()
	else:
		animation.play()
		root.show()
