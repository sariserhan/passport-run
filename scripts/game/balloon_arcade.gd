class_name BalloonArcade
extends Control

signal exited
const WORLD := Vector2(720, 600)
var floor_y := 570.0
var world_height := 600.0
var touches: Dictionary = {}
const PORTRAIT := preload("res://assets/arcade-poses.png")
const DROPS := ["double", "sticky", "gun", "triple", "spread", "laser", "rocket", "shield", "freeze", "slow", "boots", "heart", "time", "coin", "bomb", "magnet", "speed", "multiply", "heavy", "reverse", "jam", "shrink_time"]
const WEAPONS := ["double", "sticky", "gun", "triple", "spread", "laser", "rocket"]
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
var weapon := "wire"
var weapon_time := 0.0
var effects: Dictionary = {}
var rng := RandomNumberGenerator.new()
var notice: Label
var shot_time := 0.0
var hurt_time := 0.0
var death_time := 0.0
var death_reason := ""
var pause_from := Phase.PLAY
var movement := 0.0
var facing := 1.0
var walk_clock := 0.0
var combo := 0
var combo_time := 0.0
var particles: Array[Dictionary] = []
var coop := false
var partner_x := 430.0
var partner_down := false
var player_down := false
var revive_time := 0.0
var down_time := 0.0
var partner_shot := 0.0
var partner_grace := 0.0
var partner_slide := 0.0
var partner_movement := 0.0
var partner_walk := 0.0
var partner_controls: HBoxContainer
var partner_held: Dictionary = {}
var mechanic := "stone"
var slide_speed := 0.0
var challenge := ""
var round_elapsed := 0.0
var wave_clock := 0.0
var weapon_level := 1
var weapon_trait := ""
var accept_drops := true
var mystery_chain := 0
var margins := Vector4i(16, 16, 16, 26)

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 heading = style.label("", 24, GameHUD.CREAM)
 stats = style.label("", 17, GameHUD.CREAM)
 add_child(heading)
 add_child(stats)
 notice = style.label("Mystery drops can help—or hurt.", 14, GameHUD.CREAM)
 add_child(notice)
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
 partner_controls = HBoxContainer.new()
 partner_controls.add_theme_constant_override("separation", 10)
 add_child(partner_controls)
 for text in ["P2 ◀", "P2 ▶", "P2 FIRE"]:
  var button := style.button(text, text == "P2 FIRE")
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.custom_minimum_size.y = 58
  partner_controls.add_child(button)
  button.button_down.connect(func(): set_control(text, true))
  button.button_up.connect(func(): set_control(text, false))
 panel = ColorRect.new()
 panel.color = Color(0.04, 0.12, 0.18, 0.94)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(panel)
 resized.connect(layout)
 layout()
 load_destination()
 show_panel("BALLOON TOUR\nMove ◀ ▶ and FIRE ↑.\nSplit balloons; clear 3 rounds.\n? drops may help or hurt.", "START", begin_round)

func set_control(key: String, pressed: bool) -> void:
 if key == "◀": left_held = pressed
 elif key == "▶": right_held = pressed
 elif key == "FIRE ↑": fire_held = pressed
 elif key.begins_with("P2"):
  if pressed: partner_held[key] = true
  else: partner_held.erase(key)

func layout() -> void:
 margins = Vector4i(16, 16, 16, 26)
 if OS.has_feature("mobile"):
  margins = SafeAreaMargins.calculate(size, DisplayServer.screen_get_size(), DisplayServer.get_display_safe_area(), margins)
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
 heading.position = Vector2(margins.x, margins.y)
 heading.size.x = maxf(150, size.x - margins.x - margins.z - 66)
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 stats.position = Vector2(margins.x, margins.y + 56)
 notice.position = Vector2(margins.x, margins.y + 82)
 notice.size.x = size.x - margins.x - margins.z
 notice.clip_text = true
 pause_button.position = Vector2(size.x - margins.z - 50, margins.y)
 pause_button.size = Vector2(50, 50)
 partner_controls.visible = coop
 partner_controls.position = Vector2(margins.x, size.y - margins.w - 66)
 partner_controls.size = Vector2(size.x - margins.x - margins.z, 62)
 controls.position = Vector2(margins.x, size.y - margins.w - 66)
 controls.position.y -= 68 if coop else 0
 controls.size = Vector2(size.x - margins.x - margins.z, 62)
 queue_redraw()

