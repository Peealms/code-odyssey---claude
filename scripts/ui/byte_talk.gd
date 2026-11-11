class_name ByteTalk
extends CanvasLayer
## A short scene where Byte talks to the player. The game pauses, the HUD and the other screen
## layers hide, and Byte's lines appear one at a time in a dialogue box at the bottom of the
## screen. Enter, Space or F moves on. The camera can glide to whatever Byte is talking about.
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

const BYTE_FRAMES := preload("res://assets/shared/byte/byte_frames.tres")

const INK := Color("33323d")
const WOOD := Color("ae7764")
const WOOD_DARK := Color("833f4c")
const PAPER := Color("eebd8a")
const PAPER_EDGE := Color("b77357")

## Seconds before a line moves on by itself (0 = wait for a key).
var auto_advance := 3.0

var _dialog: PanelContainer
var _dialog_text: Label
var _continue: Label
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
		_build_dialog()
	_continue.visible = false
	_dialog_text.text = text
	_dialog_text.visible_characters = 0
	for i in text.length():
		_dialog_text.visible_characters = i + 1
		if i % 3 == 0 and text[i] != " ":
			Sound.play("byte_talk", 0.2)
		await get_tree().create_timer(0.02).timeout
	_accept_ready = true
	_continue.visible = true
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


func _build_dialog() -> void:
	_dialog = PanelContainer.new()
	_dialog.add_theme_stylebox_override("panel", _box(PAPER, INK, 2, Vector4(8, 6, 10, 6), PAPER_EDGE))
	_dialog.anchor_left = 0.5
	_dialog.anchor_right = 0.5
	_dialog.anchor_top = 1.0
	_dialog.anchor_bottom = 1.0
	_dialog.offset_left = -200
	_dialog.offset_right = 200
	_dialog.offset_top = -72
	_dialog.offset_bottom = -12
	_dialog.grow_vertical = Control.GROW_DIRECTION_BEGIN  # longer lines grow upwards
	add_child(_dialog)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_dialog.add_child(row)
	var face_box := Control.new()
	face_box.custom_minimum_size = Vector2(40, 40)
	row.add_child(face_box)
	var face := AnimatedSprite2D.new()
	face.sprite_frames = BYTE_FRAMES
	face.play("talk")
	face.scale = Vector2(1.5, 1.5)
	face.position = Vector2(20, 22)
	face_box.add_child(face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var who := Label.new()
	who.text = "BYTE"
	who.add_theme_color_override("font_color", WOOD_DARK)
	col.add_child(who)
	_dialog_text = Label.new()
	_dialog_text.add_theme_color_override("font_color", INK)
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_dialog_text.custom_minimum_size = Vector2(320, 0)
	col.add_child(_dialog_text)
	_continue = Label.new()
	_continue.text = "ENTER >"
	_continue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue.add_theme_color_override("font_color", WOOD_DARK)
	_continue.add_theme_font_size_override("font_size", 8)
	col.add_child(_continue)


func _box(fill: Color, border: Color, width: int, padding: Vector4, bottom := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(3)
	s.corner_detail = 2
	s.anti_aliasing = false
	s.content_margin_left = padding.x
	s.content_margin_top = padding.y
	s.content_margin_right = padding.z
	s.content_margin_bottom = padding.w
	if bottom.a > 0.0:
		s.shadow_color = bottom
		s.shadow_offset = Vector2(0, 2)
	return s
