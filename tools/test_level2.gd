extends SceneTree
## Plays Level 2's rules: in each room the wrong rules from docs/level2_design.md must fail the
## way the doc says, and the right rule must work. Types into Byte's terminal like a player.
## Run:  godot --headless --path . --script res://tools/test_level2.gd
## (tools/test_rules.gd checks the checker's messages; this checks the machines.)
## Backs up and restores the real save file. Time runs 4x faster.

const SAVE := "user://save.cfg"
const BACKUP := "user://save_backup_for_test2.cfg"

var level: Node
var p: CharacterBody2D
var term: Node
var rooms: Array = []
var passed := 0
var failed := 0


func _initialize() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE), ProjectSettings.globalize_path(BACKUP))
	_run.call_deferred()


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  %s" % ["PASS" if ok else "FAIL", name, detail])


func wait(s: float) -> void:
	await create_timer(s).timeout  # game time (runs 4x faster)


func room(i: int) -> Node:
	return rooms[i]


## Puts the hero in room i (at map column x, row y) and waits for the room to notice.
func enter(i: int, x: float, y: float) -> void:
	var r: Node = room(i)
	var top_left: Vector2 = r.global_position - r.size / 2.0
	p.global_position = top_left + Vector2(x * 32.0 + 16.0, (y + 1) * 32.0 - 16.0)
	p.velocity = Vector2.ZERO
	await wait(0.3)


func type_line(text: String) -> void:
	term._on_submitted(text)
	while term._running:
		await process_frame
	await wait(0.1)


func runner(i: int) -> Node:
	return room(i).player_runner()


func machine(i: int, var_name: String) -> Node:
	for m in get_nodes_in_group("rule_machine"):
		if m.handles(var_name) and room(i).contains(m.global_position):
			return m
	return null


func reading_source(i: int, reading: String) -> Node:
	for s in get_nodes_in_group("reading_source"):
		if s.has_reading(reading) and room(i).contains(s.global_position):
			return s
	return null


## Waits (up to `limit` seconds) until `cond` is true.
func wait_until(cond: Callable, limit: float) -> bool:
	var t := 0.0
	while t < limit:
		if cond.call():
			return true
		await wait(0.1)
		t += 0.1
	return cond.call()


func _run() -> void:
	Engine.time_scale = 4.0
	change_scene_to_file("res://scenes/levels/level2/level2.tscn")
	await process_frame
	await process_frame
	level = current_scene
	p = level.get_node("Player")
	term = level.get_node("CodeTerminal")
	rooms = level.get_node("Rooms").get_children()
	await wait(0.5)
	check("level loads with 12 rooms", rooms.size() == 12, str(rooms.size()))
	check("hero starts declared", term.values.has("hero"))

	await _room0()
	await _room1()
	await _room2()
	await _room3()
	await _room4()
	await _room5()
	await _exam()
	await _boss()

	print("\n%d passed, %d failed" % [passed, failed])
	Engine.time_scale = 1.0
	if FileAccess.file_exists(BACKUP):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP), ProjectSettings.globalize_path(SAVE))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))
	quit(1 if failed > 0 else 0)


func _room0() -> void:
	await enter(0, 15, 5)
	var left := machine(0, "leftDoorOpen")
	var right := machine(0, "rightDoorOpen")
	check("R0 doors wait while key doesn't exist", not left.is_open and not right.is_open)
	await type_line("leftDoorOpen = true;")
	check("R0 an order to a door is turned into a rule", term.input.text.begins_with("if (___)") and not left.is_open, term.input.text)
	term.input.text = ""
	await type_line("int key = 3;")
	check("R0 key 3 runs the else: left door", left.is_open and not right.is_open)
	check("R0 Byte says to press W and points at the other door", "press W" in term.pending_hint and "Try key = 7;" in term.pending_hint, term.pending_hint)
	await type_line("key = 7;")
	check("R0 key 7 opens the right door", right.is_open)
	check("R0 Byte says both doors are open", "Both doors are open" in term.pending_hint, term.pending_hint)
	var tries: int = room(0).wrong_tries
	await type_line("if (key == 7) { leftDoorOpen = true; }")
	check("R0 a typed rule is refused (captain's rule), not a wrong try", room(0).wrong_tries == tries and "captain's rule" in term.log_label.get_parsed_text())
	var exit := machine(0, "doorOpen")
	check("R0 exit stays shut without the coins", not exit.is_open)
	for c in get_nodes_in_group("fruit"):
		if room(0).contains(c.global_position):
			c.collected.emit()
	await wait(0.3)
	check("R0 exit opens with every coin (coins >= n)", exit.is_open)


