extends SceneTree
## Builds scenes/levels/level2/level2.tscn from the room maps below (see docs/level2_design.md).
## Run:  godot --headless --path . --script res://tools/build_level2.gd
## WARNING: this overwrites level2.tscn (and resources/tilesets/level2_tileset.tres). Change
## the maps here and re-run, rather than editing the scene by hand.
##
## Treasure Hunters tiles are 32 x 32 and drawn at full size (one screen = 20 x 11 tiles).
## Each room is a text map of its inside, one character per tile. Rooms are placed left to
## right with a 1-tile wall between them, moved up or down so the `>` doorway rows of one room
## line up with the `<` rows of the next. Everything outside the rooms is solid rock (island
## rooms) or brick (ship rooms), painted with the right edge and corner pieces automatically.

const OUT := "res://scenes/levels/level2/level2.tscn"
const TILESET_OUT := "res://resources/tilesets/level2_tileset.tres"
const T := 32
const ISLAND_TEX := "res://assets/level2_treasure_hunters/tiles/island_terrain_32x32.png"
const SHIP_TEX := "res://assets/level2_treasure_hunters/tiles/ship_terrain_and_backwall_32x32.png"
const PLANK_TEX := "res://assets/level2_treasure_hunters/tiles/ship_platforms_32x32.png"
const BACKWALL := Vector2i(2, 8)  ## Plain back wall in the ship sheet.

## Map legend
##   .  air            #  ground             =  plank (jump up through it)
##   c  coin           K  checkpoint flag    h  manual chest       p  potion
##   ^  spikes         x  pit spikes (back to the checkpoint)
##   _  low beam: solid top 14 px of the tile, so only tiny Psalm fits under it
##   L  falling plank (only Kervin's sprint makes it)
##   < >  doorway rows (first / last column)
## Any other character is an anchor: the room's code in _build() puts something there.

# Room 0 - the two doors: beach, wall-jump shaft (Chelzy), the captain's doors on the plateau.
# 1 / 2 = the left / right door, l = arrive in the closet, b = closet's way back,
# r = arrive by the exit, d = way back.
const R0 := [
	".........#.........#......",
	".........#.........#.....>",
	".........#.........#drcc.>",
	".blc.c.C.#.........#######",
	"############.......c......",
	"..........##...K.1....2...",
	"..........##..############",
	"..c.c.c...##..############",
	"..............############",
	".s.h...C......############",
	"##########################",
	"##########################",
]

# Room 1 - the reef: the ship waits for tide 4+ (anchor rule), April double-jumps to the far shore.
const R1 := [
	"..............................",
	"<.............................",
	"<K...........................>",
	"###...................c...Q..>",
	"###.hT................########",
	"#######...c.c...c.c...########",
	"#######...............########",
	"#######...............########",
	"#######.S....###......########",
	"#######......###......########",
	"##############################",
	"##############################",
]

# Room 2 - the tide locks: gates shut at high tide (else!), totems, Psalm's beam, stairs out.
const R2 := [
	"......#####################.....",
	"......#####################.....",
	"<.....#####################....>",
	"<K.T..#####################....>",
	"####..#####################..###",
	"####..#####################==...",
	"####..#####################..==.",
	"####........#........#..###==...",
	"####..c..c.....c..c.....###c.==.",
	"####....c..VGU...c...G.c___==...",
	"################################",
	"################################",
]

# Room 3 - the storm: sail across with an else-if rule for the sails.
const R3 := [
	"........................................",
	"........................................",
	"<.......................................",
	"<K.hW..................................>",
	"######....c...c...c...c...c...c......P.>",
	"######.S...........................#####",
	"######.............................#####",
	"######.............................#####",
	"######.............................#####",
	"########################################",
	"########################################",
	"########################################",
]

# Room 4 - the password: falling gangplank (Kervin), the lookout, the boarding gate, the cannon.
const R4 := [
	"..........#.................",
	"..........#.................",
	"..........#...O.............",
	"<..######.....===..........>",
	"<Kh..c....GA..c....F....c.p>",
	"###LLLLLL###################",
	"###......###################",
	"###......###################",
	"###......###################",
	"###......###################",
	"############################",
	"############################",
]

# Room 5 - the sleeping crew: lanterns (l), crew (z), Sarah's dash over the bilge trench.
const R5 := [
	"############################",
	"############################",
	"############################",
	"<..........................>",
	"<K....l......l......l.....p>",
	"###.....................####",
	"###.........#######..==.####",
	"###....................=####",
	"###.z.c.^^.z.c...c...==.####",
	"##############xxx###########",
	"############################",
	"############################",
]

# Exam 1 - the stuck gate: if (tide = 0).
const E1 := [
	"............#.....",
	"............#.....",
	"............#.....",
	"<................>",
	"<Kh.T......c.G..c>",
	"##################",
	"##################",
	"##################",
	"##################",
	"##################",
	"##################",
	"##################",
]

# Exam 2 - the runaway boat: if (tide >= 4); { anchorUp = true; }
const E2 := [
	"......................",
	"......................",
	"......................",
	"<.....................",
	"<K.T.................>",
	"#####.S..........c...>",
	"#####............#####",
	"#####............#####",
	"#####.....##.....#####",
	"#####.....##.....#####",
	"######################",
	"######################",
]

