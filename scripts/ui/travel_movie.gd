class_name TravelMovie
extends RefCounted
# A web-safe color palette plus grayscale. Clear codes keep LZW at nine bits.
static func word(value: int) -> PackedByteArray: return PackedByteArray([value & 255, (value >> 8) & 255])
static func encode(images: Array[Image], delay: int = 100) -> PackedByteArray:
 if images.is_empty(): return PackedByteArray()
 var output := "GIF89a".to_ascii_buffer()
 output.append_array(word(images[0].get_width()))
 output.append_array(word(images[0].get_height()))
 output.append_array(PackedByteArray([0xf7, 0, 0]))
 for r in 6:
  for g in 6:
   for b in 6: output.append_array(PackedByteArray([r * 51, g * 51, b * 51]))
 for gray in 40:
  var channel := int(round(float(gray) * 255 / 39))
  output.append_array(PackedByteArray([channel, channel, channel]))
 output.append_array(PackedByteArray([0x21, 0xff, 11]))
 output.append_array("NETSCAPE2.0".to_ascii_buffer())
 output.append_array(PackedByteArray([3, 1, 0, 0, 0]))
 for image in images:
  if image.get_size() != images[0].get_size(): return PackedByteArray()
  output.append_array(PackedByteArray([0x21, 0xf9, 4, 4]))
  output.append_array(word(delay))
  output.append_array(PackedByteArray([0, 0, 0x2c, 0, 0, 0, 0]))
  output.append_array(word(image.get_width()))
  output.append_array(word(image.get_height()))
  output.append_array(PackedByteArray([0, 8]))
  var bytes := PackedByteArray()
  var accumulator := 0
  var bits := 0
  var group := 0
  var codes: Array[int] = [256]
  for y in image.get_height():
   for x in image.get_width():
    var pixel := image.get_pixel(x, y)
    var nearest := int(round(pixel.r * 5)) * 36 + int(round(pixel.g * 5)) * 6 + int(round(pixel.b * 5))
    if maxf(pixel.r, maxf(pixel.g, pixel.b)) - minf(pixel.r, minf(pixel.g, pixel.b)) < 0.06:
     nearest = 216 + int(round((pixel.r + pixel.g + pixel.b) / 3 * 39))
    codes.append(nearest)
    group += 1
    if group == 200: codes.append(256); group = 0
  codes.append(257)
  for code in codes:
   accumulator |= code << bits
   bits += 9
   while bits >= 8:
    bytes.append(accumulator & 255)
    accumulator >>= 8
    bits -= 8
  if bits > 0: bytes.append(accumulator & 255)
  for offset in range(0, bytes.size(), 255):
   var block := bytes.slice(offset, mini(offset + 255, bytes.size()))
   output.append(block.size())
   output.append_array(block)
  output.append(0)
 output.append(0x3b)
 return output
static func save(owner: Node, profile: PlayerProfile, recap: Dictionary, path: String) -> int:
 var viewport := SubViewport.new()
 viewport.size = Vector2i(320, 600)
 viewport.transparent_bg = false
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 owner.add_child(viewport)
 var frames: Array[Image] = []
 var route: Array = recap.route
 # Full replay keeps every stop; the portable movie samples at most twelve evenly spaced stops.
 var sampled: Array = []
 for i in mini(12, route.size()): sampled.append(route[int(round(float(i) * (route.size() - 1) / maxf(1, mini(12, route.size()) - 1)))])
 for i in sampled.size():
  var photo := TravelPhoto.new()
  photo.profile = profile
  photo.destination_id = sampled[i]
  photo.caption = recap.name + " · " + str(i + 1) + " / " + str(sampled.size())
  photo.pose = "cheer"
  photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  viewport.add_child(photo)
  await owner.get_tree().process_frame
  await RenderingServer.frame_post_draw
  var image := viewport.get_texture().get_image()
  image.resize(240, 450, Image.INTERPOLATE_BILINEAR)
  frames.append(image)
  viewport.remove_child(photo)
  photo.queue_free()
 viewport.queue_free()
 var data := encode(frames, 150)
 if data.is_empty(): return ERR_INVALID_DATA
 var file := FileAccess.open(path, FileAccess.WRITE)
 if not file: return FileAccess.get_open_error()
 file.store_buffer(data)
 file.close()
 return OK