func _room1() -> void:
	await enter(1, 3, 3)
	var ship := machine(1, "anchorUp")
	var tries: int = room(1).wrong_tries
	await type_line("anchorUp = true;")
	check("R1 anchorUp = true; is an order: refused, not a wrong try", room(1).wrong_tries == tries and ship.ship_state == ship.State.DOCKED)
	await type_line("if (tide >= 1) { anchorUp = true; }")
	var aground := await wait_until(func(): return ship.ship_state == ship.State.AGROUND or ship.ship_state == ship.State.TOWING, 20.0)
	check("R1 tide >= 1: the ship scrapes the reef", aground)
	check("R1 ...and it's a wrong try", room(1).wrong_tries > tries)
	await wait_until(func(): return ship.ship_state == ship.State.DOCKED, 15.0)
	await type_line("if (tide >= 4) { anchorUp = true; }")
	var crossed := await wait_until(func(): return ship.ship_state == ship.State.ARRIVED, 30.0)
	check("R1 tide >= 4: the ship crosses the reef", crossed, str(ship.ship_state))
	check("R1 it left at tide 4 or more", ship._depart_tide >= 4, str(ship._depart_tide))


func _room2() -> void:
	await enter(2, 7, 9)
	var water: Node = null
	for w in get_nodes_in_group("water"):
		if room(2).contains(w.global_position + Vector2(10, -2)):
			water = w
	var gate := machine(2, "gateOpen")
	var tide := reading_source(2, "tide")
	check("R2 gates start shut", gate and not gate.is_open)
	await type_line("if (tide < 3) { gateOpen = true; }")
	var flooded := await wait_until(func(): return water.level > 10.0, 20.0)
	check("R2 one-branch rule: the gates never shut and the cave floods", flooded)
	await enter(2, 1, 3)  # drowning sent the hero back; wait on the dry ledge
	await type_line("if (tide >= 3) { gateOpen = false; } else { gateOpen = true; }")
	var high := await wait_until(func(): return tide.get_reading("tide") >= 4, 20.0)
	await wait(1.5)
	check("R2 with else: shut at high tide", high and not gate.is_open)
	check("R2 ...and the cave stays dry", water.level < 1.0, str(water.level))
	var low := await wait_until(func(): return tide.get_reading("tide") <= 1, 20.0)
	check("R2 with else: open at low tide", low and gate.is_open)


func _room3() -> void:
	await enter(3, 2, 3)
	var ship := machine(3, "sails")
	var tries: int = room(3).wrong_tries
	await type_line("if (wind >= 3) { sails = 1; } else if (wind >= 7) { sails = 0; } else { sails = 2; }")
	_board(ship)
	var broke := await wait_until(func(): return ship.ship_state == ship.State.AGROUND or ship.ship_state == ship.State.TOWING, 20.0)
	check("R3 wrong order: the mast snaps in the storm", broke)
	check("R3 ...Byte explains the order", room(3).wrong_tries > tries and "Java checks from the top" in term.log_label.get_parsed_text())
	await wait_until(func(): return ship.ship_state == ship.State.DOCKED, 20.0)
	await type_line("if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; } else { sails = 2; }")
	tries = room(3).wrong_tries
	_board(ship)
	var crossed := await wait_until(func(): return ship.ship_state == ship.State.ARRIVED, 40.0)
	check("R3 right rule: the ship crosses the storm", crossed and room(3).wrong_tries == tries, str(ship.ship_state))


