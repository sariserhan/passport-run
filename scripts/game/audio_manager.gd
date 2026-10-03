class_name GameAudio
extends Node

# Original synthesized prototype audio. No external or copyrighted recordings.
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var settings: Dictionary
var cues: Dictionary = {}
var music_destination := ""
var music_style := ""

func _ready() -> void:
	music = AudioStreamPlayer.new()
	effect = AudioStreamPlayer.new()
	add_child(music)
	add_child(effect)
	for item in [["jump", [440.0, 660.0]], ["land", [660.0]], ["fall", [280.0, 210.0, 140.0]], ["stamp", [523.25, 659.25, 783.99]], ["ui", [520.0]], ["travel", [392.0, 523.25, 659.25, 783.99]]]:
		cues[item[0]] = melody(item[1], 0.075, false)
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
	music.stream = soundtrack(id, music_style)
	if DisplayServer.get_name() != "headless":
		music.play()

func soundtrack(id: String, style: String) -> AudioStreamWAV:
	# Original regional-inspired synthesis, not traditional songs or film scores.
	const RATE := 22050
	var seed_value := GameCatalog.daily_seed(id, "soundtrack")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var scale: Array = [0, 2, 4, 7, 9]
	if style in ["desert", "fantasy", "mountain", "space"]:
		scale = [0, 1, 4, 5, 7, 8, 10] if style == "desert" else [0, 2, 3, 5, 7, 10]
	var beat := 0.28 if style in ["guitar", "drums", "plucked"] else 0.38
	var root := 196.0 * pow(2.0, float(seed_value % 7) / 12.0)
	var notes: Array[float] = []
	for step in 32:
		notes.append(root * pow(2.0, float(scale[rng.randi_range(0, scale.size() - 1)]) / 12.0))
	var count := int(RATE * beat) * notes.size()
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var samples_per_beat := int(RATE * beat)
	for index in count:
		var step := index / samples_per_beat
		var local := float(index % samples_per_beat) / RATE
		var phase := TAU * notes[step] * local
		var envelope := (1.0 - exp(-local * 80.0)) * exp(-local * (5.0 if style in ["space", "water", "mountain"] else 12.0))
		var lead := sin(phase)
		if style in ["plucked", "guitar", "waltz", "desert"]:
			lead += sin(phase * 2.0) * 0.3 + sin(phase * 3.0) * 0.12
		elif style in ["bells", "water", "fantasy"]:
			lead += sin(phase * 2.76) * 0.25
		var time := float(index) / RATE
		var bass := sin(TAU * root * (0.5 if step % 8 < 4 else 0.75) * time) * 0.1
		var pad := (sin(TAU * root * time) + sin(TAU * root * 1.5 * time)) * 0.05
		var drum := 0.0
		if style in ["drums", "guitar", "desert", "plucked"]:
			drum = sin(TAU * 65.0 * local) * exp(-local * 35.0) * 0.14
		# Whole-loop fades avoid clicks on replay, including sustained layers.
		var fade := minf(1.0, minf(time, float(count - index) / RATE) * 25.0)
		pcm.encode_s16(index * 2, int(clampf((lead * envelope * 0.25 + bass + pad + drum) * fade, -1.0, 1.0) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func apply_settings(values: Dictionary) -> void:
	settings = values
	music.volume_db = linear_to_db(maxf(0.0001, float(values.music))) - 13
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
	music.stream_paused = value
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
	music.stop()
	effect.stop()
	music.stream = null
	effect.stream = null
	cues.clear()