func arena() -> Rect2:
 var top := margins.y + 112
 var height := maxf(140, size.y - top - margins.w - (162 if coop else 94))
 var width := minf(size.x - margins.x - margins.z, height * 2.1)
 return Rect2(margins.x + (size.x - margins.x - margins.z - width) / 2, top, width, height)

func load_destination() -> void:
 backdrop = GameCatalog.backdrop(route[country_index])
 audio.play_destination(route[country_index])
 heading.text = GameCatalog.country_name(route[country_index]) + " · Round %d / 3" % (round_index + 1)

func show_panel(message: String, action_text: String, callback: Callable) -> void:
 left_held = false
 right_held = false
 fire_held = false
 touches.clear()
 partner_held.clear()
 for child in panel.get_children():
  panel.remove_child(child)
  child.queue_free()
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
 panel.add_child(margin)
 var scroll := ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 margin.add_child(scroll)
 var box := VBoxContainer.new()
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 box.size_flags_vertical = Control.SIZE_EXPAND_FILL
 box.alignment = BoxContainer.ALIGNMENT_CENTER
 box.add_theme_constant_override("separation", 10)
 scroll.add_child(box)
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
 if phase == Phase.READY:
  var mode_button := style.button("LOCAL CO-OP" if not coop else "SOLO PLAY", false)
  mode_button.pressed.connect(func(): coop = not coop; layout(); show_panel("LOCAL CO-OP: P1 moves/fires · P2 J/L moves, K fires. Stay near a fallen partner to revive.\n" if coop else "SOLO BALLOON TOUR", "START", begin_round))
  box.add_child(mode_button)
 var drops_button := style.button("? DROPS: COLLECT" if accept_drops else "? DROPS: AVOID", false)
 drops_button.pressed.connect(func(): accept_drops = not accept_drops; drops_button.text = "? DROPS: COLLECT" if accept_drops else "? DROPS: AVOID")
 box.add_child(drops_button)
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
 remaining = 85.0 if profile.difficulty == "easy" else 80.0 if profile.difficulty == "moderate" else 75.0
 player_x = 280 if coop else 360
 partner_x = 440
 partner_down = false
 player_down = false
 partner_grace = 1.5
 partner_slide = 0
 partner_movement = 0
 partner_walk = 0
 revive_time = 0
 down_time = 0
 slide_speed = 0
 weapon_level = 1
 weapon_trait = ""
 mystery_chain = 0
 round_elapsed = 0
 wave_clock = 0
 mechanic = DestinationTheme.style(route[country_index])
 challenge = ["swarm", "no_fire", "flood"][country_index % 3] if round_index == 1 else ""
 if challenge != "": remaining = 25
 invincible = 1.5
 shield = false
 freeze = 0
 double_wire = 0
 cooldown = 0
 weapon = "wire"
 weapon_time = 0
 effects.clear()
 particles.clear()
 shot_time = 0
 hurt_time = 0
 death_time = 0
 movement = 0
 combo = 0
 combo_time = 0
 rng.seed = GameCatalog.daily_seed(route[country_index] + str(round_index), "arcade-drops-v1")
 notice.text = round_brief()
 balls.clear()
 wires.clear()
 pickups.clear()
 platforms.clear()
 pops = 0
 if round_index > 0: platforms.append(Rect2(250, floor_y * 0.5, 220, 18))
 var count := round_index + 1 + mini(2, country_index / 12)
 for index in count:
  balls.append(make_ball(Vector2(90 + index * 115, floor_y * 0.3), 2, -1 if index % 2 else 1))
 if round_index == 2:
  balls.clear()
  var boss := make_ball(Vector2(360, maxf(85, floor_y * 0.3)), 2, 1)
  boss.radius = 68.0
  boss.boss = true
  boss.hp = 5 if profile.difficulty == "easy" else 7 if profile.difficulty == "moderate" else 9
  boss.max_hp = boss.hp
  balls.append(boss)
 queue_redraw()

func round_brief() -> String:
 var rule: String = {"swarm": "SURVIVE THE SWARM · 25s", "no_fire": "DODGE ONLY · No firing · 25s", "flood": "RISING WATER · Clear before it floods"}.get(challenge, "ARMORED BOSS · Break armor, dodge its swarm" if round_index == 2 else "Mystery drops: collect or avoid them in Pause")
 return mechanic.to_upper() + " · " + rule