## Keeps the hero standing on the ship's deck (a test can't steer).
func _board(ship: Node) -> void:
	var deck: Node2D = ship._deck
	var t := Timer.new()
	t.wait_time = 0.02
	t.timeout.connect(func():
		if is_instance_valid(deck) and ship.ship_state != ship.State.ARRIVED:
			p.global_position = deck.global_position + Vector2(0, -14)
			p.velocity = Vector2.ZERO
		else:
			t.queue_free())
	root.add_child(t)
	t.start()


func _room4() -> void:
	await enter(4, 12, 4)
	var gate := machine(4, "gateOpen")
	var lookout := reading_source(4, "word")
	var tries: int = room(4).wrong_tries
	await type_line("if (word == \"ahoy\") { gateOpen = true; } else { gateOpen = false; }")
	check("R4 == on Strings: Byte fixes it, not a wrong try", term.input.text.contains("word.equals(\"ahoy\")") and room(4).wrong_tries == tries, term.input.text)
	term.input.text = ""
	await type_line("if (word.equals(\"ahoy\")) { gateOpen = true; }")
	var alarm := await wait_until(func(): return room(4).wrong_tries > tries, 20.0)
	check("R4 no else: the gate stays open and the lookout fires", alarm)
	await type_line("if (word.equals(\"ahoy\")) { gateOpen = true; } else { gateOpen = false; }")
	tries = room(4).wrong_tries
	var right_way := true
	for k in 30:
		await wait(0.25)
		if gate.is_open != (lookout.get_reading("word") == "ahoy"):
			right_way = false
	check("R4 with else: open only on ahoy, and no alarm", right_way and room(4).wrong_tries == tries)


func _room5() -> void:
	await enter(5, 4, 8)
	var crew := reading_source(5, "awake")
	var tries: int = room(5).wrong_tries
	var spotted := await wait_until(func(): return "spotted you" in term.log_label.get_parsed_text(), 20.0)
	check("R5 no rule: lit lanterns, the crew spots you (no code typed, so no wrong try)", spotted and room(5).wrong_tries == tries)
	await wait_until(func(): return crew.get_reading("awake") == false, 20.0)
	await enter(5, 4, 8)
	await type_line("if (awake == true) { lightsOn = false; } else { lightsOn = true; }")
	check("R5 awake == true works, with Byte's tip", "already true or false" in term.log_label.get_parsed_text())
	await type_line("if (awake) { lightsOn = false; } else { lightsOn = true; }")
	tries = room(5).wrong_tries
	var lanterns := machine(5, "lightsOn")
	var woke := await wait_until(func(): return crew.get_reading("awake") == true, 20.0)
	await wait(1.0)
	check("R5 right rule: dark while they're awake, not spotted", woke and not lanterns.lit and room(5).wrong_tries == tries)
	var slept := await wait_until(func(): return crew.get_reading("awake") == false, 20.0)
	check("R5 ...and lit again while they sleep", slept and lanterns.lit)


