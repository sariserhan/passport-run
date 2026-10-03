class_name BalloonArcade
extends Control

signal exited
const WORLD := Vector2(720, 600)
var floor_y := 570.0
var world_height := 600.0
var touches: Dictionary = {}
const PORTRAIT := preload("res://assets/backpacker-poses.png")
enum Phase { READY, PLAY, CLEAR, FAILED, PAUSED }
var phase := Phase.READY
var profile: PlayerProfile
var audio: GameAudio
var style: GameHUD
var route: Array[String] = []
var route_kind := "world"
var country_index := 0
var round_index := 0
var score := 0
var round_score := 0
var lives := 3
var remaining := 90.0
var player_x := 360.0
var invincible := 0.0
var cooldown := 0.0
var freeze := 0.0
var double_wire := 0.0
var shield := false
var country_failed := false
var left_held := false
var right_held := false
var fire_held := false
var pops := 0
var balls: Array[Dictionary] = []
var wires: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var platforms: Array[Rect2] = []
var backdrop: Texture2D
var panel: ColorRect
var heading: Label
var stats: Label
var controls: HBoxContainer
var pause_button: Button
var clock := 0.0

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 heading = style.label("", 24, GameHUD.CREAM)
 stats = style.label("", 17, GameHUD.CREAM)
 add_child(heading)
 add_child(stats)
 pause_button = style.button("Ⅱ", false)
 pause_button.pressed.connect(func(): set_paused(true))
 add_child(pause_button)
 controls = HBoxContainer.new()
 controls.add_theme_constant_override("separation", 10)
 add_child(controls)
 for text in ["◀", "▶", "FIRE ↑"]:
  var button := style.button(text, text == "FIRE ↑")
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.custom_minimum_size.y = 58
  controls.add_child(button)
  button.button_down.connect(func(): set_control(text, true))
  button.button_up.connect(func(): set_control(text, false))
 panel = ColorRect.new()
 panel.color = Color(0.04, 0.12, 0.18, 0.94)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(panel)
 resized.connect(layout)
 layout()
 load_destination()
 show_panel("BALLOON TOUR\nMove left/right. Fire upward.\nBig balloons split into smaller ones.\nClear three rounds to earn a stamp.", "START", begin_round)

func set_control(key: String, pressed: bool) -> void:
 if key == "◀": left_held = pressed
 elif key == "▶": right_held = pressed
 else: fire_held = pressed

func layout() -> void:
 var old_floor := floor_y
 var area := arena()
 world_height = area.size.y / maxf(1, area.size.x) * WORLD.x
 floor_y = world_height - 30
 var ratio := floor_y / old_floor
 for ball in balls:
  ball.position.y *= ratio
  ball.velocity.y *= sqrt(ratio)
 for wire in wires:
  wire.top *= ratio
  wire.bottom = floor_y
 for pickup in pickups: pickup.position.y *= ratio
 for index in platforms.size(): platforms[index].position.y *= ratio
 heading.position = Vector2(16, 15)
 heading.size.x = maxf(150, size.x - 85)
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stats.position = Vector2(16, 75)
 pause_button.position = Vector2(size.x - 66, 16)
 pause_button.size = Vector2(50, 50)
 controls.position = Vector2(16, size.y - 92)
 controls.size = Vector2(size.x - 32, 62)
 queue_redraw()

func arena() -> Rect2:
 return Rect2(12, 115, size.x - 24, maxf(180, size.y - 235))

func load_destination() -> void:
 backdrop = GameCatalog.backdrop(route[country_index])
 audio.play_destination(route[country_index])
 heading.text = GameCatalog.country_name(route[country_index]) + " · Round %d / 3" % (round_index + 1)

