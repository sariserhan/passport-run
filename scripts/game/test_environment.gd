class_name TestEnvironment
extends Node3D

var config: DifficultyConfig
var country_id: String = ""
var endless: bool = false
var reduced_motion := false
var atmosphere: WorldAtmosphere
var finish_position := Vector3.ZERO
var starting_tile: PathTile
const INFINITE_BACKDROP := preload("res://assets/infinite-backdrop.png")

# Lighting and physical platforms over an illustrated destination matte.
func _ready() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CANVAS
	environment.background_canvas_max_layer = -1
	environment.background_color = Color("bedfe6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7efff")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0ce")
	sun.light_energy = 0.68
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	add_child(sun)
	var backdrop := CanvasLayer.new()
	backdrop.name = "Scenery"
	backdrop.layer = -1
	add_child(backdrop)
	var image := TextureRect.new()
	image.name = "Backdrop"
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture = INFINITE_BACKDROP if endless else GameCatalog.backdrop(country_id)
	backdrop.add_child(image)
	atmosphere = WorldAtmosphere.new()
	atmosphere.reduced_motion = reduced_motion
	atmosphere.cosmic = country_id in ["SPACE", "MOON", "MARS", "SATURN"]
	atmosphere.underwater = country_id == "UNDERWATER"
	atmosphere.destination_theme = DestinationTheme.style("INFINITE" if endless else country_id)
	backdrop.add_child(atmosphere)
	var finish_z: float = -(config.row_count + 1) * config.row_spacing - 1.15
	var stone := MeshFactory.stone_material(DestinationTheme.color("INFINITE" if endless else country_id))
	starting_tile = PathTile.new()
	add_child(starting_tile)
	starting_tile.build(-1, 0, Vector3(config.lane_count * config.lane_spacing + 0.5, 0.6, 3.9))
	starting_tile.position = Vector3(0, 0, 0.7)
	starting_tile.neutral = stone
	starting_tile.apply_destination("INFINITE" if endless else country_id)
	starting_tile.set_state(PathTile.State.NORMAL)
	finish_position = Vector3(0, 0.03, finish_z)
	if endless:
		return
	MeshFactory.beveled_box(self, Vector3(config.lane_count * config.lane_spacing + 0.5, 0.6, 3.4), Vector3(0, -0.3, finish_z), stone)
	if atmosphere.destination_theme == "lantern":
		for side in [-1, 1]:
			var pole := Vector3(side * (config.lane_count * config.lane_spacing / 2.0 + 0.4), 0, -config.row_spacing * 3)
			MeshFactory.cylinder(self, 0.055, 0.055, 2.8, pole + Vector3.UP * 0.7, MeshFactory.material(Color("5d453b")))
			var glow := MeshFactory.material(Color("ec775b"))
			glow.emission_enabled = true
			glow.emission = Color("b85534")
			MeshFactory.sphere(self, 0.32, pole + Vector3.UP * 2, glow, 1.3)