func make_ball(position_value: Vector2, tier: int, direction: int) -> Dictionary:
 var speed := (115.0 + mini(country_index, 20) * 4 + round_index * 15) * (1.25 if profile.difficulty == "hard" else 0.95 if profile.difficulty == "easy" else 1.1)
 return {"position": position_value, "velocity": Vector2(direction * speed, -220.0), "tier": tier, "radius": [14.0, 27.0, 48.0][tier]}

func fire(origin: float = -1) -> bool:
 var equipped := "double" if double_wire > 0 and weapon == "wire" else weapon
 var limit := 4 if equipped == "double" else 6 if equipped == "triple" else 10 if equipped in ["gun", "spread"] else 2 if equipped in ["sticky", "laser"] else 1
 var volley := 2 if equipped == "double" else 3 if equipped == "triple" else 5 if equipped == "spread" else 1
 if weapon_trait == "volley": volley += 1
 limit = maxi(limit, volley * 2) if weapon_level > 1 or weapon_trait == "volley" else limit
 if phase != Phase.PLAY or challenge == "no_fire" or (origin < 0 and player_down) or cooldown > 0 or effects.get("jam", 0) > 0 or wires.size() + volley > limit: return false
 for index in volley:
  var offset := (index - (volley - 1) / 2.0) * 24
  wires.append({"x": clampf((player_x if origin < 0 else origin) + offset, 8, WORLD.x - 8), "top": floor_y - 72, "bottom": floor_y, "age": 0.0, "kind": equipped, "vx": offset * 6 if equipped == "spread" else 0.0, "stuck": false, "hold": 0.0, "sticky": equipped == "sticky" or weapon_trait == "sticky", "pierce": equipped == "laser" or weapon_trait == "pierce", "blast": equipped == "rocket" or weapon_trait == "blast"})
 cooldown = 0.12 if equipped == "gun" else 0.6 if equipped in ["rocket", "laser"] else 0.28
 cooldown /= 1 + (weapon_level - 1) * 0.35 + (0.5 if weapon_trait == "rapid" else 0.0)
 if origin < 0: shot_time = 0.32
 else: partner_shot = 0.32
 audio.play_cue("jump")
 return true

func pop_ball(index: int) -> void:
 var ball: Dictionary = balls[index]
 if ball.get("boss", false):
  ball.hp -= 1
  burst(ball.position, Color("ffc75b"))
  if ball.hp > 0:
   if ball.hp == int(ball.max_hp) - 2 or ball.hp == int(ball.max_hp) / 2:
    ball.velocity.x *= -1.25
    for direction in [-1,1]: balls.append(make_ball(ball.position, 0, direction))
   notice.text = "BOSS ARMOR CRACKED · %d hits left" % ball.hp
   return
 balls.remove_at(index)
 combo = combo + 1 if combo_time > 0 else 1
 combo_time = 2.5
 score += (3 - int(ball.tier)) * 100 + mini(5, combo - 1) * 20
 burst(ball.position, Color("ffe8a4"))
 pops += 1
 audio.play_cue("land")
 if int(ball.tier) > 0 and not ball.get("boss", false):
  for direction in [-1, 1]: balls.append(make_ball(ball.position, int(ball.tier) - 1, direction))
 if pickups.size() < 10 and (pops % 3 == 0 or rng.randf() < 0.22):
  pickups.append({"position": ball.position, "kind": DROPS[rng.randi_range(0, DROPS.size() - 1)], "age": 0.0})

func burst(point: Vector2, color: Color) -> void:
 for index in 8:
  var angle := index * TAU / 8
  particles.append({"position": point, "velocity": Vector2(cos(angle), sin(angle)) * 90, "life": 0.45, "color": color})

