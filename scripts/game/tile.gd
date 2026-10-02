class_name PathTile
extends StaticBody3D

enum State { NORMAL, REVEALED, CORRECT, CRACKING, FALLING }
var row: int
var lane: int
var state: State = State.NORMAL
var slab: MeshInstance3D
var marker: Node3D
var cracks: Node3D
var neutral := MeshFactory.material(Color("94a9b3"))
var green := MeshFactory.material(Color("97e85f"))
var landed := MeshFactory.material(Color("78bbb0"))
var broken := MeshFactory.material(Color("e9926a"))

func build(row_index: int, lane_index: int, size: Vector3) -> void:
	row = row_index
	lane = lane_index
	collision_layer = 1
	collision_mask = 0
	slab = MeshFactory.box(self, size, Vector3(0, -size.y / 2, 0), neutral)
	MeshFactory.box(self, Vector3(size.x * 0.91, 0.035, size.z * 0.91), Vector3(0, 0.018, 0), neutral)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size + Vector3(0.05, 0.04, 0.05)
	collider.shape = shape
	collider.position.y = -size.y / 2
	add_child(collider)
	marker = Node3D.new()
	add_child(marker)
	var white := MeshFactory.material(Color("f5ffda"))
	var points: Array[Vector3] = [Vector3(-0.34, 0.05, -0.03), Vector3(-0.08, 0.05, 0.23), Vector3(0.36, 0.05, -0.34)]
	for i in 2:
		var direction := points[i + 1] - points[i]
		var stroke := MeshFactory.box(marker, Vector3(0.14, 0.025, direction.length() + 0.08), (points[i] + points[i + 1]) / 2, white)
		stroke.rotation.y = atan2(direction.x, direction.z)
	marker.visible = false
	cracks = Node3D.new()
	add_child(cracks)
	var dark := MeshFactory.material(Color("654843"))
	for index in 3:
		var crack := MeshFactory.box(cracks, Vector3(0.055, 0.03, 0.85), Vector3((index - 1) * 0.27, 0.07, (index - 1) * 0.5), dark)
		crack.rotation.y = 0.7 if index % 2 else -0.55
	cracks.visible = false

func set_state(next: State) -> void:
	state = next
	marker.visible = state == State.REVEALED or state == State.CORRECT
	cracks.visible = state == State.CRACKING or state == State.FALLING
	var mat: Material = neutral
	if state == State.REVEALED:
		mat = green
	elif state == State.CORRECT:
		mat = landed
	elif state == State.CRACKING or state == State.FALLING:
		mat = broken
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = mat
