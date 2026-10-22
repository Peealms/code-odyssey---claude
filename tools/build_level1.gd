extends SceneTree
## Builds scenes/levels/level1/level1.tscn from the layout below (see docs/level1_design.md).
## Run:  godot --headless --path . --script res://tools/build_level1.gd
## WARNING: this overwrites level1.tscn. Change the layout here and re-run, rather than
## editing the scene by hand (or stop using this script once the level is final).
##
## Style follows Pixel Frog's Pixel Adventure demo: every room is a closed box with a frame,
## its own ground colour, background and decorations, joined to the next room by a doorway,
## and full of traps (saws, Rock/Spike Heads, spiked balls, fire) and fruit.
## Fruit matters: rescue flags (rooms 0-2) and exit doors (rooms 3-6) need all of a room's fruit,
## so the optional fruit corners are worth doing. Trampolines and elevators only lead to those
## corners - never past a puzzle.
## Coordinates are in tiles (16 px): column c, row r. Room interiors are rows 1-21, most floors
## are at row 19, and the frame's bottom (row 22) is where pit spikes sit.

const OUT := "res://scenes/levels/level1/level1.tscn"
const T := 16
const BOTTOM := 21  ## Last interior row.

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
	"fruit": "res://scenes/objects/fruit.tscn",
	"chest": "res://scenes/objects/manual_chest.tscn",
	"checkpoint": "res://scenes/objects/checkpoint.tscn",
	"room": "res://scenes/levels/room.tscn",
	"gate": "res://scenes/gadgets/byte_gate.tscn",
	"bridge": "res://scenes/gadgets/code_bridge.tscn",
	"fan": "res://scenes/gadgets/code_fan.tscn",
	"path": "res://scenes/gadgets/path_platform.tscn",
	"falling": "res://scenes/gadgets/falling_platform.tscn",
	"spikes": "res://scenes/gadgets/spikes.tscn",
	"saw": "res://scenes/gadgets/saw.tscn",
	"rock_head": "res://scenes/gadgets/rock_head.tscn",
	"spike_head": "res://scenes/gadgets/spike_head.tscn",
	"ball": "res://scenes/gadgets/spiked_ball.tscn",
	"trampoline": "res://scenes/gadgets/trampoline.tscn",
	"fire": "res://scenes/gadgets/fire_trap.tscn",
	"fruit_door": "res://scenes/gadgets/fruit_door.tscn",
}

# ---- Tile sheet (assets/level1_pixel_adventure/tiles/terrain_16x16.png) ----
## Room frames: 3x3 block (edges + dark fill) at `base`, inside-corner pieces at base + (3, 0).
const FRAMES := {"stone": Vector2i(0, 0), "wood": Vector2i(0, 4), "teal": Vector2i(0, 8)}
## Ground with a coloured top: 3x3 block at `base`.
const GROUNDS := {"grass": Vector2i(6, 0), "orange": Vector2i(6, 4), "pink": Vector2i(6, 8), "brick": Vector2i(17, 4)}
## Decoration blocks: single 1x1 and the top-left of a 2x2.
const DECO := {
	"pyramid": [Vector2i(12, 1), Vector2i(13, 1)],
	"metal": [Vector2i(12, 5), Vector2i(13, 5)],
	"box": [Vector2i(12, 9), Vector2i(13, 9)],
	"gold": [Vector2i(17, 9), Vector2i(18, 9)],
}
## Thin floating bars you can jump up through: row of the 3-tile bar (left, middle, right).
const BARS := {"yellow": 0, "wood": 1, "grey": 2}

