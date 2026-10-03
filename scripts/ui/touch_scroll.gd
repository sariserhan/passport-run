class_name TouchScroll
extends ScrollContainer

# Godot forwards wheel events past MOUSE_FILTER_STOP children, but not touch drags,
# so a phone swipe starting on a button never scrolls. Plain controls inside switch
# to PASS; scripted controls (globe, map, room) keep their own drag handling.

func _enter_tree() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if not get_tree().node_added.is_connected(_pass_touch):
		get_tree().node_added.connect(_pass_touch)
	for node in find_children("*", "Control", true, false):
		_pass_touch(node)

func _exit_tree() -> void:
	get_tree().node_added.disconnect(_pass_touch)

func _pass_touch(node: Node) -> void:
	if node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP and node.get_script() == null and is_ancestor_of(node):
		node.mouse_filter = Control.MOUSE_FILTER_PASS
