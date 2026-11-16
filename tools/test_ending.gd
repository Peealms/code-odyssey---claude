extends SceneTree
## Plays the ending (scenes/ui/story_ending.tscn) and checks the main menu's CONTINUE and
## RESET PROGRESS:
##  - Level 1's CONTINUE (after its results) leads to the ending
##  - every line of the ending shows, Enter moves on, and it ends at the main menu; Esc skips
##  - CONTINUE goes to the tutorial until it has a star, then to Level 1
##  - RESET PROGRESS needs two presses, clears heroes, stars and the backstory, deletes the
##    save and turns CONTINUE off
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_ending.gd
## Prints PASS/FAIL per check. Screenshots of every line go to the user data folder
## (test_screenshots/ending_*.png). Backs up and restores the real save file.

const OUT := "user://test_screenshots/"
const SAVE := "user://save.cfg"
const BACKUP := "user://save_backup_for_test.cfg"
const ENDING := "res://scenes/ui/story_ending.tscn"
const LEVEL_ONE := "res://scenes/levels/level2/level2.tscn"
const TUTORIAL := "res://scenes/levels/level1/level1.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
const LINES := 8  ## Lines in the ending (narrator and Byte), before THE END.

var game: Node
var results: Array[String] = []


func _initialize() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	_run.call_deferred()


func check(name: String, ok: bool, detail := "") -> void:
	var line := "%s  %s  %s" % ["PASS" if ok else "FAIL", name, detail]
	results.append(line)
	print(line)


func wait(s: float) -> void:
	await create_timer(s).timeout


func scene() -> String:
	return current_scene.scene_file_path if current_scene else ""


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)


func shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_texture().get_image().save_png(OUT + name + ".png")


func _run() -> void:
	game = root.get_node("Game")

	# ---------------- Level 1 leads to the ending ----------------
	var level1_next: String = (load(LEVEL_ONE) as PackedScene).get_state().get_node_property_value(0, _prop_index(load(LEVEL_ONE), "next_scene"))
	check("Level 1's CONTINUE leads to the ending", level1_next == ENDING, level1_next)

	# ---------------- Every line, Enter to move on ----------------
	game.change_scene(ENDING)
	await wait(1.0)
	check("The ending plays", scene() == ENDING, scene())
	var lines: Array[String] = []
	var the_end := false
	var start := Time.get_ticks_msec()
	while scene() == ENDING and Time.get_ticks_msec() - start < 120000:
		var ending: Node = current_scene
		if ending._waiting:
			if ending._box.visible:
				lines.append(ending._box.line)
				shot("ending_%02d" % lines.size())
			else:
				the_end = true  # THE END waits for Enter with no dialogue box
				shot("ending_the_end")
			await wait(0.3)
			await press("ui_accept")
			await wait(0.2)
		else:
			if lines.size() == 2 and not FileAccess.file_exists(ProjectSettings.globalize_path(OUT + "ending_freed.png")):
				await wait(2.0)  # the variables flying out and the bridge coming back
				shot("ending_freed")
			await process_frame
	print("Lines: ", lines)
	await wait(1.0)
	check("Ending: all %d lines show" % LINES, lines.size() == LINES, str(lines.size()))
	check("Ending: THE END waits for Enter", the_end)
	check("The ending goes back to the main menu", scene() == MENU, scene())

	# ---------------- Esc skips ----------------
	game.change_scene(ENDING)
	await wait(2.5)
	await press("ui_cancel")
	await wait(1.2)
	check("Esc skips the ending back to the main menu", scene() == MENU, scene())

	# ---------------- CONTINUE ----------------
	var menu: Node = current_scene
	game.best_stars = {}
	check("CONTINUE: the tutorial until it has a star", menu.continue_scene() == TUTORIAL, menu.continue_scene())
	game.best_stars = {"level1": 2}
	check("CONTINUE: Level 1 once the tutorial has a star", menu.continue_scene() == LEVEL_ONE, menu.continue_scene())

	# ---------------- RESET PROGRESS ----------------
	game.unlocked_heroes = ["chelzy", "sarah", "april"]
	game.story_seen = true
	game.save_progress()
	menu._open_settings()
	await wait(0.3)
	var reset: Button = menu.reset_button
	check("Settings has RESET PROGRESS", reset != null and reset.is_visible_in_tree(), reset.text if reset else "")
	shot("ending_menu_settings")
	reset.pressed.emit()
	await wait(0.2)
	check("RESET PROGRESS asks first", reset.text == "SURE? PRESS AGAIN" and game.best_stars.size() == 1, reset.text)
	reset.pressed.emit()
	await wait(0.2)
	check("The second press resets heroes, stars and the backstory",
		game.best_stars.is_empty() and game.unlocked_heroes == ["chelzy"] and not game.story_seen, "%s %s" % [game.best_stars, game.unlocked_heroes])
	check("...deletes the save and turns CONTINUE off", not game.has_save() and menu.continue_button.disabled)

	print("\n%d checks, %d failed" % [results.size(), results.filter(func(r): return r.begins_with("FAIL")).size()])
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	quit()


## Where a property of the scene's root node is in its saved state.
func _prop_index(packed: PackedScene, prop: String) -> int:
	var state := packed.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == prop:
			return i
	return -1
