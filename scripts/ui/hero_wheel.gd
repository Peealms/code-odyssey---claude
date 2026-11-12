class_name HeroWheel
extends CanvasLayer
## The hero wheel: hold Q, point the mouse at a hero (or scroll), let go of Q to switch.
## The world runs in slow motion while it's open. Esc closes it without switching.
##
## A hero is on the wheel once they're rescued AND the player has switched to them in code
## once, e.g. hero = "April"; (see Game.wheel_heroes - it's saved, so once is enough).
## The other heroes show what's missing:
##   not rescued yet          a flat silhouette with a padlock and "???"
##   rescued, never typed     a grey face with the line to type in Byte's terminal
## Switching here is the same as typing the line: if `hero` exists in the code it changes
## too (CodeTerminal.switch_from_wheel).
##
## Level adds one to every level.

enum State { READY, NEEDS_CODE, LOCKED }

const SLOW_MOTION := 0.25  ## Engine.time_scale while the wheel is open.
const OUTER := 146.0  ## Ring radii, in screen pixels.
const INNER := 60.0
const POP := 6.0  ## How much bigger the pointed-at slice gets.
const GAP := 0.03  ## Radians left empty between slices.
const DEAD_ZONE := 36.0  ## Pointing closer to the middle than this keeps the current pick.
const HEAD_SIZE := 54.0  ## The 18 px heads at 3x.
const LABEL_WIDTH := 120.0

const INK := Color(0.129412, 0.121569, 0.188235)
const EDGE := Color(0.952941, 0.835294, 0.607843)
const YELLOW := Color(1, 0.894118, 0.470588)
const HOVER := Color(0.784314, 0.494118, 0.317647)
const HOVER_LOCKED := Color(0.32, 0.29, 0.42)
const DIM_TEXT := Color(0.66, 0.64, 0.76)
const CODE_COLOR := Color(1, 0.827451, 0.301961)
const LOCK_COLOR := Color(0.75, 0.72, 0.85)
const TRAIT_TEXT := {
	"wall_jump": "WALL JUMP",
	"dash": "DASH",
	"double_jump": "DOUBLE JUMP",
	"sprint": "SPRINT",
	"shrink": "SHRINK",
}
const HERO_DATA: Dictionary = preload("res://scripts/player/player.gd").HERO_DATA

@export var player: CharacterBody2D
var is_open := false

var _selected := 0
var _root: Control
var _ring: Control
var _locks: Control
var _heads: Array[HeroHead] = []
var _slot_labels: Array[Label] = []
var _center_name: Label
var _center_trait: Label
var _center_note: Label
var _hint_panel: PanelContainer
var _hint_text: Label
var _hint_code: Label
var _tween: Tween
var _mono: SystemFont


func _ready() -> void:
	layer = 30  # over the HUD, under Byte's terminal and the pause menu
	process_mode = Node.PROCESS_MODE_ALWAYS  # notices the pause menu opening, and closes
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Consolas", "Courier New", "Monospace"])
	_build()
	_root.visible = false


func _exit_tree() -> void:
	if is_open:
		Engine.time_scale = 1.0  # never leave the next scene in slow motion


# ---------------- Opening and closing ----------------

