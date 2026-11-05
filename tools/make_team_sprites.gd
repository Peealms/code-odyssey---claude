extends SceneTree
## Draws the five Code Odyssey team members as one-frame idle pixel art, in two sizes:
##  - TEAM: big portraits in the Pirate Bomb / Kings and Pigs style (soft #323443 outline,
##    flat colours with one shade and one highlight, dark solid legs).
##    Writes assets/shared/team/<name>.png on a 40x68 CANVAS.
##  - TEAM_SMALL: hero-sized versions that can replace the Pixel Adventure heroes. Same people
##    and colours, with the heroes' darker #211f30 outline, and black trousers drawn as a fill
##    ('e') so the legs still read. They sit on a 40x40 frame (centred, feet on the bottom row):
##    taller than the heroes' 32x32, so Chelzy can clearly tower over Kervin.
##    Writes assets/shared/team/small/<name>.png.
## Each person is a hand-made character map below (one letter per pixel, see PALETTE).
## The outer outline is added automatically around everything that is not already dark;
## ':' marks a pixel that must stay empty (the gap between the feet).
## Every sprite of a set sits on the same canvas, centred, with the feet on the bottom row,
## so they line up when placed at the same y.
## Run:  godot --headless --path . --script res://tools/make_team_sprites.gd [-- <preview.png> [<small_preview.png>]]
## Then: godot --headless --path . --import

const OUT_DIR := "res://assets/shared/team/"
const CANVAS := Vector2i(40, 68)
const SMALL_DIR := "res://assets/shared/team/small/"
const SMALL_CANVAS := Vector2i(40, 40)  # the team's hero frame (see make_team_heroes.gd)
## Colours that differ in the hero-sized set.
const SMALL_OVERRIDES := {"o": Color("211f30")}
## Left-to-right order of the preview lineup (as in the group photo).
const LINEUP := ["april", "sarah", "psalm", "kervin", "chelzy"]
const PREVIEW_SCALE := 6
const SMALL_PREVIEW_SCALE := 10

const PALETTE := {
	"o": Color("323443"),  # outline, black trousers and shoes, eyes, mouths
	"p": Color("45475e"),  # trouser crease highlight
	"q": Color("8b90a8"),  # shoe shine, earrings
	"w": Color("ffffff"),  # teeth, ID cards, undershirt
	"r": Color("bd3b53"),  # open mouth
	"k": Color("4a4c66"),  # hair
	"K": Color("3b3d52"),  # hair shade
	"j": Color("6e7393"),  # hair shine
	"u": Color("a8c0da"),  # uniform shirt
	"U": Color("7f98ba"),  # uniform shade
	"l": Color("cfe0ee"),  # uniform light
	"t": Color("4d659e"),  # collar and sleeve trim
	"T": Color("39497a"),  # trim shade, pocket
	"y": Color("f6c94e"),  # STI lanyard
	"n": Color("33417a"),  # navy lanyard
	"b": Color("4d89cb"),  # blue ID card
	"x": Color("e3edf2"),  # clear ID holder
	"v": Color("a98bdc"),  # crochet charm purple
	"g": Color("f6c27d"),  # gold watch
	"G": Color("d1964f"),  # gold watch shade
	"a": Color("bdb8ad"),  # grey jacket
	"A": Color("948f86"),  # jacket shade
	"i": Color("dcd8ce"),  # jacket light
	"z": Color("6c6862"),  # zipper
	"d": Color("57596e"),  # charcoal trousers
	"D": Color("46485b"),  # charcoal trousers shade
	"e": Color("323443"),  # black trousers as a fill (hero-sized set)
}

## s = skin, S = shade, h = light, c = blush
const SKINS := {
	"light": {"s": Color("fdcaab"), "S": Color("e39b89"), "h": Color("ffe3c6"), "c": Color("f6a48c")},
	"medium": {"s": Color("e8ad86"), "S": Color("c7876c"), "h": Color("f7cba5"), "c": Color("e08f74")},
}