func show_panel(message: String, action_text: String, callback: Callable) -> void:
 left_held = false
 right_held = false
 fire_held = false
 touches.clear()
 for child in panel.get_children():
  panel.remove_child(child)
  child.queue_free()
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
 panel.add_child(margin)
 var box := VBoxContainer.new()
 box.alignment = BoxContainer.ALIGNMENT_CENTER
 box.add_theme_constant_override("separation", 10)
 margin.add_child(box)
 var label := style.label(message, 23, GameHUD.CREAM)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(label)
 var map := PassportWorldMap.new()
 map.discoveries = profile.discoveries.duplicate()
 map.route.assign(route.slice(maxi(0, country_index - 2), mini(route.size(), country_index + 6)))
 map.current_country = route[country_index]
 box.add_child(map)
 var button := style.button(action_text, true)
 button.pressed.connect(callback)
 box.add_child(button)
 var back := style.button("MAIN MENU", false)
 back.pressed.connect(exit_game)
 box.add_child(back)
 panel.show()
 queue_redraw()

func begin_round() -> void:
 if phase == Phase.FAILED: score = round_score
 else: round_score = score
 phase = Phase.PLAY
 panel.hide()
 load_destination()
 lives = 3
 remaining = 90.0
 player_x = 360
 invincible = 1.5
 shield = false
 freeze = 0
 double_wire = 0
 cooldown = 0
 balls.clear()
 wires.clear()
 pickups.clear()
 platforms.clear()
 pops = 0
 if round_index > 0: platforms.append(Rect2(250, floor_y * 0.5, 220, 18))
 var count := round_index + 1
 for index in count:
  balls.append(make_ball(Vector2(140 + index * 180, floor_y * 0.3), 2, -1 if index % 2 else 1))
 queue_redraw()

func make_ball(position_value: Vector2, tier: int, direction: int) -> Dictionary:
 var speed := (95.0 + country_index % 8 * 6 + round_index * 10) * (1.15 if profile.difficulty == "hard" else 0.85 if profile.difficulty == "easy" else 1.0)
 return {"position": position_value, "velocity": Vector2(direction * speed, -220.0), "tier": tier, "radius": [14.0, 27.0, 48.0][tier]}

func fire() -> bool:
 if phase != Phase.PLAY or cooldown > 0 or wires.size() >= (2 if double_wire > 0 else 1): return false
 wires.append({"x": player_x, "top": floor_y - 48, "bottom": floor_y, "age": 0.0})
 cooldown = 0.22
 audio.play_cue("jump")
 return true

func pop_ball(index: int) -> void:
 var ball: Dictionary = balls[index]
 balls.remove_at(index)
 score += (3 - int(ball.tier)) * 100
 pops += 1
 audio.play_cue("land")
 if int(ball.tier) > 0:
  for direction in [-1, 1]: balls.append(make_ball(ball.position, int(ball.tier) - 1, direction))
 if pops % 5 == 0:
  pickups.append({"position": ball.position, "kind": ["shield", "freeze", "double"][int(pops / 5 - 1) % 3], "age": 0.0})

func hit() -> void:
 if invincible > 0: return
 if shield: shield = false
 else:
  lives -= 1
  country_failed = true
 invincible = 2
 audio.play_cue("fall")
 if lives <= 0:
  phase = Phase.FAILED
  profile.record("balloon", profile.difficulty, score)
  show_panel("OUT OF LIVES\nScore %d · Try this round again" % score, "RETRY ROUND", begin_round)

func clear_round() -> void:
 if phase != Phase.PLAY: return
 phase = Phase.CLEAR
 score += int(remaining) * 10
 profile.record("balloon", profile.difficulty, score)
 if round_index == 2:
  profile.discover(route[country_index])
  profile.advance_missions(route[country_index], not country_failed, false)
  audio.play_cue("stamp")
 show_panel(("DESTINATION STAMPED!" if round_index == 2 else "ROUND CLEARED!") + "\n" + GameCatalog.country_name(route[country_index]) + " · Score %d" % score, "NEXT DESTINATION" if round_index == 2 else "NEXT ROUND", next_round)

func next_round() -> void:
 if round_index == 2:
  if country_index == route.size() - 1:
   exit_game()
   return
  country_index += 1
  country_failed = false
  round_index = 0
 else: round_index += 1
 begin_round()

