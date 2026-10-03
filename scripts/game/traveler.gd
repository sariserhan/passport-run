class_name Traveler
extends Node3D

var kids := false
var body: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var contact_shadow: MeshInstance3D
var portrait: Sprite3D
var animation := "thinking"
var animation_clock := 0.0
var animation_paused := false
var reduced_motion := false
var passport_prop: Node3D
var destination_theme := "stone"
var customization := {"outfit": "classic", "hat": "none", "backpack": "classic"}
var reaction: Label3D
var pressure := 0.0:
	set(value):
		pressure = value
		if reaction: reaction.visible = value > 0.65 and animation == "thinking"

func _ready() -> void:
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
	if not kids:
		var shade := MeshFactory.material(Color(0.05, 0.04, 0.04, 0.22))
		shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		contact_shadow = MeshFactory.cylinder(self, 0.32, 0.32, 0.008, Vector3(0, 0.01, 0), shade)
		contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		portrait = Sprite3D.new()
		portrait.texture = preload("res://assets/backpacker-poses.png")
		portrait.hframes = 4
		portrait.vframes = 4
		portrait.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		portrait.pixel_size = 2.8 / (portrait.texture.get_height() / 4.0)
		portrait.position.y = 1.28
		portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(portrait)
		apply_customization()
		return
	var shirt := MeshFactory.material(Color("f6e9ce"))
	var skin := MeshFactory.material(Color("bce2dd"))
	var hair := MeshFactory.material(Color("28546b"))
	var pants := MeshFactory.material(Color("345263"))
	var boots := MeshFactory.material(Color("624335"))
	var bag := MeshFactory.material(Color("b58147"))
	var strap := MeshFactory.material(Color("735539"))
	for side in [-1, 1]:
		MeshFactory.capsule(body, 0.15, 0.42, Vector3(side * 0.20, 0.62, 0), pants)
		MeshFactory.capsule(body, 0.11, 0.40, Vector3(side * 0.20, 0.30, 0), skin)
		MeshFactory.beveled_box(body, Vector3(0.29, 0.22, 0.48), Vector3(side * 0.20, 0.11, -0.06), boots, 0.06)
		MeshFactory.beveled_box(body, Vector3(0.31, 0.06, 0.50), Vector3(side * 0.20, 0.03, -0.06), shirt, 0.025)
	MeshFactory.capsule(body, 0.37, 0.85, Vector3(0, 1.05, 0), shirt)
	MeshFactory.cylinder(body, 0.13, 0.13, 0.22, Vector3(0, 1.42, 0), skin)
	MeshFactory.sphere(body, 0.32, Vector3(0, 1.58, 0), skin, 1.1)
	MeshFactory.sphere(body, 0.34, Vector3(0, 1.77, 0.045), hair, 0.7)
	# Friendly explorer robot; cosmetic only, with identical game rules.
	MeshFactory.cylinder(body, 0.035, 0.035, 0.25, Vector3(0, 2.0, 0), hair)
	MeshFactory.sphere(body, 0.10, Vector3(0, 2.16, 0), bag_material())
	for side in [-1, 1]:
		MeshFactory.sphere(body, 0.065, Vector3(side * 0.12, 1.62, -0.30), hair)
	left_arm = MeshFactory.capsule(body, 0.12, 0.65, Vector3(-0.43, 1.00, 0), skin)
	right_arm = MeshFactory.capsule(body, 0.12, 0.65, Vector3(0.43, 1.00, 0), skin)
	MeshFactory.beveled_box(body, Vector3(0.64, 0.78, 0.40), Vector3(0, 1.02, 0.34), bag, 0.12)
	MeshFactory.beveled_box(body, Vector3(0.58, 0.27, 0.15), Vector3(0, 1.33, 0.52), strap, 0.06)
	MeshFactory.beveled_box(body, Vector3(0.45, 0.26, 0.12), Vector3(0, 0.80, 0.56), bag, 0.05)
	for side in [-1, 1]:
		MeshFactory.box(body, Vector3(0.06, 0.67, 0.045), Vector3(side * 0.20, 1.06, 0.58), strap)
		MeshFactory.beveled_box(body, Vector3(0.11, 0.12, 0.045), Vector3(side * 0.20, 1.13, 0.61), MeshFactory.material(Color("e2c38a")), 0.02)
		MeshFactory.capsule(body, 0.16, 0.30, Vector3(side * 0.39, 1.20, 0), shirt)
		MeshFactory.capsule(body, 0.045, 0.62, Vector3(side * 0.29, 1.15, 0.12), strap)
		MeshFactory.sphere(body, 0.075, Vector3(side * 0.30, 1.61, 0), skin)
	scale = Vector3.ONE * 1.25
	passport_prop = Node3D.new()
	passport_prop.position = Vector3(-0.48, 0.95, 0.48)
	body.add_child(passport_prop)
	MeshFactory.beveled_box(passport_prop, Vector3(0.50, 0.07, 0.33), Vector3.ZERO, shirt, 0.025)
	MeshFactory.box(passport_prop, Vector3(0.03, 0.08, 0.35), Vector3.ZERO, strap)
	passport_prop.hide()