## One entry per room: interior columns, frame, ground top, background, decoration, bar colour.
const ROOMS := [
	{"c0": 1, "c1": 39, "frame": "stone", "ground": "grass", "bg": "green", "deco": "pyramid", "bar": "wood"},
	{"c0": 42, "c1": 79, "frame": "wood", "ground": "orange", "bg": "yellow", "deco": "box", "bar": "yellow"},
	{"c0": 82, "c1": 119, "frame": "teal", "ground": "pink", "bg": "purple", "deco": "gold", "bar": "grey"},
	{"c0": 122, "c1": 169, "frame": "stone", "ground": "grass", "bg": "blue", "deco": "metal", "bar": "wood"},
	{"c0": 172, "c1": 209, "frame": "wood", "ground": "orange", "bg": "brown", "deco": "pyramid", "bar": "yellow"},
	{"c0": 212, "c1": 249, "frame": "teal", "ground": "pink", "bg": "gray", "deco": "gold", "bar": "grey"},
	{"c0": 252, "c1": 299, "frame": "stone", "ground": "orange", "bg": "pink", "deco": "box", "bar": "wood"},
]
## Doorways through the 2-tile walls between rooms: wall columns and the open rows.
const DOORS := [
	{"c": 40, "r0": 6, "r1": 8},    # R0 plateau -> R1
	{"c": 80, "r0": 6, "r1": 8},    # R1 -> drop into R2
	{"c": 120, "r0": 11, "r1": 13}, # R2 step -> R3
	{"c": 170, "r0": 4, "r1": 6},   # R3 ledge -> drop into R4 (fruit door)
	{"c": 210, "r0": 2, "r1": 4},   # R4 ledge -> R5 (fruit door)
	{"c": 250, "r0": 4, "r1": 6},   # R5 exit -> drop into R6 (fruit door)
]

var level: Node2D
var interior := {}  # Vector2i -> room index (open space, incl. doorways)
var solid := {}  # Vector2i -> {"kind": "ground"/"tile", ...}
var room_nodes: Array[Node] = []
var f := 0


func _process(_d: float) -> bool:
	f += 1
	if f == 2:
		_build()
		return true
	return false


