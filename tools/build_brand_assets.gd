extends SceneTree
# Deterministic packaging sizes from the selected illustration; no artwork changes.
const ROOT := "res://assets/branding/"
const IOS_SIZES := [40, 58, 60, 76, 80, 87, 114, 120, 128, 136, 152, 167, 180, 192, 1024]
func _initialize() -> void:
 var source := Image.load_from_file(ROOT + "icon-source.png")
 if source.is_empty(): push_error("Brand icon source missing"); quit(1); return
 source.convert(Image.FORMAT_RGB8)
 for pixels in IOS_SIZES:
  var image := source.duplicate() as Image
  image.resize(pixels, pixels, Image.INTERPOLATE_LANCZOS)
  if image.save_png(ROOT + ("app-icon.png" if pixels == 1024 else "ios-icon-%d.png" % pixels)) != OK: quit(1); return
 var iconset := ROOT + "PassportRun.iconset/"
 DirAccess.make_dir_recursive_absolute(iconset)
 for pixels in [16, 32, 128, 256, 512]:
  for scale in [1, 2]:
   var image := source.duplicate() as Image
   image.resize(pixels * scale, pixels * scale, Image.INTERPOLATE_LANCZOS)
   if image.save_png(iconset + "icon_%dx%d%s.png" % [pixels, pixels, "@2x" if scale == 2 else ""]) != OK: quit(1); return
 print("Brand icon sizes generated: iPhone, iPad, notification, settings, Spotlight, App Store, macOS")
 quit()
