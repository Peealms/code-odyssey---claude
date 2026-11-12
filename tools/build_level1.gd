extends SceneTree
## Builds the tutorial, scenes/levels/level1/level1.tscn, from the room map below
## (see docs/level1_design.md). The level id stays "level1".
## Run:  godot --headless --path . --script res://tools/build_level1.gd
## WARNING: this overwrites level1.tscn. Change the map here and re-run, rather than
## editing the scene by hand.
##
## Style follows Pixel Frog's Pixel Adventure demo: the room is a closed box with a frame,
## its own ground, building blocks and background. Its fruit matters: Sarah's rescue flag and
## the trophy both need all of it. The level script, scripts/levels/tutorial.gd, adds Byte's
## lessons on top.
##
## The room is a text map, one character per 16 px tile (legend below). The builder can still
## join several rooms left to right (a `>` doorway row of one room lines up with the `<` row of
## the next), but the tutorial has only one.

const OUT := "res://scenes/levels/level1/level1.tscn"
const T := 16

## Map legend
##   .  air                         #  ground (room's ground)     B  building blocks
##   =  floating bar (jump up through it)
##   f  fruit                       ^  spikes
##   K  checkpoint flag   h  manual chest   < >  doorway rows (first / last column)
## Any other character is an anchor: the room's code in _build() puts something there
## (s start, g Byte's gate, k Sarah's rescue flag, G the trophy).

# The tutorial room: println gate, spike corridor, wall-jump shaft, gallery with steps back,
# Sarah's flag and the trophy on the plateau at the top right.
const R0 := [
	"............................................",
	"............................................",
	"............................................",
	"............................................",
	"............................BB..............",
	".........................===BB..............",
	"............................BB.f...k.....G..",
	"......................===...BB...###########",
	".....ff....ff...ff..........BB...###########",
	"...................===......BB.f.###########",
	".ff..^^....^^...^^..........BB...###########",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB...###########",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.f.###########",
	"............................BB...###########",
	"............................BB...###########",
	"...............ff....ff........f.###########",
	".................................###########",
	"..s..h....g....^^....^^..........###########",
	"############################################",
	"############################################",
	"############################################",
]

## One entry per room. `sections` places maps inside the room's box (a room can be made of
## several sections, each its own Room node).
const ROOMS := [
	{"sections": [[Vector2i(0, 0), R0]], "frame": "stone", "ground": "grass", "blocks": "bronze", "bg": "green", "bar": "wood",
		"fruit": ["apple", "bananas", "kiwi"], "manual": "variables_101"},
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
	"fruit": "res://scenes/objects/fruit.tscn",
	"chest": "res://scenes/objects/manual_chest.tscn",
	"checkpoint": "res://scenes/objects/checkpoint.tscn",
	"room": "res://scenes/levels/room.tscn",
	"gate": "res://scenes/gadgets/byte_gate.tscn",
	"spikes": "res://scenes/gadgets/spikes.tscn",
	"potion": "res://scenes/objects/health_potion.tscn",
}

# ---- Tile sheet (assets/level1_pixel_adventure/tiles/terrain_16x16.png) ----
## Room frames: 3x3 block (edges + dark fill) at `base`, inside-corner pieces at base + (3, 0).
const FRAMES := {"stone": Vector2i(0, 0), "wood": Vector2i(0, 4), "teal": Vector2i(0, 8)}
## Ground with a coloured top: 3x3 block at `base`.
const GROUNDS := {"grass": Vector2i(6, 0), "orange": Vector2i(6, 4), "pink": Vector2i(6, 8)}
## Bevelled building blocks. From `base`: a 3x1 bar at +(0..2, 0), a 1x3 pillar at +(3, 0..2),
## a 1x1 block at +(0, 1) and a 2x2 block at +(1..2, 1..2).
const BLOCKS := {"bronze": Vector2i(12, 0), "metal": Vector2i(12, 4), "orange": Vector2i(12, 8), "gold": Vector2i(17, 8)}
## Thin floating bars you can jump up through: row of the 3-tile bar (left, middle, right).
const BARS := {"yellow": 0, "wood": 1, "grey": 2}