func _build() -> void:
	level = Node2D.new()
	level.name = "Level1"
	level.set_script(load("res://scripts/levels/level.gd"))
	level.set("level_id", "level1")
	level.set("level_title", "LEVEL 1 - VARIABLES")
	level.set("level_number", 1)
	level.set("camera_top_margin", 0.0)
	var heroes: Array[String] = ["ninja_frog"]
	level.set("starting_heroes", heroes)

	_carve_rooms()
	_layout()
	var fader := CanvasLayer.new()
	fader.name = "BackgroundFader"
	fader.set_script(load("res://scripts/levels/background_fader.gd"))
	_add(fader)
	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = load("res://resources/tilesets/level1_terrain_tileset.tres")
	_paint(terrain)
	_add(terrain)

	var signs := _group("Signs")
	var fruits := _group("Fruits")
	var gadgets := _group("Gadgets")
	var traps := _group("Traps")
	var chests := _group("Chests")
	var rooms := _group("Rooms")
	var flags := _group("Checkpoints")

	# ---------------- Room 0: Wake-up (Ninja Frog only) ----------------
	_room(rooms, 0, "WAKE UP",
		"Byte's gate opens when you print something. Use System.out.println with your message in double quotes.",
		"System.out.println(\"_____\");", "System.out.println(\"Hello Byte\");")
	_chest(chests, 7, 19, "variables_101")
	_inst("gate", gadgets, _px(16.5, 19), {"height": 3})
	_sign(signs, 3, 3, "BYTE'S GATE: PRINT\nA MESSAGE TO OPEN IT")
	_sign(signs, 19, 6, "ONLY A WALL JUMP\nCLIMBS THIS SHAFT")
	# Optional: trampoline up to a shelf against the gate wall
	_inst("trampoline", traps, _px(9.5, 19), {"bounce_speed": 560.0})
	_fruit_row(fruits, 3, 6, 15, "apple")  # on the low bar
	_fruit_row(fruits, 10, 13, 8, "melon")  # on the high shelf
	# Saw sliding between the gate and the shaft
	_inst("saw", traps, _px(19.5, 18), {"travel": Vector2(64, 0), "speed": 50.0})
	_fruit_row(fruits, 19, 22, 17, "bananas")
	_fruit_column(fruits, 26, 10, 16, "kiwi")  # inside the wall-jump shaft
	# Plateau: swinging spiked ball and a fire block before the flag
	_inst("ball", traps, _px(33, 1), {"length": 100.0, "swing_degrees": 40.0, "period": 2.6})  # stays clear of the shaft and the flag
	_inst("fire", traps, _px(29.5, 9), {"phase": 0.4})
	_fruit_row(fruits, 31, 34, 8, "cherries")
	_flag(flags, 36, 9, "pink_man", 0)

	# ---------------- Room 1: The wide gap (needs Pink Man) ----------------
	_room(rooms, 1, "THE WIDE GAP",
		"Only Pink Man's dash crosses this gap: jump, then press Shift in the air. Store his name in a String called hero.",
		"String hero = \"_______\";", "String hero = \"PinkMan\";")
	_sign(signs, 43, 3, "TOO WIDE TO JUMP!\nPINK MAN CAN DASH")
	_inst("ball", traps, _px(46.5, 1), {"length": 104.0, "swing_degrees": 50.0, "period": 2.2})
	_wall_spikes(traps, 60, 10, 16)  # far wall of the gap: no wall-climbing across
	_pit_spikes(traps, 52, 59)
	_fruit_row(fruits, 53, 58, 7, "orange")  # an arc to grab mid-dash
	# Landing: a Spike Head patrolling the ground, fire before the flag
	_inst("spike_head", traps, _px(62.5, 8), {"travel": Vector2(80, 0), "wait_time": 1.0})
	_fruit_row(fruits, 63, 67, 6, "kiwi")
	_inst("fire", traps, _px(72.5, 9), {"phase": 0.0})
	# Optional: trampoline up to a high bar
	_inst("trampoline", traps, _px(70.5, 9), {"bounce_speed": 420.0})
	_fruit_row(fruits, 70, 76, 3, "strawberry")
	_flag(flags, 76, 9, "mask_dude", 1)

	# ---------------- Room 2: The broken bridge (needs Mask Dude) ----------------
	_room(rooms, 2, "THE BROKEN BRIDGE",
		"Count the gap: it is 11 blocks wide. Store that whole number in an int called bridgeLength. Then the step is too high for one jump - switch to Mask Dude, and since hero already exists, leave out the type.",
		"int bridgeLength = __;", "int bridgeLength = 11;")
	_chest(chests, 83, 19, "numbers")
	_inst("bridge", gadgets, _px(90, 19), {"max_blocks": 12, "gap_blocks": 11})  # 11 exactly: more jams and collapses
	_pit_spikes(traps, 90, 100)
	_sign(signs, 90, 17, "GAP = 11 BLOCKS")
	_sign(signs, 102, 8, "TOO HIGH FOR\nONE JUMP")
	_wall_spikes(traps, 106, 15, 18)  # step face: only a double jump gets up
	# Spiked ball swinging over the bridge from the brick ceiling
	_inst("ball", traps, _px(95.5, 16), {"length": 30.0, "swing_degrees": 75.0, "period": 2.0})
	_fruit_row(fruits, 91, 99, 18, "melon")  # along the bridge
	# Optional: Rock Head elevator up to a hidden shelf
	_inst("rock_head", traps, _px(87, 18), {"travel": Vector2(0, -224), "wait_time": 1.4, "slam_speed": 120.0})
	_fruit_row(fruits, 82, 85, 2, "pineapple")
	# Step: Spike Head and fire before the flag
	_inst("spike_head", traps, _px(111.5, 13), {"travel": Vector2(48, 0), "wait_time": 0.9})
	_fruit_row(fruits, 109, 113, 12, "apple")
	_inst("fire", traps, _px(85.5, 19), {"phase": 0.6})  # on the floor below the doorway
	_flag(flags, 116, 14, "virtual_guy", 2)

	# ---------------- Room 3: The high ledge (needs Virtual Guy) ----------------
	_room(rooms, 3, "THE HIGH LEDGE",
		"Virtual Guy can sprint over the falling platforms - hold Shift while running. The ledge is too high even for a double jump: make every jump higher with a double called jumpPower (1.0 to 2.0), then double jump as Mask Dude.",
		"double jumpPower = ___;", "double jumpPower = 1.5;")
	for i in 10:
		# 0.14 s: walking (130 px/s) falls through, Virtual Guy's sprint (247 px/s) makes it.
		# Tested: 0.10-0.16 all work; 0.20 lets walkers across, 0.08 drops sprinters too.
		_inst("falling", gadgets, Vector2((128 + i * 2 + 1) * T, 14 * T + 3), {"fall_delay": 0.14, "return_time": 2.0})
	_pit_spikes(traps, 128, 147)
	_sign(signs, 122, 15, "FALLING FLOOR!\nRUN FAST")
	_sign(signs, 150, 4, "TOO HIGH!\nJUMP HIGHER")
	_wall_spikes(traps, 158, 9, 13)  # ledge face (top 2 tiles left clear for landing)
	_fruit_row(fruits, 129, 146, 13, "strawberry")  # grab them while sprinting
	_inst("saw", traps, _px(149.5, 13), {"travel": Vector2(64, 0), "speed": 55.0})
	_fruit_row(fruits, 149, 153, 11, "orange")  # jump for them over the saw
	# Ledge top: two fire blocks around the fruit
	_inst("fire", traps, _px(160.5, 7), {"phase": 0.0})
	_inst("fire", traps, _px(164.5, 7), {"phase": 1.0})
	_fruit_row(fruits, 161, 163, 6, "apple")
	_flag(flags, 167, 7, "none", 3)
	_fruit_door(traps, 3)

	# ---------------- Room 4: The fan shaft ----------------
	_room(rooms, 4, "THE FAN SHAFT",
		"The fan is off. Switch it on with a boolean called fanOn (true or false, no quotes), then ride the air up and step off onto the ledge.",
		"boolean fanOn = ____;", "boolean fanOn = true;")
	_chest(chests, 173, 19, "booleans_chars")
	# The player bobs at the top of the air column; 280 keeps even the low point of the
	# bob well above the ledge (row 5, y=80) so stepping off always works.
	_inst("fan", gadgets, _px(181, 19), {"lift_height": 280.0})
	_sign(signs, 172, 9, "THE FAN IS\nSWITCHED OFF")
	_fruit_column(fruits, 181, 6, 16, "bananas")  # collected while riding the air
	# Optional: trampoline up to the bar by the shaft wall
	_inst("trampoline", traps, _px(175.5, 19), {"bounce_speed": 400.0})
	_fruit_row(fruits, 172, 174, 14, "melon")
	# Top walkway: saws dropping from the ceiling, fruit between them
	for i in 3:
		_inst("saw", traps, _px(192.5 + i * 6, 2), {"travel": Vector2(0, 40), "speed": 45.0 + i * 10.0})
	_fruit_row(fruits, 190, 204, 4, "cherries")
	_flag(flags, 186, 5, "none", 4)
	_fruit_door(traps, 4)

	# ---------------- Room 5: Three paths ----------------
	_room(rooms, 5, "THREE PATHS",
		"The sign's riddle: the 2nd letter of the alphabet. Choose it with a char called path - single quotes! The path ends early, so dash the last part as Pink Man.",
		"char path = '_';", "char path = 'B';")
	for c in range(214, 226, 2):  # path A (high, stops far from the exit)
		_inst("path", gadgets, Vector2((c + 1) * T, 5 * T + 3), {"letter": "A", "show_letter": c == 214})
	for c in range(214, 234, 2):  # path B (exit height, ends 8 tiles short)
		_inst("path", gadgets, Vector2((c + 1) * T, 7 * T + 3), {"letter": "B", "show_letter": c == 214})
	for c in range(214, 230, 2):  # path C (low, dead end)
		_inst("path", gadgets, Vector2((c + 1) * T, 9 * T + 3), {"letter": "C", "show_letter": c == 214})
	_pit_spikes(traps, 214, 241)
	_sign(signs, 233, 12, "SAFE PATH = THE 2ND\nLETTER OF THE ABC")
	# Spiked balls swinging across path B
	_inst("ball", traps, _px(221.5, 1), {"length": 70.0, "swing_degrees": 45.0, "period": 2.4})
	_inst("ball", traps, _px(229.5, 1), {"length": 70.0, "swing_degrees": 45.0, "period": 2.4, "phase": 0.5})
	_fruit_row(fruits, 216, 231, 6, "kiwi")  # along path B
	_fruit_row(fruits, 243, 245, 6, "cherries")
	_flag(flags, 247, 7, "none", 5)
	_fruit_door(traps, 5)

	# ---------------- Room 6: The low tunnel ----------------
	_room(rooms, 6, "THE LOW TUNNEL",
		"Your jumps are too high for this tunnel! jumpPower already exists, so change it without writing double again - back to 1.0.",
		"jumpPower = ___;", "jumpPower = 1.0;")
	_chest(chests, 254, 19, "changing_variables")
	var ceiling_spikes := _inst("spikes", traps, _px(289, 13), {"count": 31})
	ceiling_spikes.rotation = PI
	for c in [263, 270, 277, 283]:
		_inst("spikes", traps, _px(c, 19), {"count": 2})
	_sign(signs, 253, 13, "MIND YOUR HEAD!")
	for c in [266, 273, 280]:
		_fruit_row(fruits, c, c + 2, 18, "melon")
	# After the tunnel: a saw, a slamming Spike Head, then the goal
	_inst("saw", traps, _px(289.5, 18), {"travel": Vector2(48, 0), "speed": 50.0})
	_inst("spike_head", traps, _px(293.5, 4), {"travel": Vector2(0, 208), "wait_time": 1.0, "slam_speed": 300.0})
	_fruit_row(fruits, 289, 292, 16, "orange")
	# Optional: Rock Head elevator up to a high bar
	_inst("rock_head", traps, _px(298, 18), {"travel": Vector2(0, -144), "wait_time": 1.4, "slam_speed": 120.0})
	_fruit_row(fruits, 291, 296, 9, "pineapple")

	# ---------------- Start, goal, player, Byte, UI ----------------
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(72, 288)
	_add(spawn)
	_inst("goal", level, _px(296, 19), {"room": room_nodes[6]}, "EndGoal")

	var byte := _inst("byte", level, Vector2(52, 266), {}, "Byte")
	var player := _inst("player", level, Vector2(72, 288), {}, "Player")
	byte.set("target", player)
	_inst("hud", level, Vector2.ZERO, {}, "HUD")
	var terminal := _inst("terminal", level, Vector2.ZERO, {}, "CodeTerminal")
	terminal.set("player", player)
	terminal.set("byte", byte)
	var allowed: Array[String] = ["hero", "bridgeLength", "jumpPower", "fanOn", "path"]
	terminal.set("allowed_variables", allowed)
	terminal.set("require_unlocked_heroes", true)
	_inst("reader", level, Vector2.ZERO, {}, "ManualReader")
	_inst("chest_window", level, Vector2.ZERO, {}, "ChestWindow")
	var hotbar := _inst("hotbar", level, Vector2.ZERO, {}, "Hotbar")
	hotbar.set("player", player)
	_inst("pause", level, Vector2.ZERO, {}, "PauseMenu")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var packed := PackedScene.new()
	print("pack: ", error_string(packed.pack(level)))
	print("save: ", error_string(ResourceSaver.save(packed, OUT)))
	print("open cells: ", interior.size(), "  solid cells: ", solid.size(), "  fruit: ", fruits.get_child_count())