func collect(kind: String) -> void:
 if kind in WEAPONS:
  if kind == weapon and weapon_time > 0: weapon_level = mini(3, weapon_level + 1)
  else:
   weapon_trait = {"double": "volley", "triple": "volley", "spread": "volley", "sticky": "sticky", "laser": "pierce", "rocket": "blast", "gun": "rapid"}.get(weapon, "") if weapon_time > 0 else ""
   weapon_level = 1
  weapon = kind
  weapon_time = 18
  double_wire = 0
  notice.text = kind.to_upper() + " Lv%d · %s · 18s" % [weapon_level, weapon_trait.to_upper()]
 elif kind == "shield": shield = true
 elif kind == "freeze": freeze = 4
 elif kind == "heart":
  if coop:
   if player_down or partner_down:
    player_down = false
    partner_down = false
    invincible = 3
    partner_grace = 3
   else: shield = true
  else: lives = mini(5, lives + 1)
 elif kind == "time": remaining = minf(110, remaining + 12)
 elif kind == "coin": score += 750
 elif kind == "shrink_time": remaining = maxf(1, remaining - 12)
 elif kind == "multiply":
  # ponytail: multiplication caps at 40; splitting can yield 160 descendants. Profile before raising it.
  var originals := balls.duplicate(true)
  for ball in originals:
   if balls.size() >= 40: break
   if ball.get("boss", false): continue
   var clone: Dictionary = ball.duplicate(true)
   clone.position.x = clampf(clone.position.x + 30, clone.radius, WORLD.x - clone.radius)
   clone.velocity.x *= -1
   balls.append(clone)
 elif kind == "bomb":
  for index in range(balls.size() - 1, -1, -1):
   var ball: Dictionary = balls[index]
   if int(ball.tier) > 0 and not ball.get("boss", false) and balls.size() < 38:
    balls.remove_at(index)
    for direction in [-1, 1]: balls.append(make_ball(ball.position, int(ball.tier) - 1, direction))
 else: effects[kind] = 8.0 if kind in ["speed", "heavy", "reverse"] else 3.0 if kind == "jam" else 10.0
 if kind not in WEAPONS:
  notice.text = {"shield": "SHIELD · One hit protected", "freeze": "FREEZE · 4s", "heart": "EXTRA HEART", "time": "+12 SECONDS", "coin": "+750 BONUS", "multiply": "SURPRISE! BALLOONS MULTIPLIED", "speed": "CURSE: FASTER BALLOONS · 8s", "heavy": "CURSE: HEAVY BOOTS · 8s", "reverse": "CURSE: REVERSED CONTROLS · 8s", "jam": "CURSE: WEAPON JAM · 3s", "shrink_time": "CURSE: −12 SECONDS", "slow": "SLOW BALLOONS · 10s", "boots": "QUICK BOOTS · 10s", "magnet": "MYSTERY MAGNET · 10s", "bomb": "BURST BOMB · Splits every big balloon"}.get(kind, kind.to_upper())
 notice.add_theme_color_override("font_color", Color("ffb0a3") if kind in ["multiply", "speed", "heavy", "reverse", "jam", "shrink_time"] else Color("b4ffd0"))
 audio.play_cue("ui")

func fail_round(reason: String) -> void:
 phase = Phase.FAILED
 death_time = 0.9
 death_reason = reason
 left_held = false
 right_held = false
 fire_held = false
 touches.clear()
 profile.record("balloon-coop" if coop else "balloon", profile.difficulty, score)
 queue_redraw()

func hit() -> void:
 if coop:
  if invincible <= 0 and not player_down:
   if shield: shield = false; invincible = 2; return
   player_down = true
   country_failed = true
   down_time = 15
   if partner_down: fail_round("BOTH EXPLORERS DOWN")
  return
 if invincible > 0: return
 if shield: shield = false
 else:
  lives -= 1
  country_failed = true
 invincible = 2
 hurt_time = 0.5
 combo = 0
 combo_time = 0
 audio.play_cue("fall")
 if lives <= 0: fail_round("OUT OF LIVES")

func clear_round() -> void:
 if phase != Phase.PLAY: return
 phase = Phase.CLEAR
 score += int(remaining) * 10
 profile.record("balloon-coop" if coop else "balloon", profile.difficulty, score)
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
 if value and (phase == Phase.PLAY or (phase == Phase.FAILED and death_time > 0)):
  pause_from = phase
  phase = Phase.PAUSED
  audio.set_paused(true)
  show_panel("BALLOON TOUR PAUSED", "RESUME", func(): set_paused(false))
 elif not value and phase == Phase.PAUSED:
  phase = pause_from
  panel.hide()
  audio.set_paused(false)

func exit_game() -> void:
 profile.record("balloon-coop" if coop else "balloon", profile.difficulty, score)
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
  for button in controls.get_children() + (partner_controls.get_children() if coop else []):
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
 if event is InputEventKey and event.physical_keycode == KEY_Q and event.pressed and not event.echo:
  accept_drops = not accept_drops
  notice.text = "? DROPS: COLLECT" if accept_drops else "? DROPS: AVOID"
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("ui_cancel"):
  set_paused(phase != Phase.PAUSED)
  get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.physical_keycode == KEY_SPACE and event.pressed:
  fire()
  get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
 if phase != Phase.PLAY and not (phase == Phase.FAILED and death_time > 0): return
 simulate(minf(delta, 1.0 / 30))

