extends Node
## Global game state. Registered as the "Game" autoload in Project Settings.
## Access from any script with: Game.some_function()

const SETTINGS_PATH := "user://settings.cfg"
const SAVE_PATH := "user://save.cfg"

## Hero ids, in the order they are rescued.
const HEROES := ["ninja_frog", "pink_man", "mask_dude", "virtual_guy"]

var current_hero: String = "ninja_frog"
var unlocked_heroes: Array = ["ninja_frog"]

var master_volume: float = 0.8
var fullscreen: bool = false

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _changing_scene := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_layer()
	load_settings()
	load_progress()


# ---------------- Scene changes ----------------

## Fades to black, switches scene, fades back in.
func change_scene(path: String) -> void:
	if _changing_scene:
		return
	_changing_scene = true
	get_tree().paused = false
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.25)
	await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tween_in := create_tween()
	tween_in.tween_property(_fade_rect, "color:a", 0.0, 0.25)
	await tween_in.finished
	_changing_scene = false


func reload_scene() -> void:
	change_scene(get_tree().current_scene.scene_file_path)


func _build_fade_layer() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


# ---------------- Heroes ----------------

func unlock_hero(hero_id: String) -> void:
	if hero_id in HEROES and not hero_id in unlocked_heroes:
		unlocked_heroes.append(hero_id)
		save_progress()


func is_hero_unlocked(hero_id: String) -> bool:
	return hero_id in unlocked_heroes


# ---------------- Settings ----------------

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(bus, master_volume <= 0.0)


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	if DisplayServer.get_name() == "headless":
		return
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		master_volume = cfg.get_value("audio", "master_volume", master_volume)
		fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	set_master_volume(master_volume)
	set_fullscreen(fullscreen)


# ---------------- Progress ----------------

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_heroes", unlocked_heroes)
	cfg.set_value("progress", "current_hero", current_hero)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked_heroes = cfg.get_value("progress", "unlocked_heroes", unlocked_heroes)
		current_hero = cfg.get_value("progress", "current_hero", current_hero)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset_progress() -> void:
	unlocked_heroes = ["ninja_frog"]
	current_hero = "ninja_frog"
	save_progress()
