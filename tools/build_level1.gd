extends SceneTree
## Builds scenes/levels/level1/level1.tscn from the layout below (see docs/level1_design.md).
## Run:  godot --headless --path . --script res://tools/build_level1.gd
## WARNING: this overwrites level1.tscn. Change the layout here and re-run, rather than
## editing the scene by hand (or stop using this script once the level is final).
##
## Style follows Pixel Frog's Pixel Adventure demo: every room is a closed box with a frame,
## its own ground colour, background and decorations, joined to the next room by a doorway.
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
	{"c": 170, "r0": 4, "r1": 6},   # R3 ledge -> drop into R4
	{"c": 210, "r0": 2, "r1": 4},   # R4 ledge -> R5
	{"c": 250, "r0": 4, "r1": 6},   # R5 exit -> drop into R6
]

var level: Node2D
var interior := {}  # Vector2i -> room index (open space, incl. doorways)
var solid := {}  # Vector2i -> {"kind": "ground"/"deco"/"bar", ...}
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
	_backgrounds()
	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = load("res://resources/tilesets/level1_terrain_tileset.tres")
	_paint(terrain)
	_add(terrain)

	var signs := _group("Signs")
	var fruits := _group("Fruits")
	var gadgets := _group("Gadgets")
	var chests := _group("Chests")
	var rooms := _group("Rooms")
	var flags := _group("Checkpoints")

	# ---------------- Room 0: Wake-up ----------------
	_room(rooms, 0, "WAKE UP",
		"Byte's gate opens when you print something. Use System.out.println with your message in double quotes.",
		"System.out.println(\"_____\");", "System.out.println(\"Hello Byte\");")
	_chest(chests, 7, 19, "variables_101")
	_inst("gate", gadgets, _px(16.5, 19), {"height": 3})
	_sign(signs, 9, 11, "BYTE'S GATE\nPRINT A MESSAGE\nTO OPEN IT")
	_sign(signs, 19, 13, "ONLY A WALL JUMP\nCLIMBS THIS SHAFT")
	_fruit_row(fruits, 3, 6, 15, "apple")  # on top of the floating bar
	_fruit_row(fruits, 19, 22, 18, "bananas")
	_fruit_row(fruits, 30, 34, 8, "cherries")
	_flag(flags, 36, 9, "pink_man")

	# ---------------- Room 1: The wide gap ----------------
	_room(rooms, 1, "THE WIDE GAP",
		"Only Pink Man's dash crosses this gap: jump, then press Shift in the air. Store his name in a String called hero.",
		"String hero = \"_______\";", "String hero = \"PinkMan\";")
	_sign(signs, 43, 3, "TOO WIDE TO JUMP!\nPINK MAN CAN DASH")
	_wall_spikes(gadgets, 60, 10, 16)  # far wall of the gap: no wall-climbing across
	_pit_spikes(gadgets, 52, 59)
	_fruit_row(fruits, 53, 58, 7, "orange")  # an arc to grab mid-dash
	_fruit_row(fruits, 64, 72, 8, "kiwi")
	_flag(flags, 76, 9, "mask_dude")

	# ---------------- Room 2: The broken bridge ----------------
	_room(rooms, 2, "THE BROKEN BRIDGE",
		"Count the gap: it is 11 blocks wide. Store that whole number in an int called bridgeLength. Then the step is too high for one jump - switch to Mask Dude, and since hero already exists, leave out the type.",
		"int bridgeLength = __;", "int bridgeLength = 11;")
	_chest(chests, 84, 19, "numbers")
	_inst("bridge", gadgets, _px(90, 19), {"max_blocks": 12})
	_pit_spikes(gadgets, 90, 100)
	_sign(signs, 83, 8, "BRIDGE BROKEN!\nGAP = 11 BLOCKS")
	_sign(signs, 102, 8, "TOO HIGH FOR\nONE JUMP")
	_wall_spikes(gadgets, 106, 15, 18)  # step face: only a double jump gets up
	_fruit_row(fruits, 91, 99, 18, "melon")  # along the bridge
	_fruit_row(fruits, 109, 113, 13, "pineapple")
	_flag(flags, 116, 14, "virtual_guy")

	# ---------------- Room 3: The high ledge ----------------
	_room(rooms, 3, "THE HIGH LEDGE",
		"Virtual Guy can sprint over the falling platforms - hold Shift while running. The ledge is too high even for a double jump: make every jump higher with a double called jumpPower (1.0 to 2.0), then double jump as Mask Dude.",
		"double jumpPower = ___;", "double jumpPower = 1.5;")
	for i in 10:
		# 0.14 s: walking (130 px/s) falls through, Virtual Guy's sprint (247 px/s) makes it.
		# Tested: 0.10-0.16 all work; 0.20 lets walkers across, 0.08 drops sprinters too.
		_inst("falling", gadgets, Vector2((128 + i * 2 + 1) * T, 14 * T + 3), {"fall_delay": 0.14, "return_time": 2.0})
	_pit_spikes(gadgets, 128, 147)
	_sign(signs, 122, 4, "FALLING FLOOR!\nRUN FAST")
	_sign(signs, 150, 4, "TOO HIGH!\nJUMP HIGHER")
	_wall_spikes(gadgets, 158, 9, 13)  # ledge face (top 2 tiles left clear for landing)
	_fruit_row(fruits, 129, 146, 13, "strawberry")  # grab them while sprinting
	_fruit_row(fruits, 160, 164, 6, "apple")
	_flag(flags, 166, 7, "none")

	# ---------------- Room 4: The fan shaft ----------------
	_room(rooms, 4, "THE FAN SHAFT",
		"The fan is off. Switch it on with a boolean called fanOn (true or false, no quotes), then ride the air up and step off onto the ledge.",
		"boolean fanOn = ____;", "boolean fanOn = true;")
	_chest(chests, 174, 19, "booleans_chars")
	# The player bobs at the top of the air column; 280 keeps even the low point of the
	# bob well above the ledge (row 5, y=80) so stepping off always works.
	_inst("fan", gadgets, _px(181, 19), {"lift_height": 280.0})
	_sign(signs, 172, 11, "THE FAN IS\nSWITCHED OFF")
	_fruit_column(fruits, 181, 6, 16, "bananas")  # collected while riding the air
	_fruit_row(fruits, 192, 200, 4, "cherries")
	_flag(flags, 190, 5, "none")

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
	_pit_spikes(gadgets, 214, 241)
	_sign(signs, 200, 1, "SAFE PATH = THE 2ND\nLETTER OF THE ABC")
	_fruit_row(fruits, 216, 231, 6, "kiwi")  # along path B
	_flag(flags, 246, 7, "none")

	# ---------------- Room 6: The low tunnel ----------------
	_room(rooms, 6, "THE LOW TUNNEL",
		"Your jumps are too high for this tunnel! jumpPower already exists, so change it without writing double again - back to 1.0.",
		"jumpPower = ___;", "jumpPower = 1.0;")
	_chest(chests, 254, 19, "changing_variables")
	var ceiling_spikes := _inst("spikes", gadgets, _px(289, 13), {"count": 31})
	ceiling_spikes.rotation = PI
	for c in [263, 270, 277, 283]:
		_inst("spikes", gadgets, _px(c, 19), {"count": 2})
	_sign(signs, 253, 13, "MIND YOUR HEAD!")
	for c in [266, 273, 280]:
		_fruit_row(fruits, c, c + 2, 18, "melon")
	_fruit_row(fruits, 290, 293, 18, "orange")

	# ---------------- Start, goal, player, Byte, UI ----------------
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(72, 288)
	_add(spawn)
	_inst("goal", level, _px(295, 19), {}, "EndGoal")

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
	print("open cells: ", interior.size(), "  solid cells: ", solid.size())


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
	# Room 0: gate ceiling, hanging pillar (2-tile gap under it), plateau
	_ground(0, 2, 27, 19, BOTTOM)
	_ground(0, 28, 39, 9, BOTTOM)
	_brick(15, 17, 1, 14)
	_brick(24, 25, 1, 16)
	_bar(0, 3, 6, 16)  # small floating bar near the start, fruit on top
	# Room 1: plateau, 8-tile gap (cols 52-59), landing
	_ground(1, 42, 51, 9, BOTTOM)
	_ground(1, 60, 79, 9, BOTTOM)
	# Room 2: floor, 11-tile pit under a low ceiling, far floor, step
	_ground(2, 82, 89, 19, BOTTOM)
	_brick(88, 100, 12, 15)
	_ground(2, 101, 105, 19, BOTTOM)
	_ground(2, 106, 119, 14, BOTTOM)
	# Room 3: falling platforms (cols 128-147) under a low ceiling, then the high ledge
	_ground(3, 122, 127, 14, BOTTOM)
	_brick(126, 149, 8, 11)
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
	# Room 6: floor, tunnel ceiling
	_ground(6, 252, 299, 19, BOTTOM)
	_brick(258, 288, 9, 12)
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


