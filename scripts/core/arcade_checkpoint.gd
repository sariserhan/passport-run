class_name ArcadeCheckpoint
extends RefCounted

const VERSION := 1
const MAX_BYTES := 131072
const MAX_ENCODED := 32768
const NEW_FIELDS := ["country_drops", "best_before", "best_initialized", "best_beaten", "country_time", "country_retries", "country_combo", "country_pops", "country_start_score"]
const FIELDS := ["country_index", "round_index", "score", "round_score", "coins", "round_coins", "remaining", "player_x", "partner_x", "coop", "country_failed", "cooldown", "partner_cooldown", "freeze", "double_wire", "weapon", "weapon_time", "weapon_level", "weapon_trait", "starting_weapon", "starting_freeze", "starting_time", "accept_drops", "travel_choice", "pops", "mystery_chain", "clock", "round_elapsed", "wave_clock", "mechanic", "challenge", "slide_speed", "partner_slide", "facing", "visual_facing", "partner_facing", "partner_visual_facing", "walk_clock", "partner_walk", "combo", "combo_time", "team_charge", "last_shooter", "last_shot_at", "country_drops", "best_before", "best_initialized", "best_beaten", "country_time", "country_retries", "country_combo", "country_pops", "country_start_score"]

static func capture(game: Node) -> String:
	var state := {"version": VERSION, "home": game.profile.home_country, "kind": game.route_kind, "day": game.daily_day, "country": game.route[game.country_index], "difficulty": game.profile.difficulty, "floor": game.floor_y, "phase": game.pause_from if game.phase == game.Phase.PAUSED else game.phase, "rng": game.rng.state, "supplies": game.panel.has_meta("travel"), "effects": game.effects.duplicate(), "balls": game.balls.duplicate(true), "wires": game.wires.duplicate(true), "pickups": game.pickups.duplicate(true), "platforms": game.platforms.duplicate()}
	for field in FIELDS: state[field] = game.get(field)
	if state.phase == game.Phase.TRAVEL: state.phase = game.Phase.CLEAR
	if state.phase == game.Phase.COUNTDOWN: state.phase = game.Phase.PLAY
	var bytes := var_to_bytes(state)
	if bytes.size() > MAX_BYTES: return ""
	var encoded := JSON.stringify({"size": bytes.size(), "data": Marshalls.raw_to_base64(bytes.compress(FileAccess.COMPRESSION_ZSTD))})
	return encoded if encoded.length() <= MAX_ENCODED else ""

