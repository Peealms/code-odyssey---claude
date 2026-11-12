extends SceneTree
## Builds Level 1 on Treasure Island, scenes/levels/level2/level2.tscn, from the room maps below
## (see docs/level2_design.md). The level id stays "level2"; players see it as LEVEL 1.
## Run:  godot --headless --path . --script res://tools/build_level2.gd
## WARNING: this overwrites level2.tscn (and resources/tilesets/level2_tileset.tres). Change
## the maps here and re-run, rather than editing the scene by hand.
##
## The lessons are the old Pixel Adventure Level 1's (String, int, double, boolean, char and
## changing a variable), in Treasure Hunters art. Tiles are 32 x 32 and drawn at full size
## (one screen = 20 x 11 tiles). Each room is a text map of its inside, one character per
## tile. Rooms are placed left to right with a 1-tile wall between them, moved up or down so
## the `>` doorway rows of one room line up with the `<` rows of the next. Everything outside
## the rooms is solid rock, painted with the right edge and corner pieces automatically.

const OUT := "res://scenes/levels/level2/level2.tscn"
const TILESET_OUT := "res://resources/tilesets/level2_tileset.tres"
const T := 32
const BIG_SPIKES := 50.0  ## Damage of the big floor and ceiling spikes (x, V).
const ISLAND_TEX := "res://assets/level2_treasure_hunters/tiles/island_terrain_32x32.png"
const PLANK_TEX := "res://assets/level2_treasure_hunters/tiles/ship_platforms_32x32.png"

## Map legend
##   .  air            #  ground             =  plank (jump up through it)
##   c  coin           K  checkpoint flag    h  manual chest       p  potion
##   ^  spikes (20 damage)                   x  big floor spikes (50 damage)
##   V  big ceiling spikes (50 damage)       ~  water (falling in sends you back to the checkpoint)
##   _  low beam: solid top 14 px of the tile, so only tiny Psalm fits under it
##   L  falling plank (only Kervin's sprint makes it)
##   A B C  path planks: solid only while `path` is that letter
##   < >  doorway rows (first / last column)
## Any other character is an anchor: the room's code in _build() puts something there
## (s start, k rescue flag, q the bridge's first plank, S / Z the ship's two docks,
## g Byte's gate, a the arena's left edge, X Captain Clown Nose, G the treasure,
## e crab, P Pink Star, T totem head).

# Room 0 - the wide gap: a wall-jump shaft up from the start (Chelzy), then a crawlspace too
# low to jump in, with a gap only Sarah's dash crosses.
const R0 := [
	"#######.....##########........",
	"#######.....##########........",
	"#######.....##########..c..c.>",
	"#######......c......c..e..k..>",
	"#######..#######..############",
	"#######..#######..############",
	"#######c.#######~~############",
	"....cc...#######~~############",
	".s.h.....#####################",
	"##############################",
	"##############################",
]

# Room 1 - the broken bridge: an 8-plank gap for the int bridge, then planks 3 tiles up over
# the water: April's double jump from the edge. No wall is near them, so Chelzy can't climb up.
const R1 := [
	".............................>",
	".......................c.k.c.>",
	".....................=========",
	"<.cc....c.c.c..cc.............",
	"<K..hT.........p..............",
	"######q.......######..........",
	"######~~~~~~~~######~~~~~~~~~~",
	"######~~~~~~~~######~~~~~~~~~~",
	"######~~~~~~~~######~~~~~~~~~~",
	"######~~~~~~~~######~~~~~~~~~~",
	"######~~~~~~~~######~~~~~~~~~~",
	"######~~~~~~~~######~~~~~~~~~~",
]

# Room 2 - the high ledge: a falling floor in a crawlspace (Kervin's sprint), then planks
# 4 tiles up in the open that only a double jump at jumpPower 2.0 reaches. They start 5 tiles
# from the nearest wall and end over water, so Chelzy can't climb up to them.
const R2 := [
	"......########................",
	"......########................",
	"......########...............>",
	"......########.......c..k.c..>",
	"......########......==========",
	"......########................",
	"<..cc.########................",
	"<K......c..c...c..............",
	"#######LLLLLL##########.......",
	"#######~~~~~~##########~~~~~~~",
	"#######~~~~~~##########~~~~~~~",
]