const TEAM := [
	{
		"name": "sarah",
		"skin": "light",
		"map": [
			".......kkjjjkkk.......",
			".....kjjjjkkkkkkK.....",
			"....kjjjkkkkkkkkkK....",
			"...kjjkkkkkkkkkkkKK...",
			"..kjjkkkkkkkkkkkkkKK..",
			"..kjkkkkkkkkkkkkkkKK..",
			"..kkkkkkkkkkkkkKkkKK..",
			"..kkkkkkKkkkkKKsKkKK..",
			"..kKKKKKKKKKssssssKK..",
			"..kKKKsshsssssssSSKK..",
			"..kKsssossssssossSKK..",
			"..kKsssossssssossSKK..",
			".kkKsccssssSsssccSKKk.",
			".kkwsssssossossssSwKk.",
			".kkKssssssoossssSSKKk.",
			".kkKshsssssssssSSSKKk.",
			".jkK.SSSSSSSSSSSS.KKk.",
			"......................",
			"..lllllltSSSStuUuuUU..",
			"..luUolyltsstuyUouUU..",
			"..luUololuttuuoUouUU..",
			"..luUollyuuuuyuUouUU..",
			"..luUolluouuouuUouUU..",
			"..ttTolllbbbbuuUotTT..",
			"..TTTolulbkkbuuUoTTT..",
			"..ssSoluubssbTTUosSS..",
			"..ssSoluubbbbuuUosSS..",
			"..ssSoluluuuuuuUogGG..",
			"..ssSoluuuuuuuuUosSS..",
			"..ssSoluuuuuuuUUosSS..",
			"..sSSouuuuuuuuUUoSSS..",
			"......uuuuuuuuUU......",
			"......UUUUUUUUUU......",
			"......oooooooooo......",
			"......opoooooopo......",
			"......opoooooopo......",
			"......opoooooopo......",
			".....oopoo::oopoo.....",
			".....oopoo::oopoo.....",
			".....oopoo::oopoo.....",
			"....ooopoo::oopooo....",
			"....ooopoo::oopooo....",
			"....ooopoo::oopooo....",
			"...oooopoo::oopoooo...",
			"...oooopoo::oopoooo...",
			"...ooooqoo::ooqoooo...",
			"...ooooooo::ooooooo...",
		],
	},
	{
		"name": "april",
		"skin": "light",
		"map": [
			".......kjjKkjjk.......",
			".....kjjkkKkjjkkK.....",
			"....kjjkkkKkkjjkkK....",
			"...kjkkkkkKkkkjkkKK...",
			"..kjkkkkkkKkkkkkjkKK..",
			"..kkkkkKshssssKkkkKK..",
			"..kkkKsshsssssssKkKK..",
			"..kKsssssssssssssSKK..",
			"..kKsssssssssssssSKK..",
			"..kKsssossssssossSKK..",
			"..kKssosossssososSKK..",
			".kkKsccssssSsssccSKKk.",
			".kkKssssoooooosssSKKk.",
			".kkKssssowwwwosssSKKk.",
			".kkKsssssoooossssSKKk.",
			".kkKssssssssssssSSKKk.",
			".kkK.SSSSSSSSSSSS.KKk.",
			".kkkK............KkkK.",
			".kkkKolltSSSStuUoKkkK.",
			".kkkKolyltsstuyUoKkkK.",
			".kkkKololuttuuoUoKkkK.",
			".kkkKollyuuuuyuUoKkkK.",
			".kkkKolluouuouuUoKkkK.",
			".KkK.olllxxxxuuUo.KkK.",
			"..ttTolulxvhxuuUotTT..",
			"..TTToluuxhyxTTUoTTT..",
			"..ssSoluuxxxxuuUosSS..",
			"..ssSoluluuuuuuUosSS..",
			"..ooooluuuuuuuuUosSS..",
			"..ssSoluuuuuuuUUosSS..",
			"..sSSouuuuuuuuUUoSSS..",
			"......uuuuuuuuUU......",
			"......UUUUUUUUUU......",
			"......oooooooooo......",
			"......opoooooopo......",
			"......opoooooopo......",
			"......opoo::oopo......",
			"......opoo::oopo......",
			"......opoo::oopo......",
			"......opoo::oopo......",
			"......opoo::oopo......",
			"......opoo::oopo......",
			"......opoo::oopo......",
			"......opoo::oopo......",
			".....ooooo::ooooo.....",
			".....oqooo::oqooo.....",
			".....ooooo::ooooo.....",
		],
	},
	{
		"name": "kervin",
		"skin": "medium",
		"map": [
			".........kjjkkkkk.....",
			".....kkkkjjjkkkkkK....",
			"...kkkjjkkkkkkkkkKK...",
			"..kkjjkkkkkkkkkkkkKK..",
			"..kkjkkkkkkkkkkkkkKK..",
			"..kkkkkkkkKkkkkkkkKK..",
			"..kKKkkkkkKkkkkkkKKK..",
			"..kKshhssssssKkkkkkK..",
			"..KshsKKssssssKKskkK..",
			"..KsssssssssssssssSK..",
			"..sssssossssssosssSS..",
			"..sssssossssssosssSS..",
			"...shssssssSssssssS...",
			"...sssssossssossssS...",
			"...ssssssoooosssssS...",
			"...ssssssssssssssSS...",
			"....SSSSSSSSSSSSSS....",
			"......................",
			".llllllltwwwwtuuUuuUU.",
			".luUolnlltwwtuunUouUU.",
			".luUolnluuttuuunUouUU.",
			".luUollnuuuuuunuUouUU.",
			".luUollunuuuunuuUouUU.",
			".luUolluunuunuuuUouUU.",
			".ttTolluuwwwwuuuUotTT.",
			".TTToluuuwkkwuTTUoTTT.",
			".ssSoluuuwsswuuuUosSS.",
			".ssSoluuuwwwwuuuUosSS.",
			".ssSoluuuwUUwuuuUosSS.",
			".ssSoluuuuuuuuuuUosSS.",
			".ssSoluluuuuuuuuUosSS.",
			".ssSoluuuuuuuuuuUoooo.",
			".ssSoluuuuuuuuuUUosSS.",
			".sSSouuuuuuuuuuUUoSSS.",
			".....uuuuuuuuuuUU.....",
			".....uuuuuuuuuuUU.....",
			".....UUUUUUUUUUUU.....",
			".....oooooooooooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			".....opooo::opooo.....",
			"....oooooo::oooooo....",
			"....oqoooo::oqoooo....",
			"....oooooo::oooooo....",
		],
	},
	{
		"name": "chelzy",
		"skin": "medium",
		"map": [
			"......kkjjkkkk......",
			"....kjjjkkkkkkkK....",
			"...kjjkkkkkkkkkkK...",
			"..kjjkkkkkkkkkkkKK..",
			".kjjkkkkkkkkkkkkkKK.",
			".kjkkkkkkkkkkkkkkKK.",
			".kkkkkkkkkkkkkkkkKK.",
			".kkkkKkkkkKkkkkKkKK.",
			".kkkKkkkKkkkkKkkKKK.",
			".kKKKKKKKKKKKKKKKKK.",
			".kKSSssssssssssSSKK.",
			".kKssoossssssoosSKK.",
			".kKssssssssssssSSKK.",
			".kKsssssssSssssSSKK.",
			".KKsssssossosssSSKK.",
			"...ssssssoossssSS...",
			"...sssssssssssSSS...",
			"....SSSSSSSSSSSS....",
			"....................",
			"..iiaiiaaazaaAaaAA..",
			"..iaAoAAAAzAAAoaAA..",
			"..iaAoiyaaqayAoaAA..",
			"..iaAoioaazaoAoaAA..",
			"..iaAoiayazyaAoaAA..",
			"..iaAoiawwwwaAoaAA..",
			"..iaAoiawkkwaAoaAA..",
			"..iaAoiawsswaAoaAA..",
			"..iaAoiawwwwaAoaAA..",
			"..iaAoiawAAwaAoaAA..",
			"..iaAoiaaazaaAoaAA..",
			"..iaAoiiaazaaAoaAA..",
			"..iaAoiaaazaaAoaAA..",
			"..iaAoiaaazaAAoaAA..",
			"..iiAoiaaazaaAoaAA..",
			"..iaAoiiaazaaAoaAA..",
			"..iaAoiaaazaaAoaAA..",
			"..iaAoiaaazaaAoaAA..",
			"..iaAoiaaazaAAoaAA..",
			"..iaAoiiaazaaAoaAA..",
			"..iaAoiaaazaaAoaAA..",
			"..AAAoiaaazaaAoAAA..",
			"..ssSoiaaazaaAosSS..",
			"..ssSoAAAAzAAAosSS..",
			"..sSSoAAAAzAAAoSSS..",
			"......wwwwwwww......",
			".....oooooooooo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			".....odDo::odDo.....",
			"....ooooo::ooooo....",
			"....oqooo::oqooo....",
			"....ooooo::ooooo....",
		],
	},
	{
		"name": "psalm",
		"skin": "medium",
		"map": [
			"........kkjjjjkkkk........",
			".....kkjjkkkjjkkkjjkK.....",
			"...kjjkKkjjkKkjjkKkjjkK...",
			"..kjkKkjjkKkjjkKkjjkKkkK..",
			".kkKkjjkKkjjkKkjjkKkjjkKK.",
			"kjjkKkjjkKkjjkKkjjkKkjjkKK",
			"kkKkjjkKkjjkKkjjkKkjjkKkKK",
			"kkKkkKkkKkkKkkKkkKkkKkkKKK",
			"kkKKKKKKKKKKKKKKKKKKKKKKKK",
			"kkKSsssssssssssssssssSSKKK",
			"kkKsssssossssssssosssSSKKK",
			"kkKsssssossssssssosssSSKKK",
			"kkKsssccssssssssssccsSSKKK",
			"....ssssssossssosssssS....",
			"....sssssssoooossssssS....",
			"....ssssssssssssssssSS....",
			".....sssssssssssssSSS.....",
			"......SSSSSSSSSSSSSS......",
			"..........................",
			"..llllllltSSSSSStuuUuuUU..",
			"..luUollyltsssstuyuUouUU..",
			"..luUolluoutsstuouuUouUU..",
			"..ttTolluuyuttuyuuuUotTT..",
			"..TTTolluuubbbbuuuuUoTTT..",
			"..ssSoluuuubkkbuTTuUosSS..",
			"..ssSoluuuubssbuuuuUosSS..",
			"..sSSoluuuubbbbuuuUUoSSS..",
			"......UUUUUUUUUUUUUU......",
			"......oooooooooooooo......",
			"......oopooo::oopooo......",
			"......oopooo::oopooo......",
			".....oqooooo::oqooooo.....",
			".....ooooooo::ooooooo.....",
		],
	},
]

