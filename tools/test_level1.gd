extends SceneTree
## Plays the tutorial (scenes/levels/level1/level1.tscn): Byte's talks, the gate, the manual,
## the wall-jump shaft, Sarah's rescue and the trophy. Checks the wrong way fails and the
## intended way works.
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_level1.gd
## Prints PASS/FAIL per check. Screenshots go to the user data folder (test_screenshots/).
## Positions are in pixels; they follow the map in tools/build_level1.gd (tile = 16 px,
## a player standing on a floor whose top is at y has position.y = y - 16).
## Backs up and restores the real save file.
## (The checks for the old Level 1 Rooms 1-6 are in git history, commit 80011e1; they move to
## the final level's test.)

const OUT := "user://test_screenshots/"
const SAVE := "user://save.cfg"
const BACKUP := "user://save_backup_for_test.cfg"

var level: Node
var game: Node
var p: CharacterBody2D
var term: CanvasLayer
var wall_bot := false
var wall_dir := 1
var wall_cooldown := 0.0
var exit_y := 132.0
var exit_dir := 1
var results: Array[String] = []
var talks_seen: Array[String] = []  ## Script file of every Byte talk await_talk() closed.


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


func tp(x: float, y: float) -> void:
	p.global_position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	p.get_node("Camera2D").reset_smoothing()


func release_all() -> void:
	for a in ["move_left", "move_right", "move_down", "jump", "dash", "attack"]:
		Input.action_release(a)


## A full jump (held long enough not to be cut short).
func jump(hold := 0.3) -> void:
	Input.action_press("jump")
	await wait(hold)
	Input.action_release("jump")


func until_x(x: float, timeout := 4.0) -> void:
	var start := Time.get_ticks_msec()
	while p.global_position.x < x and Time.get_ticks_msec() - start < timeout * 1000:
		await process_frame


func code(line: String) -> void:
	term.open()
	term.input.text = line
	term.input.text_submitted.emit(line)
	await wait(0.2 * 8 + 0.3)
	term.close()


func last_byte() -> String:
	var text: String = term.log_label.get_parsed_text()
	var lines := text.strip_edges().split("\n")
	for i in range(lines.size() - 1, -1, -1):
		if lines[i].begins_with("BYTE:"):
			return lines[i]
	return ""


func room(i: int) -> Node:
	return level.get_node("Rooms").get_child(i)


## Collects every fruit left in room i (the bot tests puzzles, not fruit hunting).
func collect_room(i: int) -> void:
	var r := room(i)
	for f in get_nodes_in_group("fruit"):
		if is_instance_valid(f) and r.contains(f.global_position) and not f._taken:
			f._on_body_entered(p)
	await wait(0.3)


## Walks into a flag from the left (re-touches it if it was already reached).
## `y` is the player's position.y when standing at the flag.
func touch_flag(x: float, y: float) -> void:
	tp(x - 40, y)
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(x + 2, 2.0)
	release_all()
	await wait(0.4)


func press_accept() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up := InputEventAction.new()
	up.action = "ui_accept"
	Input.parse_input_event(up)


## Waits up to `appear` seconds for a Byte talk (a tutorial talk or the rescue cutscene), then
## presses Enter until every talk is over - one can follow straight after another. Returns true
## if one was shown.
## With `shot_name`, takes a screenshot of the first line once it's typed out.
func await_talk(appear := 3.0, shot_name := "") -> bool:
	var start := Time.get_ticks_msec()
	while get_first_node_in_group("byte_talk") == null and Time.get_ticks_msec() - start < appear * 1000:
		await process_frame
	if get_first_node_in_group("byte_talk") == null:
		return false
	if shot_name != "":
		await wait(2.5)
		shot(shot_name)
	var quiet := 0.0
	start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 60000 and quiet < 0.8:
		var talk := get_first_node_in_group("byte_talk")
		if talk == null:
			quiet += 0.1
			await wait(0.1)
			continue
		quiet = 0.0
		var script_file: String = talk.get_script().resource_path.get_file()
		if talks_seen.is_empty() or talks_seen[-1] != script_file + str(talk.get_instance_id()):
			talks_seen.append(script_file + str(talk.get_instance_id()))
		await wait(0.5)
		await press_accept()
	await wait(0.3)
	return true


func shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_texture().get_image().save_png(OUT + "bot_" + name + ".png")


func _process(delta: float) -> bool:
	# Wall-jump bot: press toward a wall, jump off it, then press toward the other wall.
	# Above `exit_y` it stops and walks off in `exit_dir`.
	if wall_bot and p:
		wall_cooldown -= delta
		if p.global_position.y < exit_y:
			Input.action_release("move_left" if exit_dir > 0 else "move_right")
			Input.action_press("move_right" if exit_dir > 0 else "move_left")
			Input.action_release("jump")
			return false
		Input.action_press("move_right" if wall_dir > 0 else "move_left")
		Input.action_release("move_left" if wall_dir > 0 else "move_right")
		var on_wall := p.is_on_wall_only()
		if (on_wall or p.is_on_floor()) and wall_cooldown <= 0.0:
			Input.action_release("jump")
			Input.action_press("jump")
			wall_cooldown = 0.15
			if on_wall:
				wall_dir = -wall_dir
	return false


func _run() -> void:
	game = root.get_node("Game")
	level = load("res://scenes/levels/level1/level1.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	p = level.get_node("Player")
	term = level.get_node("CodeTerminal")
	await wait(0.5)
	check("starts with Chelzy only", game.unlocked_heroes == ["chelzy"] and p.hero_id == "chelzy", str(game.unlocked_heroes))

	# ---------------- Byte's welcome ----------------
	var shown := await await_talk(3.0, "talk_intro")
	check("Intro: Byte talks when the tutorial starts", shown, str(talks_seen))
	check("Intro: the game carries on after the talk", not paused and p.input_enabled)

	# ---------------- The gate: floor y=304, gate x=184 ----------------
	tp(120, 288)
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	check("Gate blocks the way", p.global_position.x < 180, "x=%.0f" % p.global_position.x)

	# Wrong lines: Byte explains them, then the hint and "Show answer".
	await code('System.out.printn("Hi");')
	check("1 wrong line: Byte explains wrong lines", "Wrong lines are fine" in last_byte(), last_byte())
	await code('System.out.printn("Hi");')
	await code('System.out.printn("Hi");')
	check("3 wrong lines: the hint, then Byte explains Show answer",
		"SHOW ANSWER" in last_byte() and "Hint:" in term.log_label.get_parsed_text() and room(0).wrong_tries == 3,
		"tries=%d %s" % [room(0).wrong_tries, last_byte()])
	term.open()
	check("Show answer button is there after 3 wrong lines", term.answer_button.visible)
	term.close()

	await code('System.out.println("Hello Byte");')
	shown = await await_talk(3.0, "talk_gate")
	check("Gate opens: Byte talks about the wall jump", shown)
	Input.action_press("move_right")
	await wait(0.6)
	release_all()
	check("Gate opens with println", p.global_position.x > 200, "x=%.0f" % p.global_position.x)

	# ---------------- Health potion on the corridor floor (x=424) ----------------
	var potion := level.get_node("Potions").get_child(0)
	tp(424, 288)
	p.restore_vitals()
	await wait(0.4)
	check("Potion stays put at full HP", is_instance_valid(potion) and not potion._used)
	p.health = 50.0
	await wait(0.4)
	check("Potion heals 30 HP when hurt", p.health == 80.0 and (not is_instance_valid(potion) or potion._used), "hp=%.0f" % p.health)
	p.restore_vitals()

	# ---------------- The manual: chest (x=104) -> hotbar -> book ----------------
	var chests := level.get_node("Chests")
	var chest := chests.get_child(0)
	var before := chests.get_child_count()
	var window := level.get_node("ChestWindow")
	tp(104, 288)
	await wait(0.3)
	chest._open()
	await wait(1.2)
	check("Chest opens its window with Byte's tip", window.visible and "hotbar" in window.tip.text, window.tip.text)
	shot("chest_window")
	await wait(0.6)  # the potion is still flying out
	var thrown: Node2D = chests.get_child(before) if chests.get_child_count() > before else null
	check("Opening the chest throws out a potion", thrown != null and absf(thrown.global_position.y - chest.global_position.y) < 1.0, "pos=%s" % (thrown.global_position if thrown else Vector2.ZERO))
	window._on_slot_clicked("chest", 0)
	await wait(0.2)
	check("Clicking the book moves it to the hotbar", p.inventory.has(ItemDB.manual_item("variables_101")), str(p.inventory))
	window.close()
	shown = await await_talk(3.0, "talk_manual")
	check("Book in the hotbar: Byte explains how to read it", shown)
	var reader := level.get_node("ManualReader")
	reader.open("variables_101")
	await wait(0.5)
	check("The book opens and pauses the game", reader.visible and paused)
	reader.close()
	shown = await await_talk(3.0, "talk_after_reading")
	check("After the first read: Byte explains manuals", shown)

	# ---------------- The wall-jump shaft: x=496-544, plateau top y=128 ----------------
	p.restore_vitals()
	tp(520, 288)
	await wait(0.3)
	await jump()
	await wait(0.6)
	check("A normal jump can't reach the plateau", p.global_position.y > 200, "y=%.0f" % p.global_position.y)
	tp(520, 288)
	await wait(0.3)
	p.restore_vitals()
	wall_dir = 1
	exit_y = 108.0
	exit_dir = 1
	wall_bot = true
	await wait(6.0)
	wall_bot = false
	release_all()
	check("Chelzy wall-jumps up the shaft", p.global_position.y < 116 and p.global_position.x > 548, "pos=%s" % p.global_position)

	# ---------------- Sarah's flag (x=584) and the trophy (x=680), plateau y=112 ----------------
	await touch_flag(584, 112)
	check("Flag won't rescue Sarah until all fruit", not "sarah" in game.unlocked_heroes and not paused, "fruit %d/%d" % [room(0).fruit_collected, room(0).fruit_total])
	tp(640, 112)
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	check("Trophy won't finish while fruit is missing", level.get_node_or_null("LevelComplete") == null and not paused)
	await collect_room(0)
	talks_seen.clear()
	await touch_flag(584, 112)
	shown = paused and level.get_node_or_null("HeroCutscene") != null
	await wait(4.5)
	shot("rescue_cutscene")
	shown = await await_talk(1.0) and shown
	check("All fruit + flag: cutscene, then Sarah joins", shown and "sarah" in game.unlocked_heroes and not paused, str(game.unlocked_heroes))
	check("After the rescue Byte points at the trophy",
		talks_seen.size() >= 2 and talks_seen[-1].begins_with("byte_talk.gd"), str(talks_seen))

	tp(640, 112)
	Input.action_press("move_right")
	await wait(1.5)
	release_all()
	await wait(2.5)
	var screen := level.get_node_or_null("LevelComplete")
	check("Level complete screen", screen != null and paused, "stars=%d mistakes=%d" % [game.stars_earned(), game.mistakes])
	check("It says TUTORIAL COMPLETE!", screen != null and screen._title.text == "TUTORIAL COMPLETE!", screen._title.text if screen else "")
	check("3 stars (no answer shown)", game.stars_earned() == 3, str(game.stars_earned()))
	shot("complete")

	print("\n%d / %d checks passed" % [results.filter(func(r): return r.begins_with("PASS")).size(), results.size()])
	paused = false
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	quit()
