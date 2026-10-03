extends SceneTree

var checks := 0
var failures := 0

func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func _initialize() -> void:
 create_timer(60).timeout.connect(func(): quit(1))
 run.call_deferred()

func run() -> void:
 var catalog = load("res://scripts/core/game_catalog.gd")
 var art = load("res://scripts/core/realistic_art.gd")
 var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/realistic-explorer.json"))
 expect(data is Array and data.size() == 16, "Export contains all character frame alignment data")
 var jumping: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/jumping-explorer.json"))
 expect(jumping is Dictionary and jumping.human.size() == 16 and jumping.robot.size() == 16, "Export contains complete front-facing jump poses for both characters")
 expect(catalog.DESTINATIONS.size() == 282, "Export contains the full destination catalog")
 var seen := {}
 for id in catalog.DESTINATIONS:
  var texture: Texture2D = catalog.backdrop(id)
  expect(texture != null and texture.get_width() >= 512 and texture.get_height() >= 768, "High-detail exported backdrop loads: " + id)
  if texture == null: continue
  var key: String = texture.atlas.resource_path + str(texture.region) if texture is AtlasTexture else texture.resource_path
  expect(key not in seen, "Export keeps separate artwork: " + id)
  seen[key] = true
 expect(catalog.backdrop_cache.size() <= 8 and catalog.country_atlases.size() <= 4, "Exported scenery caches remain bounded")
 for name in ["explorer", "memory-explorer", "robot-explorer", "objects", "medals", "materials", "menu", "infinite"]:
  var texture = load("res://assets/realistic/" + name + ".png")
  expect(texture is Texture2D and texture.get_width() > 900, "Exported realistic asset loads: " + name)
 for theme in ["stone", "sand", "ice", "jungle"]:
  expect(art.surface_3d(theme).get_image().has_mipmaps(), "Exported material works in 3D: " + theme)
 expect(not ResourceLoader.exists("res://assets/menu-key-art.png"), "Export omits superseded illustrated scenery")
 var game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://realistic-export-qa.json"
 root.add_child(game)
 await process_frame
 expect(game.menu.visible, "Exported game scene opens the menu")
 game.queue_free()
 await process_frame
 print("Exported realistic artwork checks: ", checks, "; failures: ", failures)
 quit(1 if failures else 0)
