extends SceneTree
## Checks checkpoint saves (scripts/levels/level_save.gd) in Level 1 on Treasure Island:
## plays Room 0 and part of Room 1, touches a flag, then comes back the ways a player can -
## the pause menu's LAST CHECKPOINT, and CONTINUE after a restart of the game - and checks the
## level is as it was: code, bridge, coins, rescued hero, flags, hotbar, stats. Then RESTART
## LEVEL starts over, and finishing the level forgets the save.
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_checkpoint_save.gd
## Backs up and restores the real save file.

const LEVEL := "res://scenes/levels/level2/level2.tscn"
const SAVE := "user://save.cfg"
const BACKUP := "user://save_backup_for_checkpoint_test.cfg"

var game: Node
var level: Node
var p: CharacterBody2D
var term: CanvasLayer
var results: Array[String] = []


func _initialize() -> void:
	# A backup left by a run that crashed is the real save: keep it, don't overwrite it.
	if FileAccess.file_exists(SAVE) and not FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	_run.call_deferred()


func check(name: String, ok: bool, detail := "") -> void:
	var line := "%s  %s  %s" % ["PASS" if ok else "FAIL", name, detail]
	results.append(line)
	print(line)


func wait(s: float) -> void:
	await create_timer(s).timeout


func room(i: int) -> Node:
	return level.get_node("Rooms").get_child(i)


func tp(pos: Vector2) -> void:
	p.global_position = pos
	p.velocity = Vector2.ZERO
	p.get_node("Camera2D").reset_smoothing()


func code(line: String) -> void:
	term.open()
	term.input.text = line
	term.input.text_submitted.emit(line)
	await wait(0.2 * 8 + 0.3)
	term.close()


func press_accept() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up := InputEventAction.new()
	up.action = "ui_accept"
	Input.parse_input_event(up)


## Presses Enter through any Byte talks (rescue cutscene, "declare once").
func skip_talks(appear := 2.0) -> void:
	var start := Time.get_ticks_msec()
	while get_first_node_in_group("byte_talk") == null and Time.get_ticks_msec() - start < appear * 1000:
		await process_frame
	start = Time.get_ticks_msec()
	while get_first_node_in_group("byte_talk") != null and Time.get_ticks_msec() - start < 30000:
		await wait(0.4)
		await press_accept()
	await wait(0.3)


func collect_room(i: int) -> void:
	for c in get_nodes_in_group("fruit"):
		if is_instance_valid(c) and room(i).contains(c.global_position) and not c._taken:
			c._on_body_entered(p)
	await wait(0.5)


func flag_for(hero: String) -> Node:
	for f in get_nodes_in_group("checkpoint"):
		if f.unlock_hero == hero:
			return f
	return null


func bridge_in(i: int) -> Node:
	for n in level.find_children("*", "Node2D", true, false):
		if n.get("variable_name") == "bridgeLength" and n._room == room(i):
			return n
	return null


## Loads Level 1 the way the game does (play_level), and waits for a restore to finish.
func load_level(resume: bool) -> void:
	game.play_level(LEVEL, resume)
	await wait(2.5)
	level = current_scene
	p = level.player
	term = level.get_node("CodeTerminal")


func coins_left(i: int) -> int:
	var n := 0
	for c in get_nodes_in_group("fruit"):
		if is_instance_valid(c) and not c._taken and room(i).contains(c.global_position):
			n += 1
	return n


