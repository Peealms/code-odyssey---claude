extends Node2D
## The "CODE ODYSSEY" title: one sprite per letter, cut from title_letters.png (made by
## tools/make_title_logo.gd). Letters drop in with a bounce when the menu opens and then ride
## a gentle wave. The node's position is the top-centre of the logo.

const LETTERS := preload("res://assets/shared/ui/menu/title_letters.png")
const LETTER_W := 34  ## Keep in step with tools/make_title_logo.gd
const LETTER_H := 40
const STEP := 24.0  ## Horizontal distance between letters (a glyph is 21 wide).
const LINE_STEP := 32.0
const LINES := ["CODE", "ODYSSEY"]

var _sprites: Array[Sprite2D] = []
var _base: Array[Vector2] = []
var _time := 0.0
var _landed := false


func _ready() -> void:
	var index := 0
	for line_i in LINES.size():
		var text: String = LINES[line_i]
		var width := (text.length() - 1) * STEP
		for k in text.length():
			var s := Sprite2D.new()
			s.texture = LETTERS
			s.region_enabled = true
			s.region_rect = Rect2(index * LETTER_W, 0, LETTER_W, LETTER_H)
			s.centered = false
			var pos := Vector2(-width * 0.5 + k * STEP - 15.5, line_i * LINE_STEP)
			s.position = pos + Vector2(0, -90)
			s.modulate.a = 0.0
			add_child(s)
			_sprites.append(s)
			_base.append(pos)
			# Drop in from above, one letter after another.
			var tw := create_tween()
			tw.tween_interval(0.07 * index)
			tw.tween_property(s, "modulate:a", 1.0, 0.05)
			tw.tween_property(s, "position", pos, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			index += 1
	get_tree().create_timer(0.07 * index + 0.7).timeout.connect(func(): _landed = true)


func _process(delta: float) -> void:
	_time += delta
	if not _landed:
		return
	for i in _sprites.size():
		var wave := roundf(sin(_time * 3.0 + i * 0.55) * 2.0)
		_sprites[i].position = _base[i] + Vector2(0, wave)