var level: Node2D
var grids: Array[Dictionary] = []  # per room: local Vector2i -> map character
var sizes: Array[Vector2i] = []  # per room: width, height in tiles
var origins: Array[Vector2i] = []  # per room: absolute tile of the map's top-left
var anchors: Array[Dictionary] = []  # per room: character -> absolute cells (reading order)
var interior := {}  # absolute Vector2i -> room index (everything inside a frame, incl. doorways)
var solid := {}  # absolute Vector2i -> {"kind": "ground", "mat": ...} or {"kind": "tile", "atlas": ...}
var room_nodes: Array = []  # per room: its Room nodes (one per section)
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
	level.set_script(load("res://scripts/levels/tutorial.gd"))
	level.set("level_id", "level1")
	level.set("level_title", "TUTORIAL")
	level.set("level_number", 0)  # the level-complete screen says "TUTORIAL COMPLETE!"
	level.set("next_scene", "res://scenes/levels/level2/level2.tscn")  # CONTINUE goes to Level 1
	level.set("camera_top_margin", 0.0)
	var heroes: Array[String] = ["chelzy"]
	level.set("starting_heroes", heroes)

	if not _read_maps():
		quit(1)
		return
	_place_rooms()
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

	# ---------------- The room: wake up (Chelzy only) - spikes ----------------
	_room(rooms, 0, 0, "WAKE UP",
		"Byte's gate opens when you print something. Use System.out.println with your message in double quotes.",
		"System.out.println(\"_____\");", "System.out.println(\"Hello Byte\");")
	_inst("gate", gadgets, _foot(_a(0, "g")), {"height": 3})
	_flag(flags, 0, _a(0, "k"), "sarah")
	_sign(signs, 0, 1, 13, "BYTE'S GATE: PRINT\nA MESSAGE TO OPEN IT")
	_sign(signs, 0, 21, 13, "ONLY A WALL JUMP\nCLIMBS THIS SHAFT")
	_sign(signs, 0, 1, 1, "FRUIT GALLERY")

	# ---------------- Health potion (heals 30; the chest throws out one more) ----------------
	var potions := _group("Potions")
	for spot in [[0, 25, 17]]:
		_inst("potion", potions, _foot(origins[spot[0]] + Vector2i(spot[1], spot[2])))

	# ---------------- Map characters: fruit, spikes, flags, chests ----------------
	for i in ROOMS.size():
		_place_map_things(i, fruits, traps, chests, flags)

	# ---------------- Start, trophy, player, Byte, UI ----------------
	var start := _foot(_a(0, "s")) + Vector2(0, -16)
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = start
	_add(spawn)
	var goal_rooms: Array[Node] = []
	goal_rooms.assign(room_nodes[0])
	_inst("goal", level, _foot(_a(0, "G")), {"rooms": goal_rooms}, "EndGoal")

	var byte := _inst("byte", level, start + Vector2(-20, -22), {}, "Byte")
	var player := _inst("player", level, start, {}, "Player")
	byte.set("target", player)
	_inst("hud", level, Vector2.ZERO, {}, "HUD")
	var terminal := _inst("terminal", level, Vector2.ZERO, {}, "CodeTerminal")
	terminal.set("player", player)
	terminal.set("byte", byte)
	# println needs no variable; hero is allowed so the player can try switching to Sarah.
	var allowed: Array[String] = ["hero"]
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
	for i in ROOMS.size():
		print("room %d at %s, %s tiles" % [i, origins[i], sizes[i]])
	print("solid cells: ", solid.size(), "  fruit: ", fruits.get_child_count())


# ---------------- Maps -> rooms ----------------

