extends CanvasLayer
## Press Esc in a level to pause. Works while the game tree is paused.
## Has Music and Sounds volume sliders (saved in the settings file when you resume).
## Once the level has a checkpoint save (LevelSave), RESTART becomes LAST CHECKPOINT and a
## RESTART LEVEL button (press twice) starts over from the beginning.
## CONTROLS shows every key; BACK (or Esc) returns to the pause buttons.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

@onready var resume_button: Button = $Center/Panel/VBox/ResumeButton
@onready var restart_button: Button = $Center/Panel/VBox/RestartButton
@onready var menu_button: Button = $Center/Panel/VBox/MenuButton

const RESTART_LEVEL_TEXT := "RESTART LEVEL"
const INK := Color(0.239216, 0.141176, 0.164706)  ## Same ink as the main menu.
const KEY_INK := Color(0.55, 0.2, 0.12)
## Key, what it does. Kept in step with the input map in project.godot.
const CONTROLS := [
	["A D  /  ARROWS", "Move"],
	["SPACE  /  W", "Jump (April: jump again in the air)"],
	["SHIFT", "Sarah: dash   Kervin: sprint"],
	["S  /  DOWN", "Psalm: hold to shrink"],
	["JUMP AT A WALL", "Chelzy: wall jump"],
	["E  /  TAB", "Byte's terminal: type code"],
	["F", "Open chests, next line of talk"],
	["LEFT CLICK", "Use the held item (sword, manual)"],
	["1 - 6  /  WHEEL", "Pick a hotbar slot"],
	["HOLD Q", "Hero wheel: switch heroes"],
	["ESC", "Pause"],
]

var _music_slider: HSlider
var _sfx_slider: HSlider
var _restart_level_button: Button
var _restart_level_armed := false
var _controls_button: Button
var _controls_panel: PanelContainer
var _controls_back: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(func(): Game.change_scene(MAIN_MENU))
	_add_restart_level_button()
	_add_controls()
	_music_slider = _add_volume_row("MUSIC", Game.set_music_volume)
	_sfx_slider = _add_volume_row("SOUNDS", Game.set_sfx_volume)
	for b in [resume_button, restart_button, _restart_level_button, _controls_button, _controls_back, menu_button]:
		b.pressed.connect(Sound.play.bind("ui_select"))


## With a checkpoint save, RESTART becomes LAST CHECKPOINT and RESTART LEVEL appears under it.
func _refresh_restart() -> void:
	var level := get_tree().current_scene as Level
	var saved := level != null and level.has_checkpoint_save()
	restart_button.text = "LAST CHECKPOINT" if saved else "RESTART"
	_restart_level_button.visible = saved
	_disarm_restart_level()


## LAST CHECKPOINT: the level as it was at the last flag. RESTART (no save): from the start.
func _on_restart() -> void:
	var level := get_tree().current_scene as Level
	if level == null:
		Game.reload_scene()
	elif level.has_checkpoint_save():
		level.back_to_checkpoint()
	else:
		level.restart_level()


## RESTART LEVEL throws the checkpoint away, so the first press asks "SURE? PRESS AGAIN".
func _add_restart_level_button() -> void:
	_restart_level_button = Button.new()
	_restart_level_button.name = "RestartLevelButton"
	_restart_level_button.text = RESTART_LEVEL_TEXT
	$Center/Panel/VBox.add_child(_restart_level_button)
	$Center/Panel/VBox.move_child(_restart_level_button, restart_button.get_index() + 1)
	_restart_level_button.pressed.connect(_on_restart_level)


func _on_restart_level() -> void:
	if not _restart_level_armed:
		_restart_level_armed = true
		_restart_level_button.text = "SURE? PRESS AGAIN"
		return
	var level := get_tree().current_scene as Level
	if level:
		level.restart_level()


func _disarm_restart_level() -> void:
	_restart_level_armed = false
	if _restart_level_button:
		_restart_level_button.text = RESTART_LEVEL_TEXT


## CONTROLS (above MAIN MENU) swaps the buttons for a list of keys.
func _add_controls() -> void:
	_controls_button = Button.new()
	_controls_button.name = "ControlsButton"
	_controls_button.text = "CONTROLS"
	$Center/Panel/VBox.add_child(_controls_button)
	$Center/Panel/VBox.move_child(_controls_button, menu_button.get_index())
	_controls_button.pressed.connect(_show_controls.bind(true))

	_controls_panel = PanelContainer.new()
	_controls_panel.name = "ControlsPanel"
	_controls_panel.visible = false
	$Center.add_child(_controls_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_controls_panel.add_child(vbox)
	var heading := Label.new()
	heading.text = "CONTROLS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", INK)
	vbox.add_child(heading)
	var grid := GridContainer.new()
	grid.name = "Keys"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(grid)
	for row in CONTROLS:
		for i in 2:
			var label := Label.new()
			label.text = row[i]
			label.add_theme_color_override("font_color", KEY_INK if i == 0 else INK)
			grid.add_child(label)
	_controls_back = Button.new()
	_controls_back.text = "BACK"
	_controls_back.pressed.connect(_show_controls.bind(false))
	vbox.add_child(_controls_back)


func _show_controls(show: bool) -> void:
	_controls_panel.visible = show
	$Center/Panel.visible = not show
	if show:
		_controls_back.grab_focus()
	else:
		_controls_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _controls_panel.visible:
			_show_controls(false)
		elif visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_music_slider.set_value_no_signal(Game.music_volume)
	_sfx_slider.set_value_no_signal(Game.sfx_volume)
	_refresh_restart()
	_controls_panel.visible = false
	$Center/Panel.visible = true
	visible = true
	get_tree().paused = true
	Sound.play("terminal_open")
	resume_button.grab_focus()


func close() -> void:
	Game.save_settings()
	visible = false
	get_tree().paused = false


func _add_volume_row(text: String, setter: Callable) -> HSlider:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = 52
	label.add_theme_color_override("font_color", Color(0.239216, 0.141176, 0.164706))  # same ink as the main menu
	row.add_child(label)
	var slider := HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(setter)
	slider.drag_ended.connect(func(_changed): Sound.play("ui_move"))
	row.add_child(slider)
	$Center/Panel/VBox.add_child(row)
	return slider
