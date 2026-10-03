class_name FriendGhost
extends Node3D

var game: Node3D
var decisions: Array = []
var clock := 0.0
var actor: Traveler
var progress := 0

func _ready() -> void:
	if decisions.is_empty(): return
	actor = Traveler.new()
	actor.reduced_motion = true
	add_child(actor)
	actor.portrait.modulate = Color(0.5, 0.9, 1, 0.4)
	actor.contact_shadow.hide()
	actor.reaction.hide()
	actor.scale = Vector3.ONE * 0.8
	var label := Label3D.new()
	label.text = "FRIEND"
	label.font_size = 28
	label.pixel_size = 0.01
	label.position.y = 2.9
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("a5efff")
	actor.add_child(label)

func _process(delta: float) -> void:
	if not actor or game.paused or game.menu.root.visible: return
	if game.run.phase not in [RunState.Phase.PLAY, RunState.Phase.JUMPING]:
		actor.hide()
		return
	clock += delta
	var end := 0.0
	progress = 0
	var offset: int = game.session.country_index * game.config.row_count
	if offset >= decisions.size():
		actor.hide()
		game.hud.phase_hint.text = "GHOST REPLAY ENDED · Target %d tiles" % game.session.target
		return
	for index in range(offset, decisions.size()):
		if index >= offset + game.config.row_count: break
		end += float(decisions[index]) / 1000.0 + game.config.jump_seconds
		if end > clock: break
		progress += 1
	game.hud.phase_hint.text = "FRIEND GHOST · %d steps · %s" % [progress, "ahead" if progress > game.run.completed_rows else "behind" if progress < game.run.completed_rows else "side by side"]
	# Never show a future lane: that would spoil the memory puzzle.
	actor.visible = progress > 0 and progress <= game.run.completed_rows
	if actor.visible:
		var row := progress - 1
		actor.position = game.grid.tile_at(row, game.run.safe_lane(row)).position + Vector3(0.6, 0.03, 0.15)