## Hero-sized versions (with the outline: Psalm 18 px tall, Sarah and April 24 like the current
## heroes, Kervin 27, Chelzy 34). Heads stay the same size; the height is in the body and legs.
const TEAM_SMALL := [
	{
		"name": "sarah",
		"skin": "light",
		"map": [
			"...kkjjjkkk...",
			".kkjjkkkkkkkK.",
			"kjjkkkkkkkkkKK",
			"kjkkkkkkkkkKKK",
			"kkkkkkkkkKsKKK",
			"kKKKKKKsssssKK",
			"kKssossssosSKK",
			"kKssossssosSKK",
			"kKscsssssscSKK",
			"kwsssSooSsSSwK",
			"kK.SSSSSSSS.KK",
			"..............",
			"llllltSStuUuUU",
			"luolyuttuyUouU",
			"tTollouuouUotT",
			"sSoluubbuuUogG",
			"sSouuubbuuUosS",
			"sSoUUUUUUUUosS",
			"...eeeeeeee...",
			"...epeooepe...",
			"...epeooepe...",
			"..eepeooepee..",
			"..oooo::oooo..",
		],
	},
	{
		"name": "april",
		"skin": "light",
		"map": [
			"...kjjKkjjk...",
			".kjjkkKkkjjkK.",
			"kjkkkkKkkkkkKK",
			"kkkkKshsKkkkKK",
			"kkKsshssssKkKK",
			"kKssossssosSKK",
			"kKsosossosoSKK",
			"kKscsssssscSKK",
			"kKsssowwossSKK",
			"kKssssoossSSKK",
			"kK.SSSSSSSS.KK",
			"kK..........KK",
			"kKolltSStuUoKK",
			"kKolyuttuyUoKK",
			"tTollouuouUotT",
			"sSoluuvxuuUosS",
			"sSouuuxxuuUosS",
			"sSoUUUUUUUUosS",
			"...eeeeeeee...",
			"...epeooepe...",
			"...epeooepe...",
			"...epeooepe...",
			"..oooo::oooo..",
		],
	},
	{
		"name": "kervin",
		"skin": "medium",
		"map": [
			".....kjjkkkk..",
			"..kkkjjkkkkkK.",
			".kkjjkkkkkkkKK",
			"kKshhsssKkkkKK",
			"KssKKssssKKskK",
			"ssssossssossSS",
			"ssssossssossSS",
			".shsssssssssS.",
			".ssssossosssS.",
			".sssssoossssS.",
			"..SSSSSSSSSS..",
			"..............",
			"llllltwwtuUuUU",
			"luolnuttunUouU",
			"luolunuunuUouU",
			"tToluuwwuuUotT",
			"sSouuuwwuuUosS",
			"sSouluuuuuUosS",
			"sSoUUUUUUUUosS",
			"...eeeeeeee...",
			"...epeooepe...",
			"...epeooepe...",
			"...epeooepe...",
			"...epeooepe...",
			"...epeooepe...",
			"..oooo::oooo..",
		],
	},
	{
		"name": "chelzy",
		"skin": "medium",
		"map": [
			"...kkjjkk...",
			".kjjkkkkkkK.",
			"kjjkkkkkkkKK",
			"kjkkkkkkkkKK",
			"kkkKkkkKkkKK",
			"kKKKKKKKKKKK",
			"kKSssssssSKK",
			"kKsoossooSKK",
			"kKsssssssSKK",
			"KKssossosSKK",
			"KKsssoossSKK",
			"...SSSSSS...",
			"............",
			"iaaAAAzAAaAA",
			"iaoyaaqayoaA",
			"iaoioazoaoaA",
			"iaoiawwaAoaA",
			"iaoiawwaAoaA",
			"iaoiaazaAoaA",
			"AAoiaazaAoAA",
			"sSoAAAzAAosS",
			"sSowwwwwwosS",
			"...dddDDD...",
			"...dDoodD...",
			"...dDoodD...",
			"...dDoodD...",
			"...dDoodD...",
			"...dDoodD...",
			"...dDoodD...",
			"...dDoodD...",
			"...dDoodD...",
			"...dDoodD...",
			"..ooo::ooo..",
		],
	},
	{
		"name": "psalm",
		"skin": "medium",
		"map": [
			"....kkjjjjkk....",
			"..kkjjkkjjkkkK..",
			".kjjkkjjkkjjkkK.",
			"kjkKkjjKkjjKkjKK",
			"kkKkKKkKKkKKkKKK",
			"kKSssssssssssSKK",
			"kKssossssssosSKK",
			"kKssossssssosSKK",
			"kKscssossosscSKK",
			".ssssssoosssssS.",
			"...SSSSSSSSSS...",
			"................",
			".llllltSStuUuUU.",
			".tToluyttyuUotT.",
			".sSoUUUbbUUUosS.",
			"....epeooepe....",
			"...oooo::oooo...",
		],
	},
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var small_palette: Dictionary = PALETTE.duplicate()
	small_palette.merge(SMALL_OVERRIDES, true)
	var sets := [
		{"team": TEAM, "dir": OUT_DIR, "canvas": CANVAS, "palette": PALETTE, "scale": PREVIEW_SCALE},
		{"team": TEAM_SMALL, "dir": SMALL_DIR, "canvas": SMALL_CANVAS, "palette": small_palette,
			"scale": SMALL_PREVIEW_SCALE},
	]
	for i in sets.size():
		var kind: Dictionary = sets[i]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(kind.dir))
		var sprites := {}
		for person: Dictionary in kind.team:
			var img := _draw_person(person, kind.canvas, kind.palette)
			if img == null:
				quit(1)
				return
			var err := img.save_png(kind.dir + person.name + ".png")
			print("%s%s.png: %s (%s)" % [kind.dir, person.name, img.get_used_rect().size, error_string(err)])
			sprites[person.name] = img
		if args.size() > i:
			_write_preview(sprites, args[i], kind.scale)
	quit()


