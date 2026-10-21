extends Control
## Main menu: Play / Continue / Settings / Quit.

const FIRST_LEVEL := "res://scenes/levels/test/test_room.tscn"

@onready var background: TextureRect = $Background
@onready var title: Label = $Title
@onready var prompt: Label = $Prompt
@onready var menu_buttons: VBoxContainer = $MenuButtons
@onready var play_button: Button = $MenuButtons/PlayButton
@onready var continue_button: Button = $MenuButtons/ContinueButton
@onready var settings_button: Button = $MenuButtons/SettingsButton
@onready var quit_button: Button = $MenuButtons/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var volume_slider: HSlider = $SettingsPanel/VBox/VolumeRow/VolumeSlider
@onready var fullscreen_check: CheckButton = $SettingsPanel/VBox/FullscreenCheck
@onready var back_button: Button = $SettingsPanel/VBox/BackButton

var _time := 0.0
var _title_base_y := 0.0


func _ready() -> void:
	play_button.pressed.connect(_on_play)
	continue_button.pressed.connect(_on_continue)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(func(): get_tree().quit())
	back_button.pressed.connect(_close_settings)
	volume_slider.value_changed.connect(func(v): Game.set_master_volume(v))
	fullscreen_check.toggled.connect(func(on): Game.set_fullscreen(on))

	continue_button.disabled = not Game.has_save()
	settings_panel.visible = false
	_title_base_y = title.position.y
	play_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	# Slowly scroll the tiled background diagonally (loops every 64 px).
	background.position = Vector2(-fmod(_time * 12.0, 64.0), -fmod(_time * 12.0, 64.0))
	# Gentle bob on the title.
	title.position.y = _title_base_y + roundf(sin(_time * 2.0) * 2.0)
	# Blinking cursor, like a terminal waiting for input.
	prompt.text = "> PRESS PLAY TO COMPILE" + ("_" if fmod(_time, 1.0) < 0.5 else " ")


func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()


func _on_play() -> void:
	Game.reset_progress()
	Game.change_scene(FIRST_LEVEL)


func _on_continue() -> void:
	Game.change_scene(FIRST_LEVEL)


func _open_settings() -> void:
	volume_slider.value = Game.master_volume
	fullscreen_check.button_pressed = Game.fullscreen
	settings_panel.visible = true
	menu_buttons.visible = false
	volume_slider.grab_focus()


func _close_settings() -> void:
	Game.save_settings()
	settings_panel.visible = false
	menu_buttons.visible = true
	settings_button.grab_focus()
