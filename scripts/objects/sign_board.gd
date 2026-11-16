class_name SignBoard
extends Node2D
## A wooden sign hanging in a room: the clue in big letters and, under it, the name of the
## variable that solves it on a strip that looks like Byte's terminal, e.g.
##   GAP = 8 PLANKS
##   [ bridgeLength ]
## Only the name: working out the type (and whether it already exists) is the player's job.
## The level builders (tools/build_level*.gd) place them; the node's position is the sign's
## top-left corner. The builders add the Signs group right after the terrain, so a sign is
## drawn over the rock but under coins, gadgets and the heroes: it never hides any of them.
## When the player walks near, the sign lights up a little.
## Two looks: a plain wooden board (the tutorial, Pixel Adventure), or, with `paper` set, a
## pinned-up note of torn parchment from Treasure Hunters' Wood and Paper UI (Level 1).

@export_multiline var text := ""
@export var code := ""  ## The variable's name on the strip ("" = no strip).
## Half-size letters, for the tutorial's 16 px tiles (Level 1's tiles are 32 px).
@export var small := false
## A note to stretch behind the words instead of the wooden board: its outer PAPER_EDGE px
## (the pins, the torn corner) stay as drawn and the middle stretches.
@export var paper: Texture2D

const PAPER_EDGE := 7

const WOOD := Color("c48a5c")
const WOOD_DARK := Color("8a4f37")
const OUTLINE := Color("33323d")
const INK := Color("3b2114")
const NAIL := Color("6e6a73")
const STRIP := Color("2b2135")
const STRIP_INK := Color("7cf07c")
const NEAR := 96.0  ## How close (px) the player must be for the sign to light up.

var _board: PanelContainer
var _nails: Array[ColorRect] = []
var _lit := false


func _ready() -> void:
	_board = PanelContainer.new()
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if paper:
		_board.add_theme_stylebox_override("panel", _paper_box())
	else:
		var margins := Vector4(4, 2, 4, 3) if small else Vector4(6, 3, 6, 4)
		_board.add_theme_stylebox_override("panel", _box(WOOD, OUTLINE, 1, 2, margins, WOOD_DARK))
	add_child(_board)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	_board.add_child(column)

	var words := Label.new()
	words.text = text
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.add_theme_font_override("font", GameFonts.TEXT_BOLD)
	words.add_theme_font_size_override("font_size", GameFonts.SMALL_TEXT_SIZE if small else GameFonts.TEXT_SIZE)
	words.add_theme_color_override("font_color", INK)
	words.add_theme_constant_override("line_spacing", -1 if small else -2)
	column.add_child(words)

	if code != "":
		var strip := PanelContainer.new()
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_theme_stylebox_override("panel", _box(STRIP, OUTLINE, 1, 1, Vector4(4, 0, 4, 1)))
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(strip)
		column.add_child(holder)
		var line := Label.new()
		line.text = code
		line.add_theme_font_override("font", GameFonts.CODE_BOLD)
		line.add_theme_font_size_override("font_size", 8 if small else GameFonts.CODE_SIZE)
		line.add_theme_color_override("font_color", STRIP_INK)
		strip.add_child(line)

	if paper:
		return  # the note has its own pins
	# Two nails at the top corners, drawn over the frame. (Not inside the board: a container
	# would stretch them over the whole sign.)
	for side in 2:
		var nail := ColorRect.new()
		nail.color = NAIL
		nail.size = Vector2(2, 2)
		nail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(nail)
		_nails.append(nail)
	_board.resized.connect(_place_nails)
	_place_nails.call_deferred()


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or _board == null:
		return
	var near := Rect2(global_position, _board.size).grow(NEAR).has_point(player.global_position)
	if near == _lit:
		return
	_lit = near
	var tween := create_tween()
	tween.tween_property(_board, "modulate", Color(1.12, 1.12, 1.12) if near else Color.WHITE, 0.2)


func _place_nails() -> void:
	for side in _nails.size():
		_nails[side].position = Vector2(3.0 if side == 0 else _board.size.x - 5.0, 3.0)


## The parchment note, stretched to fit: corners as drawn, edges repeated, the middle stretched.
func _paper_box() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = paper
	s.set_texture_margin_all(PAPER_EDGE)
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.content_margin_left = 7
	s.content_margin_right = 7
	s.content_margin_top = 4
	s.content_margin_bottom = 5
	return s


func _box(fill: Color, border: Color, width: int, radius: int, margins: Vector4, shadow := Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = false
	s.content_margin_left = margins.x
	s.content_margin_top = margins.y
	s.content_margin_right = margins.z
	s.content_margin_bottom = margins.w
	if shadow.a > 0.0:
		s.shadow_color = shadow
		s.shadow_size = 0
		s.shadow_offset = Vector2(0, 2)
	return s
