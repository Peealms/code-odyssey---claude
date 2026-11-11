extends Node
## Global game state. Registered as the "Game" autoload in Project Settings.
## Access from any script with: Game.some_function()

const SETTINGS_PATH := "user://settings.cfg"
const SAVE_PATH := "user://save.cfg"

## Hero ids (the five of us), in the order they are rescued. Psalm isn't placed in a level yet.
const HEROES := ["chelzy", "sarah", "april", "kervin", "psalm"]
## Saves from before the team replaced the Pixel Adventure heroes: each old hero becomes the
## teammate with the same ability.
const OLD_HERO_IDS := {"ninja_frog": "chelzy", "pink_man": "sarah", "mask_dude": "april", "virtual_guy": "kervin"}

var current_hero: String = "chelzy"
var unlocked_heroes: Array = ["chelzy"]
## Heroes on the hero wheel (hold Q): a hero joins the first time the player switches to them
## in code after rescuing them. Saved for good, so it's typed once, not in every level.
var wheel_heroes: Array = ["chelzy"]
## Best stars per level id, e.g. {"level1": 3}. Saved with progress.
var best_stars: Dictionary = {}

# The level being played right now (reset by start_level).
var level_id := ""
var answers_shown := 0  ## "Show answer" uses - each one costs a star.
var mistakes := 0  ## Wrong lines typed in the terminal.
var _level_start_ms := 0

var immune := false  # IMMUNITY: true while the secret testing mode is on (scripts/dev/immunity.gd)
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var fullscreen: bool = false

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _changing_scene := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_layer()
	load_settings()
	load_progress()
	if OS.has_feature("editor") and ResourceLoader.exists("res://scripts/dev/immunity.gd"):  # IMMUNITY: editor runs only
		add_child(load("res://scripts/dev/immunity.gd").new())  # IMMUNITY


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


## Puts a rescued hero on the hero wheel. Returns true if they just joined it.
func add_wheel_hero(hero_id: String) -> bool:
	if immune: return false  # IMMUNITY: code run in immunity mode doesn't change the save
	if not hero_id in HEROES or not hero_id in unlocked_heroes or hero_id in wheel_heroes:
		return false
	wheel_heroes.append(hero_id)
	save_progress()
	return true


func is_on_wheel(hero_id: String) -> bool:
	return hero_id in wheel_heroes


# ---------------- Level stats & stars ----------------

func start_level(id: String) -> void:
	level_id = id
	answers_shown = 0
	mistakes = 0
	_level_start_ms = Time.get_ticks_msec()


## 0 answers shown = 3 stars, 1 = 2 stars, 2 or more = 1 star.
func stars_earned() -> int:
	return clampi(3 - answers_shown, 1, 3)


## Call when the level's goal is reached. Saves the best stars and returns the results.
func finish_level() -> Dictionary:
	var stars := stars_earned()
	var best: int = maxi(stars, best_stars.get(level_id, 0))
	var results := {
		"stars": stars,
		"best": best,
		"answers_shown": answers_shown,
		"mistakes": mistakes,
		"seconds": (Time.get_ticks_msec() - _level_start_ms) / 1000.0,
	}
	if immune: return results  # IMMUNITY: a level finished in immunity mode isn't saved
	best_stars[level_id] = best
	save_progress()
	return results


# ---------------- Settings ----------------

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_set_bus("Master", master_volume)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_set_bus("Music", music_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus("SFX", sfx_volume)


func _set_bus(bus_name: String, value: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(bus, value <= 0.0)


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
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		master_volume = cfg.get_value("audio", "master_volume", master_volume)
		music_volume = cfg.get_value("audio", "music_volume", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
		fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	set_master_volume(master_volume)
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	set_fullscreen(fullscreen)


# ---------------- Progress ----------------

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_heroes", unlocked_heroes)
	cfg.set_value("progress", "current_hero", current_hero)
	cfg.set_value("progress", "wheel_heroes", wheel_heroes)
	cfg.set_value("progress", "best_stars", best_stars)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked_heroes = cfg.get_value("progress", "unlocked_heroes", unlocked_heroes)
		current_hero = cfg.get_value("progress", "current_hero", current_hero)
		# A save from before the hero wheel: the hero being played was surely typed.
		wheel_heroes = cfg.get_value("progress", "wheel_heroes", [HEROES[0], current_hero])
		best_stars = cfg.get_value("progress", "best_stars", best_stars)
		_update_old_hero_ids()


## Turns hero ids from an older save into the team's ids and drops any it doesn't know.
func _update_old_hero_ids() -> void:
	var heroes: Array = [HEROES[0]]
	for id in unlocked_heroes:
		var new_id: String = OLD_HERO_IDS.get(id, id)
		if new_id in HEROES and not new_id in heroes:
			heroes.append(new_id)
	unlocked_heroes = heroes
	current_hero = OLD_HERO_IDS.get(current_hero, current_hero)
	if not current_hero in unlocked_heroes:
		current_hero = HEROES[0]
	var on_wheel: Array = [HEROES[0]]
	for id in wheel_heroes:
		var new_id: String = OLD_HERO_IDS.get(id, id)
		if new_id in HEROES and not new_id in on_wheel:
			on_wheel.append(new_id)
	wheel_heroes = on_wheel


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset_progress() -> void:
	unlocked_heroes = [HEROES[0]]
	current_hero = HEROES[0]
	wheel_heroes = [HEROES[0]]
	best_stars = {}
	save_progress()
