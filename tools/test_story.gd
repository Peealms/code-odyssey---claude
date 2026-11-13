extends SceneTree
## Plays the backstory (scenes/ui/story_intro.tscn) and checks the ways in and out of it:
##  - the level select plays it before the tutorial the first time, and goes straight to the
##    tutorial once it's been seen
##  - every line shows, Enter moves on, and it ends in the tutorial with story_seen saved
##  - STORY on the main menu plays it again, and Esc skips back to the main menu
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_story.gd
## Prints PASS/FAIL per check. Screenshots of every line go to the user data folder
## (test_screenshots/story_*.png). Backs up and restores the real save file.

const OUT := "user://test_screenshots/"
const SAVE := "user://save.cfg"
const BACKUP := "user://save_backup_for_test.cfg"
const STORY := "res://scenes/ui/story_intro.tscn"
const TUTORIAL := "res://scenes/levels/level1/level1.tscn"
const LEVEL_SELECT := "res://scenes/ui/level_select.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
const LINES := 10  ## Lines in the story (narrator, Byte and the captain).
## Extra screenshots of the action after some lines: line number -> seconds after Enter.
const AFTER := {2: 0.5, 5: 1.1, 8: 0.3}

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
	game.story_seen = false

	# ---------------- The first time: level select -> story ----------------
	var select: Node = load(LEVEL_SELECT).instantiate()
	root.add_child(select)
	current_scene = select
	await wait(0.6)
	select._target = 0
	select._play_selected()
	await wait(1.0)
	check("First tutorial start plays the story", scene() == STORY, scene())

	# ---------------- Every line, Enter to move on ----------------
	var lines: Array[String] = []
	var start := Time.get_ticks_msec()
	while scene() == STORY and Time.get_ticks_msec() - start < 120000:
		var story: Node = current_scene
		if story._waiting:
			lines.append(story._box.line)
			shot("story_%02d" % lines.size())
			await wait(0.3)
			await press("ui_accept")
			if AFTER.has(lines.size()):
				await wait(AFTER[lines.size()])
				shot("story_%02d_after" % lines.size())
			await wait(0.2)
		else:
			await process_frame
	print("Lines: ", lines)
	await wait(0.5)  # Godot swaps the scene in over a frame
	check("Story: all %d lines show" % LINES, lines.size() == LINES, str(lines.size()))
	check("Story ends in the tutorial", scene() == TUTORIAL, scene())
	var cfg := ConfigFile.new()
	cfg.load(SAVE)
	check("Story is remembered and saved", game.story_seen and cfg.get_value("progress", "story_seen", false) == true)
	await wait(1.5)
	shot("story_then_tutorial")

	# ---------------- Seen: level select -> tutorial ----------------
	game.change_scene(LEVEL_SELECT)
	await wait(1.0)
	current_scene._target = 0
	current_scene._play_selected()
	await wait(1.0)
	check("Once seen, the tutorial starts straight away", scene() == TUTORIAL, scene())

	# ---------------- Main menu: STORY, then Esc ----------------
	game.change_scene(MENU)
	await wait(1.0)
	shot("story_menu")
	var button: Button = current_scene.get_node_or_null("MenuButtons/StoryButton")
	check("Main menu has a STORY button", button != null and button.visible)
	button.pressed.emit()
	await wait(0.7)
	check("STORY plays the story", scene() == STORY, scene())
	await press("ui_cancel")
	await wait(0.2)
	check("Esc does nothing before the first shot fades in", scene() == STORY, scene())
	await wait(1.5)
	await press("ui_cancel")
	await wait(1.0)
	check("Esc skips back to the main menu", scene() == MENU, scene())

	print("\n%d checks, %d failed" % [results.size(), results.filter(func(r): return r.begins_with("FAIL")).size()])
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	quit()
