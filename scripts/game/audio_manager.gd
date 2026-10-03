class_name GameAudio
extends Node

# Original synthesized prototype audio. No external or copyrighted recordings.
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var settings: Dictionary
var cues: Dictionary = {}
var music_destination := ""
var music_style := ""
var outgoing: AudioStreamPlayer
var fade_remaining := 0.0
var paused := false
var synthesis: Thread
var generating_destination := ""
var playing_destination := ""

func _ready() -> void:
	music = AudioStreamPlayer.new()
	effect = AudioStreamPlayer.new()
	outgoing = AudioStreamPlayer.new()
	add_child(music)
	add_child(effect)
	add_child(outgoing)
	for item in [["jump", [440.0, 660.0]], ["land", [660.0]], ["fall", [280.0, 210.0, 140.0]], ["stamp", [523.25, 659.25, 783.99]], ["ui", [520.0]], ["travel", [392.0, 523.25, 659.25, 783.99]]]:
		cues[item[0]] = melody(item[1], 0.075, false)
	for key in ["wire", "double", "triple", "sticky", "gun", "spread", "laser", "rocket"]:
		var pitch := 180.0 + ["wire", "double", "triple", "sticky", "gun", "spread", "laser", "rocket"].find(key) * 85
		cues["shot_" + key] = melody([pitch * 1.8, pitch, pitch * 0.6], 0.025, false)
	cues.burst = melody([980.0, 420.0, 120.0], 0.025, false)
	cues.armor = melody([1800.0, 1250.0], 0.03, false)
	cues.team = melody([330.0, 440.0, 660.0, 880.0], 0.055, false)
	music.stream = melody([261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23, 261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 196.0], 0.45, true)
	if DisplayServer.get_name() != "headless":
		music.play()

func soundtrack_style(id: String) -> String:
	if id == "INFINITE" or id in ["SPACE", "MOON", "MARS", "SATURN"]:
		return "space"
	if id in ["UNDERWATER", "GREAT_BARRIER_REEF", "CRYSTAL_CAVERN"]:
		return "water"
	if id in ["SAHARA", "PETRA"]:
		return "desert"
	if id in ["EVEREST", "NORTHERN_LIGHTS", "STONEHENGE", "CLOUD_CITY"]:
		return "mountain"
	if id in GameCatalog.CINEMA_DESTINATIONS or id == "DRAGON_ISLAND":
		return "fantasy"
	var region: String = GameCatalog.DESTINATIONS.get(id, {}).get("region", "")
	if region in ["Northern Africa", "Western Asia", "Central Asia"]:
		return "desert"
	if "Africa" in region or id in ["SERENGETI", "VICTORIA_FALLS"]:
		return "drums"
	if region in ["Eastern Asia", "South-Eastern Asia"] or id == "ANGKOR_WAT":
		return "plucked"
	if region == "Southern Asia" or id == "TAJ_MAHAL":
		return "bells"
	if region in ["South America", "Central America", "Caribbean"] or id in ["AMAZON", "MACHU_PICCHU", "SALAR_UYUNI", "SANTORINI"]:
		return "guitar"
	if region in ["Northern Europe", "Eastern Europe"]:
		return "mountain"
	return "waltz"

func play_destination(id: String) -> void:
	if id == music_destination:
		return
	music_destination = id
	music_style = soundtrack_style(id)
	if synthesis == null: prepare_destination()

func prepare_destination() -> void:
	generating_destination = music_destination
	synthesis = Thread.new()
	if synthesis.start(soundtrack.bind(music_destination, music_style)) != OK:
		synthesis = null
		start_track(soundtrack(music_destination, music_style))

func start_track(next: AudioStreamWAV) -> void:
	playing_destination = music_destination
	outgoing.stop()
	outgoing.stream = music.stream
	var position := music.get_playback_position()
	music.stream = next
	fade_remaining = 1.2
	update_music_volume()
	if DisplayServer.get_name() != "headless":
		outgoing.play(position)
		music.play()

