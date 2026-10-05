extends SceneTree

func _initialize() -> void:
 var seen := {}
 for id in GameCatalog.DESTINATIONS:
  var texture := GameCatalog.backdrop(id)
  assert(texture != null, "Destination artwork must exist: " + id)
  var key := texture.resource_path
  if texture is AtlasTexture:
   assert(texture.atlas != null and texture.region.has_area(), "Atlas image is valid: " + id)
   assert(texture.atlas.resource_path.begins_with("res://assets/realistic/details/"), "The selected high-detail atlas is used: " + id)
   assert(texture.region.size.x >= 512 and texture.region.size.y >= 768, "Each destination keeps phone-sized photographic detail: " + id)
   var bounds := Rect2(Vector2.ZERO, texture.atlas.get_size())
   assert(bounds.encloses(texture.region), "Artwork fits its atlas: " + id)
   key = texture.atlas.resource_path + str(texture.region)
  assert(not seen.has(key), "Destinations must never share artwork: " + id)
  seen[key] = id
  assert(GameCatalog.backdrop_cache.size() <= GameCatalog.BACKDROP_CACHE_LIMIT, "Destination texture cache stays bounded")
  assert(GameCatalog.country_atlases.size() <= GameCatalog.ATLAS_CACHE_LIMIT, "Atlas texture cache stays bounded")
 assert(seen.size() == 282)
 assert(GameCatalog.backdrop("AF").resource_path == "res://assets/realistic/backdrops/AF.png", "Afghanistan uses its own mountain scenery")
 assert(GameCatalog.backdrop("AF") != GameCatalog.backdrop("TH"))
 var explorer: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/realistic-explorer.json"))
 assert(explorer is Array and explorer.size() == 16, "Runtime character-alignment data ships with all frames")
 assert(RealisticArt.surface_3d("stone").get_image().has_mipmaps(), "Memory-path surfaces retain distant texture detail without shimmer")
 var souvenirs := {}
 for id in GameCatalog.DESTINATIONS:
  assert(id in DestinationTheme.SOUVENIRS, "Every destination has its own named souvenir: " + id)
  assert(not souvenirs.has(DestinationTheme.souvenir(id)), "Souvenirs never repeat between destinations: " + id)
  souvenirs[DestinationTheme.souvenir(id)] = id
 assert(DestinationTheme.souvenir("RU") == "Painted nesting doll")
 var pictured := 0
 for id in GameCatalog.DESTINATIONS:
  var path := "res://assets/realistic/souvenirs/%s.png" % id
  if not ResourceLoader.exists(path): continue
  pictured += 1
  var picture: Texture2D = load(path)
  assert(picture.get_size() == Vector2(512, 512), "Souvenir pictures are 512x512: " + id)
  var pixels := picture.get_image()
  if pixels.is_compressed(): pixels.decompress()
  for corner in [Vector2i(0, 0), Vector2i(511, 0), Vector2i(0, 511), Vector2i(511, 511)]:
   assert(pixels.get_pixelv(corner).a < 0.05, "Souvenir pictures are cut out on a transparent background: " + id)
 for file in DirAccess.get_files_at("res://assets/realistic/souvenirs"):
  if file.ends_with(".png"): assert(file.get_basename() in GameCatalog.DESTINATIONS, "Every souvenir picture belongs to a destination: " + file)
 print("Souvenir pictures: %d of %d destinations" % [pictured, GameCatalog.DESTINATIONS.size()])
 print("Unique artwork checks: all 282 destinations have separate images")
 quit()
