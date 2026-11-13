class_name ByteTalk
extends CanvasLayer
## A short scene where Byte talks to the player. The game pauses, the HUD and the other screen
## layers hide, and Byte's lines appear one at a time in the dialogue box at the bottom of the
## screen (dialogue_box.gd). Enter, Space or F moves on. The camera can glide to whatever Byte
## is talking about.
## The hero-rescue cutscene (hero_cutscene.gd) and the tutorial (tutorial.gd) are built on it:
##
##   var talk := ByteTalk.new()
##   level.add_child(talk)
##   talk.begin(player)
##   await talk.point_camera(chest.global_position)
##   await talk.say("This chest holds a manual.")
##   await talk.end()

signal finished
signal _advance

const INK := DialogueBox.INK
const WOOD := DialogueBox.WOOD
const WOOD_DARK := DialogueBox.WOOD_DARK
const PAPER := DialogueBox.PAPER

## Seconds before a line moves on by itself (0 = wait for a key).
var auto_advance := 3.0

var _dialog: DialogueBox
var _accept_ready := false
var _player: Node2D
var _cam: Camera2D
var _cam_mode := Node.PROCESS_MODE_INHERIT
var _hidden: Array[CanvasLayer] = []


func _ready() -> void:
	add_to_group("byte_talk")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 70


## Pauses the game and hides the HUD, hotbar and the other screen layers so the scene is clean.
func begin(player: Node2D) -> void:
	_player = player
	get_tree().paused = true
	for n in get_parent().get_children():
		if n is CanvasLayer and n != self and n.visible and n.layer >= 0:
			n.visible = false
			_hidden.append(n)
	_cam = player.get_node("Camera2D")
	_cam_mode = _cam.process_mode
	_cam.process_mode = Node.PROCESS_MODE_ALWAYS  # so it can still move while the game is paused


## Glides the camera until `point` (a position in the level) is in the middle of the screen,
## zoomed in by `zoom` (1 = normal).
func point_camera(point: Vector2, zoom := 1.6, seconds := 0.7) -> void:
	var focus := point - (_player.global_position + _cam.position)
	var t := create_tween().set_parallel()
	t.tween_property(_cam, "offset", focus, seconds).set_trans(Tween.TRANS_SINE)
	t.tween_property(_cam, "zoom", Vector2(zoom, zoom), seconds).set_trans(Tween.TRANS_SINE)
	await t.finished


## Shows a line in Byte's dialogue box, typed out letter by letter, then waits for a key
## (or `auto_advance` seconds).
func say(text: String) -> void:
	if _dialog == null:
		_dialog = DialogueBox.new()
		add_child(_dialog)
	await _dialog.type_line(text)
	_accept_ready = true
	if auto_advance > 0.0:
		var auto := get_tree().create_timer(auto_advance)
		auto.timeout.connect(func():
			if _accept_ready:
				_accept_ready = false
				_advance.emit())
	await _advance


func hide_dialog() -> void:
	if _dialog:
		_dialog.queue_free()
		_dialog = null


## Camera back to normal, the screen layers back, the game carries on.
func end() -> void:
	hide_dialog()
	var t := create_tween().set_parallel()
	t.tween_property(_cam, "offset", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(_cam, "zoom", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	await t.finished
	_cam.process_mode = _cam_mode
	for n in _hidden:
		if is_instance_valid(n):
			n.visible = true
	get_tree().paused = false
	remove_from_group("byte_talk")  # so the next talk doesn't wait for this one
	finished.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if not _accept_ready:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_accept_ready = false
		_advance.emit()
