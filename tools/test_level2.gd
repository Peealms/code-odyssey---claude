extends SceneTree
## Plays Level 1 on Treasure Island (scenes/levels/level2/level2.tscn) room by room: checks the
## wrong way fails and the intended way works, typing into Byte's terminal like a player, and
## fights Captain Clown Nose, dodging each attack with the right hero.
## Run (needs a window, not --headless):  godot --path . --script res://tools/test_level2.gd
## Prints PASS/FAIL per check. Screenshots go to the user data folder (test_screenshots/).
## Positions come from the maps in tools/build_level2.gd: at(room, column, row) is where a hero
## stands in that map cell (tile = 32 px). Backs up and restores the real save file.

const OUT := "user://test_screenshots/"
const SAVE := "user://save.cfg"
const BACKUP := "user://save_backup_for_test.cfg"
const T := 32
## The captain's states (captain.gd's enum S).
const WAIT := 0
const THINK := 1
const TELL := 2
const CHARGE := 3
const THROW := 4
const OPEN := 6
const DEAD := 7

var level: Node
var game: Node
var p: CharacterBody2D
var term: CanvasLayer
var wall_bot := false
var wall_dir := 1
var wall_cooldown := 0.0
var exit_y := 0.0
var exit_dir := 1
var exit_walk := 0.0  ## Seconds the wall-jump bot still walks off the top.
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


func room(i: int) -> Node:
	return level.get_node("Rooms").get_child(i)


## Top-left corner of room i's map, in pixels (a Room covers its map and the wall on its right).
func org(i: int) -> Vector2:
	var r := room(i)
	return r.global_position - r.size / 2.0


## Where a hero stands in map cell (x, row) of room i: feet on top of the row below.
func at(i: int, x: float, row: int) -> Vector2:
	return org(i) + Vector2((x + 0.5) * T, (row + 1) * T - 16)


## The left edge of map column x of room i.
func col(i: int, x: float) -> float:
	return org(i).x + x * T


func tp(pos: Vector2) -> void:
	p.global_position = pos
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


func dash() -> void:
	Input.action_press("dash")
	await wait(0.05)
	Input.action_release("dash")


func swing() -> void:
	Input.action_press("attack")
	await wait(0.05)
	Input.action_release("attack")
	await wait(0.4)


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


## Collects every coin left in room i (the bot tests puzzles, not coin hunting).
func collect_room(i: int) -> void:
	var r := room(i)
	for c in get_nodes_in_group("fruit"):
		if is_instance_valid(c) and r.contains(c.global_position) and not c._taken:
			c._on_body_entered(p)
	await wait(0.5)


## Walks into a flag from the left (re-touches it if it was already reached).
func touch_flag(pos: Vector2) -> void:
	tp(pos - Vector2(40, 0))
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(pos.x + 2, 2.0)
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


## Waits up to `appear` seconds for a Byte talk (the rescue cutscene), then presses Enter until
## it's over. Returns true if one was shown.
func await_talk(appear := 3.0) -> bool:
	var start := Time.get_ticks_msec()
	while get_first_node_in_group("byte_talk") == null and Time.get_ticks_msec() - start < appear * 1000:
		await process_frame
	if get_first_node_in_group("byte_talk") == null:
		return false
	start = Time.get_ticks_msec()
	while get_first_node_in_group("byte_talk") != null and Time.get_ticks_msec() - start < 30000:
		await wait(0.5)
		await press_accept()
	await wait(0.3)
	return true


## Tries an obstacle the wrong way: `hero` at jumpPower `jp` runs right from `start` and at
## `edge_x` does the most it can - Sarah jumps and dashes at the top, April double jumps,
## Kervin sprint-jumps, the others jump. Sets the hero and jumpPower directly, not through
## the terminal. Returns where the hero ended up.
func attempt(hero: String, start: Vector2, edge_x: float, jp := 1.0) -> Vector2:
	p.set_hero(hero)
	p.jump_power = jp
	tp(start)
	p.restore_vitals()
	await wait(0.4)
	if hero == "kervin":
		Input.action_press("dash")
	Input.action_press("move_right")
	await until_x(edge_x)
	if hero == "sarah":
		Input.action_press("jump")
		await wait(0.28 * sqrt(jp))
		await dash()
		Input.action_release("jump")
	else:
		await jump(0.28 * sqrt(jp))
		if hero == "april":
			await wait(0.04)
			await jump(0.28)
	await wait(1.6)
	release_all()
	await wait(0.6)
	return p.global_position


