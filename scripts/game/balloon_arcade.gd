class_name BalloonArcade
extends Control

signal exited
const WORLD := Vector2(720, 600)
var floor_y := 570.0
var world_height := 600.0
var touches: Dictionary = {}
const EXPLORER := preload("res://assets/realistic/explorer.png")
const DROPS := ["double", "sticky", "gun", "triple", "spread", "laser", "rocket", "rapid", "freeze", "slow", "boots", "upgrade", "time", "coin", "bomb", "magnet", "speed", "multiply", "heavy", "reverse", "jam", "shrink_time"]
const WEAPONS := ["double", "sticky", "gun", "triple", "spread", "laser", "rocket"]
enum Phase { READY, PLAY, CLEAR, FAILED, PAUSED, TRAVEL, COUNTDOWN }
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
var lives := 1
var remaining := 90.0
var player_x := 360.0
var invincible := 0.0
var cooldown := 0.0
var freeze := 0.0
var double_wire := 0.0
var country_failed := false
var rare_earned := false
var buddy_clock := 0.0
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
var controls: Control
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
var visual_facing := 1.0
var partner_visual_facing := 1.0
var walk_clock := 0.0
var walk_speed := 0.0
var partner_walk_speed := 0.0
var partner_facing := 1.0
var combo := 0
var combo_time := 0.0
var particles: Array[Dictionary] = []
var coop := false
var partner_x := 430.0
var partner_shot := 0.0
var partner_slide := 0.0
var partner_movement := 0.0
var partner_walk := 0.0
var partner_controls: Control
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
var coins := 0
var round_coins := 0
var travel_choice := "safe"
var starting_freeze := false
var starting_time := false
var starting_weapon := "wire"
var daily_day := ""
var daily_modifier := ""
var team_charge := 0
var last_shooter := -1
var last_shot_at := -10.0
var partner_cooldown := 0.0
var shake := 0.0
var hit_flash := 0.0
var margins := Vector4i(16, 16, 16, 26)
var autosave_time := 0.0
var resumed := false
var finished_tour := false
var parcel: SouvenirParcel
var stamp: PassportStamp
var arrival: TravelTransition
var stamp_pending := false
var last_haptic := -1000
var quick_retry: Button
var countdown: ColorRect
var countdown_label: Label
var countdown_remaining := 0.0
var feedback: Label
var feedback_time := 0.0
var country_drops := 0
var earned_badges: Array[String] = []
var best_before := 0
var best_initialized := false
var best_beaten := false
var country_time := 0.0
var country_retries := 0
var country_combo := 0
var country_pops := 0
var country_start_score := 0
var progress_dirty := false

func record_difficulty() -> String:
 return "moderate" if route_kind == "daily" else profile.difficulty

func control_height() -> float:
 return 88.0 if profile.settings.arcade_large else 72.0

func destination_result() -> String:
 var medal := ArcadeProgress.medal(country_time, country_retries, country_combo)
 if country_time < 0: return "BRONZE MEDAL\nDestination totals unavailable for this older save.\nNew destinations track time, retries and combos."
 return "%s MEDAL%s\nClear time: %s · Retries: %d\nBest combo: ×%d · Balloons popped: %d\nDestination score: %d pts" % [ArcadeProgress.MEDALS[medal].to_upper(), " · PRACTICE" if route_kind == "practice" else "", "%d:%02d" % [int(country_time) / 60, int(country_time) % 60] if country_time >= 0 else "unavailable for older save", country_retries, country_combo, country_pops, maxi(0, score - country_start_score)]

func initialize_best() -> void:
 if best_initialized: return
 best_before = profile.best_score(record_mode(), "moderate" if route_kind == "daily" else profile.difficulty)
 best_initialized = true

func show_feedback(message: String) -> void:
 feedback.text = message
 feedback_time = 4.0
 feedback.show()

func update_personal_best() -> void:
 if not best_initialized or best_beaten or score <= best_before: return
 best_beaten = true
 if not feedback.visible or not feedback.text.begins_with("ACHIEVEMENT"):
  show_feedback("PERSONAL BEST! · %d pts" % score)
 pulse(30)

func retry_round() -> void:
 if phase != Phase.FAILED: return
 begin_round()

func clear_controls() -> void:
 left_held = false
 right_held = false
 fire_held = false
 touches.clear()
 partner_held.clear()
 update_control_feedback()

func checkpoint_key() -> String:
 return "daily:" + daily_day if route_kind == "daily" else route_kind

func save_checkpoint() -> void:
 if route_kind == "practice" or finished_tour or route.is_empty() or not is_instance_valid(panel): return
 var encoded := ArcadeCheckpoint.capture(self)
 if encoded.is_empty():
  notice.text = "Progress could not be saved. Try returning to the menu."
  return
 var keep_daily := "daily:" + (daily_day if route_kind == "daily" else GameCatalog.today_utc())
 for key in profile.arcade_saves.keys():
  if key.begins_with("daily:") and key != keep_daily: profile.arcade_saves.erase(key)
 profile.arcade_saves[checkpoint_key()] = encoded
 if not profile.save(): notice.text = profile.last_error
 autosave_time = 0

func restore_checkpoint() -> bool:
 if route_kind == "practice": return false
 var state := ArcadeCheckpoint.decode(profile.arcade_saves.get(checkpoint_key(), ""), self)
 if state.is_empty(): return false
 for field in ArcadeCheckpoint.FIELDS: set(field, state[field])
 profile.difficulty = state.difficulty if route_kind != "daily" else profile.difficulty
 layout()
 balls.assign(state.balls)
 wires.assign(state.wires)
 pickups.assign(state.pickups)
 platforms.assign(state.platforms)
 effects = state.effects
 rng.state = state.rng
 initialize_best()
 rescale_world(state.floor)
 resumed = true
 lives = 0 if state.phase == Phase.FAILED else 1
 load_destination()
 notice.text = round_brief()
 update_stats()
 if state.phase == Phase.PLAY:
  phase = Phase.PAUSED
  pause_from = Phase.PLAY
  audio.set_paused(true)
  show_panel("JOURNEY SAVED\n%s · Round %d/3\n%d pts · %d coins" % [GameCatalog.country_name(route[country_index]), round_index + 1, score, coins], "RESUME ROUND", func(): set_paused(false))
 elif state.phase == Phase.CLEAR:
  phase = Phase.CLEAR
  if state.supplies and round_index == 2 and country_index < route.size() - 1:
   panel.set_meta("travel", true)
   show_travel()
  else: show_clear_panel()
 elif state.phase == Phase.FAILED:
  phase = Phase.FAILED
  death_time = 0
  show_panel("GAME OVER\n%s · Round %d/3 · %d pts" % [GameCatalog.country_name(route[country_index]), round_index + 1, score], "RETRY ROUND", retry_round)
 else: phase = Phase.READY
 return true

func rescale_world(old_floor: float) -> void:
 var ratio := floor_y / old_floor
 for ball in balls:
  ball.position.y *= ratio
  ball.velocity.y *= sqrt(ratio)
 for wire in wires:
  wire.top *= ratio
  wire.bottom = floor_y
 for pickup in pickups: pickup.position.y *= ratio
 for index in platforms.size():
  platforms[index].position.y *= ratio
  platforms[index].size.y *= ratio

func pulse(duration: int = 20) -> void:
 if not profile.settings.haptics or not OS.has_feature("mobile"): return
 var now := Time.get_ticks_msec()
 if now - last_haptic < 100: return
 last_haptic = now
 Input.vibrate_handheld(duration, 0.35)

func record_mode() -> String:
 if route_kind == "practice": return "balloon-practice:" + route[0] + (":coop" if coop else "")
 return "balloon-daily:" + daily_day if route_kind == "daily" else "balloon-coop" if coop else "balloon"

static func daily_destination(day: String) -> String:
 var destinations: Array = GameCatalog.FREE_DESTINATIONS.keys()
 destinations.sort()
 return destinations[posmod(GameCatalog.daily_seed(day, "balloon-daily-v1"), destinations.size())]

func configure_daily(day: String) -> void:
 daily_day = day
 country_index = 0
 round_index = 0
 var seed_value := GameCatalog.daily_seed(day, "balloon-daily-v1")
 route.assign([daily_destination(day)])
 starting_weapon = WEAPONS[posmod(seed_value / 7, WEAPONS.size())]
 daily_modifier = ["zigzag", "armored", "timed", "dodge"][posmod(seed_value / 31, 4)]

func buy_upgrade(kind: String) -> bool:
 if phase != Phase.CLEAR or round_index != 2 or route_kind == "daily": return false
 var cost := 30 if kind == "time" else 25 if kind == "freeze" else 40
 if kind not in ["time", "freeze"] + WEAPONS or coins < cost or (kind == "time" and starting_time) or (kind == "freeze" and starting_freeze): return false
 coins -= cost
 if kind == "time": starting_time = true
 elif kind == "freeze": starting_freeze = true
 else: starting_weapon = kind
 update_stats()
 save_checkpoint()
 show_travel()
 return true