func _run() -> void:
	game = root.get_node("Game")
	game.reset_progress()
	game.unlock_hero("sarah")  # as after the tutorial

	# ---- Play: Room 0, then part of Room 1 ----
	await load_level(false)
	check("fresh level has no checkpoint save", not level.has_checkpoint_save())
	tp(room(0).global_position)
	await wait(0.4)
	await code("String hero = \"Sarah\";")
	await skip_talks()
	await collect_room(0)
	tp(flag_for("april").global_position)
	await wait(0.4)
	await skip_talks(3.0)
	check("April rescued while playing", game.is_hero_unlocked("april"))
	tp(room(1).global_position)
	await wait(0.4)
	await code("int bridgeLength = 9;")  # too long: collapses, a wrong try
	await wait(1.5)
	await code("bridgeLength = 8;")
	await code("hero = \"April\";")
	await wait(1.2)
	var tries_before: int = room(1).wrong_tries
	var mistakes_before: int = game.mistakes
	var room0_coins_total: int = room(0).fruit_total
	check("bridge built while playing", bridge_in(1)._blocks.size() == 8, str(bridge_in(1)._blocks.size()))
	var kervin_flag := flag_for("kervin")
	tp(kervin_flag.global_position)  # Room 1's flag, coins not all collected: just a checkpoint
	await wait(0.5)
	var save: Dictionary = game.checkpoint_for("level2")
	check("touching a flag saves", not save.is_empty())
	check("save names that flag", save.get("checkpoint", "") == String(level.get_path_to(kervin_flag)), save.get("checkpoint", ""))
	check("save is in the save file", ConfigFile.new().load(SAVE) == OK and _file_has_checkpoint())
	check("pause menu offers LAST CHECKPOINT", level.has_checkpoint_save())
	check("CONTINUE goes to the saved level", root.get_node_or_null("MainMenu") == null and _continue_scene() == LEVEL)

	# ---- Come back: LAST CHECKPOINT ----
	tp(room(2).global_position)  # wander off, then go back
	await wait(0.3)
	level.back_to_checkpoint()
	await wait(2.6)
	level = current_scene
	p = level.player
	term = level.get_node("CodeTerminal")
	_check_restored("checkpoint", flag_for("kervin"), tries_before, mistakes_before, room0_coins_total)

	# ---- Come back: CONTINUE after quitting the game (save file read again) ----
	game.checkpoint_save = {}
	game.load_progress()
	check("save survives a restart of the game", not game.checkpoint_for("level2").is_empty())
	await load_level(true)
	_check_restored("continue", flag_for("kervin"), tries_before, mistakes_before, room0_coins_total)

	# ---- A new checkpoint after coming back still saves the old code too ----
	tp(room(2).global_position)
	await wait(0.4)
	await code("double jumpPower = 1.5;")
	tp(flag_for("psalm").global_position)
	await wait(0.5)
	var names: Array = game.checkpoint_save.get("code", []).map(func(l): return l["name"])
	check("next save keeps earlier code", "bridgeLength" in names and "hero" in names and "jumpPower" in names, str(names))

	# ---- RESTART LEVEL: from the start, save gone ----
	level.restart_level()
	await wait(2.0)
	level = current_scene
	p = level.player
	term = level.get_node("CodeTerminal")
	check("restart level forgets the save", game.checkpoint_for("level2").is_empty())
	check("restart level has no code", term.values.is_empty(), str(term.values))
	check("restart level: Room 0 coins back", coins_left(0) == room(0).fruit_total)

	# ---- Finishing the level forgets the save ----
	game.checkpoint_save = {"level_id": "level2", "scene": LEVEL}
	game.start_level("level2")
	game.finish_level()
	check("finishing the level forgets the save", game.checkpoint_for("level2").is_empty())

	# ---- A save from before the level was rebuilt starts fresh ----
	game.checkpoint_save = {"level_id": "level2", "scene": LEVEL, "checkpoint": "Checkpoints/NoSuchFlag"}
	await load_level(true)
	check("stale save: level starts fresh", term.values.is_empty() and coins_left(0) == room(0).fruit_total)
	check("stale save: save dropped", game.checkpoint_for("level2").is_empty())

	_finish()


func _check_restored(how: String, flag: Node, tries: int, mistakes: int, room0_total: int) -> void:
	check("%s: values back" % how, term.values.get("hero") == "April" and term.values.get("bridgeLength") == "8", str(term.values))
	check("%s: bridge rebuilt to 8" % how, bridge_in(1) != null and bridge_in(1)._blocks.size() == 8, str(bridge_in(1)._blocks.size() if bridge_in(1) else -1))
	check("%s: hero is April" % how, p.hero_id == "april", p.hero_id)
	check("%s: April still rescued" % how, game.is_hero_unlocked("april") and flag_for("april").is_rescued)
	check("%s: Room 0 coins stay taken" % how, coins_left(0) == 0 and room(0).fruit_collected == room0_total)
	check("%s: flag raised" % how, flag.activated)
	check("%s: at the flag" % how, p.global_position.distance_to(flag.respawn_position()) < 40.0, str(p.global_position))
	check("%s: Room 1 wrong tries kept" % how, room(1).wrong_tries == tries, "%d vs %d" % [room(1).wrong_tries, tries])
	check("%s: mistakes kept" % how, game.mistakes == mistakes, "%d vs %d" % [game.mistakes, mistakes])
	check("%s: dictionary in hotbar" % how, "manual_dictionary" in p.inventory)
	check("%s: replay said nothing" % how, not term.log_label.get_parsed_text().contains("too long"))
	check("%s: sounds back on" % how, not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))


func _file_has_checkpoint() -> bool:
	var cfg := ConfigFile.new()
	cfg.load(SAVE)
	return (cfg.get_value("progress", "checkpoint", {}) as Dictionary).get("level_id", "") == "level2"


func _continue_scene() -> String:
	var menu = load("res://scripts/ui/main_menu.gd").new()
	var scene: String = menu.continue_scene()
	menu.free()
	return scene


func _finish() -> void:
	var fails := results.filter(func(r): return r.begins_with("FAIL")).size()
	print("\n%d checks, %d failed" % [results.size(), fails])
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	quit(1 if fails > 0 else 0)