## `hero` at jumpPower `jp` jumps straight up from `pos` (April double jumps at the top).
func jump_up(hero: String, pos: Vector2, jp: float) -> Vector2:
	p.set_hero(hero)
	p.jump_power = jp
	tp(pos)
	p.restore_vitals()
	await wait(0.4)
	await jump(0.28 * sqrt(jp))
	if hero == "april":
		await wait(0.04)
		await jump(0.28)
	await wait(1.2)
	return p.global_position


func shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_texture().get_image().save_png(OUT + "l2_" + name + ".png")


func _process(delta: float) -> bool:
	# Wall-jump bot (Chelzy): press toward a wall, jump off it, then toward the other way.
	# Above `exit_y` it walks off in `exit_dir` for half a second and stops (past the top the
	# way often leads on into the next room's water).
	if wall_bot and p:
		wall_cooldown -= delta
		if exit_walk > 0.0 or (p.global_position.y < exit_y and wall_dir == exit_dir):
			if exit_walk <= 0.0:
				exit_walk = 0.5
			exit_walk -= delta
			Input.action_release("move_left" if exit_dir > 0 else "move_right")
			Input.action_press("move_right" if exit_dir > 0 else "move_left")
			Input.action_release("jump")
			if exit_walk <= 0.0:
				wall_bot = false
				release_all()
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


## Chelzy wall-jumps, first toward `dir`, until she's above `top_y`, then walks off right.
func wall_climb(start: Vector2, top_y: float, seconds := 6.0, dir := 1) -> Vector2:
	p.set_hero("chelzy")
	tp(start)
	p.restore_vitals()
	await wait(0.3)
	wall_dir = dir
	exit_y = top_y
	exit_dir = 1
	exit_walk = 0.0
	wall_bot = true
	await wait(seconds)
	wall_bot = false
	release_all()
	await wait(0.5)
	return p.global_position


func find_in(group_parent: String, script_end: String, i: int) -> Node:
	for n in level.get_node(group_parent).get_children():
		if n.get_script() and n.get_script().resource_path.ends_with(script_end) and room(i).contains(n.global_position):
			return n
	return null


func hold_sword() -> void:
	p.select_slot(p.inventory.find("sword"))
	await wait(0.1)


# ---------------- The boss ----------------

var cap: Node
var arena_y := 0.0  ## Where a hero stands on the arena floor.


## Waits for the captain to be between attacks, stands the hero `tiles` away from him (on the
## side with more room) and waits for his shout. Returns the attack he shouted.
func provoke(tiles: float) -> String:
	var start := Time.get_ticks_msec()
	while cap.st != THINK and Time.get_ticks_msec() - start < 10000:
		await process_frame
	var mid: float = (cap.arena_left + cap.arena_right) / 2.0
	var side := -1.0 if cap.global_position.x > mid else 1.0
	tp(Vector2(cap.global_position.x + side * tiles * T, arena_y))
	p.restore_vitals()
	start = Time.get_ticks_msec()
	while cap.st != TELL and Time.get_ticks_msec() - start < 3000:
		await process_frame
	return cap.move


func until_state(states: Array, timeout := 6.0) -> void:
	var start := Time.get_ticks_msec()
	while not cap.st in states and Time.get_ticks_msec() - start < timeout * 1000:
		await process_frame


## While the captain is open, stands next to him facing him and swings twice.
func hit_captain() -> float:
	var before: float = cap.health
	var side := -1.0 if p.global_position.x < cap.global_position.x else 1.0
	tp(Vector2(cap.global_position.x + side * 22.0, p.global_position.y))
	p.facing = int(-side)
	await hold_sword()
	await swing()
	await swing()
	return before - cap.health