func show_travel() -> void:
 show_panel("TRAVEL SUPPLIES · %d coins\nYour next stop is a mystery.\nTime boost: +8s to clear, 8s shorter survival.\nSafe: 2s freeze, normal rewards.\nHard: faster armored balloons, double coins.\nSupplies apply to every following destination." % coins, "REVEAL NEXT STOP", next_round)
 var box := panel.get_child(0).get_child(0).get_child(0)
 var route_button := style.button("HARD CHALLENGE · DOUBLE COINS" if travel_choice == "safe" else "SAFE CHALLENGE · STARTING FREEZE", false)
 route_button.pressed.connect(func(): travel_choice = "detour" if travel_choice == "safe" else "safe"; save_checkpoint(); show_travel())
 box.add_child(route_button)
 box.move_child(route_button, 1)
 var shop_index := 2
 for kind in ["time", "freeze"] + WEAPONS:
  var cost := 30 if kind == "time" else 25 if kind == "freeze" else 40
  var label_text: String = "ROUND TIME BOOST" if kind == "time" else "2s STARTING FREEZE" if kind == "freeze" else kind.to_upper()
  var button := style.button("%s · %d COINS" % [label_text, cost], false)
  button.disabled = coins < cost or (kind == "time" and starting_time) or (kind == "freeze" and starting_freeze)
  button.pressed.connect(func(): buy_upgrade(kind))
  box.add_child(button)
  box.move_child(button, shop_index)
  shop_index += 1

func team_attack() -> void:
 team_charge = 0
 score += 300
 freeze = maxf(freeze, 1.5)
 for index in range(balls.size() - 1, -1, -1): pop_ball(index)
 notice.text = "TEAM BURST! +300 · Balloons frozen"
 audio.play_cue("team")

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 heading = style.label("", 20, GameHUD.CREAM)
 stats = style.label("", 17, GameHUD.CREAM)
 add_child(heading)
 add_child(stats)
 notice = style.label("Mystery drops can help—or hurt.", 13, GameHUD.CREAM)
 add_child(notice)
 pause_button = style.button("Ⅱ", false)
 pause_button.pressed.connect(func(): set_paused(true))
 add_child(pause_button)
 controls = Control.new()
 controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(controls)
 for text in ["◀", "▶", "FIRE ↑"]:
  var button := style.button(text, text == "FIRE ↑")
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.custom_minimum_size = Vector2(56, 72)
  button.add_theme_font_size_override("font_size", 20)
  button.set_meta("control_active", false)
  controls.add_child(button)
  button.button_down.connect(func(): set_control(text, true))
  button.button_up.connect(func(): set_control(text, false))
 partner_controls = Control.new()
 partner_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(partner_controls)
 for text in ["P2 ◀", "P2 ▶", "P2 FIRE"]:
  var button := style.button(text, text == "P2 FIRE")
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.custom_minimum_size = Vector2(56, 72)
  button.add_theme_font_size_override("font_size", 20)
  button.set_meta("control_active", false)
  partner_controls.add_child(button)
  button.button_down.connect(func(): set_control(text, true))
  button.button_up.connect(func(): set_control(text, false))
 panel = ColorRect.new()
 panel.color = Color(0.04, 0.12, 0.18, 0.94)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(panel)
 quick_retry = style.button("RETRY ROUND", true)
 quick_retry.pressed.connect(retry_round)
 quick_retry.hide()
 add_child(quick_retry)
 countdown = ColorRect.new()
 countdown.color = Color(0.03, 0.10, 0.16, 0.55)
 countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(countdown)
 countdown_label = style.label("3", 72, GameHUD.CREAM)
 countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 countdown.add_child(countdown_label)
 countdown.hide()
 feedback = style.label("", 18, Color("ffdf80"))
 feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 feedback.add_theme_color_override("font_shadow_color", Color("102c43"))
 feedback.add_theme_constant_override("shadow_offset_x", 2)
 feedback.add_theme_constant_override("shadow_offset_y", 2)
 add_child(feedback)
 feedback.hide()
 move_child(panel, get_child_count() - 1)
 parcel = SouvenirParcel.new()
 add_child(parcel)
 parcel.setup(style)
 stamp = PassportStamp.new()
 add_child(stamp)
 stamp.setup(style)
 stamp.layer = 7
 stamp.stamped.connect(func(): audio.play_cue("stamp"); pulse(35))
 stamp.finished.connect(finish_stamp)
 arrival = TravelTransition.new()
 add_child(arrival)
 arrival.profile = profile
 arrival.setup(style)
 arrival.layer = 7
 arrival.arrived.connect(finish_arrival)
 resized.connect(layout)
 layout()
 if restore_checkpoint() and phase != Phase.READY: return
 load_destination()
 show_panel(("PRACTICE · " + GameCatalog.country_name(route[0]) + "\nYour journey stays saved.\n" if route_kind == "practice" else "DAILY ARCADE · " + daily_day + "\n" + starting_weapon.to_upper() + " · " + daily_modifier.to_upper() + "\nBest today: %d pts\n" % int(profile.records.get(record_mode() + ":moderate", 0)) if route_kind == "daily" else "") + "BALLOON TOUR\nMove ◀ ▶ and FIRE ↑.\nSplit balloons; clear 3 rounds.\nOne balloon hit ends the game.\n? drops may help or hurt.", "START", begin_round)

func set_control(key: String, pressed: bool) -> void:
 if phase != Phase.PLAY and pressed: return
 if pressed: pulse()
 if key == "◀": left_held = pressed
 elif key == "▶": right_held = pressed
 elif key == "FIRE ↑": fire_held = pressed
 elif key.begins_with("P2"):
  if pressed: partner_held[key] = true
  else: partner_held.erase(key)
 update_control_feedback()

func update_control_feedback() -> void:
 if not is_instance_valid(controls): return
 var keyboard := {"◀": Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"), "▶": Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"), "FIRE ↑": Input.is_physical_key_pressed(KEY_SPACE), "P2 ◀": Input.is_physical_key_pressed(KEY_J), "P2 ▶": Input.is_physical_key_pressed(KEY_L), "P2 FIRE": Input.is_physical_key_pressed(KEY_K)}
 for button in controls.get_children() + partner_controls.get_children():
  var key: String = button.text
  var held := left_held if key == "◀" else right_held if key == "▶" else fire_held if key == "FIRE ↑" else partner_held.has(key)
  var active: bool = phase == Phase.PLAY and (held or key in touches.values() or keyboard.get(key, false))
  if button.get_meta("control_active", false) == active: continue
  button.set_meta("control_active", active)
  var color := Color("e8c68a") if active else Color("bfa477") if "FIRE" in key else Color("263a43")
  var surface := style.panel_style(color, 14)
  if active:
   surface.border_color = Color("fff6df")
   surface.set_border_width_all(3)
  for state in ["normal", "hover", "pressed"]: button.add_theme_stylebox_override(state, surface)
  button.add_theme_color_override("font_color", GameHUD.INK if active or "FIRE" in key else GameHUD.CREAM)

func layout() -> void:
 margins = Vector4i(16, 16, 16, 26)
 if OS.has_feature("mobile"):
  margins = SafeAreaMargins.calculate(size, DisplayServer.screen_get_size(), DisplayServer.get_display_safe_area(), margins)
 var old_floor := floor_y
 var area := arena()
 world_height = area.size.y / maxf(1, area.size.x) * WORLD.x
 floor_y = world_height - 30
 rescale_world(old_floor)
 heading.position = Vector2(margins.x, margins.y)
 heading.size.x = maxf(150, size.x - margins.x - margins.z - 66)
 heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 heading.clip_text = false
 stats.position = Vector2(margins.x, margins.y + 48)
 stats.size.x = size.x - margins.x - margins.z
 stats.clip_text = true
 notice.position = Vector2(margins.x, margins.y + 96)
 notice.size.x = size.x - margins.x - margins.z
 notice.clip_text = false
 notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 if landscape():
  # One header row (title | stats | notice) so the short landscape arena keeps its height.
  var row := size.x - margins.x - margins.z - 62
  heading.autowrap_mode = TextServer.AUTOWRAP_OFF
  heading.clip_text = true
  heading.size.x = row * 0.24
  stats.position = Vector2(margins.x + row * 0.24 + 12, margins.y)
  stats.size.x = row * 0.36
  notice.position = Vector2(margins.x + row * 0.6 + 24, margins.y)
  notice.size.x = row * 0.4 - 12
 pause_button.position = Vector2(size.x - margins.z - 50, margins.y)
 pause_button.size = Vector2(50, 50)
 partner_controls.visible = coop and phase != Phase.TRAVEL
 var button_height := control_height()
 partner_controls.position = Vector2(margins.x, size.y - margins.w - button_height)
 partner_controls.size = Vector2(size.x - margins.x - margins.z, button_height)
 controls.position = Vector2(margins.x, size.y - margins.w - button_height)
 controls.position.y -= button_height + 8 if coop else 0
 controls.size = Vector2(size.x - margins.x - margins.z, button_height)
 if coop_side_by_side():
  var row_width := (size.x - margins.x - margins.z - 16) / 2
  controls.position.y = partner_controls.position.y
  controls.size.x = row_width
  partner_controls.size.x = row_width
  partner_controls.position.x = controls.position.x + row_width + 16
 for row in [controls, partner_controls]:
  var gap := clampf(row.size.x * 0.08, 20, 42)
  var arrow_width: float = (row.size.x - gap - 8) / 4
  for index in 3:
   var button := row.get_child(index) as Button
   var positions := [0.0, arrow_width + 8, arrow_width * 2 + 8 + gap]
   if profile.settings.arcade_swap: positions = [arrow_width * 2 + gap, arrow_width * 3 + gap + 8, 0.0]
   button.position = Vector2(positions[index], 0)
   button.size = Vector2(arrow_width if index < 2 else arrow_width * 2, button_height)
 quick_retry.position = Vector2(margins.x, controls.position.y)
 quick_retry.size = Vector2(size.x - margins.x - margins.z, button_height)
 if landscape(): layout_edge_controls(button_height)
 countdown.position = area.position
 countdown.size = area.size
 feedback.position = area.position + Vector2(10, 10)
 feedback.size.x = area.size.x - 20
 queue_redraw()

