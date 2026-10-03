class_name Traveler
extends Node3D

static var pose_bounds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/jumping-explorer.json"))

var weather := "clear"
var buddy_accessory := false
var victory_pose := "wave"
var buddy_kind := "none"
var buddy: Node3D
var buddy_face: Label3D
var character_id := "classic"
var kids := false
var body: Node3D
var contact_shadow: MeshInstance3D
var portrait: Sprite3D
var animation := "thinking"
var animation_clock := 0.0
var motion_pose := -2
var animation_paused := false
var reduced_motion := false
var destination_theme := "stone"
var customization := {"outfit": "classic", "hat": "none", "backpack": "classic"}
var reaction: Label3D
var pressure := 0.0:
	set(value):
		pressure = value
		if reaction: reaction.visible = value > 0.65 and animation == "thinking"

func _ready() -> void:
	if buddy_kind != "none":
		buddy = Node3D.new()
		add_child(buddy)
		var color := Color("ffc85c") if buddy_kind == "bird" else Color("86d7ed") if buddy_kind == "robot" else Color("8ed599")
		var material := MeshFactory.material(color)
		MeshFactory.sphere(buddy, 0.23, Vector3.ZERO, material)
		MeshFactory.sphere(buddy, 0.16, Vector3(0, 0.18, 0), material)
		if buddy_kind == "bird": MeshFactory.box(buddy, Vector3(0.14, 0.08, 0.18), Vector3(0, 0.17, 0.18), MeshFactory.material(Color("e98c45")))
		if buddy_kind == "robot": MeshFactory.box(buddy, Vector3(0.38, 0.22, 0.25), Vector3(0, 0.2, 0), MeshFactory.material(Color("426b89")))
		if buddy_kind == "dragon":
			MeshFactory.sphere(buddy, 0.09, Vector3(0, -0.05, 0.35), material)
			for side in [-1, 1]: MeshFactory.cylinder(buddy, 0.06, 0, 0.18, Vector3(side * 0.1, 0.4, 0), MeshFactory.material(Color("ffe0a0")))
		for side in [-1, 1]: MeshFactory.box(buddy, Vector3(0.28, 0.04, 0.18), Vector3(side * 0.28, 0, 0), material)
		buddy_face = Label3D.new()
		buddy_face.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		buddy_face.pixel_size = 0.005
		buddy_face.position.y = 0.55
		buddy.add_child(buddy_face)
		if buddy_accessory:
			MeshFactory.box(buddy, Vector3(0.4, 0.08, 0.25), Vector3(0, 0.35, 0), MeshFactory.material(Color("f4cc66")))
		buddy.position = Vector3(0.8, 1.7, 0)
	body = Node3D.new()
	add_child(body)
	reaction = Label3D.new()
	reaction.text = "!"
	reaction.font_size = 70
	reaction.pixel_size = 0.007
	reaction.position.y = 3.0
	reaction.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	reaction.modulate = Color("ffda65")
	reaction.hide()
	add_child(reaction)
	var shade := MeshFactory.material(Color(0.05, 0.04, 0.04, 0.22))
	shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	contact_shadow = MeshFactory.cylinder(self, 0.32, 0.32, 0.008, Vector3(0, 0.01, 0), shade)
	contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	portrait = Sprite3D.new()
	portrait.texture = preload("res://assets/realistic/robot-explorer.png") if kids else preload("res://assets/realistic/memory-explorer.png")
	portrait.hframes = 4
	portrait.vframes = 4
	portrait.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var idle: Array = pose_bounds["robot" if kids else "human"][0]
	portrait.pixel_size = 2.65 / (idle[3] - idle[1] - 4)
	portrait.region_enabled = true
	portrait.frame_changed.connect(align_portrait)
	align_portrait()
	portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(portrait)
	if not kids and character_id != "classic":
		portrait.texture = CharacterStyle.character_texture(character_id)
		portrait.hframes = 1
		portrait.vframes = 1
		portrait.region_enabled = false
		portrait.pixel_size = 2.65 / portrait.texture.get_height()
		portrait.position.y = 1.345
		set_motion_pose(-1)
	if not kids: apply_customization()

func align_portrait() -> void:
	if not kids and character_id != "classic": return
	var bounds: Array = pose_bounds["robot" if kids else "human"][portrait.frame]
	var origin := Vector2(bounds[0], bounds[1])
	var extent := Vector2(bounds[2] - bounds[0], bounds[3] - bounds[1])
	# Sprite3D divides region_rect by its frame grid. Offset that grid so the
	# selected frame shows the entire measured pose, including hands and boots.
	portrait.region_rect = Rect2(origin - Vector2(portrait.frame % 4, portrait.frame / 4) * extent, extent * 4)
	portrait.position.y = (extent.y / 2 - 2) * portrait.pixel_size + 0.02

func play_animation(next: String) -> void:
	animation = next
	animation_clock = 0
	body.position.y = 0
	body.rotation = Vector3.ZERO
	body.scale = Vector3.ONE
	reaction.visible = pressure > 0.65 and next == "thinking"
	if portrait and not kids and character_id != "classic":
		set_motion_pose({"jump": 2, "fall": 5, "celebrate": 4, "stamp": 4}.get(next, -1))
	if portrait and (kids or character_id == "classic"):
		portrait.frame = {"thinking": 0, "jump": 4, "celebrate": 8, "pocket": 9, "passport": 10, "stamp": 11, "fall": 12}.get(next, 0)