# Room 3 - the ship: low beams only tiny Psalm fits under, a ship that sails once its anchor
# is up, a crab in a crawlspace (you can't jump over it: fight it with the sword), then a
# wall-jump shaft up to the exit (Chelzy).
const R3 := [
	"........####.................#####......",
	"........####.................#####.....>",
	"........####.................#####...c.>",
	"........####.................#####..####",
	"........####.................#####c.####",
	"........####.................#####..####",
	"<.......####.................#####..####",
	"<K.h....____.K....c..c..c...K..e....####",
	"###############.S........Z.#############",
	"###############~~~~~~~~~~~~#############",
	"###############~~~~~~~~~~~~#############",
	"###############~~~~~~~~~~~~#############",
	"###############~~~~~~~~~~~~#############",
]

# Room 4 - three paths: A, B or C planks over the water (the sign's riddle says B), then a
# falling floor in a crawlspace that only Kervin's sprint gets over.
const R4 := [
	"................########......",
	"<.....c..c..c...########.....>",
	"<K..AAAAAAAAAAAA..c..c....P..>",
	"####BBBBBBBBBBBB#LLLLLL#######",
	"####CCCCCCCCCCCC#......#######",
	"####............#......#######",
	"####............#......#######",
	"####~~~~~~~~~~~~#~~~~~~#######",
	"####~~~~~~~~~~~~#~~~~~~#######",
	"####~~~~~~~~~~~~#~~~~~~#######",
	"####~~~~~~~~~~~~#~~~~~~#######",
]

# Exam 1 - the low cave: big spikes on the ceiling (jumpPower back to 1.0), a beam only tiny
# Psalm fits under, then a long falling floor (Kervin's sprint).
const E1 := [
	"VVVVVVVV###VVVVVVVVVVVVVVV",
	"<.......###..............>",
	"<K.h.x.c___c..........c..>",
	"#############LLLLLLLL#####",
	"#############........#####",
	"#############........#####",
	"#############~~~~~~~~#####",
	"#############~~~~~~~~#####",
]

# Exam 2 - the low bridge: a 6-plank gap under a low ceiling, three paths (C this time), then a
# wall-jump shaft up to the exit (Chelzy).
const E2 := [
	"....######..........####......",
	"....######..........####.....>",
	"....######..........####..c..>",
	"....######..........####c.####",
	"....######..........####..####",
	"....######..........####..####",
	"<...######.....c..........####",
	"<K....c.....AAAAAAAA.c....####",
	"####q.....##BBBBBBBB##########",
	"####......##CCCCCCCC##########",
	"####......##........##########",
	"####~~~~~~##~~~~~~~~##########",
	"####~~~~~~##~~~~~~~~##########",
]

# Exam 3 - the treasure: another anchored ship, Byte's gate (print "I can code!"), then a drop
# into Captain Clown Nose's arena. The treasure appears when he's beaten.
const E3 := [
	"......................................",
	"<.....................................",
	"<K.....c..c....cg.K...................",
	"####.S......Z.######..................",
	"####~~~~~~~~~~######..................",
	"####~~~~~~~~~~######..................",
	"####~~~~~~~~~~######..................",
	"####~~~~~~~~~~######..................",
	"####~~~~~~~~~~######a............X..G.",
	"####~~~~~~~~~~########################",
	"####~~~~~~~~~~########################",
]

