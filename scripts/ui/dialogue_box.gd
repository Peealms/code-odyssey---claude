class_name DialogueBox
extends PanelContainer
## The paper dialogue box at the bottom of the screen: who is talking (a face and a name), their
## line typed out letter by letter, and "ENTER >" once all of it shows. Put it under a
## CanvasLayer. Byte's talks (byte_talk.gd) and the backstory (story_intro.gd) both use it:
##
##   var box := DialogueBox.new()
##   layer.add_child(box)
##   box.set_speaker("BYTE", DialogueBox.BYTE_FRAMES)
##   await box.type_line("Hello!")   # returns once every letter shows
##
## With no face and no name it's the narrator's caption (used by the backstory).

const BYTE_FRAMES := preload("res://assets/shared/byte/byte_frames.tres")

const INK := Color("33323d")
const WOOD := Color("ae7764")
const WOOD_DARK := Color("833f4c")
const PAPER := Color("eebd8a")
const PAPER_EDGE := Color("b77357")
const LETTER_TIME := 0.02  ## Seconds per letter.
const TOP := -72.0  ## Where the box's top sits for a short line; longer lines grow it upwards.

## Sound made every third letter ("" = silent).
var voice := "byte_talk"
## The line being shown.
var line: String:
	get:
		return _text.text

var _face_box: Control
var _face: AnimatedSprite2D
var _who: Label
var _text: Label
var _continue: Label


func _init() -> void:
	add_theme_stylebox_override("panel", style(PAPER, INK, 2, Vector4(8, 6, 10, 6), PAPER_EDGE))
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -200
	offset_right = 200
	offset_top = TOP
	offset_bottom = -12
	grow_vertical = Control.GROW_DIRECTION_BEGIN  # longer lines grow upwards
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	_face_box = Control.new()
	_face_box.custom_minimum_size = Vector2(40, 40)
	row.add_child(_face_box)
	_face = AnimatedSprite2D.new()
	_face_box.add_child(_face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_who = Label.new()
	_who.add_theme_color_override("font_color", WOOD_DARK)
	col.add_child(_who)
	_text = Label.new()
	_text.add_theme_color_override("font_color", INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text.custom_minimum_size = Vector2(320, 0)
	col.add_child(_text)
	_continue = Label.new()
	_continue.text = "ENTER >"
	_continue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue.add_theme_color_override("font_color", WOOD_DARK)
	_continue.add_theme_font_size_override("font_size", 8)
	col.add_child(_continue)
	set_speaker("BYTE", BYTE_FRAMES)


## Who is talking: their name (or "" for none) and the face to show, playing `anim`. With no
## face, the line is centred like a caption. Returns the face sprite, to move or scale it.
func set_speaker(speaker: String, face: SpriteFrames = null, anim := &"talk") -> AnimatedSprite2D:
	_who.text = speaker
	_who.visible = speaker != ""
	_face_box.visible = face != null
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if face else HORIZONTAL_ALIGNMENT_CENTER
	if face:
		_face.sprite_frames = face
		_face.play(anim)
		_face.scale = Vector2(1.5, 1.5)
		_face.position = Vector2(20, 22)
	return _face


## Types `text` out letter by letter, then shows "ENTER >". Returns once every letter shows.
## The typing is a tween of this box, so it stops by itself if the box is freed.
func type_line(text: String) -> void:
	_continue.visible = false
	offset_top = TOP  # shrink back after a longer line; the new one grows it again if it needs
	_text.text = text
	_text.visible_characters = 0
	var typing := create_tween()
	typing.tween_method(_show_letters, 0.0, float(text.length()), text.length() * LETTER_TIME)
	await typing.finished
	_continue.visible = true


## Shows the first `count` letters, with a blip every third letter that isn't a space.
func _show_letters(count: float) -> void:
	var shown := int(count)
	for i in range(_text.visible_characters, shown):
		if voice != "" and i % 3 == 0 and _text.text[i] != " ":
			Sound.play(voice, 0.2)
	_text.visible_characters = shown


## The game's paper and wood box style: `padding` is left, top, right, bottom, and `bottom`
## is the colour of the 2 px edge under it (none if transparent).
static func style(fill: Color, border: Color, width: int, padding: Vector4, bottom := Color(0, 0, 0, 0)) -> StyleBoxFlat:
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