# ---------------- Rooms and terrain ----------------

func _carve_rooms() -> void:
	for i in ROOMS.size():
		var r: Dictionary = ROOMS[i]
		for c in range(r.c0, r.c1 + 1):
			for row in range(1, BOTTOM + 1):
				interior[Vector2i(c, row)] = i
	for d in DOORS:
		for c in [d.c, d.c + 1]:
			for row in range(d.r0, d.r1 + 1):
				interior[Vector2i(c, row)] = _room_at(c - 2) if c == d.c else _room_at(c + 2)


func _room_at(c: int) -> int:
	for i in ROOMS.size():
		if c >= ROOMS[i].c0 and c <= ROOMS[i].c1:
			return i
	return 0


func _layout() -> void:
	# Room 0: gate ceiling, hanging pillar (2-tile gap under it), plateau, two bars
	_ground(0, 2, 27, 19, BOTTOM)
	_ground(0, 28, 39, 9, BOTTOM)
	_brick(15, 17, 1, 14)
	_brick(24, 25, 1, 16)
	_bar(0, 3, 6, 16)
	_bar(0, 10, 13, 9)  # high shelf, reached with the trampoline
	# Room 1: plateau, 8-tile gap (cols 52-59), landing, high bar
	_ground(1, 42, 51, 9, BOTTOM)
	_ground(1, 60, 79, 9, BOTTOM)
	_bar(1, 70, 76, 4)
	# Room 2: floor, 11-tile pit under a brick wall that reaches the ceiling, far floor, step
	_ground(2, 82, 89, 19, BOTTOM)
	_brick(88, 100, 1, 15)
	_ground(2, 101, 105, 19, BOTTOM)
	_ground(2, 106, 119, 14, BOTTOM)
	_bar(2, 82, 85, 3)  # hidden shelf above the doorway, reached with the Rock Head elevator
	# Room 3: falling platforms (cols 128-147) under a brick wall, then the high ledge
	_ground(3, 122, 127, 14, BOTTOM)
	_brick(126, 149, 1, 11)
	_ground(3, 148, 169, 14, BOTTOM)
	_ground(3, 158, 169, 7, 13)
	# Room 4: floor, hanging shaft wall, ledge block to the right of the shaft
	_ground(4, 172, 182, 19, BOTTOM)
	_brick(177, 178, 1, 15)
	_ground(4, 183, 209, 5, BOTTOM)
	_bar(4, 172, 174, 15)
	# Room 5: entrance ledge, chasm (cols 214-241), exit block
	_ground(5, 212, 213, 5, BOTTOM)
	_ground(5, 242, 249, 7, BOTTOM)
	# Room 6: floor, tunnel (brick down from the ceiling)
	_ground(6, 252, 299, 19, BOTTOM)
	_brick(258, 288, 1, 12)
	_bar(6, 291, 296, 10)  # high bar, reached with the Rock Head elevator
	# Decorations in the top corners of every room (kept clear of doorways)
	for i in ROOMS.size():
		_corner_deco(i)


