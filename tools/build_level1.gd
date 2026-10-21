extends SceneTree
## Builds scenes/levels/level1/level1.tscn from the layout below (see docs/level1_design.md).
## Run:  godot --headless --path . --script res://tools/build_level1.gd
## WARNING: this overwrites level1.tscn. Change the layout here and re-run, rather than
## editing the scene by hand (or stop using this script once the level is final).
##
## Coordinates are in tiles (16 px): column c, row r. The ground of most rooms is row 19.

const OUT := "res://scenes/levels/level1/level1.tscn"
const T := 16

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

var level: Node2D
var cells := {}  # Vector2i -> "dirt" | "stone"
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
	var heroes: Array[String] = ["ninja_frog"]
	level.set("starting_heroes", heroes)

	_background()
	_layout()
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

	# ---------------- Room 0: Wake-up (cols 0-39) ----------------
	_room(rooms, 0, 39, "WAKE UP",
		"Byte's gate opens when you print something. Use System.out.println with your message in double quotes.",
		"System.out.println(\"_____\");", "System.out.println(\"Hello Byte\");")
	_chest(chests, 7, 19, "variables_101")
	_inst("gate", gadgets, _px(16.5, 19), {"height": 3})
	_sign(signs, 9, 12, "BYTE'S GATE\nPRINT A MESSAGE\nTO OPEN IT")
	_sign(signs, 19, 13, "ONLY A WALL JUMP\nCLIMBS THIS SHAFT")
	_fruit(fruits, 12, 18, "apple")
	_fruit(fruits, 21, 18, "bananas")
	_fruit(fruits, 33, 8, "cherries")
	_flag(flags, 36, 9, "pink_man")

	# ---------------- Room 1: The wide gap (cols 40-79) ----------------
	_room(rooms, 40, 79, "THE WIDE GAP",
		"Only Pink Man's dash crosses this gap: jump, then press Shift in the air. Store his name in a String called hero.",
		"String hero = \"_______\";", "String hero = \"PinkMan\";")
	_sign(signs, 44, 4, "TOO WIDE TO JUMP!\nPINK MAN CAN DASH")
	_wall_spikes(gadgets, 60, 10, 16)  # far wall of the gap: no wall-climbing across
	_fruit(fruits, 46, 8, "kiwi")
	_fruit(fruits, 68, 8, "melon")
	_flag(flags, 76, 9, "mask_dude")

	# ---------------- Room 2: The broken bridge (cols 80-119) ----------------
	_room(rooms, 80, 119, "THE BROKEN BRIDGE",
		"Count the gap: it is 11 blocks wide. Store that whole number in an int called bridgeLength. Then the step is too high for one jump - switch to Mask Dude, and since hero already exists, leave out the type.",
		"int bridgeLength = __;", "int bridgeLength = 11;")
	_chest(chests, 82, 19, "numbers")
	_inst("bridge", gadgets, _px(90, 19), {"max_blocks": 12})
	_sign(signs, 82, 8, "BRIDGE BROKEN!\nGAP = 11 BLOCKS")
	_sign(signs, 102, 8, "TOO HIGH FOR\nONE JUMP")
	_wall_spikes(gadgets, 106, 15, 18)  # step face: only a double jump gets up
	_fruit(fruits, 85, 18, "orange")
	_fruit(fruits, 112, 13, "pineapple")
	_flag(flags, 116, 14, "virtual_guy")

	# ---------------- Room 3: The high ledge (cols 120-169) ----------------
	_room(rooms, 120, 169, "THE HIGH LEDGE",
		"Virtual Guy can sprint over the falling platforms - hold Shift while running. The ledge is too high even for a double jump: make every jump higher with a double called jumpPower (1.0 to 2.0), then double jump as Mask Dude.",
		"double jumpPower = ___;", "double jumpPower = 1.5;")
	for i in 10:
		# 0.14 s: walking (130 px/s) falls through, Virtual Guy's sprint (247 px/s) makes it.
		# Tested: 0.10-0.16 all work; 0.20 lets walkers across, 0.08 drops sprinters too.
		_inst("falling", gadgets, Vector2((128 + i * 2 + 1) * T, 14 * T + 3), {"fall_delay": 0.14, "return_time": 2.0})
	_sign(signs, 121, 5, "FALLING FLOOR!\nRUN FAST")
	_sign(signs, 150, 4, "TOO HIGH!\nJUMP HIGHER")
	_wall_spikes(gadgets, 158, 9, 13)  # ledge face (top 2 tiles left clear for landing)
	_fruit(fruits, 124, 13, "strawberry")
	_fruit(fruits, 163, 6, "apple")
	_flag(flags, 166, 7, "none")

	# ---------------- Room 4: The fan shaft (cols 170-209) ----------------
	_room(rooms, 170, 209, "THE FAN SHAFT",
		"The fan is off. Switch it on with a boolean called fanOn (true or false, no quotes), then ride the air up and step off onto the ledge.",
		"boolean fanOn = ____;", "boolean fanOn = true;")
	_chest(chests, 172, 19, "booleans_chars")
	# The player bobs at the top of the air column; 280 keeps even the low point of the
	# bob well above the ledge (row 5, y=80) so stepping off always works.
	_inst("fan", gadgets, _px(181, 19), {"lift_height": 280.0})
	_sign(signs, 171, 12, "THE FAN IS\nSWITCHED OFF")
	_fruit(fruits, 175, 18, "bananas")
	_fruit(fruits, 196, 4, "cherries")
	_flag(flags, 190, 5, "none")

	# ---------------- Room 5: Three paths (cols 210-249) ----------------
	_room(rooms, 210, 249, "THREE PATHS",
		"The sign's riddle: the 2nd letter of the alphabet. Choose it with a char called path - single quotes! The path ends early, so dash the last part as Pink Man.",
		"char path = '_';", "char path = 'B';")
	for c in range(214, 226, 2):  # path A (high, stops far from the exit)
		_inst("path", gadgets, Vector2((c + 1) * T, 5 * T + 3), {"letter": "A", "show_letter": c == 214})
	for c in range(214, 234, 2):  # path B (exit height, ends 8 tiles short)
		_inst("path", gadgets, Vector2((c + 1) * T, 7 * T + 3), {"letter": "B", "show_letter": c == 214})
	for c in range(214, 230, 2):  # path C (low, dead end)
		_inst("path", gadgets, Vector2((c + 1) * T, 9 * T + 3), {"letter": "C", "show_letter": c == 214})
	_sign(signs, 200, 1, "SAFE PATH = THE 2ND\nLETTER OF THE ABC")
	_fruit(fruits, 222, 6, "kiwi")
	_flag(flags, 246, 7, "none")

	# ---------------- Room 6: The low tunnel (cols 250-301) ----------------
	_room(rooms, 250, 301, "THE LOW TUNNEL",
		"Your jumps are too high for this tunnel! jumpPower already exists, so change it without writing double again - back to 1.0.",
		"jumpPower = ___;", "jumpPower = 1.0;")
	_chest(chests, 253, 19, "changing_variables")
	var ceiling_spikes := _inst("spikes", gadgets, _px(289, 13), {"count": 31})
	ceiling_spikes.rotation = PI
	for c in [263, 270, 277, 283]:
		_inst("spikes", gadgets, _px(c, 19), {"count": 2})
	_sign(signs, 251, 13, "MIND YOUR HEAD!")
	_fruit(fruits, 267, 18, "melon")
	_fruit(fruits, 280, 18, "orange")

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
	var err := packed.pack(level)
	print("pack: ", error_string(err))
	print("save: ", error_string(ResourceSaver.save(packed, OUT)))
	print("tiles: ", cells.size())


