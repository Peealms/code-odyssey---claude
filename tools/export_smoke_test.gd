extends Node
## Smoke test for an EXPORTED build. Game adds this node only in the "Windows (smoke test)"
## export (feature "smoke_test"); the real "Windows" export leaves tools/ out, so players never
## have it. It loads every screen and level from the exported files, types code into Level 1
## and goes back to a checkpoint, prints PASS/FAIL lines and quits (exit code 1 on a failure).
## Export and run:
##   godot --headless --path . --export-release "Windows (smoke test)" build/smoke/CodeOdysseySmoke.exe
##   build/smoke/CodeOdysseySmoke.exe
## Backs up and restores the real save file.

const SCENES := {
	"main menu": "res://scenes/ui/main_menu.tscn",
	"level select": "res://scenes/ui/level_select.tscn",
	"backstory": "res://scenes/ui/story_intro.tscn",
	"tutorial": "res://scenes/levels/level1/level1.tscn",
	"Level 1": "res://scenes/levels/level2/level2.tscn",
	"ending": "res://scenes/ui/story_ending.tscn",
}
const SAVE := "user://save.cfg"
const BACKUP := "user://save_backup_for_smoke_test.cfg"

var _fails := 0


func _ready() -> void:
	if FileAccess.file_exists(SAVE) and not FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	_run.call_deferred()


func check(name: String, ok: bool, detail := "") -> void:
	if not ok:
		_fails += 1
	print("%s  %s  %s" % ["PASS" if ok else "FAIL", name, detail])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _run() -> void:
	check("running an exported build", not OS.has_feature("editor"))
	check("immunity mode left out", not ResourceLoader.exists("res://scripts/dev/immunity.gd") and get_parent().get_node_or_null("Immunity") == null)
	check("saves go to the user folder", ProjectSettings.globalize_path("user://").contains("Code Odyssey"), ProjectSettings.globalize_path("user://"))

	var game := get_parent()
	for title in SCENES:
		game.change_scene(SCENES[title])
		await _wait(1.5)
		var scene := get_tree().current_scene
		check("%s loads" % title, scene != null and scene.scene_file_path == SCENES[title], str(scene.scene_file_path if scene else "none"))

	# Level 1: type a line, touch a flag, come back to it.
	game.reset_progress()
	game.unlock_hero("sarah")
	game.play_level(SCENES["Level 1"], false)
	await _wait(2.0)
	var level: Node = get_tree().current_scene
	var term: Node = level.get_node("CodeTerminal")
	var player: Node2D = level.player
	player.global_position = level.get_node("Rooms").get_child(0).global_position
	await _wait(0.4)
	term.open()
	term.input.text_submitted.emit("String hero = \"Sarah\";")
	await _wait(2.0)
	term.close()
	check("Level 1: code runs", term.values.get("hero") == "Sarah" and player.hero_id == "sarah", str(term.values))
	for talk in get_tree().get_nodes_in_group("byte_talk"):
		talk.queue_free()
	get_tree().paused = false
	var flag: Node2D = null
	for f in get_tree().get_nodes_in_group("checkpoint"):
		if f.unlock_hero == "kervin":
			flag = f
	player.global_position = flag.global_position
	await _wait(0.6)
	check("Level 1: checkpoint saved", level.has_checkpoint_save())
	level.back_to_checkpoint()
	await _wait(3.0)
	level = get_tree().current_scene
	check("Level 1: back at the checkpoint", level.level_save != null and level.get_node("CodeTerminal").values.get("hero") == "Sarah")

	print("\nsmoke test: %d failed" % _fails)
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	get_tree().quit(1 if _fails > 0 else 0)
