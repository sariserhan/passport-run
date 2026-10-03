class_name JourneyReplay
extends VBoxContainer
var profile: PlayerProfile
var route_override: Array[String] = []
var route: Array[String] = []
var index := 0
var elapsed := 0.0
var playing := false
var speed := 1.0
var map: JourneyReplayMap
var heading: Label
var keepsake: SouvenirCard
var art: TravelArtwork
var toggle: Button
var seek: HSlider

func _ready() -> void:
 add_theme_constant_override("separation", 12)
 route = route_override.duplicate() if not route_override.is_empty() else profile.discoveries.duplicate()
 playing = not profile.settings.reduced_motion and route.size() > 1
 map = JourneyReplayMap.new()
 add_child(map)
 heading = Label.new()
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 heading.add_theme_font_size_override("font_size", 23)
 add_child(heading)
 art = TravelArtwork.new()
 art.custom_minimum_size.y = 180
 art.show_traveler = false
 add_child(art)
 seek = HSlider.new()
 seek.min_value = 0
 seek.max_value = maxi(0, route.size() - 1)
 seek.step = 1
 seek.custom_minimum_size.y = 48
 seek.editable = route.size() > 1
 seek.value_changed.connect(func(value): index = int(value); elapsed = 0; refresh())
 add_child(seek)
 var controls := HBoxContainer.new()
 add_child(controls)
 toggle = Button.new()
 toggle.custom_minimum_size.y = 54
 toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 toggle.pressed.connect(func():
  if index == route.size() - 1: index = 0; elapsed = 0; refresh()
  playing = not playing
  update_toggle()
 )
 controls.add_child(toggle)
 var pace := Button.new()
 pace.text = "SPEED · 1×"
 pace.custom_minimum_size.y = 54
 pace.pressed.connect(func(): speed = 2 if speed == 1 else 4 if speed == 2 else 1; pace.text = "SPEED · %d×" % speed)
 controls.add_child(pace)
 keepsake = SouvenirCard.new()
 add_child(keepsake)
 refresh()

func update_toggle() -> void:
 toggle.text = "PAUSE" if playing else "REPLAY" if index == route.size() - 1 else "PLAY"
 toggle.disabled = route.size() < 2

func refresh() -> void:
 if route.is_empty():
  heading.text = "Complete a destination to begin your replay."
  art.hide()
  keepsake.hide()
  update_toggle()
  return
 var id := route[index]
 map.route = route.slice(0, index + 1)
 map.discoveries = map.route.duplicate()
 map.current_country = id
 map.progress = 1 if profile.settings.reduced_motion else 0
 map.queue_redraw()
 heading.text = "STAMPED · %s · %d / %d" % [GameCatalog.country_name(id), index + 1, route.size()]
 art.country_id = id
 art.queue_redraw()
 if keepsake:
  remove_child(keepsake)
  keepsake.queue_free()
 keepsake = SouvenirCard.new()
 keepsake.destination_id = id
 keepsake.quantity = profile.souvenir_counts.get(id, 1)
 keepsake.rare_variants = profile.rare_keepsakes.get(id, [])
 add_child(keepsake)
 seek.set_value_no_signal(index)
 update_toggle()

func _process(delta: float) -> void:
 if not playing or route.is_empty(): return
 elapsed += delta * speed
 map.progress = 1 if profile.settings.reduced_motion else minf(1, elapsed / 1.2)
 map.queue_redraw()
 if elapsed >= 1.8:
  elapsed = 0
  if index + 1 < route.size(): index += 1; refresh()
  else: playing = false; update_toggle()
