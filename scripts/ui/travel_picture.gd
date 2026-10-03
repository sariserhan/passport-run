class_name TravelPicture
extends RefCounted

static func save_picture(owner: Node, profile: PlayerProfile, kind: String, id: String, path: String) -> Error:
 if DisplayServer.get_name() == "headless": return ERR_UNAVAILABLE
 var viewport := SubViewport.new()
 viewport.size = Vector2i(720, 1000)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 owner.add_child(viewport)
 var background := ColorRect.new()
 background.color = Color("153e57")
 background.size = Vector2(720, 1000)
 viewport.add_child(background)
 var title := Label.new()
 title.text = "PASSPORT RUN · MY TRAVEL " + kind.to_upper()
 title.position = Vector2(30, 25)
 title.add_theme_font_size_override("font_size", 28)
 background.add_child(title)
 var picture: Control
 if kind == "room":
  var room := SouvenirRoom.new()
  room.destinations = profile.room_display.duplicate()
  room.postcards = profile.room_postcards.duplicate()
  room.decor = profile.room_decor.duplicate()
  room.positions = profile.room_positions.duplicate(true)
  picture = room
 else:
  var album := TravelAlbumPage.new()
  album.destination_id = id
  album.profile = profile
  picture = album
 picture.position = Vector2(30, 90)
 picture.size = Vector2(660, 860)
 background.add_child(picture)
 await owner.get_tree().process_frame
 await owner.get_tree().process_frame
 await RenderingServer.frame_post_draw
 var error := viewport.get_texture().get_image().save_png(path)
 viewport.queue_free()
 return error
