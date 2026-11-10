extends ReadingSource
## The tide post: gives the reading `tide` (0-5), which rises and falls by itself following
## `pattern`, one step every `step_time` seconds. Draws a post with the number on it.
## Water nodes in mode "tide" / "flood" follow it (see water.gd).

@export var pattern: Array[int] = [0, 1, 2, 3, 4, 5, 4, 3, 2, 1]
@export var step_time := 1.5
@export var post_height := 72.0

var _index := 0
var _timer := 0.0
var _label: Label


func _ready() -> void:
	super()
	set_reading("tide", pattern[0])
	_label = Label.new()
	_label.position = Vector2(-22, -post_height - 20)
	_label.size = Vector2(44, 14)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color("ffe478"))
	_label.add_theme_color_override("font_shadow_color", Color("211f30"))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	_update_label()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= step_time:
		_timer -= step_time
		_index = (_index + 1) % pattern.size()
		set_reading("tide", pattern[_index])
		_update_label()
		queue_redraw()


func tide() -> int:
	return get_reading("tide")


func _update_label() -> void:
	_label.text = "TIDE %d" % tide()


func _draw() -> void:
	# Wooden post with six marks; the mark of the current tide is lit.
	draw_rect(Rect2(-3, -post_height, 6, post_height), Color("6e4a3a"))
	draw_rect(Rect2(-3, -post_height, 2, post_height), Color("8f6550"))
	for i in 6:
		var y := -6.0 - i * (post_height - 12.0) / 5.0
		var lit := i == tide()
		draw_rect(Rect2(-7 if lit else -5, y - 1, 14 if lit else 10, 3 if lit else 2),
			Color("ffe478") if lit else Color("d7c9a7"))
