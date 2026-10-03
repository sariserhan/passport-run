class_name RealisticArt
extends RefCounted

const EXPLORER := preload("res://assets/realistic/explorer.png")
const OBJECTS := preload("res://assets/realistic/objects.png")
const MEDALS := preload("res://assets/realistic/medals.png")
const MATERIALS := preload("res://assets/realistic/materials.png")
static var regions: Dictionary = {}
static var explorer_frames: Array = []
static var surfaces_3d: Dictionary = {}

static func object(index: int) -> Texture2D:
 return region(OBJECTS, index, Vector2i(4, 2))

static func surface(theme: String) -> Texture2D:
 return region(MATERIALS, 1 if theme in ["sand", "lava"] else 2 if theme == "ice" else 3 if theme in ["jungle", "lantern"] else 0, Vector2i(2, 2))

static func region(texture: Texture2D, index: int, grid: Vector2i) -> Texture2D:
 var key := texture.resource_path + ":" + str(index)
 if key not in regions:
  var result := AtlasTexture.new()
  result.atlas = texture
  var cell := Vector2(texture.get_size()) / Vector2(grid)
  result.region = Rect2(Vector2(index % grid.x, index / grid.x) * cell, cell)
  result.filter_clip = true
  regions[key] = result
 return regions[key]

static func explorer_frame(index: int) -> Dictionary:
 if explorer_frames.is_empty(): explorer_frames = JSON.parse_string(FileAccess.get_file_as_string("res://resources/realistic-explorer.json"))
 return explorer_frames[clampi(index, 0, 15)]

static func surface_3d(theme: String) -> Texture2D:
 var atlas := surface(theme) as AtlasTexture
 var key := str(atlas.region)
 if key not in surfaces_3d:
  var source := MATERIALS.get_image()
  if source.is_compressed(): source.decompress()
  var cropped := source.get_region(Rect2i(atlas.region))
  cropped.generate_mipmaps()
  surfaces_3d[key] = ImageTexture.create_from_image(cropped)
 return surfaces_3d[key]

static func medal(index: int) -> Texture2D:
 return region(MEDALS, clampi(index, 1, 3) - 1, Vector2i(3, 1))