func _run() -> void:
	game = root.get_node("Game")
	level = load("res://scenes/levels/level2/level2.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	p = level.get_node("Player")
	term = level.get_node("CodeTerminal")
	cap = level.get_node("Captain")
	await wait(0.6)
	check("starts with Chelzy and Sarah", game.unlocked_heroes == ["chelzy", "sarah"], str(game.unlocked_heroes))
	check("the HUD counts coins", level.hud.item_word == "COINS")
	check("Byte's first tip is the sword", "hasSword" in term.pending_hint, term.pending_hint)

	# ---------------- Room 0: the shaft (Chelzy) and the wide gap (Sarah) ----------------
	var top0 := at(0, 10, 3).y
	var won := await jump_up("sarah", at(0, 8, 8), 1.0)
	check("R0 Sarah can't get up the shaft", won.y > top0 + 40, "pos=%s" % won)
	won = await wall_climb(at(0, 7, 8), top0 - 6)
	check("R0 Chelzy wall-jumps up the shaft", won.y < top0 + 8 and won.x > col(0, 9), "pos=%s" % won)
	shot("r0_shaft")
	tp(at(0, 14, 3))
	await wait(0.3)
	Input.action_press("move_right")
	await wait(0.3)
	await jump()
	await wait(1.0)
	release_all()
	await wait(0.4)
	check("R0 Chelzy can't cross the gap in the crawlspace", p.global_position.x < col(0, 16) or p.global_position.y > top0 + 8, "pos=%s" % p.global_position)
	tp(at(0, 14, 3))
	await code('String hero = "Sarah";')
	check("R0 String hero = \"Sarah\"; switches to Sarah", p.hero_id == "sarah", last_byte())
	tp(at(0, 15, 3))
	await wait(0.3)
	Input.action_press("move_right")
	await wait(0.08)
	await dash()
	await wait(0.6)
	release_all()
	check("R0 Sarah dashes across", p.global_position.x > col(0, 18) and p.global_position.y < top0 + 8, "pos=%s" % p.global_position)
	var flag0 := at(0, 26, 3)
	await touch_flag(flag0)
	check("R0 flag won't free April until every coin", not "april" in game.unlocked_heroes and not paused)
	await collect_room(0)
	await touch_flag(flag0)
	var shown := await await_talk()
	check("R0 all coins + flag: cutscene, then April joins", shown and "april" in game.unlocked_heroes, str(game.unlocked_heroes))

	# ---------------- Room 1: the broken bridge, then April's planks ----------------
	var planks1 := at(1, 24, 1).y
	won = await attempt("sarah", at(1, 2, 4), col(1, 5.7))
	check("R1 Sarah can't jump and dash the 8-plank gap", won.x < col(1, 14), "pos=%s" % won)
	won = await attempt("april", at(1, 2, 4), col(1, 5.7))
	check("R1 April can't double jump the gap", won.x < col(1, 14), "pos=%s" % won)
	p.set_hero("sarah")
	tp(at(1, 3, 4))
	var bridge := find_in("Gadgets", "code_bridge.gd", 1)
	await code("int bridgeLength = 9;")
	await wait(1.5)
	check("R1 9 planks are too long and collapse", bridge._blocks.is_empty() and "too long" in term.log_label.get_parsed_text(), last_byte())
	await code("bridgeLength = 8;")  # it exists now (the 9 was valid Java), so no type
	await wait(1.2)
	check("R1 bridgeLength = 8 builds 8 planks", bridge._blocks.size() == 8, "blocks=%d" % bridge._blocks.size())
	Input.action_press("move_right")
	await until_x(col(1, 15), 4.0)
	release_all()
	check("R1 the bridge holds", p.global_position.x > col(1, 14) and p.global_position.y < at(1, 15, 4).y + 4, "pos=%s" % p.global_position)
	won = await attempt("chelzy", at(1, 16, 4), col(1, 19.6))
	check("R1 Chelzy can't reach the planks over the water", won.y > planks1 + 8, "pos=%s" % won)
	won = await attempt("sarah", at(1, 16, 4), col(1, 19.6))
	check("R1 Sarah can't reach the planks", won.y > planks1 + 8, "pos=%s" % won)
	tp(at(1, 17, 4))
	await code('String hero = "April";')
	check("R1 Byte fixes the redeclaration of hero", term.input.text == 'hero = "April";', term.input.text)
	await code('hero = "April";')
	check("R1 hero = \"April\"; switches to April", p.hero_id == "april")
	tp(at(1, 18, 4))
	p.restore_vitals()
	await wait(0.4)
	Input.action_press("move_right")
	await wait(0.1)
	await jump(0.28)
	await wait(0.04)
	await jump(0.28)
	await wait(1.0)
	release_all()
	await wait(0.4)
	check("R1 April double-jumps from the edge onto the planks", p.global_position.y < planks1 + 8 and p.global_position.x > col(1, 21), "pos=%s" % p.global_position)
	shot("r1_planks")
	await collect_room(1)
	await touch_flag(at(1, 25, 1))
	shown = await await_talk()
	check("R1 all coins + flag: Kervin joins", shown and "kervin" in game.unlocked_heroes, str(game.unlocked_heroes))

	# ---------------- Room 2: Kervin's falling floor, April's planks at jumpPower 2.0 ----------------
	var past_floor := col(2, 13)
	var floor2 := at(2, 16, 7).y
	won = await attempt("april", at(2, 2, 7), col(2, 7))
	check("R2 walking onto the falling floor drops you", won.x < past_floor or won.y > floor2 + 8, "pos=%s" % won)
	won = await attempt("sarah", at(2, 3, 7), col(2, 6.5))
	check("R2 Sarah's dash can't cross the falling floor", won.x < past_floor or won.y > floor2 + 8, "pos=%s" % won)
	tp(at(2, 3, 7))
	await code('hero = "Kervin";')
	tp(at(2, 2, 7))
	p.restore_vitals()
	await wait(2.5)  # the planks come back
	Input.action_press("dash")
	Input.action_press("move_right")
	await until_x(past_floor + 16, 3.0)
	release_all()
	await wait(0.3)
	check("R2 Kervin sprints over the falling floor", p.global_position.x > past_floor and p.global_position.y < floor2 + 8, "pos=%s" % p.global_position)
	var planks2 := at(2, 24, 3).y
	won = await wall_climb(at(2, 14, 7), planks2 - 40, 6.0, -1)
	check("R2 Chelzy can't wall-jump over to the planks", won.y > planks2 + 8, "pos=%s" % won)
	won = await jump_up("april", at(2, 21, 7), 1.0)
	check("R2 April at jumpPower 1.0 can't reach the planks", won.y > planks2 + 8, "pos=%s" % won)
	won = await jump_up("kervin", at(2, 21, 7), 2.0)
	check("R2 Kervin at jumpPower 2.0 can't reach the planks", won.y > planks2 + 8, "pos=%s" % won)
	tp(at(2, 20, 7))
	await code("double jumpPower = 2.0;")
	await code('hero = "April";')
	check("R2 double jumpPower = 2.0; works", is_equal_approx(p.jump_power, 2.0) and p.hero_id == "april", last_byte())
	won = await jump_up("april", at(2, 21, 7), 2.0)
	check("R2 April at jumpPower 2.0 double-jumps up onto the planks", won.y < planks2 + 8, "pos=%s" % won)
	await collect_room(2)
	await touch_flag(at(2, 24, 3))
	shown = await await_talk()
	check("R2 all coins + flag: Psalm joins", shown and "psalm" in game.unlocked_heroes, str(game.unlocked_heroes))

	# ---------------- Room 3: Psalm's beams, the ship, the crab, Chelzy's shaft ----------------
	tp(at(3, 6, 7))
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await wait(1.5)
	release_all()
	check("R3 April can't get under the beams", p.global_position.x < col(3, 8), "pos=%s" % p.global_position)
	await code('hero = "Psalm";')
	Input.action_press("move_down")
	await wait(0.4)
	Input.action_press("move_right")
	await until_x(col(3, 12) + 8, 5.0)
	release_all()
	await wait(0.6)
	check("R3 tiny Psalm walks under the beams", p.global_position.x > col(3, 12) and not p.is_small, "pos=%s small=%s" % [p.global_position, p.is_small])
	var ship := find_in("Gadgets", "code_ship.gd", 3)
	var deck: Vector2 = ship.global_position + Vector2(0, -16)
	tp(deck)
	await wait(1.0)
	check("R3 the anchored ship stays at the dock", absf(p.global_position.x - deck.x) < 4.0, "pos=%s" % p.global_position)
	await code("boolean anchorUp = true;")
	await wait(3.0)
	check("R3 anchorUp = true: the ship carries you across", p.global_position.x > deck.x + 250.0, "pos=%s" % p.global_position)
	Input.action_press("move_right")
	await jump()
	await wait(0.6)
	release_all()
	await wait(0.3)
	check("R3 you step off onto the far dock", p.global_position.x > col(3, 27), "pos=%s" % p.global_position)
	var crab := find_in("Traps", "crabby.gd", 3)
	tp(at(3, 28, 7))
	p.restore_vitals()
	Input.action_press("move_right")
	await wait(2.0)
	release_all()
	check("R3 the crab blocks the tunnel", p.global_position.x < col(3, 34), "pos=%s" % p.global_position)
	p.restore_vitals()
	await code("boolean hasSword = true;")
	check("R3 boolean hasSword = true; gives the sword", p.has_sword and "sword" in p.inventory, str(p.inventory))
	var start_fight := Time.get_ticks_msec()
	while is_instance_valid(crab) and not crab._dead and Time.get_ticks_msec() - start_fight < 10000:
		tp(Vector2(crab.global_position.x - 26.0, at(3, 30, 7).y))
		p.facing = 1
		p.restore_vitals()
		await hold_sword()
		await swing()
	check("R3 the sword beats the crab", not is_instance_valid(crab) or crab._dead)
	await wait(2.0)
	tp(at(3, 29, 7))
	Input.action_press("move_right")
	await until_x(col(3, 34) + 8, 3.0)
	release_all()
	check("R3 the tunnel is open", p.global_position.x > col(3, 34), "pos=%s" % p.global_position)
	var ledge3 := at(3, 37, 2).y
	won = await jump_up("april", at(3, 34.5, 7), 2.0)
	check("R3 April can't get up the shaft", won.y > ledge3 + 40, "pos=%s" % won)
	won = await wall_climb(at(3, 34, 7), ledge3 - 6)
	check("R3 Chelzy wall-jumps up to the exit", won.y < ledge3 + 8 and won.x > col(3, 36), "pos=%s" % won)
	shot("r3_shaft")

	# ---------------- Room 4: three paths, Kervin's falling floor ----------------
	tp(at(4, 2, 2))  # code gadgets only listen to code typed in their own room
	await code("char path = 'C';")
	tp(at(4, 2, 2))
	p.set_hero("april")
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await wait(3.5)
	release_all()
	check("R4 path C ends at a wall", p.global_position.x < col(4, 16) and p.global_position.y > at(4, 2, 2).y + 16, "pos=%s" % p.global_position)
	await code("path = 'B';")
	tp(at(4, 2, 2))
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(col(4, 16.5), 5.0)
	release_all()
	await wait(0.3)
	check("R4 path = 'B'; leads to the crawlspace", p.global_position.x > col(4, 16) and p.global_position.y < at(4, 2, 2).y + 8, "pos=%s" % p.global_position)
	won = await attempt("sarah", at(4, 16, 2), col(4, 16.6))
	check("R4 Sarah can't dash over the falling floor", won.x < col(4, 24) or won.y > at(4, 2, 2).y + 8, "pos=%s" % won)
	tp(at(4, 10, 2))
	await code('hero = "Kervin";')
	tp(at(4, 10, 2))
	p.restore_vitals()
	await wait(2.5)
	Input.action_press("dash")
	Input.action_press("move_right")
	await until_x(col(4, 24) + 8, 4.0)
	release_all()
	check("R4 Kervin sprints over the falling floor", p.global_position.x > col(4, 24) and p.global_position.y < at(4, 2, 2).y + 8, "pos=%s" % p.global_position)

	# ---------------- Exam 1: the low cave ----------------
	p.set_hero("sarah")
	p.jump_power = 2.0
	tp(at(5, 3, 2))
	p.restore_vitals()
	await wait(0.4)
	await jump(0.4)
	await wait(0.8)
	check("E1 at jumpPower 2.0 the ceiling spikes hit for 50", p.health == 50.0, "hp=%.0f" % p.health)
	await code("jumpPower = 1.0;")
	check("E1 jumpPower = 1.0; works", is_equal_approx(p.jump_power, 1.0), last_byte())
	await wait(1.0)
	tp(at(5, 3, 2))
	p.restore_vitals()
	await wait(0.3)
	Input.action_press("move_right")
	await until_x(col(5, 4.3))
	await jump()
	await wait(0.8)
	release_all()
	check("E1 at 1.0 you jump the floor spikes safely", p.global_position.x > col(5, 6) and p.health == 100.0, "pos=%s hp=%.0f" % [p.global_position, p.health])
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	check("E1 Sarah can't get under the beams", p.global_position.x < col(5, 8), "pos=%s" % p.global_position)
	await code('hero = "Psalm";')
	Input.action_press("move_down")
	await wait(0.4)
	Input.action_press("move_right")
	await until_x(col(5, 11) + 8, 5.0)
	release_all()
	await wait(0.3)
	check("E1 tiny Psalm crawls under the beams", p.global_position.x > col(5, 11), "pos=%s" % p.global_position)
	won = await attempt("psalm", at(5, 11, 2), col(5, 13))
	check("E1 walking onto the falling floor drops you", won.x < col(5, 21) or won.y > at(5, 11, 2).y + 8, "pos=%s" % won)
	tp(at(5, 11, 2))
	await code('hero = "Kervin";')
	tp(at(5, 11, 2))
	p.restore_vitals()
	await wait(2.5)
	Input.action_press("dash")
	Input.action_press("move_right")
	await until_x(col(5, 21) + 8, 3.0)
	release_all()
	check("E1 Kervin sprints over the falling floor", p.global_position.x > col(5, 21) and p.global_position.y < at(5, 11, 2).y + 8, "pos=%s" % p.global_position)

	# ---------------- Exam 2: the low bridge, three paths, Chelzy's shaft ----------------
	won = await attempt("sarah", at(6, 2, 7), col(6, 3.7))
	check("E2 Sarah can't dash the 6-plank gap", won.x < col(6, 10), "pos=%s" % won)
	tp(at(6, 2, 7))
	await code("bridgeLength = 6;")
	await wait(1.0)
	Input.action_press("move_right")
	await until_x(col(6, 10.5), 4.0)
	release_all()
	check("E2 bridgeLength = 6; builds the bridge", p.global_position.x > col(6, 10) and p.global_position.y < at(6, 2, 7).y + 8, "pos=%s" % p.global_position)
	await code("path = 'C';")
	Input.action_press("move_right")
	await until_x(col(6, 19.2), 5.0)
	await jump()
	await wait(0.8)
	release_all()
	await wait(0.3)
	check("E2 path = 'C'; leads to the far side", p.global_position.x > col(6, 20) and p.global_position.y < at(6, 2, 7).y + 8, "pos=%s" % p.global_position)
	var ledge6 := at(6, 27, 2).y
	won = await jump_up("april", at(6, 24.5, 7), 1.0)
	check("E2 April can't get up the shaft", won.y > ledge6 + 40, "pos=%s" % won)
	won = await wall_climb(at(6, 24, 7), ledge6 - 6)
	check("E2 Chelzy wall-jumps up to the exit", won.y < ledge6 + 8 and won.x > col(6, 26), "pos=%s" % won)

	# ---------------- Exam 3: the ship, the gate, Captain Clown Nose ----------------
	var ship3 := find_in("Gadgets", "code_ship.gd", 7)
	var deck3: Vector2 = ship3.global_position + Vector2(0, -16)
	tp(deck3)
	await code("boolean anchorUp = true;")
	check("E3 Byte fixes the redeclaration of anchorUp", term.input.text == "anchorUp = true;", term.input.text)
	tp(deck3)
	await code("anchorUp = true;")
	await wait(2.0)
	Input.action_press("move_right")
	await jump()
	await wait(0.8)
	release_all()
	await wait(0.3)
	check("E3 the second ship carries you to the far dock", p.global_position.x > col(7, 14), "pos=%s" % p.global_position)
	var gate_x := col(7, 16)
	Input.action_press("move_right")
	await wait(1.5)
	release_all()
	check("E3 Byte's gate blocks the way", p.global_position.x < gate_x, "pos=%s" % p.global_position)
	await code('System.out.println("Hi");')
	Input.action_press("move_right")
	await wait(0.8)
	release_all()
	check("E3 the gate needs exactly \"I can code!\"", p.global_position.x < gate_x, "pos=%s" % p.global_position)
	await code('System.out.println("I can code!");')
	await wait(0.6)
	Input.action_press("move_right")
	await until_x(col(7, 20) + 8, 4.0)
	release_all()
	await wait(1.0)
	arena_y = at(7, 22, 8).y
	check("E3 you drop into the captain's arena", p.global_position.x > col(7, 20) and absf(p.global_position.y - arena_y) < 8.0, "pos=%s" % p.global_position)
	check("E3 the treasure is hidden", not level.end_goal.visible)

	p.has_sword = false
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	await wait(0.3)
	check("E3 the captain won't fight a hero without a sword", not cap.fighting and p.global_position.x < cap.start_x, "pos=%s" % p.global_position)
	p.has_sword = true
	p.set_hero("sarah")
	await hold_sword()
	Input.action_press("move_right")
	await wait(0.5)
	release_all()
	await wait(0.3)
	check("E3 with a sword the fight starts: Byte hides, the terminal locks",
		cap.fighting and not level.byte.visible and term.locked_reason != "", term.locked_reason)
	shot("e3_boss")

	var move := await provoke(7.0)
	check("E3 far away he charges", move == "C", move)
	term.switch_from_wheel("april")
	var hp: float = p.health
	var start := Time.get_ticks_msec()
	while absf(cap.global_position.x - p.global_position.x) > 150.0 and Time.get_ticks_msec() - start < 5000:
		await process_frame
	await jump(0.28)
	await wait(0.04)
	await jump(0.28)
	await until_state([OPEN])
	check("E3 April double-jumps over the charge", p.health == hp, "hp=%.0f" % p.health)
	var dealt := await hit_captain()
	check("E3 the sword hurts him while he's dizzy", dealt > 0.0, "dealt=%.0f" % dealt)
	await wait(0.6)
	dealt = 0.0
	if not cap._vulnerable:
		var before: float = cap.health
		var side := -1.0 if p.global_position.x < cap.global_position.x else 1.0
		tp(Vector2(cap.global_position.x + side * 22.0, p.global_position.y))
		p.facing = int(-side)
		await swing()
		dealt = before - cap.health
	check("E3 the sword bounces off when he isn't dizzy", dealt == 0.0, "dealt=%.0f" % dealt)

	move = await provoke(4.0)
	check("E3 in the middle he throws his sword", move == "T", move)
	term.switch_from_wheel("psalm")
	hp = p.health
	# Duck while the spinning sword is close (out and back), like a player would.
	start = Time.get_ticks_msec()
	while cap.st != THINK and Time.get_ticks_msec() - start < 10000:
		var blade: Area2D = cap._sword
		if blade.monitoring and absf(blade.global_position.x - p.global_position.x) < 100.0:
			Input.action_press("move_down")
		else:
			Input.action_release("move_down")
		await process_frame
	Input.action_release("move_down")
	await wait(0.3)
	check("E3 tiny Psalm ducks under the thrown sword", p.health == hp, "hp=%.0f" % p.health)

	move = await provoke(1.2)
	check("E3 up close he swings", move == "S", move)
	term.switch_from_wheel("sarah")
	hp = p.health
	var away := 1 if p.global_position.x > cap.global_position.x else -1
	p.facing = away
	Input.action_press("move_right" if away > 0 else "move_left")
	await wait(0.05)
	await dash()
	release_all()
	await until_state([OPEN])
	check("E3 Sarah dashes away from the swing", p.health == hp, "hp=%.0f" % p.health)

	move = await provoke(7.0)
	term.switch_from_wheel("kervin")
	hp = p.health
	await until_state([OPEN])
	check("E3 the wrong hero gets hit (Kervin can't clear the charge)", p.health < hp, "hp=%.0f" % p.health)

	# Finish him: immunity mode keeps the bot alive while it only hits him when he's open.
	game.immune = true
	start = Time.get_ticks_msec()
	while cap.st != DEAD and Time.get_ticks_msec() - start < 60000:
		if cap._vulnerable:
			p.set_hero("sarah")
			await hit_captain()
		else:
			await process_frame
	game.immune = false
	await wait(2.0)
	check("E3 six hits beat Captain Clown Nose", cap.st == DEAD, "hp=%.0f" % cap.health)
	check("E3 Byte is back and the terminal unlocks", level.byte.visible and term.locked_reason == "")
	check("E3 the treasure appears", level.end_goal.visible)
	shot("e3_won")

	tp(at(7, 34, 8))
	Input.action_press("move_right")
	await wait(0.8)
	release_all()
	await wait(0.5)
	check("E3 the treasure waits for every exam coin", level.get_node_or_null("LevelComplete") == null and not paused)
	for i in range(5, 8):
		await collect_room(i)
	tp(at(7, 34, 8))
	Input.action_press("move_right")
	await wait(1.0)
	release_all()
	await wait(2.5)
	var screen := level.get_node_or_null("LevelComplete")
	check("Level complete screen", screen != null and paused, "stars=%d mistakes=%d" % [game.stars_earned(), game.mistakes])
	check("It says LEVEL 1 COMPLETE!", screen != null and screen._title.text == "LEVEL 1 COMPLETE!", screen._title.text if screen else "")
	shot("complete")

	print("\n%d / %d checks passed" % [results.filter(func(r): return r.begins_with("PASS")).size(), results.size()])
	paused = false
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	quit()