# ---------------- Terrain layout ----------------

func _layout() -> void:
	# Outer walls
	_rect("stone", 0, 1, 0, 22)
	_rect("stone", 300, 301, 0, 22)
	# Room 0: floor, gate ceiling, hanging pillar, plateau
	_rect("dirt", 2, 27, 19, 22)
	_rect("stone", 15, 17, 0, 14)
	_rect("stone", 24, 25, 0, 16)  # leaves a 2-tile gap to walk into the shaft
	_rect("dirt", 28, 51, 9, 22)
	# Room 1: 8-tile gap (cols 52-59), landing
	_rect("dirt", 60, 79, 9, 22)
	# Room 2: floor, 11-tile pit (cols 90-100) under a low ceiling, far floor, step
	_rect("dirt", 80, 89, 19, 22)
	_rect("stone", 88, 100, 12, 15)  # ends over the pit's far edge, so the step jump has headroom
	_rect("dirt", 101, 105, 19, 22)
	_rect("dirt", 106, 127, 14, 22)
	# Room 3: falling platforms (cols 128-147) under a low ceiling, then the high ledge
	_rect("stone", 126, 149, 8, 11)
	_rect("dirt", 148, 169, 14, 22)
	_rect("dirt", 158, 169, 7, 13)
	# Room 4: floor, shaft wall (left, hanging), block to the right of the shaft
	_rect("dirt", 170, 182, 19, 22)
	_rect("stone", 177, 178, 0, 15)
	_rect("dirt", 183, 213, 5, 22)
	# Room 5: chasm (cols 214-241), exit block
	_rect("dirt", 242, 249, 7, 22)
	# Room 6: floor, tunnel ceiling
	_rect("dirt", 250, 299, 19, 22)
	_rect("stone", 258, 288, 9, 12)


