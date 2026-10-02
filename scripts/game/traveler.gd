class_name Traveler
extends Node3D

var kids := false
var body: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var contact_shadow: MeshInstance3D

func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	if not kids:
		var shade := MeshFactory.material(Color(0.05, 0.04, 0.04, 0.22))
		shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		contact_shadow = MeshFactory.cylinder(self, 0.32, 0.32, 0.008, Vector3(0, 0.01, 0), shade)
		contact_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var portrait := Sprite3D.new()
		portrait.texture = preload("res://assets/backpacker.png")
		portrait.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		portrait.pixel_size = 2.8 / portrait.texture.get_height()
		portrait.position.y = 1.28
		portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(portrait)
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

func pose_jump(progress: float) -> void:
	if not kids:
		contact_shadow.position.y = 0.04 - position.y
		contact_shadow.scale = Vector3.ONE * (1.0 - sin(progress * PI) * 0.25)
		body.rotation.z = sin(progress * PI) * 0.08
		body.scale = Vector3(1.0 + sin(progress * PI) * 0.04, 1.0 - sin(progress * PI) * 0.03, 1.0)
		return
	body.rotation.x = -sin(progress * PI) * 0.18
	left_arm.rotation.z = sin(progress * PI) * 0.65
	right_arm.rotation.z = -sin(progress * PI) * 0.65

func pose_fall(progress: float) -> void:
	if not kids:
		contact_shadow.hide()
		body.rotation.z = progress * 0.7
		body.scale = Vector3.ONE * (1.0 - progress * 0.18)
		return
	left_arm.rotation.z = progress * 2.3
	right_arm.rotation.z = -progress * 2.3
	body.rotation.z = progress * 0.28

func bag_material() -> StandardMaterial3D:
	return MeshFactory.material(Color("a6e771"))
