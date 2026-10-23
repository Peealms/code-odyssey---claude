extends SceneTree
## Builds scenes/levels/level1/level1.tscn from the room maps below (see docs/level1_design.md).
## Run:  godot --headless --path . --script res://tools/build_level1.gd
## WARNING: this overwrites level1.tscn. Change the maps here and re-run, rather than
## editing the scene by hand (or stop using this script once the level is final).
##
## Style follows Pixel Frog's Pixel Adventure demo: every room is a closed box with a frame,
## its own ground, building blocks, background and trap, joined to the next room by a doorway.
## Rooms have floors: you may start at the bottom and finish at the top, or the other way round.
## Fruit matters: rescue flags (rooms 0-2), exit doors (rooms 3-5) and the goal need all of it.
##
## Each room is a text map, one character per 16 px tile (legend below). Rooms are placed
## left to right with a 2-tile wall between them, and moved up or down so the `>` doorway of
## one room lines up with the `<` doorway of the next. The final room is made of six sections
## (each its own Room, with its own hint) arranged in a 2 x 2 screen box.

const OUT := "res://scenes/levels/level1/level1.tscn"
const T := 16

## Map legend
##   .  air                         #  ground (room's ground)     B  building blocks
##   =  floating bar (jump up through it)
##   f  fruit                       ^  spikes                     x  pit spikes (back to checkpoint)
##   v  ceiling spikes              V  deadly ceiling spikes      w  wall spikes (point away from the wall)
##   L  falling platform, fast (2 tiles; only a sprint makes it)  l  falling platform, slow
##   a b c  platform of path A / B / C (2 tiles each)
##   F  fire block   K  checkpoint flag   h  manual chest   < >  doorway rows (first / last column)
## Any other character is an anchor: the room's code in _build() puts a gadget there.

# Room 0 - wake up: println gate, spike corridor, wall-jump shaft, gallery with steps back.
const R0 := [
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"............................BB.........>",
	".........................===BB.........>",
	"............................BB.f...k...>",
	"......................===...BB...#######",
	".....ff....ff...ff..........BB...#######",
	"...................===......BB.f.#######",
	".ff..^^....^^...^^..........BB...#######",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB...#######",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB.f.#######",
	"............................BB...#######",
	"............................BB...#######",
	"...............ff....ff........f.#######",
	".................................#######",
	"..s..h....g....^^....^^..........#######",
	"########################################",
	"########################################",
	"########################################",
]

# Room 1 - the wide gap: dash over the gap in a crawlspace, then down three floors of saws.
# The crawlspace is 2 tiles high, so nobody can jump over the gap - only Pink Man's dash crosses.
const R1 := [
	"........BBBBBBBBBBBBBBBBB...............",
	"........BBBBBBBBBBBBBBBBB...............",
	"........BBBBBBBBBBBBBBBBB...............",
	"<.......BBBBBBBBBBBBBBBBB...............",
	"<.......................................",
	"<............fffff.........1............",
	"BBBBBBBBBBBBBxxxxxBBBBBBBBBBBBBBBBBB....",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB....",
	"........................................",
	"........................................",
	"............................2...........",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	".....ffff......................ffff.....",
	"............3...........................",
	"....BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
	"....BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
	"........................................",
	".........................4..............",
	"........................................",
	"........................................",
	"..............................ffff......",
	"..............................====......",
	"........................................",
	"........ffff............................",
	"..........................===..........>",
	".......................................>",
	"......5..........................k.....>",
	"########################################",
	"########################################",
]

# Room 2 - the broken bridge: low corridor, bridge, double jump up the step, upper floor back.
const R2 := [
	"........6.....7................8........",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"......ffff...ffff.......................",
	"......====...====.......................",
	".......................................>",
	".fff...................................>",
	"BBBBBBBBBBBBBBBBBBBBB............k.....>",
	"BBBBBBBBBBBBBBBBBBBBBw...###############",
	"BBBBBBBBBBBBBBBBBBBBBw..w###############",
	"<..BBBBBBBBBBBBBBBBBB...w###############",
	"<........fffffffff.......###############",
	"<..h....q................###############",
	"########...........#####################",
	"########xxxxxxxxxxx#####################",
	"########################################",
]

