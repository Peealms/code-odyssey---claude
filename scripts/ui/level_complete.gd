extends CanvasLayer
## Results screen shown when a level's goal is reached (added by the Level script).
## Wood & paper style like the chest window: ribbon title, 3 stars that pop in one by one,
## time / fruits / mistakes / answers shown, and Replay / Continue buttons.

const FONT_COLOR := Color("33323d")
const OUTLINE := Color("33323d")
const WOOD := Color("ae7764")
const WOOD_DARK := Color("833f4c")
const PAPER := Color("eebd8a")
const PAPER_EDGE := Color("b77357")
const BANNER := Color("eebd8a")
const STAR := Color("ffd34d")
const STAR_EDGE := Color("c27a1e")
const STAR_EMPTY := Color(0.2, 0.18, 0.22, 0.35)

var _stars_earned := 0
var _stars_shown := 0
var _replay_path := ""
var _next_path := ""

var _stars_box: Control
var _stats: Label
var _note: Label
var _title: Label
var _continue_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_build()


## result: from Game.finish_level() plus "fruits", "fruit_total", "title".
func show_results(result: Dictionary, replay_path: String, next_path: String) -> void:
	get_tree().paused = true
	_replay_path = replay_path
	_next_path = next_path
	_stars_earned = result["stars"]
	_title.text = result["title"]
	var secs := int(result["seconds"])
	_stats.text = "TIME:  %d:%02d\nFRUITS:  %d / %d\nMISTAKES:  %d\nANSWERS SHOWN:  %d\nBEST:  %d STARS" % [
		secs / 60, secs % 60, result["fruits"], result["fruit_total"],
		result["mistakes"], result["answers_shown"], result["best"]]
	if _stars_earned == 3:
		_note.text = "PERFECT - NO ANSWERS SHOWN!"
	else:
		_note.text = "SHOW FEWER ANSWERS FOR MORE STARS"
	_continue_button.grab_focus()
	# Pop the stars in one at a time.
	for i in 3:
		await get_tree().create_timer(0.35, true).timeout
		_stars_shown = i + 1
		_stars_box.queue_redraw()
		if i < _stars_earned:
			var bump := create_tween()
			_stars_box.scale = Vector2(1.08, 1.08)
			bump.tween_property(_stars_box, "scale", Vector2.ONE, 0.15)


func _on_replay() -> void:
	get_tree().paused = false
	Game.change_scene(_replay_path)


func _on_continue() -> void:
	get_tree().paused = false
	Game.change_scene(_next_path)


# ---------------- Building the screen ----------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -7)  # ribbon overlaps the panel
	center.add_child(column)

	var ribbon_holder := CenterContainer.new()
	ribbon_holder.z_index = 1
	column.add_child(ribbon_holder)
	var ribbon := PanelContainer.new()
	ribbon.add_theme_stylebox_override("panel", _box(BANNER, OUTLINE, 1, 2, Vector4(12, 4, 12, 2), PAPER_EDGE))
	_title = Label.new()
	_title.add_theme_color_override("font_color", FONT_COLOR)
	ribbon.add_child(_title)
	ribbon_holder.add_child(ribbon)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(WOOD, OUTLINE, 1, 4, Vector4(3, 3, 3, 3), WOOD_DARK))
	column.add_child(frame)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", _box(PAPER, WOOD_DARK, 1, 3, Vector4(16, 14, 16, 10)))
	frame.add_child(paper)

	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 8)
	paper.add_child(inside)

	_stars_box = Control.new()
	_stars_box.custom_minimum_size = Vector2(150, 40)
	_stars_box.pivot_offset = Vector2(75, 20)
	_stars_box.draw.connect(_draw_stars)
	inside.add_child(_stars_box)

	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_color_override("font_color", WOOD_DARK)
	inside.add_child(_note)

	_stats = Label.new()
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.add_theme_color_override("font_color", FONT_COLOR)
	_stats.add_theme_constant_override("line_spacing", 3)
	inside.add_child(_stats)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	inside.add_child(buttons)
	var replay := Button.new()
	replay.text = "REPLAY"
	replay.pressed.connect(_on_replay)
	buttons.add_child(replay)
	_continue_button = Button.new()
	_continue_button.text = "CONTINUE"
	_continue_button.pressed.connect(_on_continue)
	buttons.add_child(_continue_button)


## Three five-pointed stars; earned ones are gold, the rest are faint outlines.
func _draw_stars() -> void:
	var size := _stars_box.size
	for i in 3:
		var c := Vector2(size.x / 2.0 + (i - 1) * 46.0, size.y / 2.0 + (4.0 if i != 1 else 0.0))
		var r := 17.0 if i == 1 else 14.0
		var points := PackedVector2Array()
		for k in 10:
			var radius := r if k % 2 == 0 else r * 0.45
			points.append(c + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * radius)
		var earned := i < _stars_earned and i < _stars_shown
		_stars_box.draw_colored_polygon(points, STAR if earned else STAR_EMPTY)
		points.append(points[0])
		_stars_box.draw_polyline(points, STAR_EDGE if earned else Color(0.2, 0.18, 0.22, 0.5), 1.5)


func _box(fill: Color, border: Color, width: int, radius: int, padding: Vector4,
		bottom := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
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