func _ground(room: int, c0: int, c1: int, r0: int, r1: int) -> void:
	_fill(c0, c1, r0, r1, {"kind": "ground", "mat": ROOMS[room].ground})


func _brick(c0: int, c1: int, r0: int, r1: int) -> void:
	_fill(c0, c1, r0, r1, {"kind": "ground", "mat": "brick"})


func _fill(c0: int, c1: int, r0: int, r1: int, info: Dictionary) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			solid[Vector2i(c, r)] = info


func _bar(room: int, c0: int, c1: int, r: int) -> void:
	var row: int = BARS[ROOMS[room].bar]
	for c in range(c0, c1 + 1):
		var col := 18
		if c == c0:
			col = 17
		elif c == c1:
			col = 19
		solid[Vector2i(c, r)] = {"kind": "tile", "atlas": Vector2i(col, row)}


## A 2x2 block in the top-left corner and a 1x1 in the top-right, unless a doorway or
## something else is there.
func _corner_deco(i: int) -> void:
	var r: Dictionary = ROOMS[i]
	var tiles: Array = DECO[r.deco]
	var big: Vector2i = tiles[1]
	if not _near_door(r.c0, 1, 2) and not _taken(r.c0, r.c0 + 1, 1, 3):
		for dx in 2:
			for dy in 2:
				solid[Vector2i(r.c0 + dx, 1 + dy)] = {"kind": "tile", "atlas": big + Vector2i(dx, dy)}
	if not _near_door(r.c1, 1, 1) and not _taken(r.c1, r.c1, 1, 2):
		solid[Vector2i(r.c1, 1)] = {"kind": "tile", "atlas": tiles[0]}