# Landscape puts arrows/FIRE in side gutters so the arena can use the full height.
func layout_edge_controls(button_height: float) -> void:
 var gutter := edge_gutter()
 var top := margins.y + 60.0
 var height := size.y - margins.w - top
 var fire_height := button_height * (1.2 if coop else 1.6)
 var arrow_width := (gutter - 8) / 2
 controls.position = Vector2(margins.x, top)
 controls.size = Vector2(gutter if coop else size.x - margins.x - margins.z, height)
 partner_controls.position = Vector2(size.x - margins.z - gutter, top)
 partner_controls.size = Vector2(gutter, height)
 for row in [controls, partner_controls]:
  var arrows_x := 0.0
  var fire := Vector2(0, height - button_height - 8 - fire_height)
  if not coop:
   var far: float = row.size.x - gutter
   arrows_x = far if profile.settings.arcade_swap else 0.0
   fire = Vector2(0.0 if profile.settings.arcade_swap else far, height - fire_height)
  (row.get_child(0) as Button).position = Vector2(arrows_x, height - button_height)
  (row.get_child(1) as Button).position = Vector2(arrows_x + arrow_width + 8, height - button_height)
  (row.get_child(2) as Button).position = fire
  for index in 2: (row.get_child(index) as Button).size = Vector2(arrow_width, button_height)
  (row.get_child(2) as Button).size = Vector2(gutter, fire_height)
 var retry_width := minf(320, size.x - margins.x - margins.z - gutter * 2 - 24)
 quick_retry.position = Vector2((size.x - retry_width) / 2, size.y - margins.w - button_height)
 quick_retry.size = Vector2(retry_width, button_height)

func edge_gutter() -> float:
 return clampf(size.x * 0.17, 150, 230)

func arena() -> Rect2:
 var top := margins.y + (60 if landscape() else 140)
 if landscape():
  var tall := maxf(90, size.y - top - margins.w)
  var wide := minf(size.x - margins.x - margins.z - (edge_gutter() + 12) * 2, tall * 2.1)
  return Rect2((size.x - wide) / 2, top, wide, tall)
 var height := maxf(90, size.y - top - margins.w - ((control_height() + 8) * 2 + 24 if coop and not coop_side_by_side() else control_height() + 32))
 var width := minf(size.x - margins.x - margins.z, height * 2.1)
 return Rect2(margins.x + (size.x - margins.x - margins.z - width) / 2, top, width, height)

func landscape() -> bool:
 return size.x > size.y

func coop_side_by_side() -> bool:
 return coop and size.x >= 650 and size.x > size.y

func load_destination() -> void:
 backdrop = GameCatalog.backdrop(route[country_index])
 audio.play_destination(route[country_index])
 heading.text = ("DAILY · " if route_kind == "daily" else "") + GameCatalog.country_name(route[country_index]) + " · %d/3" % (round_index + 1)

func show_panel(message: String, action_text: String, callback: Callable) -> void:
 clear_controls()
 quick_retry.hide()
 for child in panel.get_children():
  panel.remove_child(child)
  child.queue_free()
 var margin := MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
 panel.add_child(margin)
 var scroll := TouchScroll.new()
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
 if phase == Phase.CLEAR and round_index == 2 and "MEDAL" in message:
  var medal_image := TextureRect.new()
  medal_image.texture = RealisticArt.medal(ArcadeProgress.medal(country_time, country_retries, country_combo))
  medal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  medal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  medal_image.custom_minimum_size = Vector2(120, 120)
  medal_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
  box.add_child(medal_image)
 var map := PassportWorldMap.new()
 map.discoveries = profile.discoveries.duplicate()
 map.route.assign(route.slice(maxi(0, country_index - 2), country_index + 1))
 map.current_country = route[country_index]
 box.add_child(map)
 var button := style.button(action_text, true)
 button.pressed.connect(callback)
 box.add_child(button)
 if phase == Phase.READY and route_kind != "daily":
  var mode_button := style.button("LOCAL CO-OP" if not coop else "SOLO PLAY", false)
  mode_button.pressed.connect(func(): coop = not coop; layout(); show_panel("LOCAL CO-OP: P1 moves/fires · P2 J/L moves, K fires. Fire together four times to charge TEAM BURST. One balloon hit ends the game for both players.\n" if coop else "SOLO BALLOON TOUR", "START", begin_round))
  box.add_child(mode_button)
 var drops_button := style.button("? DROPS: COLLECT" if accept_drops else "? DROPS: AVOID", false)
 drops_button.pressed.connect(func(): accept_drops = not accept_drops; drops_button.text = "? DROPS: COLLECT" if accept_drops else "? DROPS: AVOID")
 box.add_child(drops_button)
 if phase == Phase.PAUSED or phase == Phase.READY:
  var swap_button := style.button("FIRE BUTTON: LEFT" if profile.settings.arcade_swap else "FIRE BUTTON: RIGHT", false)
  swap_button.pressed.connect(func(): profile.settings.arcade_swap = not profile.settings.arcade_swap; profile.save(); layout(); swap_button.text = "FIRE BUTTON: LEFT" if profile.settings.arcade_swap else "FIRE BUTTON: RIGHT")
  box.add_child(swap_button)
  var size_button := style.button("CONTROLS: LARGE" if profile.settings.arcade_large else "CONTROLS: STANDARD", false)
  size_button.pressed.connect(func(): profile.settings.arcade_large = not profile.settings.arcade_large; profile.save(); layout(); size_button.text = "CONTROLS: LARGE" if profile.settings.arcade_large else "CONTROLS: STANDARD")
  box.add_child(size_button)
 var back := style.button("MAIN MENU", false)
 back.pressed.connect(exit_game)
 box.add_child(back)
 panel.show()
 queue_redraw()

func tour_pressure() -> float:
 # Smooth escalation keeps every later destination faster, with a playable ceiling.
 return 0.0 if route_kind == "daily" else float(country_index) / (country_index + 25.0)

func wave_interval(enraged: bool) -> float:
 var base := 4.0 if challenge != "" else 3.0 if enraged else 6.0
 return base * (1.0 - tour_pressure() * 0.5)

func begin_round() -> void:
 if phase == Phase.FAILED:
  best_initialized = false
  best_beaten = false
 initialize_best()
 if phase == Phase.FAILED:
  score = round_score
  coins = round_coins
 else:
  round_score = score
  round_coins = coins
 phase = Phase.PLAY
 quick_retry.hide()
 countdown.hide()
 feedback.hide()
 feedback_time = 0
 clear_controls()
 panel.hide()
 load_destination()
 lives = 1
 remaining = 80.0 if route_kind == "daily" else 85.0 if profile.difficulty == "easy" else 80.0 if profile.difficulty == "moderate" else 75.0
 remaining -= tour_pressure() * 20
 player_x = 280 if coop else 360
 partner_x = 440
 partner_slide = 0
 partner_movement = 0
 partner_walk = 0
 walk_clock = 0
 walk_speed = 0
 partner_walk_speed = 0
 partner_facing = 1
 facing = 1
 visual_facing = 1
 partner_visual_facing = 1
 slide_speed = 0
 weapon_level = 1
 weapon_trait = ""
 mystery_chain = 0
 round_elapsed = 0
 wave_clock = 0
 mechanic = DestinationTheme.style(route[country_index])
 challenge = ["swarm", "no_fire", "flood"][country_index % 3] if round_index == 1 else ""
 if challenge != "": remaining = 25
 invincible = 0
 freeze = 2.0 if starting_freeze or (country_index > 0 and travel_choice == "safe" and route_kind != "daily") else 0.0
 if starting_time: boost_time(8)
 double_wire = 0
 cooldown = 0
 weapon = starting_weapon
 weapon_time = 18.0 if weapon != "wire" else 0.0
 partner_cooldown = 0
 team_charge = 0
 last_shooter = -1
 last_shot_at = -10
 shake = 0
 hit_flash = 0
 effects.clear()
 particles.clear()
 shot_time = 0
 hurt_time = 0
 death_time = 0
 movement = 0
 combo = 0
 combo_time = 0
 rng.seed = GameCatalog.daily_seed(daily_day + route[country_index] + str(round_index), "arcade-drops-v1")
 notice.text = round_brief()
 balls.clear()
 wires.clear()
 pickups.clear()
 platforms.clear()
 pops = 0
 if round_index > 0: platforms.append(Rect2(250, floor_y * 0.5, 220, 18))
 var count := round_index + 1 + (0 if route_kind == "daily" else mini(5, country_index / 4))
 for index in count:
  balls.append(make_ball(Vector2(60 + (index + 0.5) * 600.0 / count, floor_y * (0.22 + index % 2 * 0.12)), 2, -1 if index % 2 else 1, ["normal", "zigzag", "armored", "timed", "dodge"][posmod(country_index + round_index + index, 5)]))
 if round_index == 2:
  balls.clear()
  var boss := make_ball(Vector2(360, maxf(85, floor_y * 0.3)), 2, 1)
  boss.radius = 68.0
  boss.boss = true
  boss.hp = 7 if route_kind == "daily" else 5 if profile.difficulty == "easy" else 7 if profile.difficulty == "moderate" else 9
  boss.hp += 0 if route_kind == "daily" else mini(12, country_index / 3)
  boss.max_hp = boss.hp
  boss.pattern = ["charge", "bounce", "summoner"][posmod(GameCatalog.daily_seed(daily_day, "arcade-boss") if route_kind == "daily" else country_index, 3)]
  boss.base_speed = absf(boss.velocity.x)
  boss.dash_time = 0.0
  boss.bounce_pending = false
  balls.append(boss)
 save_checkpoint()
 update_stats()
 queue_redraw()

