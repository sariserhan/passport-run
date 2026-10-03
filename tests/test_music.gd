extends SceneTree

func _initialize() -> void:
	create_timer(60).timeout.connect(func(): quit(1))
	run.call_deferred()

func ready_song(audio: GameAudio) -> void:
	while audio.playing_destination != audio.music_destination:
		await process_frame

func run() -> void:
	var audio := GameAudio.new()
	root.add_child(audio)
	audio.apply_settings({"music": 0.0, "sound": 0.0})
	for id in GameCatalog.DESTINATIONS:
		assert(not audio.soundtrack_style(id).is_empty(), "Every destination has a soundtrack style")
	var original: AudioStream = audio.music.stream
	audio.play_destination("FR")
	assert(audio.synthesis != null and audio.music.stream == original, "Composition is prepared off the gameplay thread")
	await ready_song(audio)
	var france: AudioStreamWAV = audio.music.stream
	assert(france.get_length() > 20, "Composed themes have room for answering phrases")
	assert(france.save_to_wav("res://artifacts/music-france.wav") == OK)
	var peak := 0
	for index in range(0, france.data.size(), 2):
		peak = maxi(peak, absi(france.data.decode_s16(index)))
	assert(peak > 1000 and peak < 31130, "Soundtrack is audible with headroom and no clipping")
	assert(france.loop_mode == AudioStreamWAV.LOOP_FORWARD and france.loop_end > 0)
	audio.play_destination("FR")
	assert(audio.music.stream == france, "Retry keeps music uninterrupted")
	audio.play_destination("IT")
	await ready_song(audio)
	assert(audio.outgoing.stream == france and audio.fade_remaining > 0, "Destination changes crossfade the previous track")
	assert(audio.music.stream.data != france.data, "Countries have different compositions")
	assert(audio.music.volume_db < -80, "Changing songs preserves mute")
	audio.play_destination("JP")
	await ready_song(audio)
	assert(audio.music_style == "plucked")
	assert(audio.music.stream.save_to_wav("res://artifacts/music-japan.wav") == OK)
	audio.play_destination("SAHARA")
	await ready_song(audio)
	assert(audio.music_style == "desert")
	assert(audio.music.stream.save_to_wav("res://artifacts/music-desert.wav") == OK)
	audio.play_destination("UNDERWATER")
	await ready_song(audio)
	assert(audio.music_style == "water")
	audio.play_destination("INFINITE")
	await ready_song(audio)
	assert(audio.music_style == "space")
	audio.set_paused(true)
	var remaining := audio.fade_remaining
	await create_timer(0.08).timeout
	assert(audio.fade_remaining == remaining, "Pause freezes the music transition")
	if DisplayServer.get_name() != "headless":
		assert(audio.music.stream_paused)
	audio.set_paused(false)
	assert(not audio.music.stream_paused)
	audio.apply_settings({"music": 0.5, "sound": 0.0})
	assert(audio.outgoing.volume_db > -80, "Volume changes apply to the outgoing track")
	audio.apply_settings({"music": 0.0, "sound": 0.0})
	assert(audio.outgoing.volume_db < -80, "Mute applies to both crossfade players")
	audio.play_destination("JP")
	audio.play_destination("SPACE")
	await ready_song(audio)
	assert(audio.playing_destination == "SPACE", "Rapid destination changes keep only the latest requested song")
	await create_timer(1.3).timeout
	assert(audio.outgoing.stream == null and audio.fade_remaining == 0, "Finished transitions release the previous track")
	audio.queue_free()
	await process_frame
	print("Country music checks passed")
	quit()