# Exam 3 - the backwards sails.
const E3 := [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"<.............................",
	"<K.W.....c...c...c...c.......>",
	"#####.S...................c..>",
	"#####.....................####",
	"#####.....................####",
	"#####.....................####",
	"##############################",
	"##############################",
]

# Exam 4 - the vault: equals("Treasure").
const E4 := [
	"...........#......",
	"...........#......",
	"...........#......",
	".....O.....#......",
	"....===....#......",
	"<................>",
	"<K....c....G..c..>",
	"##################",
	"##################",
	"##################",
	"##################",
	"##################",
]

# Exam 5 - the dark cave: if (awake) { lightsOn = false; } with no else.
const E5 := [
	"####################",
	"####################",
	"####################",
	"....................",
	"...l.....l.....l....",
	"<..................>",
	"<K..z..^^..z...^^.c>",
	"####################",
	"####################",
	"####################",
	"####################",
	"####################",
]

# Exam 6 - Captain Clown Nose. X = the captain, g = the treasure (appears when he's beaten).
const E6 := [
	".......#..................",
	".......#..................",
	".......#..................",
	".......#..................",
	".......#..................",
	"<.........................",
	"<K................X...g...",
	"##########################",
	"##########################",
	"##########################",
	"##########################",
	"##########################",
]

## style: "island" or "ship"; music: Sound track; manual: chest manual id (for h).
const ROOMS := [
	{"map": R0, "style": "island", "manual": "if_else"},
	{"map": R1, "style": "island", "manual": "comparing"},
	{"map": R2, "style": "island"},
	{"map": R3, "style": "island", "manual": "else_if"},
	{"map": R4, "style": "ship", "manual": "strings_booleans"},
	{"map": R5, "style": "ship"},
	{"map": E1, "style": "island", "manual": "fixing_bugs", "music": "final_exam"},
	{"map": E2, "style": "island", "music": "final_exam"},
	{"map": E3, "style": "island", "music": "final_exam"},
	{"map": E4, "style": "island", "music": "final_exam"},
	{"map": E5, "style": "ship", "music": "final_exam"},
	{"map": E6, "style": "island", "music": "final_exam"},
]

const SCENES := {
	"player": "res://scenes/player/player.tscn",
	"byte": "res://scenes/byte/byte.tscn",
	"hud": "res://scenes/ui/hud/hud.tscn",
	"pause": "res://scenes/ui/pause_menu.tscn",
	"terminal": "res://scenes/ui/code_terminal.tscn",
	"hotbar": "res://scenes/ui/hotbar.tscn",
	"reader": "res://scenes/ui/manual_reader.tscn",
	"chest_window": "res://scenes/ui/chest_window.tscn",
	"goal": "res://scenes/objects/end_goal.tscn",
	"chest": "res://scenes/objects/manual_chest.tscn",
	"checkpoint": "res://scenes/objects/checkpoint.tscn",
	"room": "res://scenes/levels/room.tscn",
	"falling": "res://scenes/gadgets/falling_platform.tscn",
	"spikes": "res://scenes/gadgets/spikes.tscn",
	"potion": "res://scenes/objects/health_potion.tscn",
	"crab": "res://scenes/enemies/crabby.tscn",
}
const L2 := "res://scripts/level2/"
const ALL_VARIABLES: Array[String] = ["hero", "hasSword", "key", "tide", "wind", "word", "awake", "move",
	"distance", "coins", "coinsLeft", "leftDoorOpen", "rightDoorOpen", "doorOpen", "anchorUp", "gateOpen",
	"sails", "lightsOn"]

var level: Node2D
var grids: Array[Dictionary] = []  # per room: local Vector2i -> map character
var sizes: Array[Vector2i] = []
var origins: Array[Vector2i] = []  # absolute tile of each map's top-left
var anchors: Array[Dictionary] = []  # per room: character -> absolute cells (reading order)
var interior := {}  # absolute cell -> room index (inside a room or its doorway)
var solid := {}  # absolute cell -> style
var room_nodes: Array = []
var bounds := Rect2i()
var f := 0


func _process(_d: float) -> bool:
	f += 1
	if f == 2:
		_build()
		return true
	return false