func _near_door(c: int, r0: int, r1: int) -> bool:
	for d in DOORS:
		if absi(c - d.c) <= 3 or absi(c - (d.c + 1)) <= 3:
			if r0 <= d.r1 + 1 and r1 >= d.r0 - 1:
				return true
	return false


func _taken(c0: int, c1: int, r0: int, r1: int) -> bool:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			if solid.has(Vector2i(c, r)):
				return true
	return false


## Frame tiles around every room, and ground / bricks / decorations inside.
func _paint(layer: TileMapLayer) -> void:
	# Frame: every non-open cell next to an open cell, styled by the nearest room.
	var frame_cells := {}
	for cell in interior:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var n: Vector2i = cell + Vector2i(dx, dy)
				if not interior.has(n):
					frame_cells[n] = interior[cell]
	for cell in frame_cells:
		var base: Vector2i = FRAMES[ROOMS[frame_cells[cell]].frame]
		layer.set_cell(cell, 0, _frame_tile(cell, base))
	# Ground, bricks, bars, decorations
	for cell in solid:
		var info: Dictionary = solid[cell]
		if info.kind == "tile":
			layer.set_cell(cell, 0, info.atlas)
		else:
			layer.set_cell(cell, 0, _ground_tile(cell, info.mat))


func _frame_tile(cell: Vector2i, base: Vector2i) -> Vector2i:
	var closed := func(dx: int, dy: int) -> bool: return not interior.has(cell + Vector2i(dx, dy))
	var col := 1
	if not closed.call(-1, 0):
		col = 0
	elif not closed.call(1, 0):
		col = 2
	var row := 1
	if not closed.call(0, -1):
		row = 0
	elif not closed.call(0, 1):
		row = 2
	if col == 1 and row == 1:
		# Inside corner of a room: small corner piece facing the open diagonal.
		if not closed.call(1, 1):
			return base + Vector2i(3, 0)
		if not closed.call(-1, 1):
			return base + Vector2i(4, 0)
		if not closed.call(1, -1):
			return base + Vector2i(3, 1)
		if not closed.call(-1, -1):
			return base + Vector2i(4, 1)
	return base + Vector2i(col, row)