func round_brief() -> String:
 var boss_rule: String = {"charge": "SWEEP BOSS · Watch the charge arrow", "bounce": "BOUNCE BOSS · Watch for high jumps", "summoner": "SWARM BOSS · Clear its minions"}[["charge", "bounce", "summoner"][posmod(GameCatalog.daily_seed(daily_day, "arcade-boss") if route_kind == "daily" else country_index, 3)]]
 var rule: String = {"swarm": "SURVIVE THE SWARM · 25s", "no_fire": "DODGE ONLY · No firing · 25s", "flood": "RISING WATER · Clear before it floods"}.get(challenge, boss_rule if round_index == 2 else "Mystery drops · Collect / avoid in Pause")
 return ("DAILY " + daily_modifier.to_upper() + " · " if route_kind == "daily" else "LEVEL %d · " % (country_index * 3 + round_index + 1)) + mechanic.to_upper() + "\n" + rule

func make_ball(position_value: Vector2, tier: int, direction: int, behavior_value: String = "normal") -> Dictionary:
 var speed := (115.0 + tour_pressure() * 150 + round_index * 15) * (1.1 if route_kind == "daily" else 1.25 if profile.difficulty == "hard" else 0.95 if profile.difficulty == "easy" else 1.1)
 var behavior: String = daily_modifier if route_kind == "daily" else behavior_value
 if travel_choice == "detour" and country_index > 0:
  speed *= 1.25
  if tier > 0: behavior = "armored"
 return {"behavior": behavior, "armor": 2 if behavior == "armored" else 1, "age": 0.0, "flash": 0.0, "position": position_value, "velocity": Vector2(direction * speed, -220.0), "tier": tier, "radius": [14.0, 27.0, 48.0][tier]}

func fire(origin: float = -1) -> bool:
 var equipped := "double" if double_wire > 0 and weapon == "wire" else weapon
 var limit := 4 if equipped == "double" else 6 if equipped == "triple" else 10 if equipped in ["gun", "spread"] else 2 if equipped in ["sticky", "laser"] else 1
 var volley := 2 if equipped == "double" else 3 if equipped == "triple" else 5 if equipped == "spread" else 1
 if weapon_trait == "volley": volley += 1
 limit = maxi(limit, volley * 2) if weapon_level > 1 or weapon_trait == "volley" else limit
 if coop: limit *= 2
 if phase != Phase.PLAY or challenge == "no_fire" or (cooldown if origin < 0 else partner_cooldown) > 0 or effects.get("jam", 0) > 0 or wires.size() + volley > limit: return false
 for index in volley:
  var offset := (index - (volley - 1) / 2.0) * 24
  wires.append({"x": clampf((player_x if origin < 0 else origin) + offset, 8, WORLD.x - 8), "top": floor_y - 72, "bottom": floor_y, "age": 0.0, "kind": equipped, "vx": offset * 6 if equipped == "spread" else 0.0, "stuck": false, "hold": 0.0, "sticky": equipped == "sticky" or weapon_trait == "sticky", "pierce": equipped == "laser" or weapon_trait == "pierce", "blast": equipped == "rocket" or weapon_trait == "blast"})
 var shot_cooldown := 0.12 if equipped == "gun" else 0.6 if equipped in ["rocket", "laser"] else 0.28
 shot_cooldown /= 1 + (weapon_level - 1) * 0.35 + (0.5 if weapon_trait == "rapid" else 0.0) + (0.5 if effects.get("rapid", 0) > 0 else 0.0)
 if origin < 0:
  shot_time = 0.32
  cooldown = shot_cooldown
 else:
  partner_shot = 0.32
  partner_cooldown = shot_cooldown
 var special_fired := false
 if coop:
  var shooter := 0 if origin < 0 else 1
  if last_shooter != -1 and shooter != last_shooter and clock - last_shot_at <= 0.25:
   team_charge += 1
   last_shooter = -1
   if team_charge >= 4:
    team_attack()
    special_fired = true
  else:
   last_shooter = shooter
   last_shot_at = clock
 audio.play_cue("team" if special_fired else "shot_" + equipped)
 return true

func queue_boss_attack(boss: Dictionary, charge: bool, minions: int, bounce: bool = false) -> void:
 boss.warning = 0.85
 boss.charge_pending = boss.get("charge_pending", false) or charge
 boss.minions_pending = mini(4, int(boss.get("minions_pending", 0)) + minions)
 boss.bounce_pending = boss.get("bounce_pending", false) or bounce

func queue_boss_pattern(boss: Dictionary, cracked: bool = false, enraged: bool = false) -> void:
 var pattern: String = boss.get("pattern", "charge")
 queue_boss_attack(boss, pattern == "charge", 4 if pattern == "summoner" and cracked else 3 if pattern == "summoner" else 2 if cracked or enraged else 1, pattern == "bounce")

func boss_minion_position(boss: Dictionary, index: int) -> Vector2:
 var direction := -1 if index % 2 == 0 else 1
 var band := index / 2
 return Vector2(clampf(boss.position.x + direction * (44 + band * 36), 20, 700), clampf(minf(boss.position.y, floor_y - 160) - band * 32, 20, maxf(20, floor_y - 160)))

func update_boss_attacks(delta: float) -> void:
 for boss in balls:
  if not boss.get("boss", false) or boss.get("warning", 0.0) <= 0: continue
  boss.warning = maxf(0, boss.warning - delta)
  if boss.warning > 0: continue
  if boss.get("charge_pending", false):
   boss.velocity.x = clampf(-boss.velocity.x * 1.25, -520, 520)
   boss.dash_time = 0.65
  if boss.get("bounce_pending", false): boss.velocity.y = -minf(650, sqrt(maxf(100, floor_y) * 600))
  for index in int(boss.get("minions_pending", 0)):
   if balls.size() >= 20: break
   var direction := -1 if index % 2 == 0 else 1
   var spawn := boss_minion_position(boss, index)
   balls.append(make_ball(spawn, 0, direction, "dodge" if boss.get("pattern", "") == "summoner" else "normal"))
  boss.charge_pending = false
  boss.bounce_pending = false
  boss.minions_pending = 0
  audio.play_cue("armor")

func pop_ball(index: int) -> void:
 var ball: Dictionary = balls[index]
 ball.flash = 0.18
 shake = maxf(shake, 0.12)
 if not ball.get("boss", false) and int(ball.get("armor", 1)) > 1:
  ball.armor -= 1
  burst(ball.position, Color("a4ddff"))
  notice.text = "ARMOR BROKEN!"
  audio.play_cue("armor")
  return
 if ball.get("boss", false):
  ball.hp -= 1
  burst(ball.position, Color("ffc75b"))
  if ball.hp > 0:
   if ball.hp == int(ball.max_hp) - 2 or ball.hp == int(ball.max_hp) / 2:
    queue_boss_pattern(ball, true)
   notice.text = "BOSS ARMOR CRACKED · %d hits left" % ball.hp
   return
 balls.remove_at(index)
 combo = combo + 1 if combo_time > 0 else 1
 combo_time = 2.5
 country_combo = maxi(country_combo, combo)
 score += (3 - int(ball.tier)) * 100 + mini(5, combo - 1) * 20
 burst(ball.position, Color("ffe8a4"))
 pops += 1
 country_pops += 1
 var pop_badge := route_kind != "practice" and profile.note_arcade_pop()
 var daily_goal := false
 if route_kind != "practice":
  daily_goal = profile.note_arcade_goal("pops")
  if ball.get("boss", false): daily_goal = profile.note_arcade_goal("bosses") or daily_goal
 if pop_badge:
  show_feedback("ACHIEVEMENT · 100 Pops\nSky Balloon outfit unlocked")
 elif daily_goal: show_feedback("DAILY GOAL COMPLETE!\nSee Balloon daily goals")
 coins += 2 if travel_choice == "detour" and country_index > 0 else 1
 audio.play_cue("burst")
 if int(ball.tier) > 0 and not ball.get("boss", false):
  for direction in [-1, 1]: balls.append(make_ball(ball.position, int(ball.tier) - 1, direction))
 if pickups.size() < 10 and (pops % 3 == 0 or rng.randf() < 0.22):
  pickups.append({"position": ball.position, "kind": DROPS[rng.randi_range(0, DROPS.size() - 1)], "age": 0.0})
 if pop_badge or daily_goal: save_checkpoint()