func play_animation(next: String) -> void:
	animation = next
	animation_clock = 0
	body.position.y = 0
	body.rotation = Vector3.ZERO
	body.scale = Vector3.ONE
	reaction.visible = pressure > 0.65 and next == "thinking"
	if portrait:
		portrait.frame = {"thinking": 0, "jump": 4, "celebrate": 8, "pocket": 9, "passport": 10, "stamp": 11, "fall": 12}.get(next, 0)
	if passport_prop:
		passport_prop.visible = next in ["passport", "stamp"]

func _process(delta: float) -> void:
	if animation_paused or reduced_motion:
		return
	animation_clock += delta
	if animation == "thinking":
		if portrait:
			portrait.frame = 3 if pressure > 0.65 else int(animation_clock / 0.8) % 4
			portrait.position.x = sin(animation_clock * 0.8) * 0.035
		body.rotation.z = sin(animation_clock * (8.0 if pressure > 0.65 else 1.5)) * (0.045 if pressure > 0.65 else 0.025)
		body.position.y = sin(animation_clock * 2.0) * 0.012
		if kids:
			right_arm.rotation.z = -maxf(0, sin(animation_clock)) * 0.9
			body.rotation.y = sin(animation_clock * 0.8) * 0.12
	elif animation == "celebrate":
		if destination_theme == "lantern":
			body.rotation.z = sin(minf(animation_clock * 5.0, PI)) * 0.18
		elif destination_theme in ["space", "magic"]:
			body.position.y = absf(sin(animation_clock * 4)) * 0.12
			body.rotation.z = sin(animation_clock * 6) * 0.12
		else:
			body.position.y = absf(sin(animation_clock * 7)) * 0.06
			body.rotation.z = sin(animation_clock * 9) * 0.055
		if kids:
			left_arm.rotation.z = 2.2
			right_arm.rotation.z = -2.2
	elif kids and animation in ["pocket", "passport", "stamp"]:
		right_arm.rotation.z = -0.7 if animation == "pocket" else -1.5
		left_arm.rotation.z = 1.1

func pose_jump(progress: float) -> void:
	if not kids:
		portrait.frame = 4 + mini(3, int(progress * 4))
		contact_shadow.position.y = -sin(progress * PI) * 1.45
		contact_shadow.scale = Vector3.ONE * (1.0 - sin(progress * PI) * 0.25)
		body.rotation.z = sin(progress * PI) * 0.08
		body.scale = Vector3(1.0 + sin(progress * PI) * 0.04, 1.0 - sin(progress * PI) * 0.03, 1.0)
		return
	body.rotation.x = -sin(progress * PI) * 0.18
	left_arm.rotation.z = sin(progress * PI) * 0.65
	right_arm.rotation.z = -sin(progress * PI) * 0.65

func pose_fall(progress: float) -> void:
	if not kids:
		portrait.frame = 12 + mini(3, int(progress * 4))
		contact_shadow.hide()
		body.rotation.z = progress * 0.7
		body.scale = Vector3.ONE * (1.0 - progress * 0.18)
		return
	left_arm.rotation.z = progress * 2.3
	right_arm.rotation.z = -progress * 2.3
	body.rotation.z = progress * 0.28

func bag_material() -> StandardMaterial3D:
	return MeshFactory.material(Color("a6e771"))

func apply_customization() -> void:
	var outfit: String = customization.get("outfit", "classic")
	portrait.modulate = Color(CharacterStyle.OUTFITS.get(outfit, CharacterStyle.OUTFITS.classic).color)
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