# Room 3 - the high ledge: sprint the falling floor, jump the ledge, falling stairs to a balcony.
const R3 := [
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"........................................",
	"...ffffff...............................",
	"BBBBBBBBBBBBB...........................",
	"BBBBBBBBBBBBB...........................",
	"...............ll.......................",
	"........................................",
	"........................................",
	"...................ll...................",
	"........................................",
	"........................................",
	".......................ll...............",
	"........................................",
	"........................................",
	"...........................ll..........>",
	".......................................>",
	"....ff......ffff......ff.........k.....>",
	"BBBBBBBBBBBBBBBBBBBBBBBBBB.....#########",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBw...w#########",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBw...w#########",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBw...w#########",
	"<.....BBBBBBBBBBBBBBBBBBBBw...w#########",
	"<......f.f.f.f.f.f.f.f.f.......#########",
	"<..............................#########",
	"######LLLLLLLLLLLLLLLLLLLL##############",
	"######....................##############",
	"######....................##############",
	"######xxxxxxxxxxxxxxxxxxxx##############",
]

# Room 4 - the fan shaft: drop to the bottom, ride the fan up, Rock Head elevator to the top.
const R4 := [
	"............BB..........................",
	"............BB.fffff...................>",
	"............BBBBBBBB...S...............>",
	"............BBBBBBBB.............k.....>",
	"............BB...............BBBBBBBBBBB",
	"............BB...............BBBBBBBBBBB",
	"<...........BB..........................",
	"<...........BB..........................",
	"<...........BB..........................",
	"BBBBBB......BB..........................",
	"BBBBBB......BB..........................",
	"............BB..........................",
	".........f..BB..f.......................",
	"............BB..........................",
	"............BB....BBBBBB..E.............",
	".........f..BB..f.BBBBBB................",
	"............BB..........................",
	"............BB..........................",
	".........f..BB..f.......................",
	"............BB..........................",
	"............BB..........................",
	".........f..BB..f.......................",
	"............BB..........................",
	"............BB..........................",
	".........f..BB..f.......................",
	"............BB..........................",
	"............BB..........................",
	".........f..BB..f.......................",
	"............BB..........................",
	"............BB..........................",
	"..ff........BB..........................",
	"........................................",
	"........ff..............................",
	"................f.......................",
	"........................................",
	"........................................",
	"................f.......................",
	"........................................",
	"........................................",
	"..r.....r...............................",
	".....h..........n.......................",
	"########################################",
	"########################################",
]

# Room 5 - three paths over a spike chasm; fruit on paths A and C too.
# Path B ends in a crawlspace over a spike trench: only Pink Man's dash crosses it.
const R5 := [
	"....................BBBBBBBBBBB.........",
	".......T....T....T..BBBBBBBBBBB.........",
	"....................BBBBBBBBBBB.........",
	"....................BBBBBBBBBBB.........",
	"<.........ffffff....BBBBBBBBBBB........>",
	"<...aaaaaaaaaaaa..........fffff........>",
	"<K......ffffffffff................k....>",
	"####bbbbbbbbbbbbbbbbbbbbbb.....#########",
	"####......................xxxxx#########",
	"####..........ffffff......##############",
	"####cccccccccccccccc.....w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####.....................w##############",
	"####xxxxxxxxxxxxxxxxxxxxxx##############",
]