func _unhandled_input(event: InputEvent) -> void:
	if is_open or not event.is_action_pressed("hero_wheel") or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	_try_open()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_released("hero_wheel"):
		_close(true)
	elif event.is_action_pressed("pause"):
		_close(false)
	elif event.is_action_pressed("open_terminal"):
		pass  # one thing at a time: let go of Q first
	elif event is InputEventMouseMotion:
		_point_at(event.position)
		return
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_selected(posmod(_selected + 1, Game.HEROES.size()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_selected(posmod(_selected - 1, Game.HEROES.size()))
	elif event is InputEventMouseButton:
		pass  # clicks don't swing the sword through the wheel
	else:
		return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not is_open:
		return
	var terminal := _terminal()
	if get_tree().paused or not player.input_enabled or (terminal and terminal.is_open):
		_close(false)  # the pause menu, a cutscene or the terminal took over
	elif not Input.is_action_pressed("hero_wheel"):
		_close(true)  # Q was let go while the window wasn't listening


func _try_open() -> void:
	if player == null or get_tree().paused or not player.input_enabled:
		return
	var terminal := _terminal()
	if terminal and terminal.is_open:
		return
	is_open = true
	player.wheel_open = true
	Engine.time_scale = SLOW_MOTION
	Sound.play("terminal_open")
	_selected = maxi(Game.HEROES.find(player.hero_id), 0)
	_layout()
	_refresh()
	_root.visible = true
	_root.pivot_offset = _root.size / 2.0
	_root.scale = Vector2(0.9, 0.9)
	_root.modulate.a = 0.0
	_animate({"scale": Vector2.ONE, "modulate:a": 1.0}, 0.1)


## `pick`: switch to the pointed-at hero (Q let go), or just close (Esc, the pause menu...).
func _close(pick: bool) -> void:
	if not is_open:
		return
	is_open = false
	Engine.time_scale = 1.0
	_animate({"modulate:a": 0.0}, 0.08).finished.connect(func(): _root.visible = is_open)
	_free_hands()
	if pick:
		_pick(Game.HEROES[_selected])
	else:
		Sound.play("terminal_close")


## Clicks work again after the next physics step, so a click on the frame Q was let go
## doesn't swing the sword.
func _free_hands() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_open and is_instance_valid(player):
		player.wheel_open = false


func _animate(props: Dictionary, time: float) -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel().set_ignore_time_scale()
	for prop in props:
		_tween.tween_property(_root, prop, props[prop], time)
	return _tween


func _pick(hero_id: String) -> void:
	if hero_id == player.hero_id:
		Sound.play("terminal_close")
		return
	var hero_name: String = HERO_DATA[hero_id]["name"]
	match _state(hero_id):
		State.LOCKED:
			Sound.play("blocked")
			_hud_message("RESCUE THIS HERO FIRST!")
		State.NEEDS_CODE:
			Sound.play("blocked")
			_hud_message("SWITCH TO %s IN CODE ONCE!" % hero_name.to_upper())
			var terminal := _terminal()
			if terminal:
				terminal.byte_says("Type %s once and %s joins your hero wheel for good." % [terminal.hero_line(hero_id), hero_name])
		State.READY:
			var terminal := _terminal()
			var switched: bool = terminal.switch_from_wheel(hero_id) if terminal else player.set_hero(hero_id)
			if not switched:
				Sound.play("blocked")
				_hud_message("NO ROOM TO GROW HERE!")


# ---------------- Pointing ----------------

func _point_at(screen_pos: Vector2) -> void:
	var from_center := screen_pos - _root.size / 2.0
	if from_center.length() < DEAD_ZONE:
		return
	var slice := TAU / Game.HEROES.size()
	# Slot 0 is straight up; the slots go round clockwise.
	var turned := fposmod(from_center.angle() + PI / 2.0 + slice / 2.0, TAU)
	_set_selected(int(turned / slice) % Game.HEROES.size())


func _set_selected(index: int) -> void:
	if index == _selected:
		return
	_selected = index
	Sound.play("ui_move")
	_refresh()


func _state(hero_id: String) -> State:
	if Game.immune: return State.READY  # IMMUNITY: every hero, rescued or not
	if hero_id == player.hero_id:
		return State.READY
	if not Game.is_hero_unlocked(hero_id):
		return State.LOCKED
	if not Game.is_on_wheel(hero_id):
		return State.NEEDS_CODE
	return State.READY


func _slot_angle(index: int) -> float:
	return -PI / 2.0 + index * TAU / Game.HEROES.size()


func _slot_center(index: int) -> Vector2:
	return _root.size / 2.0 + Vector2.from_angle(_slot_angle(index)) * (OUTER + INNER) / 2.0


# ---------------- Showing ----------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)
	_ring = Control.new()
	_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	_root.add_child(_ring)
	for id in Game.HEROES:
		var head := HeroHead.new()
		head.hero_id = id
		head.size = Vector2(HEAD_SIZE, HEAD_SIZE)
		_root.add_child(head)
		_heads.append(head)
		var label := _label("", Color.WHITE)
		label.size = Vector2(LABEL_WIDTH, 24)
		_root.add_child(label)
		_slot_labels.append(label)
	_locks = Control.new()
	_locks.set_anchors_preset(Control.PRESET_FULL_RECT)
	_locks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_locks.draw.connect(_draw_locks)
	_root.add_child(_locks)
	_center_name = _label("", YELLOW)
	_center_trait = _label("", Color.WHITE)
	_center_note = _label("", DIM_TEXT)
	for label in [_center_name, _center_trait, _center_note]:
		label.size = Vector2(INNER * 2.0 - 12.0, 12)
		_root.add_child(label)

	_hint_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK, 0.9)
	box.set_border_width_all(1)
	box.border_color = Color(EDGE, 0.6)
	box.content_margin_left = 6
	box.content_margin_right = 6
	box.content_margin_top = 3
	box.content_margin_bottom = 2
	box.anti_aliasing = false
	_hint_panel.add_theme_stylebox_override("panel", box)
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.add_child(row)
	_hint_text = _label("", Color.WHITE)
	row.add_child(_hint_text)
	_hint_code = _code_label()
	row.add_child(_hint_code)


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	return label


func _code_label() -> Label:
	var label := _label("", CODE_COLOR)
	label.add_theme_font_override("font", _mono)
	label.add_theme_font_size_override("font_size", 9)
	return label


## Puts the heads and labels round the ring (the screen size can change between openings).
func _layout() -> void:
	var middle := _root.size / 2.0
	for i in Game.HEROES.size():
		var spot := _slot_center(i)
		_heads[i].position = (spot - Vector2(HEAD_SIZE / 2.0, HEAD_SIZE / 2.0 + 8.0)).floor()
		_slot_labels[i].position = (spot + Vector2(-LABEL_WIDTH / 2.0, HEAD_SIZE / 2.0 - 8.0)).floor()
	var width := INNER * 2.0 - 12.0
	_center_name.position = (middle + Vector2(-width / 2.0, -19)).floor()
	_center_trait.position = (middle + Vector2(-width / 2.0, -6)).floor()
	_center_note.position = (middle + Vector2(-width / 2.0, 7)).floor()


func _refresh() -> void:
	var terminal := _terminal()
	for i in Game.HEROES.size():
		var id: String = Game.HEROES[i]
		var head := _heads[i]
		var label := _slot_labels[i]
		var state := _state(id)
		match state:
			State.READY: head.look = HeroHead.Look.NORMAL
			State.NEEDS_CODE: head.look = HeroHead.Look.DIM
			State.LOCKED: head.look = HeroHead.Look.SILHOUETTE
		head.animate = state == State.READY
		label.remove_theme_font_override("font")
		label.remove_theme_font_size_override("font_size")
		match state:
			State.READY:
				label.text = HERO_DATA[id]["name"]
				label.add_theme_color_override("font_color", YELLOW if i == _selected else Color.WHITE)
			State.NEEDS_CODE:
				# The line to type; a declaration (String hero = ...) goes on two lines to fit.
				var line: String = terminal.hero_line(id) if terminal else "hero = \"%s\";" % HERO_DATA[id]["name"]
				label.text = line.replace("= ", "=\n") if line.begins_with("String") else line
				label.add_theme_font_override("font", _mono)
				label.add_theme_font_size_override("font_size", 9)
				label.add_theme_color_override("font_color", CODE_COLOR)
			State.LOCKED:
				label.text = "???"
				label.add_theme_color_override("font_color", DIM_TEXT)
	_show_selected(terminal)
	_ring.queue_redraw()
	_locks.queue_redraw()


## The middle of the wheel and the hint under it: about the pointed-at hero.
func _show_selected(terminal: Node) -> void:
	var id: String = Game.HEROES[_selected]
	var data: Dictionary = HERO_DATA[id]
	var state := _state(id)
	var hero_name: String = data["name"].to_upper()
	_hint_code.text = ""
	if state == State.LOCKED:
		_center_name.text = "???"
		_center_trait.text = "NOT RESCUED"
		_center_note.text = ""
		_hint_text.text = "RESCUE THIS HERO TO MEET THEM"
	else:
		_center_name.text = hero_name
		_center_trait.text = TRAIT_TEXT.get(data["trait"], "")
		if id == player.hero_id:
			_center_note.text = "PLAYING NOW"
			_hint_text.text = "POINT AT A HERO, THEN LET GO OF Q"
		elif state == State.NEEDS_CODE:
			_center_note.text = "TYPE IT ONCE"
			_hint_text.text = "TYPE THIS ONCE IN BYTE'S TERMINAL:"
			_hint_code.text = terminal.hero_line(id) if terminal else ""
		elif not player.can_change_hero():
			_center_note.text = "NO ROOM HERE"
			_hint_text.text = "GET PSALM OUT OF THE TUNNEL FIRST"
		else:
			_center_note.text = "LET GO OF Q"
			_hint_text.text = "LET GO OF Q TO PLAY AS " + hero_name
	_hint_code.visible = _hint_code.text != ""
	_hint_panel.reset_size()
	var fit := _hint_panel.get_combined_minimum_size()
	_hint_panel.position = (Vector2(_root.size.x / 2.0 - fit.x / 2.0, _root.size.y / 2.0 + OUTER + 8.0)).floor()


func _draw_ring() -> void:
	var middle := _root.size / 2.0
	var count := Game.HEROES.size()
	var slice := TAU / count
	for i in count:
		var id: String = Game.HEROES[i]
		var state := _state(id)
		var selected := i == _selected
		var from := _slot_angle(i) - slice / 2.0 + GAP / 2.0
		var to := _slot_angle(i) + slice / 2.0 - GAP / 2.0
		var outer := OUTER + (POP if selected else 0.0)
		var points := PackedVector2Array()
		var steps := 18
		for s in steps + 1:
			points.append(middle + Vector2.from_angle(lerpf(from, to, float(s) / steps)) * outer)
		for s in range(steps, -1, -1):
			points.append(middle + Vector2.from_angle(lerpf(from, to, float(s) / steps)) * INNER)
		var fill := Color(INK, 0.86)
		if selected:
			fill = Color(HOVER, 0.95) if state == State.READY else Color(HOVER_LOCKED, 0.95)
		_ring.draw_colored_polygon(points, fill)
		points.append(points[0])
		_ring.draw_polyline(points, YELLOW if selected else Color(EDGE, 0.55), 1.0)
		if id == player.hero_id:
			# The hero you're playing: a yellow line along the inside of their slice.
			_ring.draw_arc(middle, INNER + 3.0, from + 0.06, to - 0.06, 16, YELLOW, 2.0)
	_ring.draw_circle(middle, INNER - 5.0, Color(INK, 0.94))
	_ring.draw_arc(middle, INNER - 5.0, 0.0, TAU, 48, Color(EDGE, 0.6), 1.0)


## Padlocks on the heroes who aren't rescued yet (drawn over their heads).
func _draw_locks() -> void:
	for i in Game.HEROES.size():
		if _state(Game.HEROES[i]) == State.LOCKED:
			_draw_padlock(_slot_center(i) + Vector2(10, 2))


## A padlock: the shackle on top of a box with a keyhole, with a dark outline.
func _draw_padlock(at: Vector2) -> void:
	at = at.floor()
	_locks.draw_arc(at + Vector2(7, 1), 5.0, PI, TAU, 10, INK, 5.0)
	_locks.draw_rect(Rect2(at + Vector2(-1, 0), Vector2(16, 13)), INK)
	_locks.draw_arc(at + Vector2(7, 1), 5.0, PI, TAU, 10, LOCK_COLOR, 2.0)
	_locks.draw_rect(Rect2(at + Vector2(0, 1), Vector2(14, 11)), LOCK_COLOR)
	_locks.draw_rect(Rect2(at + Vector2(6, 4), Vector2(2, 5)), INK)


# ---------------- Helpers ----------------

func _terminal() -> Node:
	return get_tree().get_first_node_in_group("code_terminal")


func _hud_message(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_message(text, 1.5)