func burst(point: Vector2, color: Color) -> void:
 for index in 18:
  var angle := index * TAU / 18
  particles.append({"position": point, "velocity": Vector2(cos(angle), sin(angle)) * (130 + index % 3 * 45), "life": 0.45, "color": color})

func collect(kind: String) -> void:
 if kind not in DROPS: return
 if route_kind != "practice" and profile.discover_arcade_drop(kind): progress_dirty = true
 if country_drops >= 0: country_drops += 1
 if kind in WEAPONS:
  if kind == weapon and weapon_time > 0: weapon_level = mini(3, weapon_level + 1)
  else:
   weapon_trait = {"double": "volley", "triple": "volley", "spread": "volley", "sticky": "sticky", "laser": "pierce", "rocket": "blast", "gun": "rapid"}.get(weapon, "") if weapon_time > 0 else ""
   weapon_level = 1
  weapon = kind
  weapon_time = 18
  double_wire = 0
  notice.text = kind.to_upper() + " Lv%d · %s · 18s" % [weapon_level, weapon_trait.to_upper()]
 elif kind == "freeze": freeze = 4
 elif kind == "rapid": effects["rapid"] = 8.0
 elif kind == "upgrade":
  if weapon == "wire": weapon = "double"
  else: weapon_level = mini(3, weapon_level + 1)
  weapon_time = 18
 elif kind == "time": boost_time(12)
 elif kind == "coin":
  score += 750
  coins += 15
 elif kind == "shrink_time": boost_time(-12)
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
  notice.text = {"rapid": "RAPID FIRE · 8s", "freeze": "FREEZE · 4s", "upgrade": "WEAPON UPGRADE · 18s", "time": "TIME BOOST", "coin": "+15 COINS · +750 BONUS", "multiply": "SURPRISE! BALLOONS MULTIPLIED", "speed": "CURSE: FASTER BALLOONS · 8s", "heavy": "CURSE: HEAVY BOOTS · 8s", "reverse": "CURSE: REVERSED CONTROLS · 8s", "jam": "CURSE: WEAPON JAM · 3s", "shrink_time": "CURSE: TIME PRESSURE", "slow": "SLOW BALLOONS · 10s", "boots": "QUICK BOOTS · 10s", "magnet": "MYSTERY MAGNET · 10s", "bomb": "BURST BOMB · Splits every big balloon"}.get(kind, kind.to_upper())
 notice.add_theme_color_override("font_color", Color("ffb0a3") if kind in ["multiply", "speed", "heavy", "reverse", "jam", "shrink_time"] else Color("b4ffd0"))
 audio.play_cue("ui")

func boost_time(seconds: float) -> void:
 # Survival rewards shorten the wait; clear-round rewards extend the deadline.
 remaining = clampf(remaining + (-seconds if challenge in ["swarm", "no_fire"] else seconds), 1, 110)

func fail_round(reason: String) -> void:
 phase = Phase.FAILED
 country_failed = true
 country_retries += 1
 movement = 0
 partner_movement = 0
 walk_speed = 0
 partner_walk_speed = 0
 death_time = 0.9
 death_reason = reason
 clear_controls()
 update_stats()
 update_control_feedback()
 pulse(55)
 save_checkpoint()
 profile.record(record_mode(), "moderate" if route_kind == "daily" else profile.difficulty, score)
 panel.hide()
 quick_retry.show()
 quick_retry.grab_focus.call_deferred()
 queue_redraw()

func hit() -> void:
 if phase != Phase.PLAY: return
 hit_flash = 0.3
 shake = 0.22
 lives = 0
 country_failed = true
 hurt_time = 0.5
 combo = 0
 combo_time = 0
 audio.play_cue("fall")
 fail_round("BALLOON HIT · GAME OVER")

func clear_round() -> void:
 if phase != Phase.PLAY: return
 phase = Phase.CLEAR
 score += int(remaining) * 10
 coins += 10 if round_index < 2 else 30
 profile.record(record_mode(), "moderate" if route_kind == "daily" else profile.difficulty, score)
 earned_badges.clear()
 rare_earned = false
 if round_index == 2 and route_kind != "practice":
  profile.award_arcade_medal(route[country_index], record_difficulty(), coop, ArcadeProgress.medal(country_time, country_retries, country_combo))
  if country_drops == 0 and profile.note_arcade_goal("no_drops"): show_feedback("DAILY GOAL COMPLETE!\nNo-drop destination cleared")
  profile.discover(route[country_index])
  profile.record_destination(route[country_index], "arcade", maxi(0, score - country_start_score))
  profile.note_completion(route[country_index], record_difficulty(), not country_failed, false, ArcadeProgress.medal(country_time, country_retries, country_combo))
  profile.advance_missions(route[country_index], not country_failed, false)
  if not country_failed and country_drops == 0: rare_earned = profile.earn_rare(route[country_index], "crystal")
  for id in ["arcade:clean_boss", "arcade:no_drops"]:
   if ((id == "arcade:clean_boss" and not country_failed) or (id == "arcade:no_drops" and country_drops == 0)) and profile.award_badge(id, false): earned_badges.append(id)
 update_stats()
 save_checkpoint()
 if round_index == 2 and route_kind != "practice":
  stamp_pending = true
  panel.hide()
  stamp.ink_color = Color("276e62") if profile.activities.custom.ink == "jade" else Color("285f86") if profile.activities.custom.ink == "ocean" else Color("a24c40")
  stamp.present(route[country_index], Vector2(size.x / 2, size.y / 2), profile.settings.reduced_motion)
 else: show_clear_panel()

func finish_stamp() -> void:
 if not stamp_pending: return
 stamp_pending = false
 stamp.cancel()
 show_clear_panel()
 parcel.present(route[country_index], int(profile.souvenir_counts.get(route[country_index], 1)), profile.settings.reduced_motion)

func show_clear_panel() -> void:
 var message := ("PRACTICE COMPLETE!" if round_index == 2 and route_kind == "practice" else "DESTINATION STAMPED!" if round_index == 2 else "ROUND CLEARED!") + "\n" + GameCatalog.country_name(route[country_index]) + " · Score %d" % score
 if rare_earned: message += "\nRARE CRYSTAL KEEPSAKE FOUND!"
 if round_index == 2: message += "\n\n" + destination_result()
 if round_index == 2 and route_kind != "practice":
  message += "\nSouvenir collected: " + DestinationTheme.souvenir(route[country_index])
  for character in profile.last_unlocked_characters:
   message += "\nTRAVELER UNLOCKED · " + CharacterStyle.CHARACTERS[character].name
 if best_beaten: message += "\nNEW PERSONAL BEST!"
 for id in earned_badges: message += "\n★ " + ArcadeAchievements.BADGES[id].name + " · Wardrobe reward unlocked"
 show_panel(message, "FINISH PRACTICE" if round_index == 2 and route_kind == "practice" else "NEXT DESTINATION" if round_index == 2 else "NEXT ROUND", next_round)

func next_round() -> void:
 if phase != Phase.CLEAR or stamp_pending or parcel.active: return
 if phase == Phase.CLEAR and round_index == 2 and country_index < route.size() - 1 and not panel.has_meta("travel"):
  panel.set_meta("travel", true)
  show_travel()
  save_checkpoint()
  return
 panel.remove_meta("travel")

 if round_index == 2:
  if country_index == route.size() - 1:
   finished_tour = true
   profile.arcade_saves.erase(checkpoint_key())
   profile.save()
   exit_game()
   return
  phase = Phase.TRAVEL
  panel.hide()
  controls.hide()
  partner_controls.hide()
  audio.play_cue("travel")
  arrival.begin(route[country_index], route[country_index + 1], profile.settings.reduced_motion, true, true)
  return
 round_index += 1
 begin_round()

func finish_arrival() -> void:
 if phase != Phase.TRAVEL: return
 country_index += 1
 country_failed = false
 country_drops = 0
 country_time = 0.0
 country_retries = 0
 country_combo = 0
 country_pops = 0
 country_start_score = score
 round_index = 0
 controls.show()
 partner_controls.visible = coop
 phase = Phase.CLEAR
 pulse(30)
 begin_round()

func set_paused(value: bool) -> void:
 if value and (phase in [Phase.PLAY, Phase.COUNTDOWN] or (phase == Phase.FAILED and death_time > 0)):
  pause_from = Phase.PLAY if phase == Phase.COUNTDOWN else phase
  phase = Phase.PAUSED
  countdown.hide()
  audio.set_paused(true)
  update_control_feedback()
  save_checkpoint()
  show_panel("BALLOON TOUR PAUSED", "RESUME", func(): set_paused(false))
 elif not value and phase == Phase.PAUSED:
  panel.hide()
  if pause_from == Phase.PLAY:
   phase = Phase.COUNTDOWN
   countdown_remaining = 3.0
   countdown_label.text = "3"
   countdown.show()
  else:
   phase = pause_from
   quick_retry.visible = death_time > 0
   audio.set_paused(false)

