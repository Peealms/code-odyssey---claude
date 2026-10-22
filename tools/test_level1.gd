extends SceneTree
## Plays every room of Level 1: checks the wrong way fails and the intended way works.
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_level1.gd
## Prints PASS/FAIL per check. Screenshots go to the user data folder (test_screenshots/).
## Each room starts from a fixed spot so one failure doesn't break the next room.
## Backs up and restores the real save file.

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


func tp(x: float, y: float) -> void:
	p.global_position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	p.get_node("Camera2D").reset_smoothing()


func release_all() -> void:
	for a in ["move_left", "move_right", "jump", "dash", "attack"]:
		Input.action_release(a)


## A full jump (held long enough not to be cut short).
func jump(hold := 0.3) -> void:
	Input.action_press("jump")
	await wait(hold)
	Input.action_release("jump")


func double_jump() -> void:
	await jump(0.28)
	await wait(0.04)
	await jump(0.3)


func dash() -> void:
	Input.action_press("dash")
	await wait(0.05)
	Input.action_release("dash")


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


func ensure_hero(id: String) -> void:
	if not id in game.unlocked_heroes:
		game.unlocked_heroes.append(id)


func shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_texture().get_image().save_png(OUT + "bot_" + name + ".png")


func _process(delta: float) -> bool:
	# Wall-jump bot: press toward a wall, jump off it, then press toward the other wall.
	if wall_bot and p:
		wall_cooldown -= delta
		if p.global_position.y < exit_y:
			Input.action_release("move_left")
			Input.action_press("move_right")
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
	check("starts with Ninja Frog only", game.unlocked_heroes == ["ninja_frog"] and p.hero_id == "ninja_frog", str(game.unlocked_heroes))

	# ---------------- Room 0 ----------------
	tp(200, 288)
	Input.action_press("move_right")
	await wait(1.2)
	release_all()
	check("R0 gate blocks the way", p.global_position.x < 260, "x=%.0f" % p.global_position.x)
	await code('System.out.println("Hello Byte");')
	await wait(0.6)
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	check("R0 gate opens with println", p.global_position.x > 300, "x=%.0f" % p.global_position.x)
	tp(436, 288)
	await wait(0.3)
	await jump()
	await wait(0.6)
	check("R0 a normal jump can't reach the plateau", p.global_position.y > 200, "y=%.0f" % p.global_position.y)
	tp(436, 288)
	await wait(0.3)
	p.restore_vitals()
	wall_dir = 1
	exit_y = 132.0
	wall_bot = true
	await wait(6.0)
	wall_bot = false
	release_all()
	check("R0 Ninja Frog wall-jumps up the shaft", p.global_position.y < 150 and p.global_position.x > 448, "pos=%s" % p.global_position)
	tp(560, 128)
	Input.action_press("move_right")
	await wait(0.8)
	release_all()
	check("R0 flag rescues Pink Man", "pink_man" in game.unlocked_heroes, str(game.unlocked_heroes))
	shot("r0_done")

	# ---------------- Room 1 ----------------
	ensure_hero("pink_man")
	tp(760, 128)
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(826)
	await jump()
	await wait(2.5)
	release_all()
	check("R1 Ninja Frog can't jump the gap", not (p.global_position.x > 960 and p.global_position.y < 150), "pos=%s" % p.global_position)
	await code('String hero = "PinkMan";')
	check("R1 String hero = \"PinkMan\" switches hero", p.hero_id == "pink_man", last_byte())
	tp(760, 128)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(826)
	Input.action_press("jump")
	await wait(0.22)
	await dash()
	await wait(0.2)
	Input.action_release("jump")
	await wait(1.0)
	release_all()
	check("R1 Pink Man dash-jumps the gap", p.global_position.x > 960 and p.global_position.y < 150, "pos=%s" % p.global_position)
	tp(1224, 128)
	await wait(0.5)
	check("R1 flag rescues Mask Dude", "mask_dude" in game.unlocked_heroes, str(game.unlocked_heroes))

	# ---------------- Room 2 ----------------
	ensure_hero("mask_dude")
	tp(1400, 288)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(1426)
	Input.action_press("jump")
	await wait(0.1)
	await dash()
	await wait(1.5)
	release_all()
	check("R2 Pink Man can't dash over the pit (low ceiling)", p.global_position.x < 1600, "x=%.0f" % p.global_position.x)
	await code("int bridgeLength = 11;")
	await wait(1.5)
	tp(1400, 288)
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(1620)
	release_all()
	await wait(0.3)
	check("R2 walks across the 11-block bridge", p.global_position.x > 1610 and p.global_position.y < 300, "pos=%s" % p.global_position)
	shot("r2_bridge")
	# Can Ninja Frog cheat the step by wall-jumping up its single wall again and again?
	await code('hero = "NinjaFrog";')
	tp(1650, 288)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	for k in 12:
		await jump(0.25)
		await wait(0.3)
	release_all()
	await wait(0.5)
	check("R2 Ninja Frog can't wall-climb the step", not (p.global_position.x > 1696 and p.global_position.y < 230), "pos=%s stamina=%.0f" % [p.global_position, p.stamina])
	await code('hero = "PinkMan";')
	tp(1650, 288)
	await wait(0.3)
	Input.action_press("move_right")
	await jump()
	await wait(0.6)
	release_all()
	check("R2 Pink Man's jump can't reach the step", p.global_position.y > 250, "pos=%s" % p.global_position)
	await code('String hero = "MaskDude";')
	check("R2 redeclaring hero is refused", p.hero_id == "pink_man" and "already exists" in last_byte(), last_byte())
	await code('hero = "MaskDude";')
	check("R2 hero = \"MaskDude\" switches hero", p.hero_id == "mask_dude", last_byte())
	tp(1650, 288)
	p.restore_vitals()
	await wait(0.3)
	await jump(0.28)
	await wait(0.04)
	Input.action_press("jump")
	await wait(0.15)
	Input.action_press("move_right")
	await wait(0.15)
	Input.action_release("jump")
	await wait(0.5)
	release_all()
	check("R2 Mask Dude double-jumps onto the step", p.global_position.y < 230, "pos=%s" % p.global_position)
	tp(1860, 208)
	await wait(0.5)
	check("R2 flag rescues Virtual Guy", "virtual_guy" in game.unlocked_heroes, str(game.unlocked_heroes))

	# ---------------- Room 3 ----------------
	ensure_hero("virtual_guy")
	await code('hero = "NinjaFrog";')
	tp(1990, 208)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await wait(3.6)
	release_all()
	check("R3 walking over the falling floor fails", p.global_position.x < 2370, "x=%.0f" % p.global_position.x)
	await code('hero = "VirtualGuy";')
	tp(1990, 208)
	p.restore_vitals()
	await wait(1.0)
	Input.action_press("dash")
	Input.action_press("move_right")
	await wait(2.4)
	release_all()
	check("R3 Virtual Guy sprints across", p.global_position.x > 2370 and p.global_position.y < 230, "pos=%s" % p.global_position)
	await code('hero = "MaskDude";')
	tp(2500, 208)
	p.restore_vitals()
	await wait(0.4)
	Input.action_press("move_right")
	await double_jump()
	await wait(0.5)
	release_all()
	check("R3 double jump alone can't reach the ledge", p.global_position.y > 150, "pos=%s" % p.global_position)
	await code("double jumpPower = 1.5;")
	tp(2496, 208)
	p.restore_vitals()
	await wait(0.4)
	await jump(0.3)
	await wait(0.04)
	Input.action_press("jump")
	await wait(0.2)
	Input.action_press("move_right")
	await wait(0.2)
	Input.action_release("jump")
	await wait(0.6)
	release_all()
	check("R3 jumpPower 1.5 + double jump reaches the ledge", p.global_position.y < 115, "pos=%s" % p.global_position)

	# ---------------- Room 4 ----------------
	await code('hero = "NinjaFrog";')
	await code("jumpPower = 1.0;")
	tp(2896, 288)
	p.restore_vitals()
	await wait(1.0)
	check("R4 fan is off: nothing happens", p.global_position.y > 280, "y=%.0f" % p.global_position.y)
	await code("boolean fanOn = true;")
	tp(2896, 288)
	await wait(1.6)
	check("R4 fan lifts the player above the ledge", p.global_position.y < 72, "y=%.0f" % p.global_position.y)
	shot("r4_fan")
	Input.action_press("move_right")
	await wait(1.5)
	release_all()
	await wait(0.5)
	check("R4 steps off the fan onto the ledge", p.global_position.y < 80 and p.global_position.x > 2928, "pos=%s" % p.global_position)

	# ---------------- Room 5 ----------------
	tp(3400, 64)
	await wait(0.4)
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	await wait(1.0)
	check("R5 no path chosen: you fall", p.global_position.x < 3420 or p.global_position.y > 200, "pos=%s" % p.global_position)
	await code("char path = 'B';")
	await code('hero = "PinkMan";')
	tp(3400, 64)
	p.restore_vitals()
	await wait(0.4)
	Input.action_press("move_right")
	await until_x(3728, 6.0)
	Input.action_press("jump")
	await wait(0.22)
	await dash()
	await wait(0.2)
	Input.action_release("jump")
	await wait(1.0)
	release_all()
	shot("r5_paths")
	check("R5 path B + dash reaches the exit", p.global_position.x > 3872 and p.global_position.y < 115, "pos=%s" % p.global_position)

	# ---------------- Room 6 ----------------
	await code('hero = "NinjaFrog";')
	await code("jumpPower = 1.5;")
	tp(4150, 288)
	p.restore_vitals()
	await wait(0.3)
	await jump()
	await wait(0.6)
	check("R6 jumpPower 1.5 hits the ceiling spikes", p.health < 100, "hp=%.0f" % p.health)
	await code("jumpPower = 1.0;")
	tp(4150, 288)
	p.restore_vitals()
	await wait(0.3)
	await jump()
	await wait(0.6)
	check("R6 jumpPower 1.0 is safe", p.health == 100, "hp=%.0f" % p.health)
	tp(4150, 288)
	p.restore_vitals()
	await wait(1.2)
	Input.action_press("move_right")
	for x in [4184, 4296, 4408, 4504]:
		await until_x(x)
		await jump()
	await wait(1.0)
	release_all()
	check("R6 runs the tunnel without getting hurt", p.health == 100, "hp=%.0f x=%.0f" % [p.health, p.global_position.x])
	Input.action_press("move_right")
	await wait(2.5)
	release_all()
	await wait(2.5)
	var screen := level.get_node_or_null("LevelComplete")
	check("Level complete screen", screen != null and paused, "stars=%d mistakes=%d" % [game.stars_earned(), game.mistakes])
	shot("complete")

	print("\n%d / %d checks passed" % [results.filter(func(r): return r.begins_with("PASS")).size(), results.size()])
	paused = false
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	quit()
