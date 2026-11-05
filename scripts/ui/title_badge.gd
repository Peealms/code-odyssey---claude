extends Node2D
## A small tag shown next to the title for one of the game's subjects (variables, if/else, ...).
## The node's position is the badge's centre. It bobs gently, offset by `phase`.

const FONT := preload("res://assets/shared/ui/fonts/pixel_font.fnt")
const SIZE := Vector2(110, 34)
const BODY := Color("14112a")

var symbol := ""
var label := ""
var color := Color.WHITE
var phase := 0.0
var _base_y := 0.0
var _time := 0.0


func setup(sym: String, text: String, accent: Color, ph: float) -> void:
	symbol = sym
	label = text
	color = accent
	phase = ph


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + roundf(sin(_time * 2.0 + phase) * 2.0)


func _draw() -> void:
	var o := -SIZE * 0.5
	# Shadow, then a pixel-cornered body with an accent border.
	draw_rect(Rect2(o + Vector2(3, 3), SIZE), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(o + Vector2(2, 0), SIZE - Vector2(4, 0)), color)
	draw_rect(Rect2(o + Vector2(0, 2), SIZE - Vector2(0, 4)), color)
	draw_rect(Rect2(o + Vector2(2, 2), SIZE - Vector2(4, 4)), BODY)
	draw_rect(Rect2(o + Vector2(3, 3), Vector2(SIZE.x - 6, 3)), Color(1, 1, 1, 0.08))
	var sw := FONT.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(FONT, Vector2(-sw * 0.5, o.y + 14), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		color.lightened(0.35))
	var lw := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(FONT, Vector2(-lw * 0.5, o.y + 27), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(1, 1, 1, 0.8))