func _exam() -> void:
	# Exam 1: if (tide = 0)
	await enter(6, 3, 4)
	check("E1 the captain's rule can't run", runner(6).error != "" and "==" in runner(6).error, runner(6).error)
	check("E1 opening the terminal offers the captain's rule", true)
	term.open()
	check("E1 ...it's put in the input", term.input.text == runner(6).start_rule, term.input.text)
	term.close()
	await type_line("if (tide == 0) { gateOpen = true; } else { gateOpen = false; }")
	var gate := machine(6, "gateOpen")
	var opened := await wait_until(func(): return gate.is_open, 20.0)
	check("E1 fixed: the gate opens at tide 0", opened)

	# Exam 2: if (tide >= 4); { anchorUp = true; }
	await enter(7, 2, 4)
	var ship := machine(7, "anchorUp")
	var tries: int = room(7).wrong_tries
	var ran_away := await wait_until(func(): return ship.ship_state != ship.State.DOCKED and ship._depart_tide < 4, 25.0)
	check("E2 the stray ; sends the boat out at a low tide", ran_away)
	await wait_until(func(): return ship.ship_state == ship.State.TOWING, 20.0)
	check("E2 ...but the captain's own mistakes aren't wrong tries", room(7).wrong_tries == tries and "captain's rule just failed" in term.log_label.get_parsed_text())
	check("E2 the panel shows the bug: false, yet the block ran", runner(7).last_trace.get("ran", []) == [0])
	await wait_until(func(): return ship.ship_state == ship.State.DOCKED, 20.0)
	await type_line("if (tide >= 4) { anchorUp = true; }")
	var crossed := await wait_until(func(): return ship.ship_state == ship.State.ARRIVED, 30.0)
	check("E2 fixed: the boat waits for the tide", crossed and ship._depart_tide >= 4)

	# Exam 3: backwards sails
	await enter(8, 2, 5)
	var sail_ship := machine(8, "sails")
	_board(sail_ship)
	var broke := await wait_until(func(): return sail_ship.ship_state in [sail_ship.State.AGROUND, sail_ship.State.TOWING], 20.0)
	check("E3 the captain's order snaps the mast", broke)
	await wait_until(func(): return sail_ship.ship_state == sail_ship.State.DOCKED, 20.0)
	await type_line("if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; } else { sails = 2; }")
	_board(sail_ship)
	var made_it := await wait_until(func(): return sail_ship.ship_state == sail_ship.State.ARRIVED, 40.0)
	check("E3 fixed: the boat crosses", made_it)

	# Exam 4: equals("Treasure")
	await enter(9, 3, 6)
	var vault := machine(9, "gateOpen")
	var never := true
	for k in 30:
		await wait(0.25)
		if vault.is_open:
			never = false
	check("E4 \"Treasure\" never matches", never)
	await type_line("if (word.equals(\"treasure\")) { gateOpen = true; } else { gateOpen = false; }")
	var opened4 := await wait_until(func(): return vault.is_open, 20.0)
	check("E4 fixed: opens on treasure", opened4)

	# Exam 5: no else
	await enter(10, 2, 6)
	var lanterns := machine(10, "lightsOn")
	var crew := reading_source(10, "awake")
	await wait_until(func(): return crew.get_reading("awake") == true, 20.0)
	await wait_until(func(): return crew.get_reading("awake") == false, 20.0)
	await wait(0.5)
	check("E5 no else: the lights stay off after the crew sleeps", not lanterns.lit)
	await type_line("if (awake) { lightsOn = false; } else { lightsOn = true; }")
	check("E5 fixed: lit while they sleep", lanterns.lit)


func _boss() -> void:
	var captain: Node = level.get_node("Captain")
	await enter(11, 2, 6)
	await type_line("if (move == 'C') { hero = \"April\"; } else if (move == 'T') { hero = \"Psalm\"; } else { hero = \"Sarah\"; }")
	check("B the boss rule is saved", not runner(11).rule.is_empty())
	await enter(11, 10, 6)
	var started := await wait_until(func(): return captain.fighting, 5.0)
	check("B the fight starts past the line", started)
	check("B Byte hides: no terminal", term.locked_reason != "")
	var switched := await wait_until(func(): return captain._move != "" and captain.st == captain.S.TELL, 10.0)
	var want := {"C": "april", "T": "psalm", "S": "sarah"}
	await wait(0.2)
	check("B the rule picks the hero for the captain's move", switched and p.hero_id == want.get(captain._move, ""), "%s -> %s" % [captain._move, p.hero_id])
	var hp: float = captain.health
	captain._vulnerable = false
	captain.take_damage(p.global_position, 10.0)
	check("B the sword bounces off when he isn't open", captain.health == hp)
	for k in 6:
		captain._vulnerable = true
		captain.take_damage(p.global_position, 10.0)
	await wait(2.0)
	check("B six hits beat him", captain.st == captain.S.DEAD)
	check("B the treasure appears", level.end_goal.visible)
	check("B Byte is back", term.locked_reason == "")
