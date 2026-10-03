class_name GameAudio
extends Node

# Original synthesized prototype audio. No external or copyrighted recordings.
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var settings: Dictionary
var cues: Dictionary = {}

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