## One entry per room, in the order you play them. manual: the chest's manual (for h);
## zone: rooms with the same zone count as one place for code gadgets (the exam);
## music: Sound track.
const ROOMS := [
	{"map": R0, "manual": "variables_101"},
	{"map": R1, "manual": "numbers"},
	{"map": R2},
	{"map": R3, "manual": "booleans_chars"},
	{"map": R4},
	{"map": E1, "manual": "changing_variables", "zone": "exam", "music": "final_exam"},
	{"map": E2, "zone": "exam", "music": "final_exam"},
	{"map": E3, "zone": "exam", "music": "final_exam"},
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
	"goal": "res://scenes/objects/treasure_goal.tscn",
	"chest": "res://scenes/objects/manual_chest.tscn",
	"checkpoint": "res://scenes/objects/checkpoint_flag.tscn",
	"room": "res://scenes/levels/room.tscn",
	"gate": "res://scenes/gadgets/byte_gate_island.tscn",
	"bridge": "res://scenes/gadgets/code_bridge.tscn",
	"falling": "res://scenes/gadgets/falling_platform.tscn",
	"path": "res://scenes/gadgets/path_platform.tscn",
	"spikes": "res://scenes/gadgets/spikes.tscn",
	"potion": "res://scenes/objects/health_potion.tscn",
	"crab": "res://scenes/enemies/crabby.tscn",
}
const L2 := "res://scripts/level2/"
## Variables players can use in this level (see VariableLibrary).
const VARIABLES: Array[String] = ["hero", "bridgeLength", "jumpPower", "anchorUp", "path", "hasSword"]