static func decode(encoded: String, game: Node) -> Dictionary:
	if encoded.is_empty() or encoded.length() > MAX_ENCODED: return {}
	var envelope: Variant = JSON.parse_string(encoded)
	if not envelope is Dictionary or not envelope.get("data") is String or not envelope.get("size") is float: return {}
	var length := int(envelope.size)
	if length < 1 or length > MAX_BYTES: return {}
	var bytes := Marshalls.base64_to_raw(envelope.data).decompress(length, FileAccess.COMPRESSION_ZSTD)
	if bytes.size() != length: return {}
	# Object deserialization is disabled; only bounded, whitelisted state is restored.
	var state: Variant = bytes_to_var(bytes)
	if not state is Dictionary or state.get("version") != VERSION: return {}
	if state.get("home") != game.profile.home_country or state.get("kind") != game.route_kind or state.get("day") != game.daily_day: return {}
	if not state.get("country_index") is int or state.country_index < 0 or state.country_index >= game.route.size(): return {}
	if state.get("country") != game.route[state.country_index] or not game.profile.can_visit(state.country): return {}
	if not state.get("round_index") is int or state.round_index not in [0, 1, 2]: return {}
	if state.get("difficulty") not in GameCatalog.DIFFICULTIES or state.get("phase") not in [game.Phase.READY, game.Phase.PLAY, game.Phase.CLEAR, game.Phase.FAILED]: return {}
	if not state.get("floor") is float or state.floor <= 0 or not is_finite(state.floor): return {}
	# Saves made before achievements cannot prove that no drops were collected.
	for field in NEW_FIELDS:
		if not state.has(field): state[field] = -1 if field == "country_drops" else -1.0 if field == "country_time" else game.get(field)
	for field in FIELDS:
		if not state.has(field) or typeof(state[field]) != typeof(game.get(field)): return {}
		if state[field] is float and (not is_finite(state[field]) or absf(state[field]) > 10000000): return {}
	if state.score < 0 or state.score > 10000000 or state.coins < 0 or state.coins > 10000000 or state.round_score < 0 or state.round_score > state.score or state.round_coins < 0 or state.round_coins > 10000000 or state.remaining < 0 or state.remaining > 110: return {}
	if game.route_kind == "daily" and state.coop: return {}
	if state.country_time < -1 or state.country_retries < 0 or state.country_retries > 10000000 or state.country_combo < 0 or state.country_combo > 10000000 or state.country_pops < 0 or state.country_pops > 10000000 or state.country_start_score < 0 or state.country_start_score > 10000000: return {}
	if state.country_drops < -1 or state.country_drops > 10000000 or state.best_before < 0 or state.best_before > 10000000: return {}
	if state.weapon not in ["wire"] + game.WEAPONS or state.starting_weapon not in ["wire"] + game.WEAPONS or state.weapon_level not in [1, 2, 3] or state.travel_choice not in ["safe", "detour"]: return {}
	if not state.get("rng") is int or not state.get("supplies") is bool or not state.get("effects") is Dictionary: return {}
	for key in state.effects:
		if key not in game.DROPS or not (state.effects[key] is float or state.effects[key] is int) or state.effects[key] < 0 or state.effects[key] > 60: return {}
	for field in ["balls", "wires", "pickups", "platforms"]:
		if not state.get(field) is Array or state[field].size() > {"balls": 160, "wires": 64, "pickups": 10, "platforms": 8}[field]: return {}
	for ball in state.balls:
		if not ball is Dictionary or not ball.get("position") is Vector2 or not ball.get("velocity") is Vector2 or not ball.position.is_finite() or not ball.velocity.is_finite(): return {}
		if ball.get("tier") not in [0, 1, 2] or not ball.get("radius") is float or ball.radius <= 0 or ball.radius > 100 or not ball.get("armor") is int or not ball.get("age") is float or not ball.get("flash") is float: return {}
		if not is_finite(ball.radius) or not is_finite(ball.age) or not is_finite(ball.flash) or not ball.get("boss", false) is bool or not ball.get("behavior", "") is String: return {}
		if ball.get("boss", false) and (not ball.get("hp") is int or not ball.get("max_hp") is int or ball.hp <= 0 or ball.max_hp <= 0): return {}
		if ball.get("boss", false):
			if not ball.get("warning", 0.0) is float or not is_finite(ball.get("warning", 0.0)) or ball.get("warning", 0.0) < 0 or ball.get("warning", 0.0) > 0.85: return {}
			if not ball.get("charge_pending", false) is bool or not ball.get("minions_pending", 0) is int or ball.get("minions_pending", 0) not in [0, 1, 2, 3, 4]: return {}
			if ball.get("pattern", "charge") not in ["charge", "bounce", "summoner"] or not ball.get("bounce_pending", false) is bool: return {}
			for key in ["base_speed", "dash_time"]:
				if not ball.get(key, 0.0) is float or not is_finite(ball.get(key, 0.0)) or ball.get(key, 0.0) < 0 or ball.get(key, 0.0) > (520.0 if key == "base_speed" else 0.65): return {}
	for wire in state.wires:
		if not wire is Dictionary or wire.get("kind") not in ["wire"] + game.WEAPONS: return {}
		for key in ["x", "top", "bottom", "age", "vx", "hold"]:
			if not (wire.get(key) is float or wire.get(key) is int) or not is_finite(float(wire[key])): return {}
		for key in ["stuck", "sticky", "pierce", "blast"]:
			if not wire.get(key) is bool: return {}
	for pickup in state.pickups:
		if not pickup is Dictionary or not pickup.get("position") is Vector2 or not pickup.position.is_finite() or pickup.get("kind") not in game.DROPS or not pickup.get("age") is float: return {}
		if not is_finite(pickup.age): return {}
	for platform in state.platforms:
		if not platform is Rect2 or not platform.position.is_finite() or not platform.size.is_finite(): return {}
	return state
