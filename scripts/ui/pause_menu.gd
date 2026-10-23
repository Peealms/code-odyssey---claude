extends CanvasLayer
## Press Esc in a level to pause. Works while the game tree is paused.
## Has Music and Sounds volume sliders (saved in the settings file when you resume).

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

@onready var resume_button: Button = $Center/Panel/VBox/ResumeButton
@onready var restart_button: Button = $Center/Panel/VBox/RestartButton
@onready var menu_button: Button = $Center/Panel/VBox/MenuButton

var _music_slider: HSlider
var _sfx_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(func(): Game.reload_scene())
	menu_button.pressed.connect(func(): Game.change_scene(MAIN_MENU))
	_music_slider = _add_volume_row("MUSIC", Game.set_music_volume)
	_sfx_slider = _add_volume_row("SOUNDS", Game.set_sfx_volume)
	for b in [resume_button, restart_button, menu_button]:
		b.pressed.connect(Sound.play.bind("ui_select"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_music_slider.set_value_no_signal(Game.music_volume)
	_sfx_slider.set_value_no_signal(Game.sfx_volume)
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
