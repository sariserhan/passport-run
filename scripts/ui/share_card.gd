class_name ShareCard
extends RefCounted

static func save_card(owner_node: Node, session: JourneySession, score: int, hud: GameHUD, filename: String = "user://passport-run-share.png") -> Error:
	if DisplayServer.get_name() == "headless":
		return ERR_UNAVAILABLE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1000)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	owner_node.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("153e57")
	background.size = Vector2(720, 1000)
	viewport.add_child(background)
	var stack := VBoxContainer.new()
	stack.position = Vector2(48, 38)
	stack.size = Vector2(624, 924)
	stack.add_theme_constant_override("separation", 12)
	background.add_child(stack)
	var brand := hud.label("PASSPORT RUN", 42, GameHUD.CREAM)
	stack.add_child(brand)
	stack.add_child(hud.label("Remember the path. Travel the world.", 24, Color("c4dce5")))
	var artwork := TravelArtwork.new()
	artwork.country_id = session.current_country()
	artwork.custom_minimum_size.y = 250
	stack.add_child(artwork)
	stack.add_child(hud.label(str(score), 98, Color("a6e771")))
	stack.add_child(hud.label("TILES REMEMBERED", 24, GameHUD.CREAM))
	stack.add_child(hud.label("%s · %d countries reached" % [session.difficulty.capitalize(), session.completed_countries], 25, GameHUD.CREAM))
	var route_names: Array[String] = []
	for id in session.challenge_route():
		route_names.append(GameCatalog.country_name(id))
	var route := hud.label(" → ".join(route_names), 23, Color("c4dce5"))
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(route)
	stack.add_child(hud.label("Can you beat me?", 40, GameHUD.CREAM))
	var invitation := hud.label("Play this exact route with the\nchallenge code sent alongside.", 24, Color("c4dce5"))
	stack.add_child(invitation)
	await owner_node.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result: Error = viewport.get_texture().get_image().save_png(filename)
	viewport.queue_free()
	return result
