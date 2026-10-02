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
	stack.position = Vector2(56, 70)
	stack.size = Vector2(608, 860)
	stack.add_theme_constant_override("separation", 30)
	background.add_child(stack)
	var lines: Array = [["PASSPORT RUN", 46, GameHUD.CREAM], ["Remember the path.\nTravel the world.", 27, Color("c4dce5")], ["%d" % score, 118, Color("a6e771")], ["TILES REMEMBERED", 27, GameHUD.CREAM], ["%s difficulty" % session.difficulty.capitalize(), 28, GameHUD.CREAM]]
	var route_names: Array[String] = []
	for id in session.challenge_route():
		route_names.append(GameCatalog.country_name(id))
	lines.append([" → ".join(route_names), 26, Color("c4dce5")])
	lines.append(["Can you beat me?", 43, GameHUD.CREAM])
	lines.append(["Play my exact path with the\nchallenge code I send alongside.", 25, Color("c4dce5")])
	for entry in lines:
		var label := hud.label(entry[0], entry[1], entry[2])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(label)
	await owner_node.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result: Error = viewport.get_texture().get_image().save_png(filename)
	viewport.queue_free()
	return result
