class_name TestEnvironment
extends Node3D

var config: DifficultyConfig
var country_id: String = ""
var endless: bool = false

# An original temporary coastal set. No country or progression logic.
func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("bedfe6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7efff")
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)
	var water := MeshFactory.material(Color("c7a67c") if country_id == "EG" else Color("278fba"), 0.35)
	MeshFactory.box(self, Vector3(250, 0.3, 250), Vector3(0, -8, -30), water)
	var rock := MeshFactory.material(Color("d2b990"))
	var grass := MeshFactory.material(Color("79a970"))
	var leaves := MeshFactory.material(Color("d9a0b4") if country_id == "JP" else Color("408677"))
	var trunk := MeshFactory.material(Color("8a735b"))
	var foam := MeshFactory.material(Color("80c9d1"))
	for i in 16:
		var side: int = -1 if i % 2 == 0 else 1
		var pos := Vector3(side * (11.0 + (i % 3) * 3.0), -6.7, 12 - i * 4.8)
		MeshFactory.cylinder(self, 3.7, 2.7, 3.1, pos, rock)
		MeshFactory.cylinder(self, 2.85, 2.7, 0.25, pos + Vector3(0, 1.6, 0), grass)
		for j in 3:
			var tree_pos := pos + Vector3((j - 1) * 1.5, 2.3, (j % 2) * 1.4 - 0.7)
			MeshFactory.cylinder(self, 0.12, 0.09, 1.6, tree_pos, trunk)
			MeshFactory.sphere(self, 0.9, tree_pos + Vector3(0, 1.0, 0), leaves, 1.4)
		MeshFactory.box(self, Vector3(3.8, 0.025, 0.12), pos + Vector3(side * 2, -1.1, 3.5), foam)
	add_landmarks()
	var finish_z: float = -(config.row_count + 1) * config.row_spacing - 1.15
	var stone := MeshFactory.material(Color("e4d0a9"))
	MeshFactory.box(self, Vector3(config.lane_count * config.lane_spacing + 0.5, 1.0, 3.9), Vector3(0, -0.5, 0.7), stone)
	if endless:
		return
	MeshFactory.box(self, Vector3(config.lane_count * config.lane_spacing + 0.5, 1.0, 3.4), Vector3(0, -0.5, finish_z), stone)
	var blue := MeshFactory.material(Color("246488"))
	var gold := MeshFactory.material(Color("f9ce72"))
	for side in [-1, 1]:
		MeshFactory.cylinder(self, 0.2, 0.16, 4.2, Vector3(side * 2.8, 2.1, finish_z - 0.4), blue)
		MeshFactory.sphere(self, 0.25, Vector3(side * 2.8, 4.35, finish_z - 0.4), gold)
	MeshFactory.box(self, Vector3(5.9, 0.9, 0.22), Vector3(0, 3.7, finish_z - 0.4), blue)
	var finish := Label3D.new()
	finish.text = "BON VOYAGE" if country_id.is_empty() else country_id
	finish.font_size = 64
	finish.pixel_size = 0.007
	finish.position = Vector3(0, 3.7, finish_z - 0.24)
	finish.modulate = Color("fff2c8")
	add_child(finish)

func add_landmarks() -> void:
	if country_id.is_empty():
		return
	var stone := MeshFactory.material(Color(GameCatalog.COUNTRIES[country_id].color))
	var light := MeshFactory.material(Color("ead8b6"))
	var dark := MeshFactory.material(Color("38566c"))
	var gold := MeshFactory.material(Color("d5a74d"))
	var span: float = config.lane_count * config.lane_spacing / 2.0 + 2.8
	for side in [-1, 1]:
		var landmark := Node3D.new()
		landmark.position = Vector3(side * span, -5.1, -config.row_count * config.row_spacing * 0.6)
		add_child(landmark)
		match country_id:
			"EG":
				for i in 3:
					var pyramid := MeshFactory.cylinder(landmark, 3.7 - i * 0.6, 0, 5.8 - i, Vector3(i * side * 2, 2.8 - i * 0.5, -i * 4.0), light)
					pyramid.mesh.radial_segments = 4
					pyramid.rotation.y = PI / 4
			"FR":
				# A four-legged, open stylized tower, authored from simple geometry.
				for x in [-1, 1]:
					for z in [-1, 1]:
						var leg := MeshFactory.box(landmark, Vector3(0.35, 5.5, 0.35), Vector3(x * 0.85, 2.6, z * 0.85), dark)
						leg.rotation.z = x * 0.22
						leg.rotation.x = -z * 0.22
				MeshFactory.box(landmark, Vector3(2.8, 0.3, 2.8), Vector3(0, 2.5, 0), gold)
				MeshFactory.cylinder(landmark, 0.8, 0.04, 5.0, Vector3(0, 6.7, 0), dark)
				MeshFactory.box(landmark, Vector3(1.8, 0.25, 1.8), Vector3(0, 4.5, 0), gold)
			"TR":
				MeshFactory.box(landmark, Vector3(3.8, 3.3, 4.2), Vector3(0, 1.65, 0), light)
				MeshFactory.sphere(landmark, 2.0, Vector3(0, 3.5, 0), stone, 0.7)
				for x in [-1, 1]:
					MeshFactory.cylinder(landmark, 0.23, 0.2, 7, Vector3(x * 2.8, 3.5, 0), light)
					MeshFactory.cylinder(landmark, 0.4, 0, 1.3, Vector3(x * 2.8, 7.5, 0), dark)
			"JP":
				for i in 3:
					var width: float = 4.0 - i * 0.75
					MeshFactory.box(landmark, Vector3(width - 0.7, 1.4, width - 0.7), Vector3(0, i * 1.8 + 0.7, 0), light)
					var roof := MeshFactory.cylinder(landmark, width, width * 0.28, 0.8, Vector3(0, i * 1.8 + 1.7, 0), dark)
					roof.mesh.radial_segments = 4
					roof.rotation.y = PI / 4
			"US":
				for i in 4:
					var height: float = 4.0 + (i % 3) * 2.0
					var pos := Vector3(side * (i % 2) * 2, height / 2, -i * 2.4)
					MeshFactory.box(landmark, Vector3(1.65, height, 1.7), pos, stone)
					for floor_index in int(height):
						MeshFactory.box(landmark, Vector3(1.3, 0.22, 0.04), Vector3(pos.x, floor_index + 0.6, pos.z + 0.87), light)