func exit_game() -> void:
 save_checkpoint()
 profile.record(record_mode(), "moderate" if route_kind == "daily" else profile.difficulty, score)
 audio.set_paused(false)
 exited.emit()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  if is_instance_valid(panel):
   if phase == Phase.TRAVEL: arrival.finish()
   if stamp_pending: finish_stamp()
   set_paused(true)
   save_checkpoint()

func _input(event: InputEvent) -> void:
 if phase == Phase.COUNTDOWN and event is InputEventScreenTouch and event.pressed and pause_button.get_global_rect().has_point(event.position):
  set_paused(true)
  get_viewport().set_input_as_handled()
  return
 if phase == Phase.FAILED and event is InputEventScreenTouch and event.pressed and quick_retry.visible and quick_retry.get_global_rect().has_point(event.position):
  retry_round()
  get_viewport().set_input_as_handled()
  return
 if phase != Phase.PLAY: return
 if event is InputEventScreenDrag and touches.has(event.index):
  var old_key: String = touches[event.index]
  var key := ""
  for button in controls.get_children() + (partner_controls.get_children() if coop else []):
   if button.get_global_rect().has_point(event.position): key = button.text; break
  touches[event.index] = key
  if old_key not in touches.values(): set_control(old_key, false)
  update_control_feedback()
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch:
  if event.pressed:
   if pause_button.get_global_rect().has_point(event.position):
    set_paused(true)
    get_viewport().set_input_as_handled()
    return
   for button in controls.get_children() + (partner_controls.get_children() if coop else []):
    if button.get_global_rect().has_point(event.position):
     touches[event.index] = button.text
     pulse()
     update_control_feedback()
     get_viewport().set_input_as_handled()
     return
  elif touches.has(event.index):
   var key: String = touches[event.index]
   touches.erase(event.index)
   if key not in touches.values(): set_control(key, false)
   update_control_feedback()
   get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if phase == Phase.FAILED and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_R, KEY_SPACE, KEY_ENTER]:
  retry_round()
  get_viewport().set_input_as_handled()
 elif phase == Phase.COUNTDOWN:
  if event.is_action_pressed("ui_cancel"): set_paused(true)
 elif event is InputEventKey and event.physical_keycode == KEY_Q and event.pressed and not event.echo:
  accept_drops = not accept_drops
  notice.text = "? DROPS: COLLECT" if accept_drops else "? DROPS: AVOID"
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("ui_cancel"):
  set_paused(phase != Phase.PAUSED)
  get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.physical_keycode == KEY_SPACE and event.pressed:
  fire()
  get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
 if not visible or not profile or profile.travel_buddy == "none" or profile.settings.reduced_motion or phase == Phase.PAUSED: return
 buddy_clock += delta
 if phase in [Phase.READY, Phase.CLEAR, Phase.TRAVEL]: queue_redraw()

func _physics_process(delta: float) -> void:
 if phase not in [Phase.PLAY, Phase.COUNTDOWN] and not (phase == Phase.FAILED and death_time > 0): return
 simulate(minf(delta, 1.0 / 30))

func simulate(delta: float) -> void:
 if phase == Phase.COUNTDOWN:
  countdown_remaining = maxf(0, countdown_remaining - delta)
  countdown_label.text = str(ceili(countdown_remaining))
  if countdown_remaining == 0:
   phase = Phase.PLAY
   countdown.hide()
   audio.set_paused(false)
  return
 if phase == Phase.FAILED and death_time > 0:
  death_time = maxf(0, death_time - delta)
  queue_redraw()
  if death_time == 0: show_panel("GAME OVER · %d pts\n%s" % [score, death_reason], "RETRY ROUND", retry_round)
  return
 if phase != Phase.PLAY: return
 feedback_time = maxf(0, feedback_time - delta)
 if feedback_time == 0: feedback.hide()
 clock += delta
 autosave_time += delta
 update_control_feedback()
 if autosave_time >= 2: save_checkpoint()
 shake = maxf(0, shake - delta)
 hit_flash = maxf(0, hit_flash - delta)
 partner_cooldown = maxf(0, partner_cooldown - delta)
 round_elapsed += delta
 if country_time >= 0: country_time += delta
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
 var move_speed := 330.0 if effects.get("boots", 0) > 0 else 150.0 if effects.get("heavy", 0) > 0 else 240.0
 var desired := clampf(movement, -1, 1) * move_speed
 slide_speed = move_toward(slide_speed, desired, delta * movement_acceleration(slide_speed, desired))
 var wind := sin(clock * 1.7) * 32 if mechanic == "sand" else 0.0
 var previous_player_x := player_x
 player_x = clampf(player_x + (slide_speed + wind) * delta, 26, WORLD.x - 26)
 visual_facing = update_turn(visual_facing, facing, delta)
 walk_speed = absf(player_x - previous_player_x) / maxf(delta, 0.0001)
 walk_clock += absf(player_x - previous_player_x) * 8.0 / 110.0
 if coop:
  var axis := float(Input.is_physical_key_pressed(KEY_L) or partner_held.has("P2 ▶") or "P2 ▶" in touches.values()) - float(Input.is_physical_key_pressed(KEY_J) or partner_held.has("P2 ◀") or "P2 ◀" in touches.values())
  if effects.get("reverse", 0) > 0: axis *= -1
  partner_movement = axis
  var previous_partner_x := partner_x
  partner_slide = move_toward(partner_slide, axis * move_speed, delta * movement_acceleration(partner_slide, axis * move_speed))
  partner_x = clampf(partner_x + (partner_slide + wind) * delta, 26, WORLD.x - 26)
  if Input.is_physical_key_pressed(KEY_K) or partner_held.has("P2 FIRE") or "P2 FIRE" in touches.values(): fire(partner_x)
  partner_walk_speed = absf(partner_x - previous_partner_x) / maxf(delta, 0.0001)
  partner_walk += absf(partner_x - previous_partner_x) * 8.0 / 110.0
  if axis != 0: partner_facing = signf(axis)
  partner_visual_facing = update_turn(partner_visual_facing, partner_facing, delta)
 wave_clock += delta if round_index != 2 or freeze <= 0 else 0.0
 var enraged := balls.any(func(ball): return ball.get("boss", false) and ball.hp <= int(ball.max_hp) / 2)
 if (challenge in ["swarm", "no_fire"] or round_index == 2) and wave_clock >= wave_interval(enraged):
  wave_clock = 0
  if round_index == 2:
   for boss in balls:
    if boss.get("boss", false): queue_boss_pattern(boss, false, enraged)
  else:
   if balls.size() < 20: balls.append(make_ball(Vector2(rng.randf_range(40,680), 40), 0, 1 if rng.randf() > 0.5 else -1))
 if freeze <= 0: update_boss_attacks(delta)
 if fire_held or "FIRE ↑" in touches.values() or Input.is_physical_key_pressed(KEY_SPACE): fire()
 for ball in balls: ball.flash = maxf(0, float(ball.get("flash", 0)) - delta)
 if freeze <= 0:
  for ball in balls:
   ball.age = float(ball.get("age", 0)) + delta
   if ball.get("boss", false) and ball.get("dash_time", 0.0) > 0:
    ball.dash_time = maxf(0, ball.dash_time - delta)
    if ball.dash_time == 0: ball.velocity.x = signf(ball.velocity.x) * float(ball.get("base_speed", absf(ball.velocity.x)))
   if ball.get("behavior", "") == "zigzag": ball.position.x += sin(ball.age * 7) * delta * 95
   if ball.get("behavior", "") == "dodge":
    for wire in wires:
     if absf(wire.x - ball.position.x) < ball.radius + 30 and wire.top > ball.position.y:
      ball.position.x += (-1 if wire.x >= ball.position.x else 1) * delta * 180
      break
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
 for ball in balls:
  var radius: float = ball.radius
  var body := Rect2(player_x - 17, floor_y - 65, 34, 65)
  var nearest := Vector2(clampf(ball.position.x, body.position.x, body.end.x), clampf(ball.position.y, body.position.y, body.end.y))
  if nearest.distance_squared_to(ball.position) <= radius * radius: hit()
  if coop:
   var partner_body := Rect2(partner_x - 17, floor_y - 65, 34, 65)
   var partner_near := Vector2(clampf(ball.position.x, partner_body.position.x, partner_body.end.x), clampf(ball.position.y, partner_body.position.y, partner_body.end.y))
   if partner_near.distance_squared_to(ball.position) <= radius * radius:
    invincible = 0
    hit()
  if phase != Phase.PLAY: return
 for index in range(balls.size() - 1, -1, -1):
  var timed: Dictionary = balls[index]
  if freeze <= 0 and timed.get("behavior", "") == "timed" and timed.get("age", 0) >= 5 and int(timed.tier) > 0 and not timed.get("boss", false):
   balls.remove_at(index)
   burst(timed.position, Color("c7ff91"))
   for direction in [-1, 1]: balls.append(make_ball(timed.position, int(timed.tier) - 1, direction))
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
  if accept_drops and (absf(pickup.position.x - player_x) < 30 or (coop and absf(pickup.position.x - partner_x) < 30)) and pickup.position.y > floor_y - 75:
   mystery_chain = 0 if pickup.kind in ["multiply", "speed", "heavy", "reverse", "jam", "shrink_time"] else mystery_chain + 1
   if mystery_chain > 0 and mystery_chain % 3 == 0: score += 500
   collect(pickup.kind)
   if mystery_chain > 0 and mystery_chain % 3 == 0: notice.text += " · LUCKY STREAK +500"
   pickups.remove_at(index)
  elif pickup.age > 12: pickups.remove_at(index)
 if progress_dirty:
  progress_dirty = false
  save_checkpoint()
 update_stats()
 if challenge in ["swarm", "no_fire"]:
  if remaining <= 0: clear_round()
 elif balls.is_empty(): clear_round()
 elif remaining <= 0:
  country_failed = true
  lives = 0
  audio.play_cue("fall")
  fail_round("FLOODED!" if challenge == "flood" else "TIME UP")
 queue_redraw()