func _process(delta: float) -> void:
	if buddy:
		buddy_face.text = BuddyPersonality.message(buddy_kind, animation, animation_clock, pressure)
		if animation == "thinking" and pressure < 0.65 and weather != "clear": buddy_face.text = "Snow!" if weather == "snow" else {"bird": "Drip!", "robot": "Rain scan", "dragon": "Cozy?"}[buddy_kind]
		if not animation_paused and not reduced_motion:
			buddy.position = Vector3(0.8, 1.7, 0) + BuddyPersonality.offset(buddy_kind, animation, animation_clock)
			buddy.rotation.z = sin(animation_clock * (8 if buddy_kind == "bird" else 2)) * 0.1
			buddy.rotation.y = animation_clock * 2 if buddy_kind == "bird" and animation in ["celebrate", "stamp"] else 0
			if buddy_kind == "dragon" and animation in ["celebrate", "stamp"]:
				buddy_face.text = "✦ " + BuddyPersonality.FRIENDS.dragon.cheer
			elif animation in ["celebrate", "stamp"] and fmod(animation_clock, 3) > 1.5:
				buddy_face.text = BuddyPersonality.FRIENDS[buddy_kind].cheer
	if animation_paused or reduced_motion:
		return
	animation_clock += delta
	if not kids and character_id != "classic":
		if animation == "walk":
			set_motion_pose(int(animation_clock * 7) % 2)
		elif animation == "celebrate":
			set_motion_pose(4)
		if character_id == "astronaut" and animation in ["thinking", "jump", "celebrate"]:
			body.position.y = (sin(animation_clock * 2.3) + 1) * 0.06
	if animation == "thinking":
		if portrait and (kids or character_id == "classic"):
			portrait.frame = 3 if pressure > 0.65 else int(animation_clock / 0.8) % 4
			portrait.position.x = sin(animation_clock * 0.8) * 0.035
		body.rotation.z = sin(animation_clock * (8.0 if pressure > 0.65 else 1.5)) * (0.045 if pressure > 0.65 else 0.025)
		body.position.y = sin(animation_clock * 2.0) * 0.012
	elif animation == "celebrate":
		if destination_theme == "lantern":
			body.rotation.z = sin(minf(animation_clock * 5.0, PI)) * 0.18
		elif destination_theme in ["space", "magic"]:
			body.position.y = absf(sin(animation_clock * 4)) * 0.12
			body.rotation.z = sin(animation_clock * 6) * 0.12
		else:
			body.position.y = absf(sin(animation_clock * 7)) * 0.06
			body.rotation.z = sin(animation_clock * 9) * 0.055

	if animation == "celebrate":
		if victory_pose == "jump": body.position.y = absf(sin(animation_clock * 5)) * 0.25
		elif victory_pose == "cheer": body.rotation.z = sin(animation_clock * 4) * 0.12
		elif victory_pose == "wave": body.rotation.y = sin(animation_clock * 2) * 0.1

func pose_jump(progress: float) -> void:
	if kids or character_id == "classic": portrait.frame = 4 + mini(3, int(progress * 4))
	if not kids and character_id != "classic":
		var pose := 2 if progress < 0.65 else 3
		if character_id in ["dragon", "fairy"] and progress < 0.8: pose = 2 + int(progress * 8) % 2
		set_motion_pose(pose)
	contact_shadow.position.y = -sin(progress * PI) * 1.45
	contact_shadow.scale = Vector3.ONE * (1.0 - sin(progress * PI) * 0.25)
	body.rotation.z = sin(progress * PI) * 0.08
	body.scale = Vector3(1.0 + sin(progress * PI) * 0.04, 1.0 - sin(progress * PI) * 0.03, 1.0)

func pose_fall(progress: float) -> void:
	if kids or character_id == "classic": portrait.frame = 12 + mini(3, int(progress * 4))
	if not kids and character_id != "classic": set_motion_pose(5)
	contact_shadow.hide()
	body.rotation.z = progress * 0.7
	body.scale = Vector3.ONE * (1.0 - progress * 0.18)

func apply_customization() -> void:
	var outfit: String = customization.get("outfit", "classic")
	portrait.modulate = Color(CharacterStyle.OUTFITS.get(outfit, CharacterStyle.OUTFITS.classic).color)
	if CharacterStyle.CHARACTERS.get(character_id, {}).get("fantasy_art", false): return
	var backpack: String = customization.get("backpack", "classic")
	if backpack != "classic":
		var cloth := MeshFactory.material(Color(CharacterStyle.BACKPACKS.get(backpack, "b58147")))
		MeshFactory.beveled_box(body, Vector3(0.48, 0.55, 0.18), Vector3(0.12, 1.24, 0.14), cloth, 0.05)
		MeshFactory.box(body, Vector3(0.34, 0.1, 0.02), Vector3(0.12, 1.09, 0.24), MeshFactory.material(Color("ffe6ac")))
	var hat: String = customization.get("hat", "none")
	if hat == "none": return
	var fabric := MeshFactory.material(Color("e6be7d") if hat == "sun" else Color("769bc8") if hat == "winter" else Color("b9a5dd"))
	MeshFactory.cylinder(body, 0.31, 0.24, 0.18, Vector3(0, 2.53, 0.08), fabric)
	if hat == "sun": MeshFactory.cylinder(body, 0.43, 0.43, 0.035, Vector3(0, 2.45, 0.08), fabric)
	if hat == "winter": MeshFactory.sphere(body, 0.09, Vector3(0, 2.7, 0.08), fabric)

func set_motion_pose(pose: int) -> void:
	if motion_pose == pose: return
	motion_pose = pose
	portrait.texture = CharacterStyle.character_texture(character_id) if pose < 0 else CharacterStyle.motion_texture(character_id, pose)
	portrait.pixel_size = 2.65 / (portrait.texture.get_height() if pose < 0 else CharacterStyle.motion_height(character_id))
	portrait.position.y = portrait.texture.get_height() * portrait.pixel_size / 2 + 0.02