func _ground_tile(cell: Vector2i, mat: String) -> Vector2i:
	# Neighbours of the same material, or the frame, count as "joined" (no edge drawn there).
	var joined := func(dx: int, dy: int) -> bool:
		var n: Vector2i = cell + Vector2i(dx, dy)
		if not interior.has(n):
			return true
		return solid.has(n) and solid[n].get("mat", "") == mat
	var col := 1
	if not joined.call(-1, 0) and joined.call(1, 0):
		col = 0
	elif joined.call(-1, 0) and not joined.call(1, 0):
		col = 2
	var row := 1
	if not joined.call(0, -1):
		row = 0
	elif not joined.call(0, 1):
		row = 2
	return GROUNDS[mat] + Vector2i(col, row)


# ---------------- Helpers ----------------

func _px(c: float, r: float) -> Vector2:
	return Vector2(c * T, r * T)


func _add(node: Node, parent: Node = null) -> Node:
	(parent if parent else level).add_child(node)
	node.owner = level
	return node


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
	_add(n, parent)
	return n


func _room(parent: Node, i: int, title: String, hint: String, blanks: String, answer: String) -> void:
	var r: Dictionary = ROOMS[i]
	var node := _inst("room", parent, Vector2((r.c0 + r.c1 + 1) * T / 2.0, (BOTTOM + 2) * T / 2.0), {
		"size": Vector2((r.c1 - r.c0 + 1) * T, BOTTOM * T),
		"title": title, "hint": hint, "blanks": blanks, "answer": answer,
		"background": load("res://assets/level1_pixel_adventure/backgrounds/bg_%s.png" % r.bg)})
	node.name = "Room_" + title.replace(" ", "_").replace("'", "")
	room_nodes.append(node)


func _chest(parent: Node, c: int, r: int, manual: String) -> void:
	_inst("chest", parent, _px(c + 0.5, r), {"manual_id": manual})


func _flag(parent: Node, c: int, r: int, hero: String, room: int) -> void:
	var props := {"unlock_hero": hero}
	if hero != "none":
		props["room"] = room_nodes[room]  # rescue needs all of this room's fruit
	_inst("checkpoint", parent, _px(c + 0.5, r), props)


## Crates in the room's exit doorway that break once all its fruit is collected.
func _fruit_door(parent: Node, room: int) -> void:
	var d: Dictionary = DOORS[room]
	_inst("fruit_door", parent, _px(d.c + 1, d.r1 + 1), {
		"room": room_nodes[room], "size": Vector2(32, (d.r1 - d.r0 + 1) * T)})


## Spikes on the left-facing wall of column `c`, from row r0 to r1, pointing left.
## Stops Ninja Frog from climbing a single wall by wall-jumping against it.
func _wall_spikes(parent: Node, c: int, r0: int, r1: int) -> void:
	var s := _inst("spikes", parent, _px(c, r1 + 1), {"count": r1 - r0 + 1})
	s.rotation = -PI / 2.0


## Spikes along the bottom of a pit (on the frame); touching them sends you to the checkpoint.
func _pit_spikes(parent: Node, c0: int, c1: int) -> void:
	_inst("spikes", parent, _px(c0, BOTTOM + 1), {"count": c1 - c0 + 1, "send_to_checkpoint": true})


func _fruit_row(parent: Node, c0: int, c1: int, r: int, kind: String) -> void:
	for c in range(c0, c1 + 1):
		var n := _inst("fruit", parent, _px(c + 0.5, r + 0.5), {"fruit": kind})
		n.add_to_group("fruit", true)


func _fruit_column(parent: Node, c: int, r0: int, r1: int, kind: String) -> void:
	for r in range(r0, r1 + 1, 2):
		var n := _inst("fruit", parent, _px(c + 0.5, r + 0.5), {"fruit": kind})
		n.add_to_group("fruit", true)


func _sign(parent: Node, c: int, r: int, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = _px(c, r)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	l.add_theme_color_override("font_shadow_color", Color(0.129, 0.122, 0.188, 1))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	_add(l, parent)