func _rect(kind: String, c0: int, c1: int, r0: int, r1: int) -> void:
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			cells[Vector2i(c, r)] = kind


## Picks the right edge/corner tile for every cell from its neighbours.
func _paint(layer: TileMapLayer) -> void:
	for cell in cells:
		var kind: String = cells[cell]
		var same := func(dx: int, dy: int) -> bool:
			var n: Vector2i = cell + Vector2i(dx, dy)
			if n.y > 22:
				return true  # the map's bottom edge counts as solid
			return cells.get(n, "") == kind
		var col := 1
		if not same.call(-1, 0) and same.call(1, 0):
			col = 0
		elif same.call(-1, 0) and not same.call(1, 0):
			col = 2
		var row := 1
		if not same.call(0, -1):
			row = 0
		elif not same.call(0, 1):
			row = 2
		var atlas: Vector2i
		if kind == "dirt":
			atlas = Vector2i(6 + col, row)
		else:
			atlas = Vector2i(12 + col, 4 + row)
			if atlas == Vector2i(12, 6):
				atlas = Vector2i(12, 5)  # that corner has no collision in the tileset
		layer.set_cell(cell, 0, atlas)


func _background() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BackgroundLayer"
	layer.layer = -10
	_add(layer)
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = load("res://assets/level1_pixel_adventure/backgrounds/bg_blue.png")
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.size = Vector2(704, 424)
	bg.set_script(load("res://scripts/levels/scrolling_background.gd"))
	layer.add_child(bg)
	bg.owner = level


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


func _room(parent: Node, c0: int, c1: int, title: String, hint: String, blanks: String, answer: String) -> void:
	var r := _inst("room", parent, Vector2((c0 + c1 + 1) * T / 2.0, 184), {
		"size": Vector2((c1 - c0 + 1) * T, 368),
		"title": title, "hint": hint, "blanks": blanks, "answer": answer})
	r.name = "Room_" + title.replace(" ", "_").replace("'", "")


func _chest(parent: Node, c: int, r: int, manual: String) -> void:
	_inst("chest", parent, _px(c + 0.5, r), {"manual_id": manual})


func _flag(parent: Node, c: int, r: int, hero: String) -> void:
	_inst("checkpoint", parent, _px(c + 0.5, r), {"unlock_hero": hero})


## Spikes on the left-facing wall of column `c`, from row r0 to r1, pointing left.
## Stops Ninja Frog from climbing a single wall by wall-jumping against it.
func _wall_spikes(parent: Node, c: int, r0: int, r1: int) -> void:
	var s := _inst("spikes", parent, _px(c, r1 + 1), {"count": r1 - r0 + 1})
	s.rotation = -PI / 2.0


func _fruit(parent: Node, c: int, r: int, kind: String) -> void:
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
