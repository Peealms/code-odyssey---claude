extends Node
## Music and sound effects. Registered as the "Sound" autoload.
##   Sound.play("jump")                    - a sound effect anywhere (UI, the player)
##   Sound.play_at("rock_slam", position)  - a trap sound, only heard near the camera
##   Sound.music("rooms")                  - crossfades to a music track (loops)
##   Sound.loop_player("fan_loop", node)   - a looping sound attached to a node (fans, saws)
## Music plays on the "Music" bus, everything else on "SFX"; Game saves both volumes.
## All files are CC0 - see assets/shared/audio/CREDITS.md.

const SFX_DIR := "res://assets/shared/audio/sfx/"
## Sound name -> [volume dB, original file in the 512-sound pack].
const SFX := {
	"jump": [-8.0, "sfx_movement_jump1"],
	"double_jump": [-8.0, "sfx_movement_jump8"],
	"wall_jump": [-8.0, "sfx_movement_jump13"],
	"land": [-16.0, "sfx_movement_jump9_landing"],
	"dash": [-6.0, "sfx_wpn_sword3"],
	"trampoline": [-6.0, "sfx_movement_jump20"],
	"fruit": [-10.0, "sfx_coin_single1"],
	"hurt": [-4.0, "sfx_damage_hit2"],
	"fall": [-6.0, "sfx_sounds_falling3"],
	"checkpoint": [-6.0, "sfx_sounds_powerup2"],
	"heal": [-6.0, "sfx_sounds_powerup10"],
	"rescue": [-4.0, "sfx_sounds_fanfare2"],
	"level_complete": [-4.0, "sfx_sounds_fanfare1"],
	"hero_swap": [-8.0, "sfx_movement_portal5"],
	"byte_talk": [-14.0, "sfx_sounds_Blip7"],
	"code_ok": [-6.0, "sfx_sounds_powerup4"],
	"code_error": [-6.0, "sfx_sounds_error1"],
	"terminal_open": [-8.0, "sfx_sounds_pause1_in"],
	"terminal_close": [-8.0, "sfx_sounds_pause1_out"],
	"ui_move": [-10.0, "sfx_menu_move1"],
	"ui_select": [-8.0, "sfx_menu_select1"],
	"page_turn": [-8.0, "sfx_menu_move3"],
	"chest_open": [-6.0, "sfx_movement_dooropen1"],
	"gate_break": [-4.0, "sfx_exp_shortest_soft1"],
	"crates_break": [-4.0, "sfx_exp_shortest_soft4"],
	"bridge_block": [-12.0, "sfx_sounds_Blip4"],
	"bridge_collapse": [-4.0, "sfx_exp_shortest_hard3"],
	"rock_slam": [-6.0, "sfx_sounds_impact3"],
	"spike_slam": [-6.0, "sfx_sounds_impact7"],
	"platform_crumble": [-8.0, "sfx_sounds_impact11"],
	"fire": [-10.0, "sfx_exp_shortest_soft7"],
	"fan_loop": [-14.0, "sfx_sound_mechanicalnoise1"],
	"saw_loop": [-20.0, "sfx_sound_mechanicalnoise2"],
	"sword": [-6.0, "sfx_wpn_sword1"],
	"blocked": [-8.0, "sfx_sounds_negative2"],
}
const MUSIC := {
	"rooms": ["res://assets/shared/audio/music/rooms.mp3", -10.0],
	"final_exam": ["res://assets/shared/audio/music/final_exam.ogg", -10.0],
	"menu": ["res://assets/shared/audio/music/menu.ogg", -10.0],
}
const HEARING := 360.0  ## Trap sounds fade out over this many px from the camera.
const VOICES := 12  ## How many sound effects can play at once.
const MUSIC_FADE := 1.0

var _streams := {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # menus and cutscenes pause the game
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)
	_music_a = _music_player()
	_music_b = _music_player()


## A sound effect at full volume (the player's own sounds, UI, Byte).
func play(name: String, pitch_spread := 0.0) -> void:
	var stream := _stream(name)
	if stream == null:
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = stream
	p.volume_db = SFX[name][0]
	p.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	p.play()


## A sound from something in the level: quieter the farther it is from the camera, silent
## off-screen, so twenty saws don't all play at once.
func play_at(name: String, world_pos: Vector2, pitch_spread := 0.05) -> void:
	var volume := _distance_volume(world_pos)
	if volume <= 0.0:
		return
	var stream := _stream(name)
	if stream == null:
		return
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	p.stream = stream
	p.volume_db = SFX[name][0] + linear_to_db(volume)
	p.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	p.play()


## A looping sound attached to `owner_node` (a fan or saw). It plays only while the node is
## near the camera. Call .stop() / .play() on the returned player to switch it.
func loop_player(name: String, owner_node: Node2D) -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	var stream: AudioStreamWAV = _stream(name).duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	p.stream = stream
	p.bus = "SFX"
	p.volume_db = SFX[name][0]
	p.max_distance = HEARING
	p.attenuation = 1.5
	owner_node.add_child(p)
	return p


## Crossfades to a music track. Calling it with the track already playing does nothing.
func music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	var old := _music_a if _music_a.playing else null
	var new := _music_b if old == _music_a else _music_a
	var stream: AudioStream = load(MUSIC[name][0])
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true
	new.stream = stream
	new.volume_db = -60.0
	new.play()
	var tween := create_tween().set_parallel()
	tween.tween_property(new, "volume_db", MUSIC[name][1], MUSIC_FADE)
	if old:
		tween.tween_property(old, "volume_db", -60.0, MUSIC_FADE)
		tween.chain().tween_callback(old.stop)


func stop_music() -> void:
	_music_name = ""
	for p in [_music_a, _music_b]:
		var tween := create_tween()
		tween.tween_property(p, "volume_db", -60.0, MUSIC_FADE)
		tween.tween_callback(p.stop)


func _music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	add_child(p)
	return p


func _stream(name: String) -> AudioStream:
	if not SFX.has(name):
		push_warning("Unknown sound: %s" % name)
		return null
	if not _streams.has(name):
		_streams[name] = load(SFX_DIR + name + ".wav")
	return _streams[name]


## 1 near the middle of the screen, fading to 0 at HEARING px away.
func _distance_volume(world_pos: Vector2) -> float:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return 1.0
	var d := cam.get_screen_center_position().distance_to(world_pos)
	return clampf(1.0 - (d - 120.0) / (HEARING - 120.0), 0.0, 1.0)