# Final exam, bottom half (left to right): high wall, low tunnel, short bridge.
const S1 := [
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"...................fffff..",
	"..........................",
	"..................########",
	"...ffff...........########",
	".................w########",
	".................w########",
	"<................w########",
	"<....ffffff.......########",
	"<K..h...1.........########",
	"##########################",
	"##########################",
	"##########################",
]
const S2 := [
	"..........................BB",
	"..........................BB",
	"..........................BB",
	"..........................BB",
	"..........................BB",
	"..........................BB",
	"..........................BB",
	"......ff.....ff.....ff....BB",
	"..........F......F........BB",
	"....BBBBBBBBBBBBBBBBBBBBBBBB",
	"....BBBBBBBBBBBBBBBBBBBBBBBB",
	"....BBBBBBBBBBBBBBBBBBBBBBBB",
	".....VVVVVVVVVVVVVVVVVVVVV..",
	"............................",
	"............................",
	".......f....ff....f....ff...",
	"............................",
	"..K....F....^^....F....^^...",
	"############################",
	"############################",
	"############################",
]
const S3 := [
	"...............7..........",
	"..........................",
	"..........................",
	"......................f...",
	"..........................",
	"..........................",
	"..........................",
	"......................f...",
	"..........................",
	"..........................",
	"..........................",
	"......................f...",
	"BBBBBBBBBBBBBBB...........",
	"BBBBBBBBBBBBBBB...........",
	"BBBBBBBBBBBBBBB...........",
	"BBBBBBBBBBBBBBB...........",
	"...ffffffffffff.......R...",
	"...q...........K..........",
	"###............###########",
	"###xxxxxxxxxxxx###########",
	"##########################",
]
# Final exam, top half (right to left): fan trap, last path, final gate.
const S4 := [
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB........................",
	"BB...fff.9...fff..........",
	"BBBBBBBBBBBBBBBBBBBB......",
	"BBBBBBBBBBBBBBBBBBBB......",
	"..VVVVVVVVVVVVVVVVVV.===..",
	"....f.f.f.f.f.............",
	".....n.n.n.n.n..........K.",
	"BBBBBBBBBBBBBBBBBBBBB...BB",
	"BBBBBBBBBBBBBBBBBBBBB...BB",
	"BBBBBBBBBBBBBBBBBBBBB...BB",
]
const S5 := [
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB.T.....T.....T....",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB............fffff.",
	"BBBBBBBBBB..................",
	"BBBBBBBBBB........aaaaaaaaaa",
	"fffff.......................",
	"........f.f.f.f.f.f.f.f.f.f.",
	".....Bcccccccccccccccccccccc",
	"xxxxxBxxxxxxxxxxxxxxxxxxxxxx",
	"BBBBBBBBBBBBBBBBBBBBBBBBBBBB",
]
const S6 := [
	".........................B",
	".........................B",
	"......ff....ff....ff.....B",
	".........F....F......G...B",
	"...BBBBBBBBBBBBBBBBBBBBBBB",
	"...BBBBBBBBBBBBBBBBBBBBBBB",
	".f.BB.....................",
	"...BB.....................",
	"...BB.....................",
	"...BB...f.f.f.f.f.f.f.....",
	".f.BB..1..................",
	"...BBBBBBBBBBBBBBBBBB.....",
	"...BBBBBBBBBBBBBBBBBB===..",
	"...BBBBBBBBBBBBBBBBBB.....",
	".f.BBBBBBBBBBBBBBBBB......",
	"...BBBBBBBBBBBBBBBBB.===..",
	"..........f.f.f.f.........",
	".K..................g...K.",
	"########LLLLLLLLLLLL######",
	"########xxxxxxxxxxxx######",
	"##########################",
]

