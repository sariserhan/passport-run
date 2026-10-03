extends SceneTree

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	run.call_deferred()

func run() -> void:
	var audio := GameAudio.new()
	root.add_child(audio)
	audio.apply_settings({"music": 0.0, "sound": 0.0})
	for id in GameCatalog.DESTINATIONS:
		assert(not audio.soundtrack_style(id).is_empty(), "Every destination has a soundtrack style")
	audio.play_destination("FR")
	var france: AudioStreamWAV = audio.music.stream
	assert(france.loop_mode == AudioStreamWAV.LOOP_FORWARD and france.loop_end > 0)
	audio.play_destination("FR")
	assert(audio.music.stream == france, "Retry keeps music uninterrupted")
	audio.play_destination("IT")
	assert(audio.music.stream.data != france.data, "Countries have different compositions")
	assert(audio.music.volume_db < -80, "Changing songs preserves mute")
	audio.play_destination("JP")
	assert(audio.music_style == "plucked")
	audio.play_destination("SAHARA")
	assert(audio.music_style == "desert")
	audio.play_destination("UNDERWATER")
	assert(audio.music_style == "water")
	audio.play_destination("INFINITE")
	assert(audio.music_style == "space")
	audio.set_paused(true)
	if DisplayServer.get_name() != "headless":
		assert(audio.music.stream_paused)
	audio.set_paused(false)
	assert(not audio.music.stream_paused)
	audio.queue_free()
	await process_frame
	print("Country music checks passed")
	quit()