var level: Node2D
var grids: Array[Dictionary] = []  # per room: local Vector2i -> map character
var sizes: Array[Vector2i] = []
var origins: Array[Vector2i] = []  # absolute tile of each map's top-left
var anchors: Array[Dictionary] = []  # per room: character -> absolute cells (reading order)
var interior := {}  # absolute cell -> room index (inside a room or its doorway)
var solid := {}  # absolute cell -> true
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
	level.set("level_title", "LEVEL 1 - VARIABLES")
	level.set("level_number", 1)
	level.set("camera_top_margin", 0.0)
	# Chelzy, and Sarah from the tutorial; the others are rescued here.
	var heroes: Array[String] = ["chelzy", "sarah"]
	level.set("starting_heroes", heroes)

	var bg := CanvasLayer.new()
	bg.name = "Background"
	bg.set_script(load(L2 + "background.gd"))
	_add(bg)
	var tileset := _make_tileset()
	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = tileset
	_paint(terrain)
	_add(terrain)

	var rooms := _group("Rooms")
	var things := _group("Gadgets")
	var coins := _group("Coins")
	var traps := _group("Traps")
	var flags := _group("Checkpoints")
	var signs := _group("Signs")

	# ---------------- Room 0: the wide gap (Chelzy, then Sarah) ----------------
	_room(rooms, 0, "THE WIDE GAP",
		"Only Chelzy's wall jump climbs the shaft. Up top, the crawlspace is too low to jump over the gap - only Sarah's dash crosses it: walk to the edge and press Shift. Store Sarah's name in a String called hero.",
		"String hero = \"_____\";", "String hero = \"Sarah\";")
	_flag(flags, 0, _a(0, "k"), "april")
	_enemy(traps, _a(0, "e"), "crabby", 32.0)
	_sign(signs, 0, 1, 6, "ONLY A WALL JUMP\nCLIMBS THIS")
	_sign(signs, 0, 9, 0, "TOO LOW TO JUMP!\nSARAH CAN DASH")

	# ---------------- Room 1: the broken bridge (April) ----------------
	_room(rooms, 1, "THE BROKEN BRIDGE",
		"Count the gap: it is 8 planks wide. Store that whole number in an int called bridgeLength. Then the planks over the water are too high for one jump - switch to April, and since hero already exists, leave out the type.",
		"int bridgeLength = _;", "int bridgeLength = 8;")
	var q := _a(1, "q")
	_inst("bridge", things, _px(q.x, q.y), {"max_blocks": 10, "gap_blocks": 8})  # 8 exactly: more jams and collapses
	_shooter(traps, _a(1, "T"), "totem", 1, 3.0, 0.0, 256.0)  # shoots across the bridge
	_flag(flags, 1, _a(1, "k"), "kervin")
	_sign(signs, 1, 6, 1, "GAP = 8 PLANKS")
	_sign(signs, 1, 15, 0, "TOO HIGH FOR\nONE JUMP")

	# ---------------- Room 2: the high ledge (Kervin, then April) ----------------
	_room(rooms, 2, "THE HIGH LEDGE",
		"Kervin can sprint over the falling floor - hold Shift while running. The planks up high are too high even for a double jump: make your first jump higher with a double called jumpPower (1.0 to 2.0 - try the highest), then double jump as April under them.",
		"double jumpPower = ___;", "double jumpPower = 2.0;")
	_flag(flags, 2, _a(2, "k"), "psalm")
	_sign(signs, 2, 1, 4, "RUN FAST!")
	_sign(signs, 2, 15, 5, "TOO HIGH!\nJUMP HIGHER")

	# ---------------- Room 3: the ship (Psalm, the sword, Chelzy) ----------------
	_room(rooms, 3, "THE SHIP",
		"Only tiny Psalm fits under the beams: switch to him and hold Down. The ship is anchored: pull the anchor up with a boolean called anchorUp (true or false, no quotes), then ride it across. A crab blocks the tunnel on the far side and you can't jump over it: give yourself a sword with another boolean, hasSword, and left-click to swing. Chelzy climbs the shaft to the exit.",
		"boolean anchorUp = ____;", "boolean anchorUp = true;")
	_ship(things, 3)
	_enemy(traps, _a(3, "e"), "crabby", 24.0)
	_sign(signs, 3, 4, 3, "TINY PSALM FITS\nUNDER THE BEAMS")
	_sign(signs, 3, 15, 3, "THE SHIP IS\nANCHORED")
	_sign(signs, 3, 27, 4, "A CRAB! NO WAY\nOVER IT: FIGHT!")

	# ---------------- Room 4: three paths (Kervin) ----------------
	_room(rooms, 4, "THREE PATHS",
		"The sign's riddle: the 2nd letter of the alphabet. Choose it with a char called path - single quotes! Coins are on path A too: go back to the ledge, change path, collect, come back. The falling floor at the end needs Kervin's sprint.",
		"char path = '_';", "char path = 'B';")
	_enemy(traps, _a(4, "P"), "pink_star", 32.0)
	_sign(signs, 4, 4, 0, "SAFE PATH = THE 2ND\nLETTER OF THE ABC")

	# ---------------- The exam: every variable gets a new value ----------------
	_room(rooms, 5, "EXAM 1: THE LOW CAVE",
		"With a high jumpPower every jump hits the ceiling spikes. Change jumpPower back to 1.0. Then only Psalm fits under the beams, and only Kervin's sprint makes it over the falling floor.",
		"jumpPower = ___;", "jumpPower = 1.0;")
	_room(rooms, 6, "EXAM 2: THE LOW BRIDGE",
		"This gap is 6 planks wide. bridgeLength already exists - give it the new number. Then the safe path is the 3rd letter: change path (single quotes!). Chelzy climbs the shaft at the end.",
		"bridgeLength = _;", "bridgeLength = 6;")
	q = _a(6, "q")
	_inst("bridge", things, _px(q.x, q.y), {"max_blocks": 8, "gap_blocks": 6})
	_sign(signs, 6, 4, 7, "GAP = 6\nPLANKS")
	_sign(signs, 6, 12, 2, "SAFE PATH = THE\n3RD LETTER")
	_room(rooms, 7, "EXAM 3: THE TREASURE",
		"This ship is anchored too: anchorUp already exists, so set it without the type and ride across. Print exactly: I can code! Then Captain Clown Nose guards the treasure. Have your sword (hasSword), switch heroes with Q to dodge him - April jumps his charge, tiny Psalm ducks his thrown sword, Sarah dashes from his swing - and hit him while he's dizzy.",
		"anchorUp = ____;", "anchorUp = true;")
	_ship(things, 7)
	_inst("gate", things, _foot(_a(7, "g")), {"height": 3, "required_text": "I can code!"})
	_captain(7)
	_sign(signs, 7, 14, 0, "PRINT\n\"I can code!\"")
	_sign(signs, 7, 21, 1, "HOLD Q TO SWITCH HEROES!\nCHARGE - APRIL JUMPS\nTHROW - TINY PSALM\nSWING - SARAH DASHES")

	# ---------------- Map characters ----------------
	for i in ROOMS.size():
		_place_map_things(i, coins, traps, flags, things)

	# ---------------- Start, treasure, player, Byte, UI ----------------
	var start := _foot(_a(0, "s")) + Vector2(0, -16)
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = start
	_add(spawn)
	var exam_rooms: Array[Node] = []
	exam_rooms.assign(room_nodes.slice(5))
	_inst("goal", level, _foot(_a(7, "G")), {"rooms": exam_rooms}, "EndGoal")

	var byte := _inst("byte", level, start + Vector2(-20, -22), {}, "Byte")
	var player := _inst("player", level, start, {}, "Player")
	byte.set("target", player)
	_inst("hud", level, Vector2.ZERO, {}, "HUD")
	var terminal := _inst("terminal", level, Vector2.ZERO, {}, "CodeTerminal")
	terminal.set("player", player)
	terminal.set("byte", byte)
	terminal.set("allowed_variables", VARIABLES)
	terminal.set("require_unlocked_heroes", true)
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
					solid[cell] = true
				elif not ch in [".", "=", "c", "K", "h", "p", "^", "x", "V", "~", "_", "L", "A", "B", "C", "<", ">"]:
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
				solid[cell] = true