func _build() -> void:
	if not _read_maps():
		quit(1)
		return
	_place_rooms()
	level = Node2D.new()
	level.name = "Level2"
	level.set_script(load(L2 + "level2.gd"))
	level.set("level_id", "level2")
	level.set("level_title", "LEVEL 2 - CONDITIONALS")
	level.set("level_number", 2)
	level.set("camera_top_margin", 0.0)
	var heroes: Array[String] = ["chelzy", "sarah", "april", "kervin", "psalm"]
	level.set("starting_heroes", heroes)

	var bg := CanvasLayer.new()
	bg.name = "Background"
	bg.set_script(load(L2 + "background.gd"))
	_add(bg)
	var tileset := _make_tileset()
	var backwall := TileMapLayer.new()
	backwall.name = "Backwall"
	backwall.tile_set = tileset
	_add(backwall)
	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = tileset
	_paint(terrain, backwall)
	_add(terrain)

	var rooms := _group("Rooms")
	var things := _group("Things")
	var coins := _group("Coins")
	var traps := _group("Traps")
	var flags := _group("Checkpoints")
	var signs := _group("Signs")

	# ---------------- Room 0: the two doors ----------------
	_room(rooms, 0, "THE TWO DOORS",
		"The doors follow the captain's rule: if key is 7 the right door opens, otherwise the left one does. Make an int called key and store 7 in it. Coins are behind both doors, so try another number too.",
		"int key = _;", "int key = 7;")
	_runner(0, "Doors", "if (key == 7) { rightDoorOpen = true; } else { leftDoorOpen = true; }", {
		"locked": true, "machine_vars": ["leftDoorOpen", "rightDoorOpen"], "trigger_text": "every time key changes",
		"locked_message": "These doors follow the captain's rule - you can't change it. Change key instead!"})
	_door(things, _a(0, "1"), "leftDoorOpen", "portal", _foot(_a(0, "l")) + Vector2(0, -16))
	_door(things, _a(0, "2"), "rightDoorOpen", "portal", _foot(_a(0, "r")) + Vector2(0, -16))
	_door(things, _a(0, "b"), "", "portal", _foot(_a(0, "1")) + Vector2(-24, -16), true)
	_door(things, _a(0, "d"), "", "portal", _foot(_a(0, "2")) + Vector2(-24, -16), true)
	for cell in anchors[0].get("C", []):
		_inst("crab", traps, _foot(cell), {"patrol_left": -48.0, "patrol_right": 48.0})
	_sign(signs, 0, 10, 8, "ONLY A WALL JUMP\nCLIMBS THIS")
	_sign(signs, 0, 13, 6, "THE CAPTAIN'S DOORS\nCOINS BEHIND BOTH!\nW: GO THROUGH")
	_exit_door(things, 0, "if (coins >= %d) { doorOpen = true; }")

	# ---------------- Room 1: the reef ----------------
	_room(rooms, 1, "THE REEF",
		"The reef needs a tide of 4 or more. The anchor is a machine, so give it a rule: if the tide is 4 or more, anchorUp is true. Get on the ship and wait. At the far shore, April's double jump reaches the high dock.",
		"if (tide >= _) { anchorUp = ____; }", "if (tide >= 4) { anchorUp = true; }")
	_runner(1, "Anchor", "", {"machine_vars": ["anchorUp"], "reading_names": ["tide"], "trigger_text": "every time the tide changes"})
	_tide(things, _a(1, "T"), [0, 1, 2, 3, 4, 5, 4, 3, 2, 1], 1.5)
	_water(things, 1, 7, 22, 9, "tide", 64.0)
	_ship(things, _a(1, "S"), "anchor", Vector2(11.5 * T, 0), 0.5)
	_shooter(traps, _a(1, "Q"), "seashell", -1, 2.6)
	_sign(signs, 1, 7, 6, "THE REEF:\nTIDE 4 OR MORE")
	_exit_door(things, 1, "if (coins == %d) { doorOpen = true; }")

	# ---------------- Room 2: the tide locks ----------------
	_room(rooms, 2, "THE TIDE LOCKS",
		"At high tide (3 or more) an open gate floods the cave, but shut gates keep you stuck. The rule must say what to do both ways: if the tide is 3 or more the gates shut, else they open.",
		"if (tide >= _) { gateOpen = _____; } else { gateOpen = ____; }",
		"if (tide >= 3) { gateOpen = false; } else { gateOpen = true; }")
	_runner(2, "Gates", "", {"machine_vars": ["gateOpen"], "reading_names": ["tide"], "trigger_text": "every time the tide changes"})
	_tide(things, _a(2, "T"), [0, 1, 2, 3, 4, 5, 4, 3, 2, 1], 1.5)
	for cell in anchors[2].get("G", []):
		_door(things, cell, "gateOpen", "block", Vector2.ZERO)
	_water(things, 2, 4, 30, 10, "flood", 0.0, 28.0)
	_shooter(traps, _a(2, "U"), "totem", 1, 2.2)
	_shooter(traps, _a(2, "V"), "totem", -1, 2.6, 1.0)
	_sign(signs, 2, 6, 7, "HIGH TIDE - 3 OR MORE -\nFLOODS AN OPEN CAVE")
	_exit_door(things, 2, "if (coinsLeft == 0) { doorOpen = true; }")

	# ---------------- Room 3: the storm ----------------
	_room(rooms, 3, "THE STORM",
		"Turn the sailor's table into one rule, biggest wind first: if wind >= 7 the sails are 0, else if wind >= 3 they are 1, else 2. Then get on board.",
		"if (wind >= _) { sails = _; } else if (wind >= _) { sails = _; } else { sails = _; }",
		"if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; } else { sails = 2; }")
	_runner(3, "Sails", "", {"machine_vars": ["sails"], "reading_names": ["wind"], "trigger_text": "every time the wind changes"})
	_wind(things, _a(3, "W"), [1, 5, 8, 2, 6, 9, 3, 0, 7, 4])
	_water(things, 3, 6, 35, 6, "fixed", 160.0)
	_ship(things, _a(3, "S"), "sail", Vector2(26.0 * T, 0), 0.0)
	_enemy(traps, _a(3, "P"), "pink_star", 32.0)
	_sign(signs, 3, 6, 0, "SAILOR'S TABLE\nWIND 7-9: SAILS 0\nWIND 3-6: SAILS 1\nWIND 0-2: SAILS 2")

	# ---------------- Room 4: the password ----------------
	_room(rooms, 4, "THE PASSWORD",
		"The gate may only be open when the lookout shouts ahoy. Strings are compared with .equals: if word equals \"ahoy\" the gate opens, else it shuts. Kervin sprints over the falling gangplank.",
		"if (word.equals(\"____\")) { gateOpen = ____; } else { gateOpen = _____; }",
		"if (word.equals(\"ahoy\")) { gateOpen = true; } else { gateOpen = false; }")
	_runner(4, "Gate", "", {"machine_vars": ["gateOpen"], "reading_names": ["word"], "trigger_text": "every time the lookout shouts"})
	_door(things, _a(4, "G"), "gateOpen", "block", Vector2.ZERO)
	_lookout(things, _a(4, "O"), ["avast", "ahoy", "arrr", "yo-ho", "ahoy", "avast", "arrr", "ahoy"], "ahoy")
	_shooter(traps, _a(4, "A"), "cannon", -1, 0.0, 0.0, true)
	_water(things, 4, 3, 9, 7, "fixed", 96.0)
	_enemy(traps, _a(4, "F"), "fierce_tooth", 64.0)
	_sign(signs, 4, 2, 6, "ONLY KERVIN'S SPRINT\nMAKES THE GANGPLANK")
	_exit_door(things, 4, "if (coinsLeft < 1) { doorOpen = true; }")

	# ---------------- Room 5: the sleeping crew ----------------
	_room(rooms, 5, "THE SLEEPING CREW",
		"When the crew is awake the lanterns must be off, otherwise on. awake is already true or false, so the condition is just: if (awake). Sarah's dash crosses the bilge trench.",
		"if (_____) { lightsOn = _____; } else { lightsOn = ____; }",
		"if (awake) { lightsOn = false; } else { lightsOn = true; }")
	_runner(5, "Lanterns", "", {"machine_vars": ["lightsOn"], "reading_names": ["awake"], "trigger_text": "every time the crew wakes or sleeps"})
	_crew(things, 5, 4.0)
	_lanterns(things, 5)
	_sign(signs, 5, 12, 4, "BILGE TRENCH:\nDASH!")
	_exit_door(things, 5, "if (coinsLeft != 0) { doorOpen = false; } else { doorOpen = true; }")

	# ---------------- Exam 1: the stuck gate ----------------
	_room(rooms, 6, "EXAM 1: THE STUCK GATE",
		"One = stores a value; it can't compare. The captain meant: is the tide equal to 0? Use ==.",
		"if (tide __ 0) { gateOpen = true; } else { gateOpen = false; }",
		"if (tide == 0) { gateOpen = true; } else { gateOpen = false; }")
	_runner(6, "Gate", "if (tide = 0) { gateOpen = true; } else { gateOpen = false; }", {
		"machine_vars": ["gateOpen"], "reading_names": ["tide"], "trigger_text": "every time the tide changes",
		"offer_start_rule": true})
	_tide(things, _a(6, "T"), [0, 0, 1, 2, 3, 4, 5, 5, 4, 3, 2, 1], 1.0)
	_door(things, _a(6, "G"), "gateOpen", "block", Vector2.ZERO)

	# ---------------- Exam 2: the runaway boat ----------------
	_room(rooms, 7, "EXAM 2: THE RUNAWAY BOAT",
		"The ; right after if (...) ends the if, so the { } after it always runs and the anchor comes up at any tide. Take the ; out.",
		"if (tide >= 4) { anchorUp = true; }", "if (tide >= 4) { anchorUp = true; }")
	_runner(7, "Anchor", "if (tide >= 4); { anchorUp = true; }", {
		"machine_vars": ["anchorUp"], "reading_names": ["tide"], "trigger_text": "every time the tide changes",
		"offer_start_rule": true})
	_tide(things, _a(7, "T"), [0, 1, 2, 3, 4, 5, 4, 3, 2, 1], 1.5)
	_water(things, 7, 5, 17, 9, "tide", 64.0)
	_ship(things, _a(7, "S"), "anchor", Vector2(9.0 * T, 0), 0.45)

	# ---------------- Exam 3: the backwards sails ----------------
	_room(rooms, 8, "EXAM 3: THE BACKWARDS SAILS",
		"Java checks from the top. With wind >= 3 first, a storm of 8 never reaches wind >= 7. Put the biggest number first.",
		"if (wind >= _) { sails = 0; } else if (wind >= _) { sails = 1; } else { sails = 2; }",
		"if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; } else { sails = 2; }")
	_runner(8, "Sails", "if (wind >= 3) { sails = 1; } else if (wind >= 7) { sails = 0; } else { sails = 2; }", {
		"machine_vars": ["sails"], "reading_names": ["wind"], "trigger_text": "every time the wind changes",
		"offer_start_rule": true})
	_wind(things, _a(8, "W"), [1, 8, 5, 9, 2, 6])
	_water(things, 8, 5, 26, 7, "fixed", 96.0)
	_ship(things, _a(8, "S"), "sail", Vector2(18.0 * T, 0), 0.0)

	# ---------------- Exam 4: the vault ----------------
	_room(rooms, 9, "EXAM 4: THE VAULT",
		"equals checks every letter, capitals too. Listen: the lookout shouts treasure in lowercase.",
		"if (word.equals(\"________\")) { gateOpen = true; } else { gateOpen = false; }",
		"if (word.equals(\"treasure\")) { gateOpen = true; } else { gateOpen = false; }")
	_runner(9, "Vault", "if (word.equals(\"Treasure\")) { gateOpen = true; } else { gateOpen = false; }", {
		"machine_vars": ["gateOpen"], "reading_names": ["word"], "trigger_text": "every time the lookout shouts",
		"offer_start_rule": true})
	_door(things, _a(9, "G"), "gateOpen", "block", Vector2.ZERO)
	_lookout(things, _a(9, "O"), ["gold", "treasure", "rum", "parrot", "treasure", "map"], "treasure")

	# ---------------- Exam 5: the dark cave ----------------
	_room(rooms, 10, "EXAM 5: THE DARK CAVE",
		"An if without an else never undoes its change: the lights go off and never come back. Add else { lightsOn = true; }.",
		"if (awake) { lightsOn = false; } else { lightsOn = ____; }",
		"if (awake) { lightsOn = false; } else { lightsOn = true; }")
	_runner(10, "Lanterns", "if (awake) { lightsOn = false; }", {
		"machine_vars": ["lightsOn"], "reading_names": ["awake"], "trigger_text": "every time the crew wakes or sleeps",
		"offer_start_rule": true})
	_crew(things, 10, 2.0)
	_lanterns(things, 10)

	# ---------------- Exam 6: Captain Clown Nose ----------------
	_room(rooms, 11, "EXAM 6: CAPTAIN CLOWN NOSE",
		"Byte has to hide during the fight, so leave a rule that picks the hero: 'C' charge - April jumps twice over it; 'T' thrown sword - tiny Psalm (hold Down) fits under it; 'S' swing - Sarah dashes away. Hit him while he's dizzy or unarmed.",
		"if (move == '_') { hero = \"April\"; } else if (move == '_') { hero = \"Psalm\"; } else { hero = \"_____\"; }",
		"if (move == 'C') { hero = \"April\"; } else if (move == 'T') { hero = \"Psalm\"; } else { hero = \"Sarah\"; }")
	_runner(11, "Heroes", "", {"reading_names": ["move", "distance"], "trigger_text": "every time the captain picks a move"})
	var x_cell := _a(11, "X")
	var body := CharacterBody2D.new()
	body.name = "Captain"
	body.set_script(load(L2 + "captain.gd"))
	var o := origins[11]
	body.set("arena_left", float((o.x + 8) * T))
	body.set("arena_right", float((o.x + sizes[11].x) * T))
	body.set("start_x", float((o.x + 8.5) * T))
	body.set("sign_position", Vector2((o.x + 8.3) * T, (o.y + 2.0) * T))
	body.position = _foot(x_cell)
	_add(body, level)
	var goal := _inst("goal", level, _foot(_a(11, "g")), {}, "EndGoal")
	goal.set("rooms", [] as Array[Node])

	# ---------------- Map characters ----------------
	for i in ROOMS.size():
		_place_map_things(i, coins, traps, flags, things)

	# ---------------- Start, player, Byte, UI ----------------
	var start := _foot(_a(0, "s")) + Vector2(0, -16)
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = start
	_add(spawn)
	var byte := _inst("byte", level, start + Vector2(-20, -22), {}, "Byte")
	var player := _inst("player", level, start, {}, "Player")
	byte.set("target", player)
	_inst("hud", level, Vector2.ZERO, {}, "HUD")
	var terminal := _inst("terminal", level, Vector2.ZERO, {}, "CodeTerminal")
	terminal.set("player", player)
	terminal.set("byte", byte)
	terminal.set("allowed_variables", ALL_VARIABLES)
	terminal.set("require_unlocked_heroes", true)
	var declared: Array[String] = ["hero"]
	terminal.set("start_declared", declared)
	var panel := CanvasLayer.new()
	panel.name = "RulePanel"
	panel.set_script(load("res://scripts/ui/rule_panel.gd"))
	_add(panel)
	_inst("reader", level, Vector2.ZERO, {}, "ManualReader")
	_inst("chest_window", level, Vector2.ZERO, {}, "ChestWindow")
	var hotbar := _inst("hotbar", level, Vector2.ZERO, {}, "Hotbar")
	hotbar.set("player", player)
	_inst("pause", level, Vector2.ZERO, {}, "PauseMenu")

	ResourceSaver.save(tileset, TILESET_OUT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var packed := PackedScene.new()
	print("pack: ", error_string(packed.pack(level)))
	print("save: ", error_string(ResourceSaver.save(packed, OUT)))
	for i in ROOMS.size():
		print("room %d at %s, %s tiles" % [i, origins[i], sizes[i]])
	print("coins: ", coins.get_child_count())


# ---------------- Maps -> rooms ----------------

func _read_maps() -> bool:
	var ok := true
	for i in ROOMS.size():
		var rows: Array = ROOMS[i].map
		var w: int = rows[0].length()
		var grid := {}
		for y in rows.size():
			if rows[y].length() != w:
				printerr("room %d row %d is %d long, not %d: %s" % [i, y, rows[y].length(), w, rows[y]])
				ok = false
			for x in rows[y].length():
				grid[Vector2i(x, y)] = rows[y][x]
		grids.append(grid)
		sizes.append(Vector2i(w, rows.size()))
	return ok


## Rows of room i's column x marked with `mark` (< or >).
func _door_rows(i: int, x: int, mark: String) -> Array[int]:
	var out: Array[int] = []
	for y in sizes[i].y:
		if grids[i].get(Vector2i(x, y), "") == mark:
			out.append(y)
	return out


func _place_rooms() -> void:
	var x := 0
	var y := 0
	for i in ROOMS.size():
		if i > 0:
			var prev_out := _door_rows(i - 1, sizes[i - 1].x - 1, ">")
			var my_in := _door_rows(i, 0, "<")
			if prev_out.is_empty() or my_in.is_empty() or prev_out.size() != my_in.size():
				printerr("rooms %d and %d: doorways don't match (%s / %s)" % [i - 1, i, prev_out, my_in])
			else:
				y = origins[i - 1].y + prev_out[0] - my_in[0]
		origins.append(Vector2i(x, y))
		x += sizes[i].x + 1
	# Inside cells, doorways in the wall between rooms, solid cells and anchors.
	for i in ROOMS.size():
		var o := origins[i]
		var a := {}
		for yy in sizes[i].y:
			for xx in sizes[i].x:
				var ch: String = grids[i][Vector2i(xx, yy)]
				var cell := o + Vector2i(xx, yy)
				interior[cell] = i
				if ch == "#":
					solid[cell] = ROOMS[i].style
				elif not ch in [".", "=", "c", "K", "h", "p", "^", "x", "_", "L", "<", ">"]:
					if not a.has(ch):
						a[ch] = []
					a[ch].append(cell)
		anchors.append(a)
		for yy in _door_rows(i, sizes[i].x - 1, ">"):
			interior[o + Vector2i(sizes[i].x, yy)] = i
	var r := Rect2i(origins[0], Vector2i.ONE)
	for i in ROOMS.size():
		r = r.merge(Rect2i(origins[i], sizes[i]))
	bounds = r.grow(2)
	for yy in range(bounds.position.y, bounds.end.y):
		for xx in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(xx, yy)
			if not interior.has(cell):
				solid[cell] = _style_at(xx)


func _style_at(x: int) -> String:
	for i in ROOMS.size():
		if x <= origins[i].x + sizes[i].x:
			return ROOMS[i].style
	return ROOMS[-1].style


# ---------------- Tiles ----------------

func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var full := PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
	var plank := PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, -10), Vector2(-16, -10)])
	for spec in [[ISLAND_TEX, 0, 99], [SHIP_TEX, 1, 6], [PLANK_TEX, 2, -1]]:
		var src := TileSetAtlasSource.new()
		src.texture = load(spec[0])
		src.texture_region_size = Vector2i(T, T)
		ts.add_source(src, spec[1])
		var grid: Vector2i = src.get_atlas_grid_size()
		for yy in grid.y:
			for xx in grid.x:
				var c := Vector2i(xx, yy)
				src.create_tile(c)
				var data := src.get_tile_data(c, 0)
				if spec[1] == 2:
					data.add_collision_polygon(0)
					data.set_collision_polygon_points(0, 0, plank)
					data.set_collision_polygon_one_way(0, 0, true)
				elif yy <= spec[2]:
					data.add_collision_polygon(0)
					data.set_collision_polygon_points(0, 0, full)
	return ts


