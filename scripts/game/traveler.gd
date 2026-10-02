class_name Traveler
extends Node3D

var body: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D

func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	var shirt := MeshFactory.material(Color("f6e9ce"))
	var skin := MeshFactory.material(Color("dca578"))
	var hair := MeshFactory.material(Color("43312d"))
	var pants := MeshFactory.material(Color("345263"))
	var boots := MeshFactory.material(Color("624335"))
	var bag := MeshFactory.material(Color("d59433"))
	var strap := MeshFactory.material(Color("735539"))
	for side in [-1, 1]:
		MeshFactory.box(body, Vector3(0.23, 0.48, 0.28), Vector3(side * 0.19, 0.42, 0), pants)
		MeshFactory.box(body, Vector3(0.28, 0.19, 0.44), Vector3(side * 0.19, 0.1, -0.06), boots)
	MeshFactory.cylinder(body, 0.36, 0.42, 0.65, Vector3(0, 0.93, 0), shirt)
	MeshFactory.sphere(body, 0.32, Vector3(0, 1.58, 0), skin, 1.1)
	MeshFactory.sphere(body, 0.34, Vector3(0, 1.77, 0.045), hair, 0.7)
	for i in 4:
		MeshFactory.sphere(body, 0.16, Vector3(-0.23 + i * 0.14, 1.87, 0.01), hair)
	left_arm = MeshFactory.cylinder(body, 0.12, 0.13, 0.62, Vector3(-0.47, 0.92, 0), skin)
	right_arm = MeshFactory.cylinder(body, 0.12, 0.13, 0.62, Vector3(0.47, 0.92, 0), skin)
	MeshFactory.box(body, Vector3(0.6, 0.67, 0.34), Vector3(0, 0.99, 0.34), bag)
	MeshFactory.box(body, Vector3(0.42, 0.25, 0.09), Vector3(0, 0.79, 0.54), strap)
	for side in [-1, 1]:
		MeshFactory.box(body, Vector3(0.075, 0.72, 0.08), Vector3(side * 0.2, 1.01, 0.54), strap)

func pose_jump(progress: float) -> void:
	body.rotation.x = -sin(progress * PI) * 0.18
	left_arm.rotation.z = sin(progress * PI) * 0.65
	right_arm.rotation.z = -sin(progress * PI) * 0.65

func pose_fall(progress: float) -> void:
	left_arm.rotation.z = progress * 2.3
	right_arm.rotation.z = -progress * 2.3
	body.rotation.z = progress * 0.28