## One entry per room. `sections` places maps inside the room's box (most rooms have one).
const ROOMS := [
	{"sections": [[Vector2i(0, 0), R0]], "frame": "stone", "ground": "grass", "blocks": "bronze", "bg": "green", "bar": "wood",
		"fruit": ["apple", "bananas", "kiwi"], "manual": "variables_101"},
	{"sections": [[Vector2i(0, 0), R1]], "frame": "wood", "ground": "orange", "blocks": "metal", "bg": "yellow", "bar": "yellow",
		"fruit": ["orange", "strawberry", "melon"]},
	{"sections": [[Vector2i(0, 0), R2]], "frame": "teal", "ground": "pink", "blocks": "gold", "bg": "purple", "bar": "grey",
		"fruit": ["melon", "pineapple", "cherries"], "manual": "numbers"},
	{"sections": [[Vector2i(0, 0), R3]], "frame": "stone", "ground": "grass", "blocks": "orange", "bg": "blue", "bar": "wood",
		"fruit": ["strawberry", "apple", "orange"]},
	{"sections": [[Vector2i(0, 0), R4]], "frame": "wood", "ground": "orange", "blocks": "bronze", "bg": "brown", "bar": "yellow",
		"fruit": ["bananas", "cherries", "melon"], "manual": "booleans_chars"},
	{"sections": [[Vector2i(0, 0), R5]], "frame": "teal", "ground": "pink", "blocks": "metal", "bg": "gray", "bar": "grey",
		"fruit": ["kiwi", "cherries", "pineapple"]},
	# Final exam, in the order you play it.
	{"sections": [[Vector2i(0, 21), S1], [Vector2i(26, 21), S2], [Vector2i(54, 21), S3],
			[Vector2i(54, 0), S4], [Vector2i(26, 0), S5], [Vector2i(0, 0), S6]],
		"frame": "stone", "ground": "orange", "blocks": "gold", "bg": "pink", "bar": "wood",
		"fruit": ["melon", "orange", "pineapple", "apple"], "manual": "changing_variables"},
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
	"bridge": "res://scenes/gadgets/code_bridge.tscn",
	"fan": "res://scenes/gadgets/code_fan.tscn",
	"path": "res://scenes/gadgets/path_platform.tscn",
	"falling": "res://scenes/gadgets/falling_platform.tscn",
	"spikes": "res://scenes/gadgets/spikes.tscn",
	"saw": "res://scenes/gadgets/saw.tscn",
	"rock_head": "res://scenes/gadgets/rock_head.tscn",
	"spike_head": "res://scenes/gadgets/spike_head.tscn",
	"ball": "res://scenes/gadgets/spiked_ball.tscn",
	"fire": "res://scenes/gadgets/fire_trap.tscn",
	"fruit_door": "res://scenes/gadgets/fruit_door.tscn",
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
	level.set_script(load("res://scripts/levels/level.gd"))
	level.set("level_id", "level1")
	level.set("level_title", "LEVEL 1 - VARIABLES")
	level.set("level_number", 1)
	level.set("camera_top_margin", 0.0)
	var heroes: Array[String] = ["ninja_frog"]
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

	# ---------------- Room 0: Wake up (Ninja Frog only) - spikes ----------------
	_room(rooms, 0, 0, "WAKE UP",
		"Byte's gate opens when you print something. Use System.out.println with your message in double quotes.",
		"System.out.println(\"_____\");", "System.out.println(\"Hello Byte\");")
	_inst("gate", gadgets, _foot(_a(0, "g")), {"height": 3})
	_flag(flags, 0, _a(0, "k"), "pink_man")
	_sign(signs, 0, 1, 13, "BYTE'S GATE: PRINT\nA MESSAGE TO OPEN IT")
	_sign(signs, 0, 21, 13, "ONLY A WALL JUMP\nCLIMBS THIS SHAFT")
	_sign(signs, 0, 1, 1, "FRUIT GALLERY")

	# ---------------- Room 1: The wide gap (needs Pink Man) - saws ----------------
	_room(rooms, 1, 0, "THE WIDE GAP",
		"The crawlspace is too low to jump over the gap - only Pink Man's dash crosses it: walk to the edge and press Shift. Store his name in a String called hero.",
		"String hero = \"_______\";", "String hero = \"PinkMan\";")
	_saw(traps, _a(1, "1"), Vector2(96, 0), 50.0, true)
	_saw(traps, _a(1, "2"), Vector2(0, 80), 45.0)
	_saw(traps, _a(1, "3"), Vector2(112, 0), 60.0, true)
	_saw(traps, _a(1, "4"), Vector2(0, 112), 55.0)
	_saw(traps, _a(1, "5"), Vector2(96, 0), 50.0, true)
	_flag(flags, 1, _a(1, "k"), "mask_dude")
	_sign(signs, 1, 1, 0, "TOO LOW TO JUMP!\nPINK MAN CAN DASH")

	# ---------------- Room 2: The broken bridge (needs Mask Dude) - spiked balls ----------------
	_room(rooms, 2, 0, "THE BROKEN BRIDGE",
		"Count the gap: it is 11 blocks wide. Store that whole number in an int called bridgeLength. Then the step is too high for one jump - switch to Mask Dude, and since hero already exists, leave out the type.",
		"int bridgeLength = __;", "int bridgeLength = 11;")
	var q := _a(2, "q")
	_inst("bridge", gadgets, _px(q.x, q.y + 1), {"max_blocks": 12, "gap_blocks": 11})  # 11 exactly: more jams and collapses
	_ball(traps, _a(2, "6"), 160.0, 40.0, 2.4, 0.0)
	_ball(traps, _a(2, "7"), 160.0, 45.0, 2.8, 0.5)
	_ball(traps, _a(2, "8"), 185.0, 35.0, 2.2, 0.0)  # over the step, just reaches your head
	_flag(flags, 2, _a(2, "k"), "virtual_guy")
	_sign(signs, 2, 1, 15, "GAP = 11 BLOCKS")
	_sign(signs, 2, 26, 9, "TOO HIGH FOR\nONE JUMP")

	# ---------------- Room 3: The high ledge (needs Virtual Guy) - falling platforms ----------------
	_room(rooms, 3, 0, "THE HIGH LEDGE",
		"Virtual Guy can sprint over the falling floor - hold Shift while running. The ledge is too high even for a double jump: make your first jump higher with a double called jumpPower (1.0 to 2.0 - try the highest), then double jump as Mask Dude.",
		"double jumpPower = ___;", "double jumpPower = 2.0;")
	_flag(flags, 3, _a(3, "k"), "none")
	_fruit_door(traps, 3)
	_sign(signs, 3, 1, 25, "RUN FAST!")
	_sign(signs, 3, 33, 14, "TOO HIGH!\nJUMP HIGHER")

	# ---------------- Room 4: The fan shaft - Rock Heads ----------------
	_room(rooms, 4, 0, "THE FAN SHAFT",
		"The fan is off. Switch it on with a boolean called fanOn (true or false, no quotes), ride the air up and step onto the platform. Then ride the Rock Head up.",
		"boolean fanOn = ____;", "boolean fanOn = true;")
	# The player bobs at the top of the air column; 540 keeps even the low point of the
	# bob above the platform (27 tiles up) so stepping off always works.
	_inst("fan", gadgets, _foot(_a(4, "n")), {"lift_height": 540.0})
	_rock(traps, _a(4, "E"), Vector2(0, -160), 1.4, 110.0)  # elevator to the top floor
	_rock(traps, _a(4, "S"), Vector2(-48, 0), 1.2, 80.0)  # shuttle to the balcony
	_rock(traps, _a(4, "r", 0), Vector2(0, -128), 1.0, 90.0)
	_rock(traps, _a(4, "r", 1), Vector2(0, -96), 1.0, 90.0, 1.0)
	_flag(flags, 4, _a(4, "k"), "none")
	_fruit_door(traps, 4)
	_sign(signs, 4, 18, 36, "THE FAN IS\nSWITCHED OFF")

	# ---------------- Room 5: Three paths - Spike Heads ----------------
	_room(rooms, 5, 0, "THREE PATHS",
		"The sign's riddle: the 2nd letter of the alphabet. Choose it with a char called path - single quotes! Fruit is on paths A and C too: go back to the ledge, change path, collect, come back. The gap at the end needs Pink Man's dash.",
		"char path = '_';", "char path = 'B';")
	for i in 3:
		_spike_head(traps, _a(5, "T", i), Vector2(0, 192), i * 0.7)
	_flag(flags, 5, _a(5, "k"), "none")
	_fruit_door(traps, 5)
	_sign(signs, 5, 31, 0, "SAFE PATH = THE 2ND\nLETTER OF THE ABC")
	_sign(signs, 5, 5, 13, "GO BACK TO THE LEDGE\nBEFORE YOU SWITCH PATH")

	# ---------------- Room 6: The final exam - every trap, every variable ----------------
	_room(rooms, 6, 0, "EXAM 1: THE HIGH WALL",
		"Only Mask Dude's double jump climbs this wall (with jumpPower 2.0 from Room 3). hero already exists, so switch without the type.",
		"hero = \"________\";", "hero = \"MaskDude\";")
	_room(rooms, 6, 1, "EXAM 2: THE LOW TUNNEL",
		"With a high jumpPower every jump hits the spikes. Change jumpPower back to 1.0.",
		"jumpPower = ___;", "jumpPower = 1.0;")
	_room(rooms, 6, 2, "EXAM 3: THE LONG BRIDGE",
		"This gap is 12 blocks wide. bridgeLength already exists - give it the new number.",
		"bridgeLength = __;", "bridgeLength = 12;")
	_room(rooms, 6, 3, "EXAM 4: THE FAN TRAP",
		"These fans are ON and blow you into the spikes. Change fanOn to false.",
		"fanOn = _____;", "fanOn = false;")
	_room(rooms, 6, 4, "EXAM 5: THE LAST PATH",
		"The safe path is the 3rd letter. Change path (single quotes!), then dash or double jump over the gap at the end.",
		"path = '_';", "path = 'C';")
	_room(rooms, 6, 5, "EXAM 6: THE FINAL GATE",
		"Print exactly: I can code! Then sprint over the falling floor as Virtual Guy and wall-jump up the shaft as Ninja Frog.",
		"System.out.println(\"__________\");", "System.out.println(\"I can code!\");")
	_saw(traps, _a(6, "1", 1), Vector2(64, 0), 60.0, true)  # high wall (anchors count from the top)
	q = _a(6, "q")
	_inst("bridge", gadgets, _px(q.x, q.y + 1), {"max_blocks": 12, "gap_blocks": 12})
	_ball(traps, _a(6, "7"), 250.0, 20.0, 2.6, 0.0)  # in front of the elevator
	_rock(traps, _a(6, "R"), Vector2(0, -304), 1.5, 140.0)  # elevator up to the fan trap
	for cell in anchors[6]["n"]:
		_inst("fan", gadgets, _foot(cell), {"start_on": true, "lift_height": 64.0, "width": 32.0})
	_saw(traps, _a(6, "9"), Vector2(64, 0), 45.0, true)  # loft above the fans
	for i in 3:
		_spike_head(traps, _a(6, "T", i), Vector2(0, 112), i * 0.6)
	_inst("gate", gadgets, _foot(_a(6, "g")), {"height": 3, "required_text": "I can code!"})
	_saw(traps, _a(6, "1", 0), Vector2(128, 0), 55.0, true)  # final gate gallery
	_sign(signs, 6, 6, 31, "WHO CAN DOUBLE\nJUMP THIS HIGH?")
	_sign(signs, 6, 31, 34, "MIND YOUR HEAD!")
	_sign(signs, 6, 48, 34, "GAP = 12 BLOCKS")
	_sign(signs, 6, 74, 10, "FANS ARE ON!")
	_sign(signs, 6, 36, 4, "SAFE PATH = THE\n3RD LETTER")
	_sign(signs, 6, 21, 13, "PRINT\n\"I can code!\"")

	# ---------------- Health potions (heal 30; chests throw out one more each) ----------------
	var potions := _group("Potions")
	for spot in [[0, 25, 17], [1, 37, 16], [1, 20, 29], [2, 27, 12], [3, 37, 20], [3, 11, 6], [4, 24, 40], [4, 36, 3],
			[5, 37, 6], [6, 11, 38], [6, 27, 38], [6, 72, 38], [6, 77, 17], [6, 22, 17], [6, 5, 3]]:
		_inst("potion", potions, _foot(origins[spot[0]] + Vector2i(spot[1], spot[2])))

	# ---------------- Map characters: fruit, spikes, platforms, fire, flags, chests ----------------
	for i in ROOMS.size():
		_place_map_things(i, fruits, gadgets, traps, chests, flags)

	# ---------------- Start, goal, player, Byte, UI ----------------
	var start := _foot(_a(0, "s")) + Vector2(0, -16)
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = start
	_add(spawn)
	var exam_rooms: Array[Node] = []
	exam_rooms.assign(room_nodes[6])
	_inst("goal", level, _foot(_a(6, "G")), {"rooms": exam_rooms}, "EndGoal")

	var byte := _inst("byte", level, start + Vector2(-20, -22), {}, "Byte")
	var player := _inst("player", level, start, {}, "Player")
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
				".", "f", "^", "x", "v", "V", "w", "L", "l", "a", "b", "c", "F", "K", "h", "<", ">", "=":
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


## Fruit, spikes, falling and path platforms, fire, flags and chests drawn in room i's map.
func _place_map_things(i: int, fruits: Node, gadgets: Node, traps: Node, chests: Node, flags: Node) -> void:
	var o := origins[i]
	var kinds: Array = ROOMS[i].fruit
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
				"f":
					for k in run:
						var n := _inst("fruit", fruits, _px(c.x + k + 0.5, c.y + 0.5), {"fruit": kinds[y % kinds.size()]})
						n.add_to_group("fruit", true)
				"^", "x":
					_inst("spikes", traps, _px(c.x, c.y + 1), {"count": run, "send_to_checkpoint": ch == "x"})
				"v", "V":
					var s := _inst("spikes", traps, _px(c.x + run, c.y), {"count": run, "send_to_checkpoint": ch == "V"})
					s.rotation = PI
				"L", "l":
					for k in range(0, run, 2):
						_inst("falling", gadgets, Vector2((c.x + k + 1) * T, c.y * T + 3), {
							# 0.14 s: walking (130 px/s) falls through, Virtual Guy's sprint (247 px/s) makes it.
							"fall_delay": 0.14 if ch == "L" else 0.45, "return_time": 2.0})
				"a", "b", "c":
					for k in range(0, run, 2):
						_inst("path", gadgets, Vector2((c.x + k + 1) * T, c.y * T + 3), {
							"letter": ch.to_upper(), "show_letter": not lettered.has(ch)})
						lettered[ch] = true
				"F":
					for k in run:
						_inst("fire", traps, _foot(c + Vector2i(k, 0)), {"phase": fmod((c.x + k) * 0.37, 1.5)})  # neighbours out of step
				"K":
					_inst("checkpoint", flags, _foot(c), {})
				"h":
					_inst("chest", chests, _foot(c), {"manual_id": ROOMS[i].manual})
			x += run
	# Wall spikes run down a column and point away from the wall next to them. They send you
	# back to the checkpoint: with plain damage Ninja Frog could climb through them while he
	# blinks after the first hit.
	for x in sizes[i].x:
		var y := 0
		while y < sizes[i].y:
			if grids[i].get(Vector2i(x, y), "") != "w":
				y += 1
				continue
			var run := 1
			while grids[i].get(Vector2i(x, y + run), "") == "w":
				run += 1
			var c := o + Vector2i(x, y)
			if solid.has(c + Vector2i.RIGHT) or not interior.has(c + Vector2i.RIGHT):
				var s := _inst("spikes", traps, _px(c.x + 1, c.y + run), {"count": run, "send_to_checkpoint": true})
				s.rotation = -PI / 2.0
			else:
				var s := _inst("spikes", traps, _px(c.x, c.y), {"count": run, "send_to_checkpoint": true})
				s.rotation = PI / 2.0
			y += run


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
func _flag(parent: Node, i: int, cell: Vector2i, hero: String) -> void:
	var props := {"unlock_hero": hero}
	if hero != "none":
		props["room"] = room_nodes[i][0]
	_inst("checkpoint", parent, _foot(cell), props)


## Crates in the room's exit doorway that break once all its fruit is collected.
func _fruit_door(parent: Node, i: int) -> void:
	var rows := _door_rows(i, sizes[i].x - 1, ">")
	var wall_x := origins[i].x + sizes[i].x
	_inst("fruit_door", parent, _px(wall_x + 1, origins[i].y + rows[-1] + 1), {
		"room": room_nodes[i][0], "size": Vector2(32, rows.size() * T)})


## A saw. On the floor (`on_floor`) it sits half a tile above the ground under its anchor;
## otherwise it's centred in the anchor cell.
func _saw(parent: Node, cell: Vector2i, travel: Vector2, speed: float, on_floor := false) -> void:
	var pos := _px(cell.x + 0.5, cell.y) if on_floor else _px(cell.x + 0.5, cell.y + 0.5)
	_inst("saw", parent, pos, {"travel": travel, "speed": speed})


## A spiked ball hanging from the top edge of its anchor cell.
func _ball(parent: Node, cell: Vector2i, length: float, swing: float, period: float, phase: float) -> void:
	_inst("ball", parent, _px(cell.x + 0.5, cell.y), {"length": length, "swing_degrees": swing, "period": period, "phase": phase})


## A Rock Head filling the 2x2 tiles from its anchor (top-left) - a block you can ride.
func _rock(parent: Node, cell: Vector2i, travel: Vector2, wait: float, speed: float, delay := 0.0) -> void:
	_inst("rock_head", parent, _px(cell.x + 1, cell.y + 1), {"travel": travel, "wait_time": wait, "slam_speed": speed, "start_delay": delay})


## A Spike Head filling the 2x2 tiles from its anchor (top-left) - hurts on touch.
func _spike_head(parent: Node, cell: Vector2i, travel: Vector2, delay: float) -> void:
	_inst("spike_head", parent, _px(cell.x + 1, cell.y + 1), {"travel": travel, "wait_time": 0.8, "slam_speed": 160.0, "start_delay": delay})


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
