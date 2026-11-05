extends Control
## Main menu: Play / Continue / Settings / Quit.

const LEVEL_SELECT := "res://scenes/ui/level_select.tscn"
const BADGE := preload("res://scripts/ui/title_badge.gd")
const FIRST_LEVEL := "res://scenes/levels/level1/level1.tscn"
## The test room (all heroes, Crabby, sword) is still at res://scenes/levels/test/test_room.tscn -
## open it in the editor and press F6 to play it.

@onready var background: TextureRect = $Background
@onready var title: Node2D = $Title
@onready var badges: Node2D = $Badges
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

var _music_slider: HSlider
var _sfx_slider: HSlider
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
	_music_slider = _add_volume_row("MUSIC", 1, Game.set_music_volume)
	_sfx_slider = _add_volume_row("SOUNDS", 2, Game.set_sfx_volume)
	for b in find_children("*", "BaseButton", true, false):
		b.pressed.connect(Sound.play.bind("ui_select"))
	Sound.music("menu")
	_build_badges()

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


func _on_continue() -> void:
	Game.change_scene(FIRST_LEVEL)


func _open_settings() -> void:
	volume_slider.value = Game.master_volume
	_music_slider.value = Game.music_volume
	_sfx_slider.value = Game.sfx_volume
	fullscreen_check.button_pressed = Game.fullscreen
	settings_panel.visible = true
	menu_buttons.visible = false
	title.visible = false
	badges.visible = false
	prompt.visible = false
	volume_slider.grab_focus()


func _close_settings() -> void:
	Game.save_settings()
	settings_panel.visible = false
	menu_buttons.visible = true
	title.visible = true
	badges.visible = true
	prompt.visible = true
	settings_button.grab_focus()


## The game's four subjects, as tags either side of the title.
func _build_badges() -> void:
	var tags := [
		["x = 5", "VARIABLES", Color("5fb8ff"), Vector2(78, 56)],
		["if / else", "CONDITIONALS", Color("ffb347"), Vector2(78, 100)],
		["a && b", "LOGIC", Color("c58bff"), Vector2(562, 56)],
		["for { }", "LOOPS", Color("6fe08a"), Vector2(562, 100)],
	]
	for i in tags.size():
		var b: Node2D = BADGE.new()
		b.position = tags[i][3]
		b.setup(tags[i][0], tags[i][1], tags[i][2], i * 1.3)
		badges.add_child(b)


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