func update_stats() -> void:
 update_personal_best()
 stats.text = "ONE HIT · %ds · %d pts · %d coins\n%s" % [ceili(remaining), score, coins, weapon.to_upper()]
 if weapon != "wire": stats.text += " Lv%d" % weapon_level
 if combo > 1 and combo_time > 0: stats.text += " · COMBO ×%d" % mini(6, combo)
 if coop: stats.text += " · TEAM BURST %d/4" % team_charge
 if best_beaten: stats.text += " · BEST!"
 stats.add_theme_font_size_override("font_size", 14)

func draw_surface(rect: Rect2) -> void:
 draw_rect(Rect2(rect.position + Vector2(0, 5), rect.size), Color(0, 0, 0, 0.35))
 var texture := RealisticArt.surface(mechanic)
 var count := maxi(1, ceili(rect.size.x / 100))
 for index in count:
  var width := rect.size.x / count
  draw_texture_rect(texture, Rect2(rect.position + Vector2(index * width, 0), Vector2(width, rect.size.y)), false, Color(0.65, 0.68, 0.68))
 draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color(1, 0.97, 0.88, 0.7), 2, true)
 draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color(0.03, 0.04, 0.04, 0.55), 3, true)

func _draw() -> void:
 if not backdrop: return
 var cover_scale := maxf(size.x / backdrop.get_width(), size.y / backdrop.get_height())
 var source_size := size / cover_scale
 var source_start := Vector2((backdrop.get_width() - source_size.x) / 2, (backdrop.get_height() - source_size.y) * 0.2)
 draw_texture_rect_region(backdrop, Rect2(Vector2.ZERO, size), Rect2(source_start, source_size))
 if profile.activities.custom.time != "day": draw_rect(Rect2(0, arena().position.y, size.x, arena().size.y * 0.12), Color(0.9, 0.4, 0.1, 0.15) if profile.activities.custom.time in ["sunrise", "sunset"] else Color(0.03, 0.05, 0.18, 0.22))
 for i in 18:
  var point := Vector2(fmod(i * 61.0 + (0 if profile.settings.reduced_motion else buddy_clock * 15), maxf(1, size.x)), arena().position.y + fmod(i * 37.0 + (0 if profile.settings.reduced_motion else buddy_clock * 20), maxf(1, arena().size.y * 0.1)))
  if profile.activities.custom.weather == "rain": draw_line(point, point + Vector2(-3, 12), Color(0.8, 0.9, 1, 0.5), 1)
  elif profile.activities.custom.weather == "snow": draw_circle(point, 2, Color("e4f7ff"))
 draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, arena().position.y - 4)), Color(0.04, 0.15, 0.22, 0.85))
 var play := arena()
 var jitter := Vector2(sin(clock * 93), cos(clock * 77)) * shake * 12 if not profile.settings.reduced_motion else Vector2.ZERO
 draw_set_transform(play.position + jitter, 0, play.size / Vector2(WORLD.x, world_height))
 if profile and profile.travel_buddy != "none":
  var buddy_color := Color("ffc85c") if profile.travel_buddy == "bird" else Color("86d7ed") if profile.travel_buddy == "robot" else Color("8ed599")
  var buddy_state := "fall" if country_failed else "celebrate" if phase == Phase.CLEAR else "jump" if shot_time > 0 else "thinking"
  var buddy_offset := Vector3.ZERO if profile.settings.reduced_motion else BuddyPersonality.offset(profile.travel_buddy, buddy_state, buddy_clock)
  var point := Vector2(clampf(player_x + 45 + buddy_offset.x * 30, 28, WORLD.x - 28), floor_y - 100 - buddy_offset.y * 30)
  if profile.travel_buddy == "robot":
   draw_rect(Rect2(point - Vector2(15, 12), Vector2(30, 24)), buddy_color)
   draw_line(point + Vector2(0, -12), point + Vector2(0, -22), buddy_color, 2)
   draw_circle(point + Vector2(0, -23), 3, Color("fff2d6"))
  else:
   draw_circle(point, 14, buddy_color)
   if profile.travel_buddy == "dragon":
    for side in [-1, 1]: draw_colored_polygon(PackedVector2Array([point + Vector2(side * 5, -10), point + Vector2(side * 12, -24), point + Vector2(side * 14, -8)]), Color("ffe0a0"))
   else:
    draw_colored_polygon(PackedVector2Array([point + Vector2(12, -2), point + Vector2(24, 3), point + Vector2(12, 6)]), Color("e98c45"))
  for side in [-1, 1]: draw_circle(point + Vector2(side * 5, -3), 2, Color("153e57"))
  for side in [-1, 1]: draw_line(point + Vector2(side * 12, 0), point + Vector2(side * 27, -5 + (0 if profile.settings.reduced_motion else sin(buddy_clock * (9 if profile.travel_buddy == "bird" else 2)) * 7)), buddy_color, 5)
  if profile.travel_buddy == "dragon" and buddy_state == "celebrate":
   for i in 3: draw_circle(point + Vector2(20 + i * 8, -5 - i * 4), 2, Color("f6c968"))
  draw_string(ThemeDB.fallback_font, point + Vector2(-10, -22), BuddyPersonality.message(profile.travel_buddy, buddy_state, buddy_clock), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, buddy_color)
 for platform in platforms:
  draw_surface(platform)
 draw_surface(Rect2(0, floor_y, WORLD.x, 30))
 if mechanic == "sand":
  for index in 6:
   var x := fmod(index * 140 + clock * 55, WORLD.x)
   draw_line(Vector2(x, floor_y * 0.3 + index * 25),Vector2(x + 40, floor_y * 0.3 + index * 25),Color(1,0.9,0.65,0.35),2)
 for wire in wires:
  var kind: String = wire.get("kind", "wire")
  if kind in ["gun", "spread", "rocket"]:
   draw_texture_rect(RealisticArt.object(6 if kind == "rocket" else 7), Rect2(wire.x - 8, wire.top, 16, 30), false)
   draw_line(Vector2(wire.x, wire.top + 22), Vector2(wire.x, wire.top + 34), Color(1, 0.7, 0.25, 0.6), 3, true)
  else:
   draw_line(Vector2(wire.x, wire.bottom), Vector2(wire.x, wire.top), Color("9df7ef") if kind == "laser" else Color("ffe5a1"), 8 if kind == "laser" else 4, true)
   draw_texture_rect(RealisticArt.object(5), Rect2(wire.x - 9, wire.top - 12, 18, 30), false)
 for ball in balls:
  draw_circle(ball.position + Vector2(3, 5), ball.radius, Color(0, 0, 0, 0.24))
  draw_texture_rect(RealisticArt.object(3 if ball.get("boss", false) else ball.tier), Rect2(ball.position - Vector2.ONE * ball.radius * 1.12, Vector2.ONE * ball.radius * 2.24), false, Color(1.25, 1.25, 1.25) if ball.get("flash", 0) > 0 else Color.WHITE)
  var behavior: String = ball.get("behavior", "normal")
  if behavior != "normal" and not ball.get("boss", false):
   draw_string(ThemeDB.fallback_font, ball.position + Vector2(-7, 5), {"zigzag": "Z", "armored": "A", "timed": "5", "dodge": "D"}.get(behavior, ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("143e55"))
  if int(ball.get("armor", 1)) > 1: draw_arc(ball.position, ball.radius + 4, 0, TAU, 32, Color("a4ddff"), 4, true)

  if ball.get("boss", false):
   draw_arc(ball.position,ball.radius+5,0,TAU,40,Color("ffdd79"),6 if ball.hp > int(ball.max_hp)-2 else 2,true)
   draw_rect(Rect2(ball.position.x-45,ball.position.y-ball.radius-15,90,7),Color("193b52"))
   draw_rect(Rect2(ball.position.x-45,ball.position.y-ball.radius-15,90*float(ball.hp)/ball.max_hp,7),Color("ffdd79"))
   if ball.get("warning", 0.0) > 0:
    var pulse_size := 0.0 if profile.settings.reduced_motion else sin(clock * 14) * 3.0
    draw_arc(ball.position, ball.radius + 12 + pulse_size, 0, TAU, 48, Color("fff5aa"), 5, true)
    var message := "CHARGE INCOMING" if ball.get("charge_pending", false) else "HIGH BOUNCE" if ball.get("bounce_pending", false) else "MINION SWARM"
    draw_string(ThemeDB.fallback_font, Vector2(clampf(ball.position.x - 140, 4, WORLD.x - 284), ball.position.y + ball.radius + 32), message, HORIZONTAL_ALIGNMENT_CENTER, 280, 24, Color("fff5aa"))
    if ball.get("charge_pending", false):
     var direction := -signf(ball.velocity.x)
     var tip: Vector2 = ball.position + Vector2(direction * (ball.radius + 65), 0)
     draw_line(ball.position + Vector2(direction * (ball.radius + 15), 0), tip, Color("fff5aa"), 5, true)
     draw_line(tip, tip + Vector2(-direction * 16, -12), Color("fff5aa"), 5, true)
     draw_line(tip, tip + Vector2(-direction * 16, 12), Color("fff5aa"), 5, true)
    if ball.get("bounce_pending", false):
     var tip: Vector2 = ball.position + Vector2(0, -ball.radius - 62)
     draw_line(ball.position + Vector2(0, -ball.radius - 15), tip, Color("fff5aa"), 5, true)
     draw_line(tip, tip + Vector2(-12, 16), Color("fff5aa"), 5, true)
     draw_line(tip, tip + Vector2(12, 16), Color("fff5aa"), 5, true)
    for index in int(ball.get("minions_pending", 0)):
     draw_arc(boss_minion_position(ball, index), 18, 0, TAU, 24, Color("fff5aa"), 3, true)
 for pickup in pickups:
  draw_texture_rect(RealisticArt.object(4), Rect2(pickup.position - Vector2(22, 22), Vector2(44, 44)), false)
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
  var teammate_frame := 8 + mini(3,int((0.32-partner_shot)/0.32*4)) if partner_shot > 0 else int(partner_walk)%4 if partner_movement != 0 else 0
  draw_explorer(teammate_frame, partner_walk, partner_walk_speed, partner_visual_facing, partner_x, Color("a4ddff"), phase == Phase.FAILED)
  draw_string(ThemeDB.fallback_font,Vector2(partner_x-14,floor_y-125),"P2",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("a4ddff"))
  draw_string(ThemeDB.fallback_font,Vector2(player_x-14,floor_y-125),"P1",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffdd79"))
 var frame := character_frame()
 var tint := Color(CharacterStyle.OUTFITS.get(profile.character_style.outfit, CharacterStyle.OUTFITS.classic).color)
 if invincible > 0 and hurt_time <= 0 and phase == Phase.PLAY and int(clock * 8) % 2: tint.a = 0.45
 if profile.equipped_character() != "classic":
  var id := profile.equipped_character()
  var pose := 5 if hurt_time > 0 or phase == Phase.FAILED else 4 if phase == Phase.CLEAR else int(walk_clock * 7) % 2 if movement != 0 and not profile.settings.reduced_motion else -1
  var traveler_texture := CharacterStyle.character_texture(id) if pose < 0 else CharacterStyle.motion_texture(id, pose)
  var scale: float = 132.0 / (traveler_texture.get_height() if pose < 0 else CharacterStyle.motion_height(id))
  var width: float = scale * traveler_texture.get_width()
  var height: float = scale * traveler_texture.get_height()
  draw_texture_rect(traveler_texture, Rect2(player_x - width / 2, floor_y - height, width * side_scale(visual_facing), height), false, tint)
 else:
  draw_explorer(frame, walk_clock, walk_speed, visual_facing, player_x, tint, hurt_time > 0 or phase == Phase.FAILED)
 draw_set_transform(Vector2.ZERO)
 if hit_flash > 0: draw_rect(play, Color(1, 0.25, 0.2, hit_flash * 0.35))

func movement_acceleration(velocity: float, desired: float) -> float:
 if mechanic == "ice": return 260.0
 return 1800.0 if velocity * desired < 0 else 4000.0

func update_turn(current: float, target: float, delta: float) -> float:
 # Brief side-profile transition; no front-facing pose or scale deformation.
 return target if profile.settings.reduced_motion else move_toward(current, target, delta * 20.0)

func side_scale(direction: float) -> float:
 return -1.0 if direction < 0 else 1.0

func side_target(x: float, direction: float, cell: Vector2, anchor: Vector2, sole: float, width_ratio: float = 1.0) -> Rect2:
 var scale: float = 132.0 / (sole - anchor.y)
 var width := cell.x * scale * width_ratio * side_scale(direction)
 # Godot flips a negative-width texture inside its rectangle; its position
 # remains the left edge. Mirror the anchor inside those same bounds.
 var anchor_x := cell.x - anchor.x if direction < 0 else anchor.x
 return Rect2(x - anchor_x / cell.x * absf(width), floor_y - sole * scale, width, cell.y * scale)

func draw_anchored_sprite(texture: Texture2D, target: Rect2, source: Rect2, tint: Color, x: float, direction: float) -> void:
 var lean := -sin(direction * PI) * 0.015 if not profile.settings.reduced_motion else 0.0
 var pivot := Vector2(x, floor_y - 118)
 var width := absf(target.size.x)
 var corners := PackedVector2Array([target.position, target.position + Vector2(width, 0), target.position + Vector2(width, target.size.y), target.position + Vector2(0, target.size.y)])
 for index in 4: corners[index] = pivot + (corners[index] - pivot).rotated(lean)
 var left := source.end.x if target.size.x < 0 else source.position.x
 var right := source.position.x if target.size.x < 0 else source.end.x
 var uv := PackedVector2Array([Vector2(left, source.position.y), Vector2(right, source.position.y), Vector2(right, source.end.y), Vector2(left, source.end.y)])
 for index in 4: uv[index] /= Vector2(texture.get_size())
 draw_polygon(corners, PackedColorArray([tint]), uv, texture)

func realistic_source(index: int) -> Rect2:
 var cell := Vector2(EXPLORER.get_size()) / 4
 var data := RealisticArt.explorer_frame(index)
 var bounds: Array = data.bounds
 return Rect2(Vector2(index % 4, index / 4) * cell + Vector2(bounds[0], bounds[1]), Vector2(bounds[2] - bounds[0], bounds[3] - bounds[1]))

func realistic_target(index: int, x: float, direction: float) -> Rect2:
 var data := RealisticArt.explorer_frame(index)
 var source := realistic_source(index)
 var anchor := Vector2(data.anchor_x - data.bounds[0], data.head_top - data.bounds[1])
 return side_target(x, direction, source.size, anchor, data.sole - data.bounds[1])

func draw_turn(x: float, direction: float, tint: Color) -> void:
 draw_anchored_sprite(EXPLORER, realistic_target(0, x, direction), realistic_source(0), tint, x, direction)

func walking_frame(gait: float) -> int:
 return posmod(int(gait), 8)

func draw_explorer(frame: int, gait: float, speed: float, direction: float, x: float, tint: Color, incapacitated: bool) -> void:
 if not incapacitated and absf(direction) < 0.35: speed = 0
 var index := frame if incapacitated and frame >= 12 else walking_frame(gait) + 1 if speed > 1 else 0
 var target := realistic_target(index, x, direction)
 if incapacitated:
  var source := realistic_source(index)
  var scale: float = 132.0 / (RealisticArt.explorer_frame(0).sole - RealisticArt.explorer_frame(0).head_top)
  target.size = Vector2(source.size.x * scale * side_scale(direction), source.size.y * scale)
  target.position = Vector2(x - absf(target.size.x) / 2, floor_y - target.size.y)
 # A soft contact shadow and one solid side profile keep feet grounded.
 var shadow := PackedVector2Array()
 for point in 20: shadow.append(Vector2(x, floor_y + 2) + Vector2(cos(point * TAU / 20) * 22, sin(point * TAU / 20) * 4))
 draw_colored_polygon(shadow, Color(0, 0, 0, 0.28))
 draw_anchored_sprite(EXPLORER, target, realistic_source(index), tint, x, direction)
 if frame in range(4, 12) and not incapacitated:
  var grip := Vector2(x + side_scale(direction) * 12, floor_y - 78)
  var head := RealisticArt.object(7 if weapon in ["gun", "spread", "laser"] else 6 if weapon == "rocket" else 5)
  draw_texture_rect(head, Rect2(grip + Vector2(-8, -30), Vector2(16, 30)), false)

func character_frame() -> int:
 if phase == Phase.FAILED and death_time > 0: return 12 + mini(3, int((0.9 - death_time) / 0.9 * 4))
 if hurt_time > 0: return 12 + mini(1, int((0.5 - hurt_time) * 4))
 if shot_time > 0:
  return (8 if weapon in ["gun", "spread", "laser", "rocket"] else 4) + mini(3, int((0.32 - shot_time) / 0.32 * 4))
 if absf(movement) > 0: return int(walk_clock) % 4
 return 0