func simulate(delta: float) -> void:
 if phase == Phase.FAILED and death_time > 0:
  death_time = maxf(0, death_time - delta)
  queue_redraw()
  if death_time == 0: show_panel(death_reason + "\nScore %d · Try this round again" % score, "RETRY ROUND", begin_round)
  return
 if phase != Phase.PLAY: return
 clock += delta
 round_elapsed += delta
 partner_grace = maxf(0, partner_grace - delta)
 partner_shot = maxf(0, partner_shot - delta)
 shot_time = maxf(0, shot_time - delta)
 hurt_time = maxf(0, hurt_time - delta)
 combo_time = maxf(0, combo_time - delta)
 weapon_time = maxf(0, weapon_time - delta)
 if weapon_time == 0:
  weapon = "wire"
  weapon_level = 1
  weapon_trait = ""
 for key in effects.keys():
  effects[key] = maxf(0, effects[key] - delta)
  if effects[key] == 0: effects.erase(key)
 for index in range(particles.size() - 1, -1, -1):
  var particle: Dictionary = particles[index]
  particle.position += particle.velocity * delta
  particle.life -= delta
  if particle.life <= 0: particles.remove_at(index)
 remaining = maxf(0, remaining - delta)
 invincible = maxf(0, invincible - delta)
 cooldown = maxf(0, cooldown - delta)
 freeze = maxf(0, freeze - delta)
 double_wire = maxf(0, double_wire - delta)
 movement = float(right_held or "▶" in touches.values()) - float(left_held or "◀" in touches.values()) + Input.get_axis("ui_left", "ui_right")
 if Input.is_physical_key_pressed(KEY_A): movement -= 1
 if Input.is_physical_key_pressed(KEY_D): movement += 1
 if effects.get("reverse", 0) > 0: movement *= -1
 if movement != 0: facing = signf(movement)
 walk_clock += delta * absf(movement) * 10
 var move_speed := 330.0 if effects.get("boots", 0) > 0 else 150.0 if effects.get("heavy", 0) > 0 else 240.0
 if player_down:
  movement = 0
  slide_speed = 0
 var desired := clampf(movement, -1, 1) * move_speed
 slide_speed = move_toward(slide_speed, desired, delta * (260 if mechanic == "ice" else 4000))
 var wind := sin(clock * 1.7) * 32 if mechanic == "sand" else 0.0
 player_x = clampf(player_x + (slide_speed + (wind if not player_down else 0.0)) * delta, 26, WORLD.x - 26)
 if coop:
  var axis := float(Input.is_physical_key_pressed(KEY_L) or partner_held.has("P2 ▶") or "P2 ▶" in touches.values()) - float(Input.is_physical_key_pressed(KEY_J) or partner_held.has("P2 ◀") or "P2 ◀" in touches.values())
  if effects.get("reverse", 0) > 0: axis *= -1
  partner_movement = axis if not partner_down else 0.0
  partner_walk += delta * absf(partner_movement) * 10
  if not partner_down:
   partner_slide = move_toward(partner_slide, axis * move_speed, delta * (260 if mechanic == "ice" else 4000))
   partner_x = clampf(partner_x + (partner_slide + wind) * delta, 26, WORLD.x - 26)
   if Input.is_physical_key_pressed(KEY_K) or partner_held.has("P2 FIRE") or "P2 FIRE" in touches.values(): fire(partner_x)
  if player_down or partner_down:
   down_time -= delta
   revive_time = revive_time + delta if absf(partner_x - player_x) < 70 and player_down != partner_down else 0.0
   if revive_time >= 2:
    player_down = false
    partner_down = false
    invincible = 3
    partner_grace = 3
    revive_time = 0
    notice.text = "TEAMMATE REVIVED!"
   elif down_time <= 0: fail_round("REVIVE MISSED · Stay near your teammate")
  if phase != Phase.PLAY: return
 wave_clock += delta
 var enraged := balls.any(func(ball): return ball.get("boss", false) and ball.hp <= int(ball.max_hp) / 2)
 if (challenge in ["swarm", "no_fire"] or round_index == 2) and wave_clock >= (4.0 if challenge != "" else 3.0 if enraged else 6.0):
  wave_clock = 0
  for wave in (2 if enraged else 1):
   if balls.size() < 20: balls.append(make_ball(Vector2(rng.randf_range(40,680), 40), 0, 1 if rng.randf() > 0.5 else -1))
 if fire_held or "FIRE ↑" in touches.values() or Input.is_physical_key_pressed(KEY_SPACE): fire()
 if freeze <= 0:
  for ball in balls:
   var previous: Vector2 = ball.position
   ball.velocity.y += delta * (90 if route[country_index] == "MOON" else 160 if mechanic == "space" else 230 if mechanic == "ocean" else 600)
   if mechanic == "sand": ball.position.x += sin(clock * 1.7) * delta * 32
   ball.position += ball.velocity * delta * (1.65 if effects.get("speed", 0) > 0 else 0.65 if effects.get("slow", 0) > 0 else 1.0)
   var radius: float = ball.radius
   if ball.position.x < radius or ball.position.x > WORLD.x - radius:
    ball.position.x = clampf(ball.position.x, radius, WORLD.x - radius)
    ball.velocity.x *= -1
   if ball.position.y < radius:
    ball.position.y = radius
    ball.velocity.y = absf(ball.velocity.y)
   var bounce_floor := floor_y
   for platform in platforms:
    if ball.position.x + radius >= platform.position.x and ball.position.x - radius <= platform.end.x and previous.y + radius <= platform.position.y and ball.position.y + radius >= platform.position.y and ball.velocity.y > 0:
     bounce_floor = platform.position.y
   if ball.position.y + radius >= bounce_floor:
    ball.position.y = bounce_floor - radius
    ball.velocity.y = -[240.0, 390.0, 550.0][int(ball.tier)] * (0.45 if mechanic == "space" else 0.65 if mechanic == "ocean" else 1.0)
   var body := Rect2(player_x - 17, floor_y - 65, 34, 65)
   var nearest := Vector2(clampf(ball.position.x, body.position.x, body.end.x), clampf(ball.position.y, body.position.y, body.end.y))
   if nearest.distance_squared_to(ball.position) <= radius * radius: hit()
   if coop and not partner_down and partner_grace <= 0:
    var partner_body := Rect2(partner_x - 17, floor_y - 65, 34, 65)
    var partner_near := Vector2(clampf(ball.position.x, partner_body.position.x, partner_body.end.x), clampf(ball.position.y, partner_body.position.y, partner_body.end.y))
    if partner_near.distance_squared_to(ball.position) <= radius * radius:
     if shield:
      shield = false
      partner_grace = 2
     else:
      partner_down = true
      partner_slide = 0
      country_failed = true
      down_time = 15
      if player_down: fail_round("BOTH EXPLORERS DOWN")
   if phase != Phase.PLAY: return
 for index in range(wires.size() - 1, -1, -1):
  var wire: Dictionary = wires[index]
  var kind: String = wire.get("kind", "wire")
  var bullet := kind in ["gun", "spread", "rocket"]
  var previous_top: float = wire.top
  wire.x += float(wire.get("vx", 0)) * delta
  wire.age += delta
  var stop := 0.0
  for platform in platforms:
   if wire.x >= platform.position.x and wire.x <= platform.end.x and platform.end.y < wire.bottom: stop = maxf(stop, platform.end.y)
  if wire.get("stuck", false): wire.hold += delta
  else:
   wire.top = maxf(stop, wire.top - delta * (1700 if kind == "laser" else 1000))
   if wire.get("sticky", false) and wire.top <= stop:
    wire.stuck = true
    wire.hold = 0.0
  var collision_bottom: float = previous_top + 20 if bullet else wire.bottom
  var popped := false
  for ball_index in range(balls.size() - 1, -1, -1):
   var ball: Dictionary = balls[ball_index]
   var closest := Vector2(wire.x, clampf(ball.position.y, wire.top, collision_bottom))
   if closest.distance_squared_to(ball.position) <= pow(float(ball.radius) + (8 if kind == "laser" else 0), 2):
    if wire.get("blast", false):
     var center: Vector2 = ball.position
     burst(center, Color("ff9758"))
     for nearby in range(balls.size() - 1, -1, -1):
      if balls[nearby].position.distance_to(center) < 110: pop_ball(nearby)
    else: pop_ball(ball_index)
    popped = true
    break
  if bullet: wire.bottom = wire.top + 18
  var expired: bool = wire.x < 0 or wire.x > WORLD.x or (bullet and wire.top <= stop and not wire.get("sticky", false)) or wire.age > maxf(2.0, world_height / 1000 + 1.0)
  if wire.get("sticky", false) and wire.get("stuck", false): expired = wire.hold > 3.0
  if kind == "laser": expired = wire.age > 0.5
  if expired or (popped and not wire.get("sticky", false) and not wire.get("pierce", false)): wires.remove_at(index)
 for index in range(pickups.size() - 1, -1, -1):
  var pickup: Dictionary = pickups[index]
  pickup.age += delta
  pickup.position.y = minf(floor_y - 16, pickup.position.y + delta * 155)
  if effects.get("magnet", 0) > 0: pickup.position.x = move_toward(pickup.position.x, player_x, delta * 110)
  if accept_drops and ((not player_down and absf(pickup.position.x - player_x) < 30) or (coop and not partner_down and absf(pickup.position.x - partner_x) < 30)) and pickup.position.y > floor_y - 75:
   mystery_chain = 0 if pickup.kind in ["multiply", "speed", "heavy", "reverse", "jam", "shrink_time"] else mystery_chain + 1
   if mystery_chain > 0 and mystery_chain % 3 == 0: score += 500
   collect(pickup.kind)
   if mystery_chain > 0 and mystery_chain % 3 == 0: notice.text += " · LUCKY STREAK +500"
   pickups.remove_at(index)
  elif pickup.age > 12: pickups.remove_at(index)
 stats.text = "♥ %d   %ds   %d pts · %s%s" % [lives, ceili(remaining), score, weapon.to_upper(), " ×%d" % mini(6, combo) if combo > 1 and combo_time > 0 else ""]
 if coop: stats.text = "TEAM %d/2 · %ds · %d pts · %s" % [2 - int(player_down) - int(partner_down), ceili(remaining), score, weapon.to_upper()]
 stats.add_theme_font_size_override("font_size", 15)
 if challenge in ["swarm", "no_fire"]:
  if remaining <= 0: clear_round()
 elif balls.is_empty(): clear_round()
 elif remaining <= 0:
  country_failed = true
  lives = 0
  audio.play_cue("fall")
  fail_round("FLOODED!" if challenge == "flood" else "TIME UP")
 queue_redraw()

