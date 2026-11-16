extends Control
## Main menu: Play / Continue / Story (watch the backstory again) / Settings / Quit.
## CONTINUE goes to the furthest level: Level 1 once the tutorial has a star, else the tutorial.
## Settings has RESET PROGRESS (press it twice), for a new player on the same computer.

const LEVEL_SELECT := "res://scenes/ui/level_select.tscn"
const FIRST_LEVEL := "res://scenes/levels/level1/level1.tscn"  ## the tutorial
const LEVEL_ONE := "res://scenes/levels/level2/level2.tscn"  ## Level 1 (its id is still level2)
const RESET_TEXT := "RESET PROGRESS"

@onready var background: TextureRect = $Background
@onready var title: Node2D = $Title
@onready var prompt: Label = $Prompt
@onready var menu_buttons: VBoxContainer = $MenuButtons
@onready var play_button: Button = $MenuButtons/PlayButton
@onready var continue_button: Button = $MenuButtons/ContinueButton
@onready var story_button: Button = $MenuButtons/StoryButton
@onready var settings_button: Button = $MenuButtons/SettingsButton
@onready var quit_button: Button = $MenuButtons/QuitButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var volume_slider: HSlider = $SettingsPanel/VBox/VolumeRow/VolumeSlider
@onready var fullscreen_check: CheckButton = $SettingsPanel/VBox/FullscreenCheck
@onready var back_button: Button = $SettingsPanel/VBox/BackButton

var _music_slider: HSlider
var _sfx_slider: HSlider
var reset_button: Button
var _reset_armed := false
var _time := 0.0
var _title_base_y := 0.0


func _ready() -> void:
	play_button.pressed.connect(_on_play)
	continue_button.pressed.connect(_on_continue)
	story_button.pressed.connect(func(): Game.play_story(scene_file_path))  # back here after
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(func(): get_tree().quit())
	back_button.pressed.connect(_close_settings)
	volume_slider.value_changed.connect(func(v): Game.set_master_volume(v))
	fullscreen_check.toggled.connect(func(on): Game.set_fullscreen(on))
	_music_slider = _add_volume_row("MUSIC", 1, Game.set_music_volume)
	_sfx_slider = _add_volume_row("SOUNDS", 2, Game.set_sfx_volume)
	_add_reset_button()
	for b in find_children("*", "BaseButton", true, false):
		b.pressed.connect(Sound.play.bind("ui_select"))
	Sound.music("menu")

	continue_button.disabled = not Game.has_save()
	settings_panel.visible = false
	_title_base_y = title.position.y
	play_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	# The background scrolls left at half the speed of the ground (parallax), like a runner.
	background.position = Vector2(-fmod(_time * 27.5, 64.0), 0.0)
	# Gentle bob on the title.
	title.position.y = _title_base_y + roundf(sin(_time * 2.0) * 2.0)
	# Blinking cursor, like a terminal waiting for input.
	prompt.text = "> PRESS PLAY TO COMPILE" + ("_" if fmod(_time, 1.0) < 0.5 else " ")


func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()


func _on_play() -> void:
	Game.change_scene(LEVEL_SELECT)


## The furthest level: Level 1 once the tutorial is done, else the tutorial (with the
## backstory first if it hasn't been seen).
func continue_scene() -> String:
	if Game.best_stars.get("level1", 0) > 0:
		return LEVEL_ONE
	return FIRST_LEVEL


func _on_continue() -> void:
	var next := continue_scene()
	if next == FIRST_LEVEL and not Game.story_seen:
		Game.play_story(FIRST_LEVEL)
	else:
		Game.change_scene(next)


func _open_settings() -> void:
	volume_slider.value = Game.master_volume
	_music_slider.value = Game.music_volume
	_sfx_slider.value = Game.sfx_volume
	fullscreen_check.button_pressed = Game.fullscreen
	settings_panel.visible = true
	menu_buttons.visible = false
	title.visible = false
	prompt.visible = false
	volume_slider.grab_focus()


func _close_settings() -> void:
	_disarm_reset()
	Game.save_settings()
	settings_panel.visible = false
	menu_buttons.visible = true
	title.visible = true
	prompt.visible = true
	settings_button.grab_focus()


## RESET PROGRESS, above BACK. The first press asks "SURE? PRESS AGAIN"; the second resets.
func _add_reset_button() -> void:
	reset_button = Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = RESET_TEXT
	$SettingsPanel/VBox.add_child(reset_button)
	$SettingsPanel/VBox.move_child(reset_button, back_button.get_index())
	reset_button.pressed.connect(_on_reset)


func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = "SURE? PRESS AGAIN"
		get_tree().create_timer(3.0).timeout.connect(_disarm_reset)
		return
	_reset_armed = false
	Game.reset_progress()
	reset_button.text = "PROGRESS RESET!"
	continue_button.disabled = true


func _disarm_reset() -> void:
	if _reset_armed:
		_reset_armed = false
		reset_button.text = RESET_TEXT


## A copy of the VOLUME row for another sound bus, placed at `index` in the settings list.
func _add_volume_row(text: String, index: int, setter: Callable) -> HSlider:
	var row: HBoxContainer = $SettingsPanel/VBox/VolumeRow.duplicate()
	row.name = text.capitalize() + "Row"
	$SettingsPanel/VBox.add_child(row)
	$SettingsPanel/VBox.move_child(row, $SettingsPanel/VBox/VolumeRow.get_index() + index)
	row.get_child(0).text = text
	for label in [row.get_child(0), $SettingsPanel/VBox/VolumeRow.get_child(0)]:
		label.custom_minimum_size.x = 56  # line the sliders up
	var slider: HSlider = row.get_child(1)
	slider.value_changed.connect(setter)
	return slider