func set_paused(value: bool) -> void:
 if value and phase == Phase.PLAY:
  phase = Phase.PAUSED
  audio.set_paused(true)
  show_panel("BALLOON TOUR PAUSED", "RESUME", func(): set_paused(false))
 elif not value and phase == Phase.PAUSED:
  phase = Phase.PLAY
  panel.hide()
  audio.set_paused(false)

func exit_game() -> void:
 profile.record("balloon", profile.difficulty, score)
 audio.set_paused(false)
 exited.emit()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  if is_instance_valid(panel): set_paused(true)

func _input(event: InputEvent) -> void:
 if phase != Phase.PLAY or not event is InputEventScreenTouch: return
 if event.pressed:
  if pause_button.get_global_rect().has_point(event.position):
   set_paused(true)
   get_viewport().set_input_as_handled()
   return
  for button in controls.get_children():
   if button.get_global_rect().has_point(event.position):
    touches[event.index] = button.text
    get_viewport().set_input_as_handled()
    return
 elif touches.has(event.index):
  var key: String = touches[event.index]
  touches.erase(event.index)
  if key not in touches.values(): set_control(key, false)
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  set_paused(phase != Phase.PAUSED)
  get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.physical_keycode == KEY_SPACE and event.pressed:
  fire()
  get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
 if phase != Phase.PLAY: return
 simulate(minf(delta, 1.0 / 30))

func simulate(delta: float) -> void:
 if phase != Phase.PLAY: return
 clock += delta
 remaining = maxf(0, remaining - delta)
 invincible = maxf(0, invincible - delta)
 cooldown = maxf(0, cooldown - delta)
 freeze = maxf(0, freeze - delta)
 double_wire = maxf(0, double_wire - delta)
 var movement := float(right_held or "▶" in touches.values()) - float(left_held or "◀" in touches.values()) + Input.get_axis("ui_left", "ui_right")
 if Input.is_physical_key_pressed(KEY_A): movement -= 1
 if Input.is_physical_key_pressed(KEY_D): movement += 1
 player_x = clampf(player_x + clampf(movement, -1, 1) * delta * 240, 26, WORLD.x - 26)
 if fire_held or "FIRE ↑" in touches.values() or Input.is_physical_key_pressed(KEY_SPACE): fire()
 if freeze <= 0:
  for ball in balls:
   var previous: Vector2 = ball.position
   ball.velocity.y += delta * 600
   ball.position += ball.velocity * delta
   var radius: float = ball.radius
   if ball.position.x < radius or ball.position.x > WORLD.x - radius:
    ball.position.x = clampf(ball.position.x, radius, WORLD.x - radius)
    ball.velocity.x *= -1
   if ball.position.y < radius:
    ball.position.y = radius
    ball.velocity.y = absf(ball.velocity.y)
   var floor_y := floor_y
   for platform in platforms:
    if ball.position.x + radius >= platform.position.x and ball.position.x - radius <= platform.end.x and previous.y + radius <= platform.position.y and ball.position.y + radius >= platform.position.y and ball.velocity.y > 0:
     floor_y = platform.position.y
   if ball.position.y + radius >= floor_y:
    ball.position.y = floor_y - radius
    ball.velocity.y = -[240.0, 390.0, 550.0][int(ball.tier)]
   var body := Rect2(player_x - 17, floor_y - 65, 34, 65)
   var nearest := Vector2(clampf(ball.position.x, body.position.x, body.end.x), clampf(ball.position.y, body.position.y, body.end.y))
   if nearest.distance_squared_to(ball.position) <= radius * radius: hit()
   if phase != Phase.PLAY: return
 for index in range(wires.size() - 1, -1, -1):
  var wire: Dictionary = wires[index]
  wire.top = maxf(0, wire.top - delta * 650)
  wire.age += delta
  for platform in platforms:
   if wire.x >= platform.position.x and wire.x <= platform.end.x and wire.top <= platform.end.y: wire.top = platform.end.y
  var popped := false
  for ball_index in range(balls.size() - 1, -1, -1):
   var ball: Dictionary = balls[ball_index]
   var closest := Vector2(wire.x, clampf(ball.position.y, wire.top, wire.bottom))
   if closest.distance_squared_to(ball.position) <= float(ball.radius) * float(ball.radius):
    pop_ball(ball_index)
    popped = true
    break
  if popped or wire.age > 1.5: wires.remove_at(index)
 for index in range(pickups.size() - 1, -1, -1):
  var pickup: Dictionary = pickups[index]
  pickup.age += delta
  pickup.position.y = minf(floor_y - 16, pickup.position.y + delta * 130)
  if absf(pickup.position.x - player_x) < 30 and pickup.position.y > floor_y - 75:
   if pickup.kind == "shield": shield = true
   elif pickup.kind == "freeze": freeze = 4
   else: double_wire = 12
   audio.play_cue("ui")
   pickups.remove_at(index)
  elif pickup.age > 12: pickups.remove_at(index)
 stats.text = "♥ %d   %ds   %d pts%s" % [lives, ceili(remaining), score, " · SHIELD" if shield else " · FREEZE" if freeze > 0 else " · DOUBLE" if double_wire > 0 else ""]
 if balls.is_empty(): clear_round()
 elif remaining <= 0:
  country_failed = true
  lives = 0
  phase = Phase.FAILED
  profile.record("balloon", profile.difficulty, score)
  show_panel("TIME UP · Score %d" % score, "RETRY ROUND", begin_round)
 queue_redraw()