func _paint(layer: TileMapLayer, backwall: TileMapLayer) -> void:
	for cell in solid:
		var base := Vector2i.ZERO if solid[cell] == "island" else Vector2i(1, 1)
		layer.set_cell(cell, 0 if solid[cell] == "island" else 1, base + _shape(cell))
	for i in ROOMS.size():
		for yy in sizes[i].y:
			for xx in sizes[i].x:
				var cell := origins[i] + Vector2i(xx, yy)
				var ch: String = grids[i][Vector2i(xx, yy)]
				if ch == "=":
					var left: bool = grids[i].get(Vector2i(xx - 1, yy), "") == "="
					var right: bool = grids[i].get(Vector2i(xx + 1, yy), "") == "="
					var col := 4 if not left and not right else (1 if not left else (3 if not right else 2))
					layer.set_cell(cell, 2, Vector2i(col, 1))
				if ROOMS[i].style == "ship" and not solid.has(cell):
					backwall.set_cell(cell, 1, BACKWALL)
		if ROOMS[i].style == "ship":
			for yy in _door_rows(i, sizes[i].x - 1, ">"):
				backwall.set_cell(origins[i] + Vector2i(sizes[i].x, yy), 1, BACKWALL)


## Which piece of the 3x3 block (plus pillars, bars and inner corners) a solid cell needs,
## from which of its neighbours are open. Same layout in the island and ship sheets.
func _shape(cell: Vector2i) -> Vector2i:
	var n := not solid.has(cell + Vector2i.UP)
	var s := not solid.has(cell + Vector2i.DOWN)
	var w := not solid.has(cell + Vector2i.LEFT)
	var e := not solid.has(cell + Vector2i.RIGHT)
	if not bounds.has_point(cell + Vector2i.UP):
		n = false
	if not bounds.has_point(cell + Vector2i.DOWN):
		s = false
	if not bounds.has_point(cell + Vector2i.LEFT):
		w = false
	if not bounds.has_point(cell + Vector2i.RIGHT):
		e = false
	if n and s and w and e:
		return Vector2i(4, 4)
	if n and s:
		return Vector2i(0 if w else (2 if e else 1), 4)
	if w and e:
		return Vector2i(4, 0 if n else (2 if s else 1))
	var col := 0 if w else (2 if e else 1)
	var row := 0 if n else (2 if s else 1)
	if col == 1 and row == 1:
		if _open(cell + Vector2i(1, 1)):
			return Vector2i(6, 0)
		if _open(cell + Vector2i(-1, 1)):
			return Vector2i(7, 0)
		if _open(cell + Vector2i(1, -1)):
			return Vector2i(6, 1)
		if _open(cell + Vector2i(-1, -1)):
			return Vector2i(7, 1)
	return Vector2i(col, row)


