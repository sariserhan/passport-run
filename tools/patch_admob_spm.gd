extends SceneTree

# The AdMob export plugin patches project.pbxproj in a deferred call that a headless
# export exits before running; export_iphone.py runs the same patch afterwards.
func _initialize() -> void:
	preload("res://addons/admob/internal/services/pbxproj_service.gd").patch(OS.get_cmdline_user_args()[0])
	quit()