# ---------------- Tiles ----------------

## Source 0: the island terrain (solid). Source 1: the planks (one-way: jump up through them).
func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var full := PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)])
	var plank := PackedVector2Array([Vector2(-16, -16), Vector2(16, -16), Vector2(16, -10), Vector2(-16, -10)])
	for spec in [[ISLAND_TEX, 0], [PLANK_TEX, 1]]:
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
				data.add_collision_polygon(0)
				if spec[1] == 1:
					data.set_collision_polygon_points(0, 0, plank)
					data.set_collision_polygon_one_way(0, 0, true)
				else:
					data.set_collision_polygon_points(0, 0, full)
	return ts


func _paint(layer: TileMapLayer) -> void:
	for cell in solid:
		layer.set_cell(cell, 0, _shape(cell))
	for i in ROOMS.size():
		for yy in sizes[i].y:
			for xx in sizes[i].x:
				if grids[i][Vector2i(xx, yy)] != "=":
					continue
				var left: bool = grids[i].get(Vector2i(xx - 1, yy), "") == "="
				var right: bool = grids[i].get(Vector2i(xx + 1, yy), "") == "="
				var col := 4 if not left and not right else (1 if not left else (3 if not right else 2))
				layer.set_cell(origins[i] + Vector2i(xx, yy), 1, Vector2i(col, 1))


## Which piece of the 3x3 block (plus pillars, bars and inner corners) a solid cell needs,
## from which of its neighbours are open.
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
	var lettered := {}
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
					_inst("spikes", traps, _px(c.x, c.y + 1), {"count": run * 2, "damage": BIG_SPIKES if ch == "x" else 20.0})
				"V":
					var s := _inst("spikes", traps, _px(c.x + run, c.y), {"count": run * 2, "damage": BIG_SPIKES})
					s.rotation = PI
				"~":
					# The top row of a pool: one Water node, as deep as the ~ rows below it.
					if grids[i].get(Vector2i(x, y - 1), "") != "~":
						var depth := 0
						while grids[i].get(Vector2i(x, y + depth), "") == "~":
							depth += 1
						_water(things, i, x, x + run, y, depth * T)
				"L":
					for k in run:
						_inst("falling", things, Vector2((c.x + k + 0.5) * T, c.y * T + 3), {"fall_delay": 0.14, "return_time": 2.0})
				"A", "B", "C":
					for k in run:
						_inst("path", things, Vector2((c.x + k + 0.5) * T, c.y * T + 3), {
							"letter": ch, "show_letter": not lettered.has(ch)})
						lettered[ch] = true
				"_":
					for k in run:
						_beam(things, c + Vector2i(k, 0))
				"K":
					_inst("checkpoint", flags, _foot(c), {})
				"h":
					_inst("chest", things, _foot(c), {"manual_id": ROOMS[i].get("manual", "variables_101")})
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

