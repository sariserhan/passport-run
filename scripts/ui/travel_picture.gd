class_name TravelPicture
extends RefCounted

static func save_picture(owner: Node, profile: PlayerProfile, kind: String, id: String, path: String, draft: Dictionary = {}) -> Error:
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
  room.rare_keepsakes = profile.rare_keepsakes.duplicate(true)
  room.buddy_kind = profile.travel_buddy
  room.profile = profile
  room.positions = profile.room_positions.duplicate(true)
  picture = room
 elif kind == "photo":
  var photo := TravelPhoto.new()
  photo.profile = profile
  photo.destination_id = id
  photo.caption = draft.get("caption", profile.activities.custom.motto)
  photo.pose = draft.get("pose", profile.activities.custom.pose)
  photo.frame = draft.get("frame", "classic")
  photo.buddy = profile.travel_buddy
  picture = photo
 elif kind == "scrapbook":
  var scrapbook := TravelScrapbook.new()
  scrapbook.profile = profile
  var index := int(id)
  if index < 0 or index >= profile.activities.scrapbook.size(): viewport.queue_free(); return ERR_INVALID_PARAMETER
  scrapbook.page = profile.activities.scrapbook[index]
  picture = scrapbook
 elif kind == "journal":
  var journal := TravelJournalPostcard.new()
  journal.page = profile.journal_page(id)
  picture = journal
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
 var full_height := maxi(1000, int(ceil(picture.get_combined_minimum_size().y)) + 140)
 viewport.size.y = full_height
 background.size.y = full_height
 picture.size.y = full_height - 140
 await owner.get_tree().process_frame
 await RenderingServer.frame_post_draw
 var error := viewport.get_texture().get_image().save_png(path)
 viewport.queue_free()
 return error
