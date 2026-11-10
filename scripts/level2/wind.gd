extends ReadingSource
## The wind vane: gives the reading `wind` (0-9). It stays at `calm_value` until a ship starts
## its crossing (start()), then follows `pattern`, one step every `step_time` seconds, so every
## range comes up early. reset() goes back to calm (when the ship is towed back to the dock).

const FLAG := preload("res://assets/level2_treasure_hunters/objects/flag/flag_frames.tres")

@export var pattern: Array[int] = [1, 5, 8, 2, 6, 9, 3, 0, 7, 4]
@export var step_time := 2.5
@export var calm_value := 1

var running := false
var _index := 0
var _timer := 0.0
var _label: Label
var _flag: AnimatedSprite2D


func _ready() -> void:
	super()
	_flag = AnimatedSprite2D.new()
	_flag.sprite_frames = FLAG
	_flag.play("idle")
	_flag.position = Vector2(0, -46)
	add_child(_flag)
	_label = Label.new()
	_label.position = Vector2(-24, -110)
	_label.size = Vector2(48, 14)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color("ffe478"))
	_label.add_theme_color_override("font_shadow_color", Color("211f30"))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	reset()


func start() -> void:
	running = true
	_index = 0
	_timer = 0.0
	_set_wind(pattern[0])


func reset() -> void:
	running = false
	_set_wind(calm_value)


func _process(delta: float) -> void:
	if not running:
		return
	_timer += delta
	if _timer >= step_time:
		_timer -= step_time
		_index = (_index + 1) % pattern.size()
		_set_wind(pattern[_index])


func _set_wind(value: int) -> void:
	set_reading("wind", value)
	_label.text = "WIND %d" % value
	_flag.speed_scale = 0.5 + value * 0.25