## Reads every room's sections into one grid per room. Returns false if a map is broken.
func _read_maps() -> bool:
	var ok := true
	for i in ROOMS.size():
		var grid := {}
		var size := Vector2i.ZERO
		for s in ROOMS[i].sections:
			var at: Vector2i = s[0]
			var rows: Array = s[1]
			for y in rows.size():
				var row: String = rows[y]
				if row.length() != rows[0].length():
					printerr("room %d section at %s: row %d is %d long, not %d" % [i, at, y, row.length(), rows[0].length()])
					ok = false
				for x in row.length():
					grid[at + Vector2i(x, y)] = row[x]
			size.x = maxi(size.x, at.x + rows[0].length())
			size.y = maxi(size.y, at.y + rows.size())
		grids.append(grid)
		sizes.append(size)
	return ok


## Rooms go left to right; each one is moved up or down so the doorways line up.
func _place_rooms() -> void:
	for i in ROOMS.size():
		if i == 0:
			origins.append(Vector2i(1, 1))
		else:
			var exits := _door_rows(i - 1, sizes[i - 1].x - 1, ">")
			var entries := _door_rows(i, 0, "<")
			if exits.size() != entries.size():
				printerr("rooms %d and %d: doorways don't match (%d vs %d rows)" % [i - 1, i, exits.size(), entries.size()])
			var prev := origins[i - 1]
			origins.append(Vector2i(prev.x + sizes[i - 1].x + 2, prev.y + exits[0] - entries[0]))
		anchors.append({})
		for cell in grids[i]:
			var abs_cell: Vector2i = origins[i] + cell
			interior[abs_cell] = i
			var ch: String = grids[i][cell]
			match ch:
				"#":
					solid[abs_cell] = {"kind": "ground", "mat": ROOMS[i].ground}
				"B":
					solid[abs_cell] = {"kind": "block"}
				".", "f", "^", "K", "h", "<", ">", "=":
					pass
				_:
					if not anchors[i].has(ch):
						anchors[i][ch] = []
					anchors[i][ch].append(abs_cell)
		for ch in anchors[i]:
			anchors[i][ch].sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return p.y < q.y or (p.y == q.y and p.x < q.x))
		_bars(i)
		_fill_blocks(i)
		# Doorway: open the 2-tile wall between this room and the previous one.
		if i > 0:
			var wall_x := origins[i].x - 2
			for y in _door_rows(i, 0, "<"):
				interior[Vector2i(wall_x, origins[i].y + y)] = i - 1
				interior[Vector2i(wall_x + 1, origins[i].y + y)] = i


func _door_rows(i: int, x: int, mark: String) -> Array[int]:
	var rows: Array[int] = []
	for y in sizes[i].y:
		if grids[i].get(Vector2i(x, y), "") == mark:
			rows.append(y)
	return rows


func _bars(i: int) -> void:
	var row: int = BARS[ROOMS[i].bar]
	for cell in grids[i]:
		if grids[i][cell] != "=":
			continue
		var left: bool = grids[i].get(cell + Vector2i.LEFT, "") == "="
		var right: bool = grids[i].get(cell + Vector2i.RIGHT, "") == "="
		var col := 18
		if not left:
			col = 17
		elif not right:
			col = 19
		solid[origins[i] + cell] = {"kind": "tile", "atlas": Vector2i(col, row)}


## Covers the room's B cells with whole block pieces: 2x2 where it fits, then 3-wide bars,
## then 3-tall pillars, then single blocks - the way the demo builds its platforms.
func _fill_blocks(i: int) -> void:
	var base: Vector2i = BLOCKS[ROOMS[i].blocks]
	var free := func(c: Vector2i) -> bool: return solid.has(c) and solid[c].kind == "block"
	var cells: Array = []
	for cell in grids[i]:
		if grids[i][cell] == "B":
			cells.append(origins[i] + cell)
	cells.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return p.y < q.y or (p.y == q.y and p.x < q.x))
	for c: Vector2i in cells:
		if not free.call(c):
			continue
		var r := Vector2i.RIGHT
		var d := Vector2i.DOWN
		if free.call(c + r) and free.call(c + d) and free.call(c + r + d):
			for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				solid[c + o] = {"kind": "tile", "atlas": base + Vector2i(1, 1) + o}
		elif free.call(c + r) and free.call(c + r * 2):
			for k in 3:
				solid[c + r * k] = {"kind": "tile", "atlas": base + Vector2i(k, 0)}
		elif free.call(c + d) and free.call(c + d * 2):
			for k in 3:
				solid[c + d * k] = {"kind": "tile", "atlas": base + Vector2i(3, k)}
		else:
			solid[c] = {"kind": "tile", "atlas": base + Vector2i(0, 1)}