func _open(cell: Vector2i) -> bool:
	return bounds.has_point(cell) and not solid.has(cell)


# ---------------- Things from the map ----------------

func _place_map_things(i: int, coins: Node, traps: Node, flags: Node, things: Node) -> void:
	var o := origins[i]
	for y in sizes[i].y:
		var x := 0
		while x < sizes[i].x:
			var ch: String = grids[i].get(Vector2i(x, y), ".")
			var run := 1
			while grids[i].get(Vector2i(x + run, y), "") == ch:
				run += 1
			var c := o + Vector2i(x, y)
			match ch:
				"c":
					for k in run:
						var coin := Area2D.new()
						coin.name = "Coin"
						coin.set_script(load(L2 + "coin.gd"))
						coin.position = _px(c.x + k + 0.5, c.y + 0.5)
						_add(coin, coins)
				"^", "x":
					_inst("spikes", traps, _px(c.x, c.y + 1), {"count": run * 2, "send_to_checkpoint": ch == "x"})
				"L":
					for k in run:
						_inst("falling", things, Vector2((c.x + k + 0.5) * T, c.y * T + 3), {"fall_delay": 0.14, "return_time": 2.0})
				"_":
					for k in run:
						_beam(things, c + Vector2i(k, 0))
				"K":
					_inst("checkpoint", flags, _foot(c), {})
				"h":
					_inst("chest", things, _foot(c), {"manual_id": ROOMS[i].get("manual", "if_else")})
				"p":
					_inst("potion", things, _foot(c))
			x += run