## A 2x2 block in the top-left corner and a 1x1 in the top-right, unless a doorway is there.
func _corner_deco(i: int) -> void:
	var r: Dictionary = ROOMS[i]
	var tiles: Array = DECO[r.deco]
	var big: Vector2i = tiles[1]
	if not _near_door(r.c0, 1, 2) and not _taken(r.c0, r.c0 + 1, 1, 2):
		for dx in 2:
			for dy in 2:
				solid[Vector2i(r.c0 + dx, 1 + dy)] = {"kind": "tile", "atlas": big + Vector2i(dx, dy)}
	if not _near_door(r.c1, 1, 1) and not _taken(r.c1, r.c1, 1, 1):
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


## Each room's own scrolling background, drawn behind everything inside the room.
func _backgrounds() -> void:
	var holder := _group("Backgrounds")
	holder.z_index = -10
	var shader: Shader = load("res://resources/shaders/scroll_tile.gdshader")
	for i in ROOMS.size():
		var r: Dictionary = ROOMS[i]
		var bg := TextureRect.new()
		bg.name = "Background%d" % i
		bg.texture = load("res://assets/level1_pixel_adventure/backgrounds/bg_%s.png" % r.bg)
		bg.stretch_mode = TextureRect.STRETCH_TILE
		bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# A tile wider on each side so it also shows through the doorways.
		bg.position = Vector2((r.c0 - 2) * T, T)
		bg.size = Vector2((r.c1 - r.c0 + 5) * T, BOTTOM * T)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("speed", Vector2(0.0, 0.25))
		bg.material = mat
		_add(bg, holder)


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
		"title": title, "hint": hint, "blanks": blanks, "answer": answer})
	node.name = "Room_" + title.replace(" ", "_").replace("'", "")


func _chest(parent: Node, c: int, r: int, manual: String) -> void:
	_inst("chest", parent, _px(c + 0.5, r), {"manual_id": manual})


func _flag(parent: Node, c: int, r: int, hero: String) -> void:
	_inst("checkpoint", parent, _px(c + 0.5, r), {"unlock_hero": hero})


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
