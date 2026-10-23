extends SceneTree
## Plays every room of Level 1: checks the wrong way fails and the intended way works.
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_level1.gd
## Prints PASS/FAIL per check. Screenshots go to the user data folder (test_screenshots/).
## Each room starts from a fixed spot so one failure doesn't break the next room.
## Positions are in pixels; they follow the maps in tools/build_level1.gd (tile = 16 px,
## a player standing on a floor whose top is at y has position.y = y - 16).
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
var exit_dir := 1
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


func dash() -> void:
	Input.action_press("dash")
	await wait(0.05)
	Input.action_release("dash")


## Jump, then double jump at the top and steer toward `dir` (Mask Dude). Each jump is held
## until its peak (the first one longer when jumpPower is high; the double jump never uses
## jumpPower), so letting go doesn't cut it short.
func double_jump_to(dir: String) -> void:
	await jump(0.28 * sqrt(p.jump_power))
	await wait(0.04)
	Input.action_press("jump")
	await wait(0.08)
	Input.action_press(dir)
	await wait(0.22)
	Input.action_release("jump")


func until_x(x: float, timeout := 4.0) -> void:
	var start := Time.get_ticks_msec()
	while p.global_position.x < x and Time.get_ticks_msec() - start < timeout * 1000:
		await process_frame


func until_x_left(x: float, timeout := 4.0) -> void:
	var start := Time.get_ticks_msec()
	while p.global_position.x > x and Time.get_ticks_msec() - start < timeout * 1000:
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


## Presses accept until the rescue cutscene is gone. Returns true if one was shown.
func dismiss_cutscene() -> bool:
	var cut := level.get_node_or_null("HeroCutscene")
	if cut == null:
		return false
	var start := Time.get_ticks_msec()
	while is_instance_valid(cut) and Time.get_ticks_msec() - start < 20000:
		await wait(0.8)
		var ev := InputEventAction.new()
		ev.action = "ui_accept"
		ev.pressed = true
		Input.parse_input_event(ev)
		await process_frame
		var up := InputEventAction.new()
		up.action = "ui_accept"
		Input.parse_input_event(up)
	await wait(0.3)
	return true


## True if room i's exit door crates still block the way.
func door_closed(i: int) -> bool:
	for n in level.get_node("Traps").get_children():
		if n.get_script() and n.get_script().resource_path.ends_with("fruit_door.gd") and n.room == room(i):
			return not n.is_open
	return false


## The gadget (bridge, fan, ...) whose script ends with `script_end`, nearest to `pos`.
func gadget_near(script_end: String, pos: Vector2) -> Node:
	var best: Node = null
	for parent in ["Gadgets", "Traps"]:
		for n in level.get_node(parent).get_children():
			if n.get_script() and n.get_script().resource_path.ends_with(script_end):
				if best == null or n.global_position.distance_to(pos) < best.global_position.distance_to(pos):
					best = n
	return best


## Waits until a Rock Head is resting at the bottom of its track, puts the player on top,
## and waits until it has carried them to the top end.
func ride_rock_head(rock: Node2D, top_y: float, timeout := 15.0) -> void:
	var bottom_y: float = rock._start.y
	var start := Time.get_ticks_msec()
	while absf(rock.position.y - bottom_y) > 1.0 and Time.get_ticks_msec() - start < timeout * 1000:
		await process_frame
	tp(rock.global_position.x, rock.global_position.y - 32)
	while rock.global_position.y > top_y + 1.0 and Time.get_ticks_msec() - start < timeout * 1000:
		await process_frame
	await wait(0.2)