## Frame tiles around every room, and ground / blocks / bars inside.
func _paint(layer: TileMapLayer) -> void:
	# Frame: every cell outside the rooms that touches one, styled like that room.
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
	# Everything else in the map's bounding box is the frames' dark fill, so the scrolling
	# background is only ever seen inside the rooms (rooms have different heights).
	var box := Rect2i(frame_cells.keys()[0], Vector2i.ONE)
	for cell in frame_cells:
		box = box.expand(cell).expand(cell + Vector2i.ONE)
	for x in range(box.position.x, box.end.x):
		for y in range(box.position.y, box.end.y):
			var c := Vector2i(x, y)
			if not interior.has(c) and not frame_cells.has(c):
				layer.set_cell(c, 0, FRAMES.stone + Vector2i(1, 1))
	for cell in solid:
		var info: Dictionary = solid[cell]
		if info.kind == "tile":
			layer.set_cell(cell, 0, info.atlas)
		elif info.kind == "ground":
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


## Fruit, spikes, flags and chests drawn in room i's map.
func _place_map_things(i: int, fruits: Node, traps: Node, chests: Node, flags: Node) -> void:
	var o := origins[i]
	var kinds: Array = ROOMS[i].fruit
	for y in sizes[i].y:
		var x := 0
		while x < sizes[i].x:
			var ch: String = grids[i].get(Vector2i(x, y), ".")
			var run := 1
			while grids[i].get(Vector2i(x + run, y), "") == ch:
				run += 1
			var c := o + Vector2i(x, y)
			match ch:
				"f":
					for k in run:
						var n := _inst("fruit", fruits, _px(c.x + k + 0.5, c.y + 0.5), {"fruit": kinds[y % kinds.size()]})
						n.add_to_group("fruit", true)
				"^":
					_inst("spikes", traps, _px(c.x, c.y + 1), {"count": run})
				"K":
					_inst("checkpoint", flags, _foot(c), {})
				"h":
					_inst("chest", chests, _foot(c), {"manual_id": ROOMS[i].manual})
			x += run


# ---------------- Helpers ----------------

## Absolute cell of anchor `ch` in room i (the n-th one, in reading order).
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


## A Room node covering section s of room i.
func _room(parent: Node, i: int, s: int, title: String, hint: String, blanks: String, answer: String) -> void:
	var at: Vector2i = ROOMS[i].sections[s][0]
	var rows: Array = ROOMS[i].sections[s][1]
	var size := Vector2(rows[0].length(), rows.size()) * T
	var node := _inst("room", parent, Vector2(origins[i] + at) * T + size / 2.0, {
		"size": size, "title": title, "hint": hint, "blanks": blanks, "answer": answer,
		"background": load("res://assets/level1_pixel_adventure/backgrounds/bg_%s.png" % ROOMS[i].bg),
		"zone": "room%d" % i if ROOMS[i].sections.size() > 1 else "",
		"music": "final_exam" if ROOMS[i].sections.size() > 1 else "rooms"})
	node.name = "Room_" + title.replace(":", "").replace(" ", "_").replace("'", "")
	while room_nodes.size() <= i:
		room_nodes.append([])
	room_nodes[i].append(node)


## A checkpoint; with a hero it's a rescue flag that needs all of the room's fruit.
func _flag(parent: Node, i: int, cell: Vector2i, hero: String) -> Node:
	var props := {"unlock_hero": hero}
	if hero != "none":
		props["room"] = room_nodes[i][0]
	return _inst("checkpoint", parent, _foot(cell), props)


## A sign at tile (c, r) of room i's map.
func _sign(parent: Node, i: int, c: int, r: int, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = _px(origins[i].x + c, origins[i].y + r)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	l.add_theme_color_override("font_shadow_color", Color(0.129, 0.122, 0.188, 1))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	_add(l, parent)
