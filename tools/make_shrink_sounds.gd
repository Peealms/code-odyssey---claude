extends SceneTree
## Makes Psalm's shrink and grow sounds: short 8-bit pitch slides (a square wave sliding down
## for shrink, up for grow), in the style of the retro pack the other sounds come from.
## Writes assets/shared/audio/sfx/shrink.wav and grow.wav.
## Run:  godot --headless --path . --script res://tools/make_shrink_sounds.gd
## Then: godot --headless --path . --import

const OUT := "res://assets/shared/audio/sfx/"
const RATE := 22050
const LENGTH := 0.22  ## Seconds.


func _initialize() -> void:
	_save("shrink", 1100.0, 240.0)
	_save("grow", 240.0, 1100.0)
	quit()


## A square wave sliding from `from_hz` to `to_hz` (evenly in pitch) with a little wobble,
## a quick fade-in and a longer fade-out.
func _save(sound_name: String, from_hz: float, to_hz: float) -> void:
	var n := int(RATE * LENGTH)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var hz := from_hz * pow(to_hz / from_hz, t) * (1.0 + 0.04 * sin(t * TAU * 9.0))
		phase = fmod(phase + hz / RATE, 1.0)
		var square := 1.0 if phase < 0.5 else -1.0
		var envelope := minf(1.0, t / 0.04) * minf(1.0, (1.0 - t) / 0.3)
		data.encode_s16(i * 2, int(square * envelope * 0.3 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	print("%s: %s" % [sound_name, error_string(wav.save_to_wav(OUT + sound_name + ".wav"))])