## Turns a character map into a canvas-sized image (centred, feet on the bottom row).
func _draw_person(person: Dictionary, canvas: Vector2i, palette: Dictionary) -> Image:
	var rows: Array = person.map
	var w: int = rows[0].length()
	var h := rows.size()
	for i in h:
		if rows[i].length() != w:
			push_error("%s: row %d is %d wide, expected %d" % [person.name, i, rows[i].length(), w])
			return null

	var colors: Dictionary = palette.duplicate()
	colors.merge(SKINS[person.skin], true)

	# Map with a 1 px empty border, so the outline has room.
	var grid: Array[String] = []
	grid.append(".".repeat(w + 2))
	for row: String in rows:
		grid.append("." + row + ".")
	grid.append(".".repeat(w + 2))

	var img := Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)
	for y in h + 2:
		for x in w + 2:
			var ch := grid[y][x]
			if ch == ":":
				continue
			if ch == "." and _touches_fill(grid, x, y):
				ch = "o"
			if ch == ".":
				continue
			if not colors.has(ch):
				push_error("%s: unknown colour '%s' at %d,%d" % [person.name, ch, x - 1, y - 1])
				return null
			img.set_pixel(x, y, colors[ch])

	var used := img.get_used_rect()
	if used.size.x > canvas.x or used.size.y > canvas.y:
		push_error("%s: %s does not fit the %s canvas" % [person.name, used.size, canvas])
		return null
	var out := Image.create(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	var at := Vector2i((canvas.x - used.size.x) / 2, canvas.y - used.size.y)
	out.blit_rect(img, used, at)
	return out


## True when a 4-neighbour is a coloured pixel that is not already dark (so it needs an outline).
func _touches_fill(grid: Array[String], x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + d.x
		var ny := y + d.y
		if ny < 0 or ny >= grid.size() or nx < 0 or nx >= grid[ny].length():
			continue
		var n := grid[ny][nx]
		if n != "." and n != ":" and n != "o":
			return true
	return false


## The team side by side (group photo order), bottoms aligned, scaled up for viewing.
func _write_preview(sprites: Dictionary, path: String, scale: int) -> void:
	const GAP := 6
	var crops: Array[Image] = []
	var width := GAP
	var height := 0
	for name: String in LINEUP:
		var img: Image = sprites[name]
		var c := img.get_region(img.get_used_rect())
		crops.append(c)
		width += c.get_width() + GAP
		height = maxi(height, c.get_height())
	var sheet := Image.create(width, height + GAP * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("c9ced6"))
	var x := GAP
	for c in crops:
		sheet.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, GAP + height - c.get_height()))
		x += c.get_width() + GAP
	sheet.resize(sheet.get_width() * scale, sheet.get_height() * scale, Image.INTERPOLATE_NEAREST)
	var err := sheet.save_png(path)
	print("preview: %s (%s)" % [path, error_string(err)])
