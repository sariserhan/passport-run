class_name TouchScroll
extends ScrollContainer

# Godot forwards wheel events past MOUSE_FILTER_STOP children, but not touch drags,
# so a phone swipe starting on a button never scrolls. Plain controls inside switch
# to PASS; scripted widgets (globe, map, room) keep their own drag handling.

func _enter_tree() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if not get_tree().node_added.is_connected(_pass_touch):
		get_tree().node_added.connect(_pass_touch)
	for node in find_children("*", "Control", true, false):
		_pass_touch(node)

func _exit_tree() -> void:
	get_tree().node_added.disconnect(_pass_touch)

func _pass_touch(node: Node) -> void:
	# Sliders and text fields keep their own drags; so do children of scripted widgets.
	if not node is Control or node.mouse_filter != Control.MOUSE_FILTER_STOP or node is Range or node is LineEdit or node is TextEdit or not is_ancestor_of(node):
		return
	var current := node
	while current != self:
		if current.get_script() != null: return
		current = current.get_parent()
	node.mouse_filter = Control.MOUSE_FILTER_PASS