func _draw() -> void:
 if not backdrop: return
 draw_texture_rect(backdrop, Rect2(Vector2.ZERO, size), false)
 draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, arena().position.y - 4)), Color(0.04, 0.15, 0.22, 0.85))
 var play := arena()
 draw_set_transform(play.position, 0, play.size / Vector2(WORLD.x, world_height))
 for platform in platforms:
  draw_style_box(style.panel_style(Color("a18a68"), 8), platform)
 draw_style_box(style.panel_style(DestinationTheme.color(route[country_index]), 8), Rect2(0, floor_y, WORLD.x, 30))
 if mechanic == "sand":
  for index in 6:
   var x := fmod(index * 140 + clock * 55, WORLD.x)
   draw_line(Vector2(x, floor_y * 0.3 + index * 25),Vector2(x + 40, floor_y * 0.3 + index * 25),Color(1,0.9,0.65,0.35),2)
 for wire in wires:
  var kind: String = wire.get("kind", "wire")
  if kind in ["gun", "spread", "rocket"]:
   draw_style_box(style.panel_style(Color("ff9a5b") if kind == "rocket" else Color("fff2ab"), 4), Rect2(wire.x - 5, wire.top, 10, 20))
   draw_line(Vector2(wire.x, wire.top + 22), Vector2(wire.x, wire.top + 34), Color(1, 0.7, 0.25, 0.6), 3, true)
  else:
   draw_line(Vector2(wire.x, wire.bottom), Vector2(wire.x, wire.top), Color("9df7ef") if kind == "laser" else Color("ffe5a1"), 8 if kind == "laser" else 4, true)
   draw_colored_polygon(PackedVector2Array([Vector2(wire.x, wire.top - 8), Vector2(wire.x - 7, wire.top + 5), Vector2(wire.x + 7, wire.top + 5)]), Color("fff5da"))
 for ball in balls:
  var color: Color = [Color("63d9f4"), Color("ffbf58"), Color("f57583")][int(ball.tier)]
  draw_circle(ball.position + Vector2(3, 5), ball.radius, Color(0, 0, 0, 0.24))
  draw_circle(ball.position, ball.radius, color)
  draw_arc(ball.position, ball.radius - 2, 0, TAU, 32, color.darkened(0.35), 3, true)
  draw_circle(ball.position - Vector2(ball.radius * 0.28, ball.radius * 0.3), ball.radius * 0.25, Color(1, 1, 1, 0.65))
  if ball.get("boss", false):
   draw_arc(ball.position,ball.radius+5,0,TAU,40,Color("ffdd79"),6 if ball.hp > int(ball.max_hp)-2 else 2,true)
   draw_rect(Rect2(ball.position.x-45,ball.position.y-ball.radius-15,90,7),Color("193b52"))
   draw_rect(Rect2(ball.position.x-45,ball.position.y-ball.radius-15,90*float(ball.hp)/ball.max_hp,7),Color("ffdd79"))
 for pickup in pickups:
  draw_style_box(style.panel_style(Color("ffda79"), 7), Rect2(pickup.position - Vector2(19, 19), Vector2(38, 38)))
  draw_string(ThemeDB.fallback_font, pickup.position + Vector2(-7, 7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("143e55"))
 for particle in particles:
  var color: Color = particle.color
  color.a = maxf(0, particle.life / 0.45)
  draw_circle(particle.position, 3, color)
 if mechanic == "ocean":
  for index in 12:
   draw_arc(Vector2(fmod(index * 67.0 + clock * 8,720), floor_y - fmod(clock * 28 + index * 43, floor_y)), 6,0,TAU,16,Color(0.65,0.95,1,0.35),2)
 if challenge == "flood":
  var depth := minf(floor_y, round_elapsed / 25 * floor_y)
  draw_rect(Rect2(0,floor_y-depth,720,depth),Color(0.15,0.65,0.92,0.35))
 if coop:
  var teammate_frame := 15 if partner_down else 8 + mini(3,int((0.32-partner_shot)/0.32*4)) if partner_shot > 0 else int(partner_walk)%4 if partner_movement != 0 else 0
  var teammate_cell := Vector2(PORTRAIT.get_size()) / 4
  draw_texture_rect_region(PORTRAIT, Rect2(partner_x-52,floor_y-120,104,124),Rect2(Vector2(teammate_frame%4,teammate_frame/4)*teammate_cell,teammate_cell),Color("a4ddff"))
  draw_string(ThemeDB.fallback_font,Vector2(partner_x-14,floor_y-125),"P2",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("a4ddff"))
  draw_string(ThemeDB.fallback_font,Vector2(player_x-14,floor_y-125),"P1",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffdd79"))
  if player_down or partner_down:
   draw_string(ThemeDB.fallback_font,Vector2(160,floor_y-150),"REVIVE: stand together 2s · %ds" % ceili(down_time),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffdd79"))
 var frame := character_frame()
 var cell := Vector2(PORTRAIT.get_size()) / 4
 var tint := Color(CharacterStyle.OUTFITS.get(profile.character_style.outfit, CharacterStyle.OUTFITS.classic).color)
 if invincible > 0 and hurt_time <= 0 and phase == Phase.PLAY and int(clock * 8) % 2: tint.a = 0.45
 var bob := -absf(sin(walk_clock * PI)) * 4 if absf(movement) > 0 and phase == Phase.PLAY and not profile.settings.reduced_motion else 0.0
 var character := Rect2(player_x - 52, floor_y - 120 + bob, 104, 124)
 var source := Rect2(Vector2(frame % 4, frame / 4) * cell, cell)
 if facing < 0 and frame < 4:
  character.position.x += character.size.x
  character.size.x *= -1
 draw_texture_rect_region(PORTRAIT, character, source, tint)
 if shield: draw_arc(Vector2(player_x, floor_y - 44), 52, 0, TAU, 40, Color("9eecff"), 3, true)
 draw_set_transform(Vector2.ZERO)

func character_frame() -> int:
 if player_down: return 15
 if phase == Phase.FAILED and death_time > 0: return 12 + mini(3, int((0.9 - death_time) / 0.9 * 4))
 if hurt_time > 0: return 12 + mini(1, int((0.5 - hurt_time) * 4))
 if shot_time > 0:
  return (8 if weapon in ["gun", "spread", "laser", "rocket"] else 4) + mini(3, int((0.32 - shot_time) / 0.32 * 4))
 if absf(movement) > 0: return int(walk_clock) % 4
 return 0
