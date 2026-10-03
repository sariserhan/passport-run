extends SceneTree

func _initialize() -> void:
 var seen := {}
 for id in GameCatalog.DESTINATIONS:
  var texture := GameCatalog.backdrop(id)
  assert(texture != null, "Destination artwork must exist: " + id)
  var key := texture.resource_path
  if texture is AtlasTexture:
   assert(texture.atlas != null and texture.region.has_area(), "Atlas image is valid: " + id)
   var bounds := Rect2(Vector2.ZERO, texture.atlas.get_size())
   assert(bounds.encloses(texture.region), "Artwork fits its atlas: " + id)
   key = texture.atlas.resource_path + str(texture.region)
  assert(not seen.has(key), "Destinations must never share artwork: " + id)
  seen[key] = id
 assert(seen.size() == 282)
 assert(GameCatalog.backdrop("AF").resource_path == "res://assets/backdrops/AF.png", "Afghanistan uses its own mountain scenery")
 assert(GameCatalog.backdrop("AF") != GameCatalog.backdrop("TH"))
 print("Unique artwork checks: all 282 destinations have separate images")
 quit()