## A wooden beam filling the top 14 px of the cell: only tiny Psalm fits under it.
func _beam(parent: Node, cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.name = "Beam"
	body.collision_layer = 1
	body.position = _px(cell.x + 0.5, cell.y + 7.0 / T)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(T, 14)
	shape.shape = rect
	body.add_child(shape)
	var art := Sprite2D.new()
	art.texture = load(PLANK_TEX)
	art.region_enabled = true
	art.region_rect = Rect2(64, 64, 32, 14)
	body.add_child(art)
	_add(body, parent)


# ---------------- Helpers for the rooms ----------------

## A Room node covering room i and its right-hand wall (where its exit door stands).
func _room(parent: Node, i: int, title: String, hint: String, blanks: String, answer: String) -> void:
	var size := Vector2(sizes[i].x + 1, sizes[i].y) * T
	var node := _inst("room", parent, Vector2(origins[i]) * T + size / 2.0, {
		"size": size, "title": title, "hint": hint, "blanks": blanks, "answer": answer,
		"music": ROOMS[i].get("music", "rooms")})
	node.name = "Room%d_%s" % [i, title.get_slice(":", title.count(":")).strip_edges().replace(" ", "_").replace("'", "")]
	room_nodes.append(node)


func _runner(i: int, node_name: String, start_rule: String, props: Dictionary) -> Node:
	var r := Node.new()
	r.name = "Rule" + node_name
	r.set_script(load("res://scripts/levels/rule_runner.gd"))
	r.set("start_rule", start_rule)
	for k in props:
		if k in ["machine_vars", "reading_names"]:
			var arr: Array[String] = []
			arr.assign(props[k])
			r.set(k, arr)
		else:
			r.set(k, props[k])
	_add(r, room_nodes[i])
	return r


## The room's exit: crates in the > doorway that follow a locked captain's rule. `rule` may
## have %d for the number of coins in the room.
func _exit_door(parent: Node, i: int, rule: String) -> void:
	var count := 0
	for y in sizes[i].y:
		for x in sizes[i].x:
			if grids[i][Vector2i(x, y)] == "c":
				count += 1
	var text := rule % count if "%d" in rule else rule
	_runner(i, "ExitDoor", text, {"locked": true, "machine_vars": ["doorOpen"], "on_panel": false})
	var rows := _door_rows(i, sizes[i].x - 1, ">")
	var door := Node2D.new()
	door.name = "ExitDoor"
	door.set_script(load(L2 + "pirate_door.gd"))
	door.set("size", Vector2(32, rows.size() * T))
	door.position = _px(origins[i].x + sizes[i].x + 0.5, origins[i].y + rows[-1] + 1)
	_add(door, parent)


func _door(parent: Node, cell: Vector2i, variable: String, kind: String, target: Vector2, always_open := false) -> void:
	var door := Node2D.new()
	door.name = "Door"
	door.set_script(load(L2 + "code_door.gd"))
	var vars: Array[String] = []
	if variable != "":
		vars.append(variable)
	door.set("variables", vars)
	door.set("kind", kind)
	door.set("target", target)
	door.set("start_open", always_open)
	door.set("size", Vector2(32, 64) if kind == "block" else Vector2(32, 48))
	door.position = _foot(cell)
	_add(door, parent)


func _tide(parent: Node, cell: Vector2i, pattern: Array, step: float) -> void:
	var n := Node2D.new()
	n.name = "TidePost"
	n.set_script(load(L2 + "tide.gd"))
	var p: Array[int] = []
	p.assign(pattern)
	n.set("pattern", p)
	n.set("step_time", step)
	n.position = _foot(cell)
	_add(n, parent)


func _wind(parent: Node, cell: Vector2i, pattern: Array) -> void:
	var n := Node2D.new()
	n.name = "WindVane"
	n.set_script(load(L2 + "wind.gd"))
	var p: Array[int] = []
	p.assign(pattern)
	n.set("pattern", p)
	n.position = _foot(cell)
	_add(n, parent)


## Water in room i from column x0 to x1 (map columns), lowest surface at the top of map row y.
func _water(parent: Node, i: int, x0: int, x1: int, y: int, mode: String, depth: float, rise := 16.0) -> void:
	var n := Node2D.new()
	n.name = "Water"
	n.set_script(load(L2 + "water.gd"))
	n.set("mode", mode)
	n.set("width", float((x1 - x0) * T))
	n.set("depth", depth)
	n.set("rise", rise)
	n.position = _px(origins[i].x + x0, origins[i].y + y)
	_add(n, parent)


func _ship(parent: Node, cell: Vector2i, mode: String, trip: Vector2, reef_at: float) -> void:
	var n := Node2D.new()
	n.name = "Ship"
	n.set_script(load(L2 + "ship.gd"))
	n.set("mode", mode)
	n.set("trip", trip)
	n.set("reef_at", reef_at)
	n.position = _px(cell.x + 0.5, cell.y + 0.5)
	_add(n, parent)


func _shooter(parent: Node, cell: Vector2i, kind: String, direction: int, interval: float, delay := 0.0, on_call := false) -> void:
	var n := Node2D.new()
	n.name = kind.capitalize()
	n.set_script(load(L2 + "shooter.gd"))
	n.set("kind", kind)
	n.set("direction", direction)
	n.set("interval", interval)
	n.set("delay", delay)
	n.set("on_call", on_call)
	if on_call:
		n.set("to_checkpoint", true)
		n.set("speed", 220.0)
		n.set("reach", 420.0)
	var lift := {"seashell": 19.0, "totem": 24.0, "cannon": 30.0}
	n.position = _foot(cell) + Vector2(0, -lift[kind])
	_add(n, parent)


func _lookout(parent: Node, cell: Vector2i, words: Array, password: String) -> void:
	var n := Node2D.new()
	n.name = "Lookout"
	n.set_script(load(L2 + "lookout.gd"))
	var w: Array[String] = []
	w.assign(words)
	n.set("words", w)
	n.set("password", password)
	n.position = _foot(cell)
	_add(n, parent)


func _crew(parent: Node, i: int, first_sleep: float) -> void:
	var cells: Array = anchors[i].get("z", [])
	var n := Node2D.new()
	n.name = "Crew"
	n.set_script(load(L2 + "crew.gd"))
	n.position = _foot(cells[0])
	var spots: Array[Vector2] = []
	for cell in cells:
		spots.append(_foot(cell) - n.position)
	n.set("spots", spots)
	n.set("first_sleep", first_sleep)
	_add(n, parent)


func _lanterns(parent: Node, i: int) -> void:
	var cells: Array = anchors[i].get("l", [])
	var n := Node2D.new()
	n.name = "Lanterns"
	n.set_script(load(L2 + "lanterns.gd"))
	n.position = _px(cells[0].x + 0.5, cells[0].y + 0.5)
	var spots: Array[Vector2] = []
	for cell in cells:
		spots.append(_px(cell.x + 0.5, cell.y + 0.5) - n.position)
	n.set("spots", spots)
	_add(n, parent)


func _enemy(parent: Node, cell: Vector2i, kind: String, patrol: float) -> void:
	_inst("crab", parent, _foot(cell), {
		"frames": load("res://assets/level2_treasure_hunters/enemies/%s/%s_frames.tres" % [kind, kind]),
		"patrol_left": -patrol, "patrol_right": patrol})


func _a(i: int, ch: String, n := 0) -> Vector2i:
	if not anchors[i].has(ch) or anchors[i][ch].size() <= n:
		printerr("room %d has no anchor '%s' #%d" % [i, ch, n])
		return Vector2i.ZERO
	return anchors[i][ch][n]


func _px(c: float, r: float) -> Vector2:
	return Vector2(c * T, r * T)


## Bottom-middle of a cell: where something standing in that cell touches the ground.
func _foot(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * T, (cell.y + 1) * T)


## Adds `node` (and everything under it) to the saved scene.
func _add(node: Node, parent: Node = null) -> Node:
	(parent if parent else level).add_child(node)
	_own(node)
	return node


func _own(node: Node) -> void:
	node.owner = level
	for child in node.get_children():
		if child.owner == null:
			_own(child)


func _group(group_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = group_name
	return _add(n)


func _inst(key: String, parent: Node, pos: Vector2, props := {}, node_name := "") -> Node:
	var n: Node = load(SCENES[key]).instantiate()
	if node_name != "":
		n.name = node_name
	for k in props:
		n.set(k, props[k])
	if n is Node2D:
		n.position = pos
	(parent if parent else level).add_child(n)
	n.owner = level
	return n


## A sign at tile (c, r) of room i's map.
func _sign(parent: Node, i: int, c: int, r: int, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = _px(origins[i].x + c, origins[i].y + r) + Vector2(4, 4)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	l.add_theme_color_override("font_shadow_color", Color(0.129, 0.122, 0.188, 1))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	_add(l, parent)