## A Room node covering room i and its right-hand wall.
func _room(parent: Node, i: int, title: String, hint: String, blanks: String, answer: String) -> void:
	var size := Vector2(sizes[i].x + 1, sizes[i].y) * T
	var node := _inst("room", parent, Vector2(origins[i]) * T + size / 2.0, {
		"size": size, "title": title, "hint": hint, "blanks": blanks, "answer": answer,
		"zone": ROOMS[i].get("zone", ""), "music": ROOMS[i].get("music", "rooms")})
	node.name = "Room%d_%s" % [i, title.get_slice(":", title.count(":")).strip_edges().replace(" ", "_").replace("'", "")]
	room_nodes.append(node)


## A rescue flag: the hero waits beside it until every coin in room i is collected.
func _flag(parent: Node, i: int, cell: Vector2i, hero: String) -> void:
	_inst("checkpoint", parent, _foot(cell), {"unlock_hero": hero, "room": room_nodes[i]})


## Captain Clown Nose in room i. He waits at X; his arena runs from the `a` cell to the room's
## right wall, and the fight starts when the hero walks two tiles into it.
func _captain(i: int) -> void:
	var left := _a(i, "a")
	var body := CharacterBody2D.new()
	body.name = "Captain"
	body.set_script(load(L2 + "captain.gd"))
	body.set("arena_left", float(left.x * T))
	body.set("arena_right", float((origins[i].x + sizes[i].x) * T))
	body.set("start_x", (left.x + 2.5) * T)
	body.position = _foot(_a(i, "X"))
	_add(body, level)


## The ship of room i: it rests at its dock S and sails to Z when anchorUp is true.
## The deck rests 10 px above the water, which starts in the row below S.
func _ship(parent: Node, i: int) -> void:
	var from := _a(i, "S")
	var to := _a(i, "Z")
	var n := Node2D.new()
	n.name = "Ship"
	n.set_script(load("res://scripts/gadgets/code_ship.gd"))
	n.set("trip", Vector2((to.x - from.x) * T, 0))
	n.position = Vector2((from.x + 0.5) * T, (from.y + 1) * T - 10)
	_add(n, parent)


## Water in room i from column x0 to x1 (map columns), its surface at the top of map row y.
func _water(parent: Node, i: int, x0: int, x1: int, y: int, depth: float) -> void:
	var n := Node2D.new()
	n.name = "Water"
	n.set_script(load(L2 + "water.gd"))
	n.set("width", float((x1 - x0) * T))
	n.set("depth", depth)
	n.position = _px(origins[i].x + x0, origins[i].y + y)
	_add(n, parent)


func _shooter(parent: Node, cell: Vector2i, kind: String, direction: int, interval: float, delay := 0.0, reach := 320.0) -> void:
	var n := Node2D.new()
	n.name = kind.capitalize()
	n.set_script(load(L2 + "shooter.gd"))
	n.set("kind", kind)
	n.set("direction", direction)
	n.set("interval", interval)
	n.set("delay", delay)
	n.set("reach", reach)
	var lift := {"seashell": 19.0, "totem": 24.0}
	n.position = _foot(cell) + Vector2(0, -lift[kind])
	_add(n, parent)


## A patrolling enemy: crabby, or another enemy's art on the same script (pink_star, fierce_tooth).
func _enemy(parent: Node, cell: Vector2i, kind: String, patrol: float) -> void:
	var props := {"patrol_left": -patrol, "patrol_right": patrol}
	if kind != "crabby":
		props["frames"] = load("res://assets/level2_treasure_hunters/enemies/%s/%s_frames.tres" % [kind, kind])
	_inst("crab", parent, _foot(cell), props)


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