func _process(delta: float) -> void:
	if paused: return
	if synthesis and not synthesis.is_alive():
		var next: AudioStreamWAV = synthesis.wait_to_finish()
		synthesis = null
		if generating_destination == music_destination:
			start_track(next)
		else:
			prepare_destination()
	if fade_remaining <= 0: return
	fade_remaining = maxf(0, fade_remaining - delta)
	update_music_volume()
	if fade_remaining == 0:
		outgoing.stop()
		outgoing.stream = null

func update_music_volume() -> void:
	var progress := 1.0 - fade_remaining / 1.2
	var volume := float(settings.get("music", 0.35))
	music.volume_db = linear_to_db(maxf(0.0001, volume * sin(progress * PI / 2))) - 10
	outgoing.volume_db = linear_to_db(maxf(0.0001, volume * cos(progress * PI / 2))) - 10

func soundtrack(id: String, style: String) -> AudioStreamWAV:
	# Original composed themes; regional colors, not traditional or film recordings.
	const RATE := 22050
	var seed_value := GameCatalog.daily_seed(id, "soundtrack")
	var minor := style in ["desert", "fantasy", "mountain", "space"]
	var scale: Array = [0, 2, 3, 5, 7, 8, 10] if minor else [0, 2, 4, 5, 7, 9, 11]
	if style == "desert": scale = [0, 1, 4, 5, 7, 8, 10]
	var beat := 0.46 if style in ["guitar", "drums", "plucked"] else 0.56
	var meter := 3 if style == "waltz" else 4
	var bar_samples := int(RATE * beat) * meter
	var count := bar_samples * 16
	var root := 220.0 * pow(2.0, float(seed_value % 5 - 2) / 12.0)
	# Four answering phrases. Rests give the melody breathing room.
	var phrases: Array = [[0, 2, 4, -1, 4, 2, 1, -1], [2, 4, 6, 4, 2, -1, 1, 0], [4, 6, 7, -1, 6, 4, 2, -1], [2, 1, 0, -1, 1, 2, 0, -1]]
	var progression: Array = [0, 5, 3, 4] if not minor else [0, 5, 2, 6]
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var dry := PackedFloat32Array()
	dry.resize(count)
	var beat_samples := int(RATE * beat)
	var chords: Array = []
	var notes: Array[float] = []
	for bar in 16:
		var chord_degree: int = progression[(bar / 2) % 4]
		var frequencies: Array[float] = []
		for interval in [0, 2, 4]:
			var d: int = chord_degree + interval
			frequencies.append(root * pow(2.0, float(scale[d % 7] + (d / 7) * 12) / 12.0))
		chords.append(frequencies)
		var phrase: Array = phrases[(bar / 4 + seed_value % 4) % 4]
		for step in meter:
			var degree: int = phrase[(bar % 2) * meter + step]
			if degree < 0:
				notes.append(0.0)
			else:
				degree += chord_degree
				notes.append(root * pow(2.0, float(scale[degree % 7] + (degree / 7) * 12) / 12.0))
	for index in count:
		var bar := index / bar_samples
		var step := (index / beat_samples) % meter
		var local := float(index % beat_samples) / RATE
		var bar_time := float(index % bar_samples) / RATE
		var chord_root: float = chords[bar][0]
		var frequency: float = notes[index / beat_samples]
		var lead := 0.0
		if frequency > 0:
			var phase := TAU * frequency * local
			var attack := minf(1.0, local * 100.0)
			var release := minf(1.0, (beat - local) * 35.0)
			if style in ["guitar", "plucked", "desert"]:
				lead = (sin(phase) + sin(phase * 2) * 0.32 + sin(phase * 3) * 0.14 + sin(phase * 4) * 0.06) * exp(-local * 7.0)
			elif style in ["bells", "water"]:
				lead = sin(phase) * exp(-local * 3.0) + sin(phase * 2) * exp(-local * 9.0) * 0.3 + sin(phase * 4) * exp(-local * 15.0) * 0.08
			elif style == "waltz":
				lead = (sin(phase) + sin(phase * 2) * 0.18 + sin(phase * 3) * 0.08) * exp(-local * 4.0)
			else:
				lead = (sin(phase + sin(TAU * 4.5 * local) * 0.035) + sin(phase * 2) * 0.1) * minf(1.0, local * 14.0) * exp(-local * 1.6)
			lead *= attack * release * 0.24
		var bass_frequency := chord_root * (0.5 if step % 2 == 0 else 0.75)
		var bass := sin(TAU * bass_frequency * local) * exp(-local * 4) * minf(1, local * 80) * 0.13
		var harmony := 0.0
		for tone in chords[bar]:
			harmony += sin(TAU * tone * bar_time) * 0.025
		harmony *= minf(1.0, minf(bar_time, beat * meter - bar_time) * 8)
		var percussion := 0.0
		if style in ["guitar", "drums", "desert", "plucked"]:
			if step == 0 or step == 2:
				percussion += sin(TAU * (48 * local + 1.4 * (1 - exp(-local * 24)))) * exp(-local * 24) * 0.12
			var offbeat := fmod(local, beat / 2)
			var noise := sin(index * 1.713) * sin(index * 2.391)
			percussion += noise * exp(-offbeat * 100) * 0.022
			if step == 1 or step == 3:
				percussion += (noise * 0.045 + sin(TAU * 180 * local) * 0.04) * exp(-local * 35)
		var phrase_gain := 0.75 if bar in [3, 7, 11, 15] else 1.0
		dry[index] = lead * phrase_gain + bass + harmony + percussion
	# Short, quiet reflections soften the synthetic instruments without burying notes.
	var delay := int(RATE * beat * 0.75)
	for index in count:
		var sample := dry[index] + dry[(index - delay + count) % count] * 0.16 + dry[(index - delay * 2 + count) % count] * 0.07
		var fade := minf(1.0, minf(float(index), float(count - index)) / RATE * 25)
		pcm.encode_s16(index * 2, int(clampf(sample * fade, -0.95, 0.95) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func apply_settings(values: Dictionary) -> void:
	settings = values
	update_music_volume()
	effect.volume_db = linear_to_db(maxf(0.0001, float(values.sound))) - 5

func play_cue(key: String) -> void:
	if DisplayServer.get_name() != "headless" and cues.has(key) and float(settings.get("sound", 0)) > 0:
		effect.pitch_scale = 1.0
		effect.stream = cues[key]
		effect.play()

func play_streak(count: int) -> void:
	play_cue("land")
	effect.pitch_scale = 1.0 + minf(count, 10) * 0.035

func set_paused(value: bool) -> void:
	paused = value
	music.stream_paused = value
	outgoing.stream_paused = value
	effect.stream_paused = value

func melody(notes: Array, seconds_per_note: float, looping: bool) -> AudioStreamWAV:
	const RATE: int = 22050
	var note_samples: int = int(RATE * seconds_per_note)
	var total: int = note_samples * notes.size()
	var pcm := PackedByteArray()
	pcm.resize(total * 2)
	for index in total:
		var local: int = index % note_samples
		var progress: float = float(local) / note_samples
		var frequency: float = notes[index / note_samples]
		var envelope: float = minf(progress * 30, 1.0) * pow(1.0 - progress, 2)
		var sample: float = sin(TAU * frequency * local / RATE) * envelope * 0.35
		pcm.encode_s16(index * 2, int(sample * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = pcm
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = total
	return stream

func _exit_tree() -> void:
	if synthesis:
		synthesis.wait_to_finish()
		synthesis = null
	music.stop()
	outgoing.stop()
	effect.stop()
	music.stream = null
	outgoing.stream = null
	effect.stream = null
	cues.clear()