func _draw() -> void:
 if not backdrop: return
 draw_texture_rect(backdrop, Rect2(Vector2.ZERO, size), false)
 draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 108)), Color(0.04, 0.15, 0.22, 0.85))
 var play := arena()
 draw_set_transform(play.position, 0, play.size / Vector2(WORLD.x, world_height))
 for platform in platforms:
  draw_style_box(style.panel_style(Color("a18a68"), 8), platform)
 draw_style_box(style.panel_style(Color("bba27c"), 8), Rect2(0, floor_y, WORLD.x, 30))
 for wire in wires:
  draw_line(Vector2(wire.x, wire.bottom), Vector2(wire.x, wire.top), Color("ffe5a1"), 4, true)
  draw_colored_polygon(PackedVector2Array([Vector2(wire.x, wire.top - 8), Vector2(wire.x - 7, wire.top + 5), Vector2(wire.x + 7, wire.top + 5)]), Color("fff5da"))
 for ball in balls:
  var color: Color = [Color("63d9f4"), Color("ffbf58"), Color("f57583")][int(ball.tier)]
  draw_circle(ball.position + Vector2(3, 5), ball.radius, Color(0, 0, 0, 0.24))
  draw_circle(ball.position, ball.radius, color)
  draw_arc(ball.position, ball.radius - 2, 0, TAU, 32, color.darkened(0.35), 3, true)
  draw_circle(ball.position - Vector2(ball.radius * 0.28, ball.radius * 0.3), ball.radius * 0.25, Color(1, 1, 1, 0.65))
 for pickup in pickups:
  draw_circle(pickup.position, 16, Color("97efac"))
  draw_string(ThemeDB.fallback_font, pickup.position + Vector2(-7, 6), {"shield": "S", "freeze": "F", "double": "2"}[pickup.kind], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("143e55"))
 var frame := 8 if phase == Phase.CLEAR else 12 if phase == Phase.FAILED else 0
 var cell := Vector2(PORTRAIT.get_size()) / 4
 var tint := Color(CharacterStyle.OUTFITS.get(profile.character_style.outfit, CharacterStyle.OUTFITS.classic).color)
 if invincible > 0 and int(clock * 8) % 2: tint.a = 0.35
 draw_texture_rect_region(PORTRAIT, Rect2(player_x - 42, floor_y - 92, 84, 96), Rect2(Vector2(frame % 4, frame / 4) * cell, cell), tint)
 if shield: draw_arc(Vector2(player_x, floor_y - 44), 52, 0, TAU, 40, Color("9eecff"), 3, true)
 draw_set_transform(Vector2.ZERO)