## Tries to get past a hero-only obstacle the wrong way: `hero` at jumpPower 2.0 runs from
## `start` toward `dir`, and at `edge_x` (0 = straight away) jumps as high/far as it can
## (Mask Dude double jumps, Virtual Guy sprint-jumps, Pink Man dashes). With `hop_time` it
## keeps hopping every time it lands, for that long. Returns where the player ended up.
## (Sets the hero and jumpPower directly, not through the terminal.)
func cheat(hero: String, start: Vector2, dir: String, edge_x: float, hop_time := 0.0) -> Vector2:
	p.set_hero(hero)
	p.jump_power = 2.0
	tp(start.x, start.y)
	p.restore_vitals()
	await wait(0.5)
	if hero == "virtual_guy":
		Input.action_press("dash")
	Input.action_press(dir)
	if edge_x > 0.0:
		if dir == "move_right":
			await until_x(edge_x)
		else:
			await until_x_left(edge_x)
	if hop_time > 0.0:
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < hop_time * 1000:
			if p.is_on_floor():
				await jump(0.1)
				if hero == "pink_man":
					await dash()
				elif hero == "mask_dude":
					await jump(0.1)
			await process_frame
	elif hero == "pink_man":
		await dash()
	else:
		await jump(0.28 * sqrt(2.0))
		if hero == "mask_dude":
			await wait(0.04)
			await jump(0.28)
	await wait(1.5)
	release_all()
	await wait(0.6)
	return p.global_position


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
	check("starts with Ninja Frog only", game.unlocked_heroes == ["ninja_frog"] and p.hero_id == "ninja_frog", str(game.unlocked_heroes))

	# ---------------- Room 0: floor y=304, gate x=184, shaft x=496-544, plateau top y=128 ----------------
	tp(120, 288)
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	check("R0 gate blocks the way", p.global_position.x < 180, "x=%.0f" % p.global_position.x)
	await code('System.out.println("Hello Byte");')
	await wait(0.6)
	Input.action_press("move_right")
	await wait(0.6)
	release_all()
	check("R0 gate opens with println", p.global_position.x > 200, "x=%.0f" % p.global_position.x)
	tp(520, 288)
	await wait(0.3)
	await jump()
	await wait(0.6)
	check("R0 a normal jump can't reach the plateau", p.global_position.y > 200, "y=%.0f" % p.global_position.y)
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
	check("R0 Ninja Frog wall-jumps up the shaft", p.global_position.y < 116 and p.global_position.x > 548, "pos=%s" % p.global_position)
	await touch_flag(584, 112)
	check("R0 flag won't rescue Pink Man until all fruit", not "pink_man" in game.unlocked_heroes and not paused, "fruit %d/%d" % [room(0).fruit_collected, room(0).fruit_total])
	await collect_room(0)
	await touch_flag(584, 112)
	var shown := paused and level.get_node_or_null("HeroCutscene") != null
	await wait(4.5)
	shot("r0_cutscene")
	shown = await dismiss_cutscene() and shown
	check("R0 all fruit + flag: cutscene, then Pink Man joins", shown and "pink_man" in game.unlocked_heroes and not paused, str(game.unlocked_heroes))

	# ---------------- Room 1: top floor y=128, crawlspace gap x=896-976 ----------------
	ensure_hero("pink_man")
	tp(720, 112)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(886)
	await jump()
	await wait(2.0)
	release_all()
	check("R1 Ninja Frog can't cross the gap", not (p.global_position.x > 980 and p.global_position.y < 130), "pos=%s" % p.global_position)
	await code('String hero = "PinkMan";')
	check("R1 String hero = \"PinkMan\" switches hero", p.hero_id == "pink_man", last_byte())
	tp(720, 112)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(886)
	await dash()
	await wait(1.0)
	release_all()
	check("R1 Pink Man dashes over the gap", p.global_position.x > 980 and p.global_position.y < 130, "pos=%s" % p.global_position)
	var won := await cheat("mask_dude", Vector2(720, 112), "move_right", 886)
	check("R1 cheat: Mask Dude at jumpPower 2.0 can't cross", not (won.x > 980 and won.y < 130), "pos=%s" % won)
	won = await cheat("virtual_guy", Vector2(720, 112), "move_right", 886)
	check("R1 cheat: Virtual Guy at jumpPower 2.0 can't cross", not (won.x > 980 and won.y < 130), "pos=%s" % won)
	p.set_hero("pink_man")
	p.jump_power = 1.0
	await collect_room(1)
	await touch_flag(1224, 496)
	var shown1 := await dismiss_cutscene()
	check("R1 all fruit + flag rescues Mask Dude", shown1 and "mask_dude" in game.unlocked_heroes, str(game.unlocked_heroes))

	# ---------------- Room 2: floor y=512, pit x=1488-1664, step top y=432 at x>=1760 ----------------
	ensure_hero("mask_dude")
	tp(1400, 496)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(1476)
	Input.action_press("jump")
	await wait(0.1)
	await dash()
	await wait(1.5)
	release_all()
	check("R2 Pink Man can't dash over the pit (low ceiling)", p.global_position.x < 1660, "x=%.0f" % p.global_position.x)
	tp(1400, 496)  # the bridge only listens to code typed in its own room
	await code("int bridgeLength = 11;")
	await wait(1.5)
	tp(1400, 496)
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(1680)
	release_all()
	await wait(0.3)
	check("R2 walks across the 11-block bridge", p.global_position.x > 1670 and p.global_position.y < 510, "pos=%s" % p.global_position)
	shot("r2_bridge")
	await code('hero = "NinjaFrog";')
	tp(1728, 496)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	for k in 12:
		await jump(0.25)
		await wait(0.3)
	release_all()
	await wait(0.5)
	check("R2 Ninja Frog can't wall-climb the step", not (p.global_position.x > 1765 and p.global_position.y < 420), "pos=%s stamina=%.0f" % [p.global_position, p.stamina])
	await code('hero = "PinkMan";')
	tp(1728, 496)
	await wait(0.3)
	Input.action_press("move_right")
	await jump()
	await wait(0.6)
	release_all()
	check("R2 Pink Man's jump can't reach the step", p.global_position.y > 440, "pos=%s" % p.global_position)
	await code('String hero = "MaskDude";')
	check("R2 redeclaring hero is refused", p.hero_id == "pink_man" and "already exists" in last_byte(), last_byte())
	check("R2 Byte puts the fixed line in the input", term.input.text == 'hero = "MaskDude";', term.input.text)
	await code('hero = "MaskDude";')
	check("R2 hero = \"MaskDude\" switches hero", p.hero_id == "mask_dude", last_byte())
	tp(1728, 496)
	p.restore_vitals()
	await wait(0.3)
	await double_jump_to("move_right")
	await wait(0.5)
	release_all()
	check("R2 Mask Dude double-jumps onto the step", p.global_position.y < 420, "pos=%s" % p.global_position)
	await collect_room(2)
	await touch_flag(1896, 416)
	var shown2 := await dismiss_cutscene()
	check("R2 all fruit + flag rescues Virtual Guy", shown2 and "virtual_guy" in game.unlocked_heroes, str(game.unlocked_heroes))

	# ---------------- Room 3: floor y=432, falling floor x=2128-2448 (crawlspace), ledge top y=320 at x>=2528 ----------------
	ensure_hero("virtual_guy")
	check("R3 exit door is shut while fruit is missing", door_closed(3), "fruit %d/%d" % [room(3).fruit_collected, room(3).fruit_total])
	await collect_room(3)
	await wait(0.5)
	check("R3 exit door opens with all the fruit", not door_closed(3))
	await code('hero = "NinjaFrog";')
	tp(2060, 416)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await wait(3.6)
	release_all()
	check("R3 walking over the falling floor fails", p.global_position.x < 2440, "x=%.0f" % p.global_position.x)
	won = await cheat("mask_dude", Vector2(2060, 416), "move_right", 2120, 4.0)
	check("R3 cheat: Mask Dude at 2.0 can't hop the falling floor", not (won.x > 2450 and won.y < 430), "pos=%s" % won)
	won = await cheat("pink_man", Vector2(2060, 416), "move_right", 2120, 4.0)
	check("R3 cheat: Pink Man can't dash the falling floor", not (won.x > 2450 and won.y < 430), "pos=%s" % won)
	p.jump_power = 1.0
	await code('hero = "VirtualGuy";')
	tp(2060, 416)
	p.restore_vitals()
	await wait(2.5)  # let the platforms come back
	Input.action_press("dash")
	Input.action_press("move_right")
	await wait(1.8)
	release_all()
	check("R3 Virtual Guy sprints across", p.global_position.x > 2450 and p.global_position.y < 430, "pos=%s" % p.global_position)
	await code('hero = "MaskDude";')
	tp(2488, 416)
	p.restore_vitals()
	await wait(0.4)
	await double_jump_to("move_right")
	await wait(0.5)
	release_all()
	await wait(1.0)
	check("R3 double jump alone can't reach the ledge", not (p.global_position.x > 2530 and p.global_position.y < 316), "pos=%s" % p.global_position)
	for h in ["virtual_guy", "pink_man"]:
		won = await cheat(h, Vector2(2488, 416), "move_right", 0.0)
		check("R3 cheat: %s at jumpPower 2.0 can't reach the ledge" % h, not (won.x > 2530 and won.y < 316), "pos=%s" % won)
	p.set_hero("mask_dude")
	p.jump_power = 1.0
	await code("double jumpPower = 2.0;")
	tp(2488, 416)
	p.restore_vitals()
	await wait(0.4)
	await double_jump_to("move_right")
	await wait(0.6)
	release_all()
	check("R3 jumpPower 2.0 + double jump reaches the ledge", p.global_position.y < 316 and p.global_position.x > 2530, "pos=%s" % p.global_position)

	# ---------------- Room 4: bottom y=832, fan x=2968, platform top y=400, top floor y=240 ----------------
	await code('hero = "NinjaFrog";')
	tp(2968, 816)
	p.restore_vitals()
	await wait(1.0)
	check("R4 fan is off: nothing happens", p.global_position.y > 806, "y=%.0f" % p.global_position.y)
	await code("boolean fanOn = true;")
	tp(2968, 816)
	await wait(3.2)
	check("R4 fan lifts the player above the platform", p.global_position.y < 376, "y=%.0f" % p.global_position.y)
	shot("r4_fan")
	Input.action_press("move_right")
	await wait(0.6)
	release_all()
	await wait(0.5)
	check("R4 steps off the fan onto the platform", p.global_position.y < 388 and p.global_position.x > 2995, "pos=%s" % p.global_position)
	await ride_rock_head(gadget_near("block_head.gd", Vector2(3136, 416)), 256.0)
	Input.action_press("move_right")
	await wait(0.8)
	release_all()
	check("R4 Rock Head elevator reaches the top floor", p.global_position.y < 228 and p.global_position.x > 3170, "pos=%s" % p.global_position)

	# ---------------- Room 5: ledge top y=240, path B to x=3792, crawlspace gap, exit at x>=3872 ----------------
	tp(3420, 224)
	await wait(0.4)
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	await wait(1.0)
	check("R5 no path chosen: you can't get across", not (p.global_position.x > 3870 and p.global_position.y < 240), "pos=%s" % p.global_position)
	await code("char path = 'A';")
	var a_on: bool = not gadget_near("path_platform.gd", Vector2(3456, 211)).shape.disabled
	check("R5 path = 'A' makes path A solid", a_on)
	await code("path = 'B';")
	for h in ["mask_dude", "virtual_guy"]:
		won = await cheat(h, Vector2(3700, 224), "move_right", 3782)
		check("R5 cheat: %s at jumpPower 2.0 can't cross the dash gap" % h, not (won.x > 3875 and won.y < 240), "pos=%s" % won)
	p.jump_power = 2.0
	await code('hero = "PinkMan";')
	tp(3420, 224)
	p.restore_vitals()
	await wait(0.4)
	Input.action_press("move_right")
	await until_x(3782, 6.0)
	await dash()
	await wait(1.0)
	release_all()
	shot("r5_paths")
	check("R5 path B + dash reaches the exit", p.global_position.x > 3875 and p.global_position.y < 240, "pos=%s" % p.global_position)

	# ---------------- Exam 1 (high wall): floor y=240, wall x>=4336, wall top y=128 ----------------
	for h in ["pink_man", "virtual_guy"]:
		won = await cheat(h, Vector2(4305, 224), "move_right", 0.0)
		check("Exam 1 cheat: %s at jumpPower 2.0 can't climb the wall" % h, not (won.x > 4340 and won.y < 120), "pos=%s" % won)
	p.set_hero("pink_man")
	p.jump_power = 2.0
	await code('hero = "MaskDude";')
	await code("jumpPower = 1.0;")
	tp(4305, 224)
	p.restore_vitals()
	await wait(0.4)
	await double_jump_to("move_right")
	await wait(0.6)
	release_all()
	await wait(0.8)
	check("Exam 1: double jump at 1.0 can't climb the wall", not (p.global_position.x > 4340 and p.global_position.y < 120), "pos=%s" % p.global_position)
	await code("double jumpPower = 2.0;")
	check("Exam 1: writing double again is refused", p.jump_power == 1.0 and "already exists" in last_byte(), last_byte())
	await code("jumpPower = 2.0;")
	tp(4305, 224)
	p.restore_vitals()
	await wait(0.4)
	await double_jump_to("move_right")
	await wait(0.8)
	release_all()
	check("Exam 1: Mask Dude at jumpPower 2.0 climbs the wall", p.global_position.x > 4340 and p.global_position.y < 120, "pos=%s" % p.global_position)

	# ---------------- Exam 2 (low tunnel): floor y=240, tunnel x=4528-4912 ----------------
	await code('hero = "NinjaFrog";')
	tp(4620, 224)
	p.restore_vitals()
	await wait(0.4)
	await jump()
	await wait(0.8)
	check("Exam 2: at 2.0 a jump hits the ceiling spikes", p.health < 100 or p.global_position.x < 4540, "hp=%.0f pos=%s" % [p.health, p.global_position])
	await code("jumpPower = 1.0;")
	tp(4620, 224)
	p.restore_vitals()
	await wait(1.2)
	await jump()
	await wait(0.8)
	check("Exam 2: at 1.0 the jump is safe", p.health == 100 and p.global_position.x > 4540, "hp=%.0f" % p.health)
	tp(4500, 224)
	p.restore_vitals()
	await wait(0.4)
	Input.action_press("move_right")
	for x in [4554, 4634, 4730, 4810]:  # just before each fire block / spike patch
		await until_x(x)
		await jump()
	await wait(0.6)
	release_all()
	check("Exam 2: runs the tunnel", p.global_position.x > 4880, "hp=%.0f x=%.0f" % [p.health, p.global_position.x])

	# ---------------- Exam 3 (long bridge, crawlspace): floor y=240, pit x=4960-5152 ----------------
	for h in ["virtual_guy", "mask_dude", "pink_man"]:
		won = await cheat(h, Vector2(4920, 224), "move_right", 4954)
		check("Exam 3 cheat: %s at jumpPower 2.0 can't cross without the bridge" % h, not (won.x > 5160 and won.y < 236), "pos=%s" % won)
	p.set_hero("ninja_frog")
	p.jump_power = 1.0
	var old_bridge := gadget_near("code_bridge.gd", Vector2(1488, 512))
	tp(4920, 224)
	await code("bridgeLength = 12;")
	await wait(1.4)
	check("Exam 3: Room 2's bridge keeps its 11 blocks", old_bridge._blocks.size() == 11, "blocks=%d" % old_bridge._blocks.size())
	tp(4920, 224)
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(5170)
	release_all()
	await wait(0.3)
	check("Exam 3: walks across the 12-block bridge", p.global_position.x > 5160 and p.global_position.y < 236, "pos=%s" % p.global_position)
	await ride_rock_head(gadget_near("block_head.gd", Vector2(5280, 224)), -80.0, 20.0)
	check("Exam 3: Rock Head elevator rises to the fan trap", p.global_position.y < -94, "pos=%s" % p.global_position)

	# ---------------- Exam 4 (fan trap): corridor floor y=-96, fans x=4992-5152 ----------------
	tp(5220, -112)
	p.restore_vitals()
	await wait(0.4)
	Input.action_press("move_left")
	await wait(2.5)
	release_all()
	await wait(0.5)
	# The spikes send you back to a checkpoint, so "through" means past the fans and still up here.
	check("Exam 4: fans on: you can't get through", not (p.global_position.x < 4980 and p.global_position.y < -90), "pos=%s hp=%.0f" % [p.global_position, p.health])
	tp(5220, -112)
	p.restore_vitals()
	await code("fanOn = false;")
	var old_fan := gadget_near("code_fan.gd", Vector2(2968, 832))
	check("Exam 4: Room 4's fan stays on", old_fan.is_on)
	await wait(0.4)
	Input.action_press("move_left")
	await wait(2.1)  # stop before the chasm (no path chosen yet)
	release_all()
	check("Exam 4: fans off: walk through", p.global_position.x < 4975 and p.global_position.y < -94, "pos=%s" % p.global_position)

	# ---------------- Exam 5 (last path): path C y=-96 x=4560-4912, block x=4544-4560, crawlspace gap to x=4464 ----------------
	await code("path = 'C';")  # typed in the fan corridor: same exam, so path C still appears
	check("Exam 5: path = 'C' from the fan corridor reaches the paths", not gadget_near("path_platform.gd", Vector2(4900, -93)).shape.disabled)
	for h in ["mask_dude", "virtual_guy"]:
		won = await cheat(h, Vector2(4600, -112), "move_left", 4554)
		check("Exam 5 cheat: %s at jumpPower 2.0 can't cross the dash gap" % h, not (won.x < 4462 and won.y < -94), "pos=%s" % won)
	p.jump_power = 1.0
	await code('hero = "PinkMan";')
	tp(4890, -112)
	p.restore_vitals()
	await wait(0.4)
	# Three Spike Heads slam down onto path C: stop before each, go when it has just gone up.
	for head_x in [4848, 4752, 4656]:
		Input.action_press("move_left")
		await until_x_left(head_x + 36, 5.0)
		release_all()
		var head: Node2D = gadget_near("block_head.gd", Vector2(head_x, -224))
		while absf(head.position.y - head._start.y) < 1.0:
			await process_frame
		while absf(head.position.y - head._start.y) > 1.0:
			await process_frame
	Input.action_press("move_left")
	await until_x_left(4554, 5.0)
	await dash()
	await wait(1.0)
	release_all()
	check("Exam 5: path C + dash reaches the last ledge", p.global_position.x < 4462 and p.global_position.y < -94, "pos=%s" % p.global_position)

	# ---------------- Exam 6 (final gate): gate x=4376, falling floor x=4176-4368 (crawlspace), shaft x=4048-4096 ----------------
	tp(4440, -112)
	await wait(0.3)
	Input.action_press("move_left")
	await wait(1.0)
	release_all()
	check("Exam 6: the gate blocks the way", p.global_position.x > 4380, "x=%.0f" % p.global_position.x)
	await code('System.out.println("Hello");')
	await wait(0.5)
	check("Exam 6: the gate needs the exact text", gadget_near("byte_gate.gd", Vector2(4376, -96)).is_open == false)
	await code('System.out.println("I can code!");')
	await wait(0.6)
	check("Exam 6: \"I can code!\" opens the gate", gadget_near("byte_gate.gd", Vector2(4376, -96)).is_open)
	tp(4420, -112)
	p.restore_vitals()
	await wait(0.4)
	Input.action_press("move_left")
	await wait(3.0)
	release_all()
	check("Exam 6: walking over the falling floor fails", p.global_position.x > 4180, "x=%.0f" % p.global_position.x)
	won = await cheat("mask_dude", Vector2(4420, -112), "move_left", 4374, 4.0)
	check("Exam 6 cheat: Mask Dude at 2.0 can't hop the falling floor", not (won.x < 4170 and won.y < -94 and won.y > -130), "pos=%s" % won)
	p.jump_power = 1.0
	await code('hero = "VirtualGuy";')
	tp(4420, -112)
	p.restore_vitals()
	await wait(2.5)
	Input.action_press("dash")
	Input.action_press("move_left")
	await wait(1.3)
	release_all()
	check("Exam 6: Virtual Guy sprints across", p.global_position.x < 4170 and p.global_position.y < -94, "pos=%s" % p.global_position)
	won = await cheat("mask_dude", Vector2(4072, -112), "move_left", 0.0)
	check("Exam 6 cheat: Mask Dude at 2.0 can't jump up the shaft", won.y > -300, "pos=%s" % won)
	p.jump_power = 1.0
	await code('hero = "NinjaFrog";')
	tp(4072, -112)
	p.restore_vitals()
	await wait(0.3)
	wall_dir = -1
	exit_y = -340.0
	exit_dir = 1
	wall_bot = true
	await wait(7.0)
	wall_bot = false
	release_all()
	check("Exam 6: Ninja Frog wall-jumps up to the goal floor", p.global_position.y < -324 and p.global_position.x > 4100, "pos=%s" % p.global_position)
	# The goal needs every fruit of the final exam.
	tp(4340, -336)
	p.restore_vitals()
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	check("Goal won't finish while exam fruit is missing", level.get_node_or_null("LevelComplete") == null and not paused, "")
	for i in range(6, 12):
		await collect_room(i)
	tp(4340, -336)
	Input.action_press("move_right")
	await wait(1.5)
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
