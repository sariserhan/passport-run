class_name PathTile
extends StaticBody3D

enum State { NORMAL, REVEALED, CORRECT, CRACKING, FALLING }
var row: int
var lane: int
var state: State = State.NORMAL
var slab: MeshInstance3D
var marker: Node3D
var pressure_progress := 0.0
var cracks: Node3D
var theme := "stone"
var decoration: Node3D
var neutral := MeshFactory.stone_material(Color("777a83"))
var green := MeshFactory.stone_material(Color("84da62"))
var landed := MeshFactory.stone_material(Color("78bbb0"))
var broken := MeshFactory.stone_material(Color("e9926a"))

func build(row_index: int, lane_index: int, size: Vector3) -> void:
	row = row_index
	lane = lane_index
	collision_layer = 1
	collision_mask = 0
	slab = MeshFactory.beveled_box(self, size, Vector3(0, -size.y / 2, 0), neutral)
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
	var dark := MeshFactory.material(Color("302b2a"))
	var fissure: Array[Vector3] = [Vector3(-0.28, 0.012, 0.8), Vector3(0.08, 0.012, 0.48), Vector3(-0.14, 0.012, 0.18), Vector3(0.19, 0.012, -0.13), Vector3(-0.03, 0.012, -0.46), Vector3(0.26, 0.012, -0.82)]
	for index in fissure.size() - 1:
		add_fissure(fissure[index], fissure[index + 1], dark)
	add_fissure(fissure[2], Vector3(-0.77, 0.012, -0.1), dark)
	add_fissure(fissure[3], Vector3(0.77, 0.012, 0.24), dark)
	cracks.visible = false

func add_fissure(from: Vector3, to: Vector3, material: Material) -> void:
	var direction := to - from
	var crack := MeshFactory.box(cracks, Vector3(0.026, 0.008, direction.length() + 0.025), (from + to) / 2, material)
	crack.rotation.y = atan2(direction.x, direction.z)

func apply_destination(id: String) -> void:
	theme = DestinationTheme.style(id)
	neutral.albedo_color = DestinationTheme.color(id)
	neutral.roughness = 0.25 if theme in ["ice", "ocean"] else 0.85
	if theme in ["space", "magic", "lava"]:
		neutral.emission_enabled = true
		neutral.emission = neutral.albedo_color * 0.25
	decoration = Node3D.new()
	add_child(decoration)
	var accent := MeshFactory.material(neutral.albedo_color.lightened(0.3))
	# Side ornaments never change collision or identify the safe lane.
	if theme in ["space", "magic", "lava"]:
		accent.emission_enabled = true
		accent.emission = accent.albedo_color * 0.65
	for side in [-1, 1]:
		MeshFactory.box(decoration, Vector3(0.035, 0.025, 1.35), Vector3(side * 0.83, 0.006, 0), accent)
	set_state(state)

func set_state(next: State) -> void:
	state = next
	marker.visible = state == State.REVEALED or state == State.CORRECT
	set_pressure(1.0 if state in [State.CRACKING, State.FALLING] else 0.0)
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

func set_pressure(progress: float) -> void:
	pressure_progress = clampf(progress, 0, 1)
	cracks.visible = pressure_progress > 0.05
	for index in cracks.get_child_count():
		var crack: Node3D = cracks.get_child(index)
		var growth := clampf((pressure_progress - index * 0.09) / 0.4, 0, 1)
		crack.visible = growth > 0
		crack.scale = Vector3(0.4 + growth * 0.6, 1, maxf(0.01, growth))
	if state not in [State.CRACKING, State.FALLING]:
		landed.albedo_color = Color("78bbb0").lerp(Color("e9926a"), pressure_progress)
