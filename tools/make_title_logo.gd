extends SceneTree
## Draws the "CODE ODYSSEY" title letters into assets/shared/ui/menu/title_letters.png:
## one chunky, glossy, colourful block letter per cell (11 cells, in the order C O D E O D Y S S E Y),
## which scripts/ui/title_logo.gd places and bounces. The letter shapes are hand-made 7x9 bitmaps
## below (no font files used).
## Run:  godot --headless --path . --script res://tools/make_title_logo.gd
## Then: godot --headless --path . --import

const OUT := "res://assets/shared/ui/menu/title_letters.png"
const CELL := 3  ## Pixels per bitmap dot.
const GW := 7
const GH := 9
const PAD := 5  ## Room around a glyph for the outline and the 3D side.
const EXTRUDE := 3
const LETTER_W := GW * CELL + PAD * 2 + EXTRUDE  ## Keep in step with title_logo.gd
const LETTER_H := GH * CELL + PAD * 2 + EXTRUDE
const TEXT := "CODEODYSSEY"

const GLYPHS := {
	"C": ["0111110", "1111111", "1100011", "1100000", "1100000", "1100000", "1100011", "1111111", "0111110"],
	"O": ["0111110", "1111111", "1100011", "1100011", "1100011", "1100011", "1100011", "1111111", "0111110"],
	"D": ["1111110", "1111111", "1100011", "1100011", "1100011", "1100011", "1100011", "1111111", "1111110"],
	"E": ["1111111", "1111111", "1100000", "1111100", "1111100", "1100000", "1100000", "1111111", "1111111"],
	"Y": ["1100011", "1100011", "1110111", "0111110", "0011100", "0011100", "0011100", "0011100", "0011100"],
	"S": ["0111111", "1111111", "1100000", "1111110", "0111111", "0000011", "0000011", "1111111", "1111110"],
}

## [face top, face bottom, 3D side]
const COLORS := [
	[Color("ff7a85"), Color("e03a5a"), Color("8f1f3d")],  # red
	[Color("ffbd5c"), Color("f07a24"), Color("9a4413")],  # orange
	[Color("fff07a"), Color("f2bd2a"), Color("a37a12")],  # yellow
	[Color("8cf08a"), Color("39b552"), Color("1f6e34")],  # green
	[Color("7aeaff"), Color("30a4dc"), Color("1b6590")],  # cyan
	[Color("93a9ff"), Color("4c63e0"), Color("2a3a95")],  # blue
	[Color("c999ff"), Color("8a4fe0"), Color("55289b")],  # purple
	[Color("ff94d2"), Color("e04ba0"), Color("902a69")],  # pink
]
const OUTLINE := Color("1b1530")

var atlas: Image


func _init() -> void:
	atlas = Image.create(LETTER_W * TEXT.length(), LETTER_H, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	for i in TEXT.length():
		_draw_letter(TEXT[i], i)
	atlas.save_png(ProjectSettings.globalize_path(OUT))
	print("Saved ", OUT, " ", atlas.get_size(), " letter cell ", Vector2i(LETTER_W, LETTER_H))
	quit()


func _draw_letter(ch: String, index: int) -> void:
	var rows: Array = GLYPHS[ch]
	var pal: Array = COLORS[index % COLORS.size()]
	# Pixel mask of the glyph, placed at (PAD, PAD) in the cell.
	var w := LETTER_W
	var h := LETTER_H
	var face := PackedByteArray()
	face.resize(w * h)
	for r in GH:
		for c in GW:
			if rows[r][c] == "1":
				for yy in CELL:
					for xx in CELL:
						face[(PAD + r * CELL + yy) * w + PAD + c * CELL + xx] = 1
	# 3D side: the face shifted down-right a few times.
	var body := face.duplicate()
	for d in range(1, EXTRUDE + 1):
		for y in h:
			for x in w:
				if face[y * w + x] == 1 and x + d < w and y + d < h:
					body[(y + d) * w + x + d] = 1
	var ox := index * LETTER_W
	# Outline: 2px dilation of the body.
	for y in h:
		for x in w:
			if body[y * w + x] == 1:
				continue
			var near := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and ny >= 0 and nx < w and ny < h and body[ny * w + nx] == 1:
						near = true
			if near:
				atlas.set_pixel(ox + x, y, OUTLINE)
	for y in h:
		for x in w:
			if body[y * w + x] == 1 and face[y * w + x] == 0:
				atlas.set_pixel(ox + x, y, pal[2])
	for y in h:
		for x in w:
			if face[y * w + x] == 1:
				var t := float(y - PAD) / float(GH * CELL)
				var col: Color = (pal[0] as Color).lerp(pal[1], t)
				# Gloss: a bright rim on edges facing up/left, a dark one facing down/right.
				var up_empty := y == 0 or face[(y - 1) * w + x] == 0
				var left_empty := x == 0 or face[y * w + x - 1] == 0
				var down_empty := y == h - 1 or face[(y + 1) * w + x] == 0
				var right_empty := x == w - 1 or face[y * w + x + 1] == 0
				if up_empty or left_empty:
					col = col.lerp(Color.WHITE, 0.55)
				elif down_empty or right_empty:
					col = col.darkened(0.18)
				atlas.set_pixel(ox + x, y, col)
	# Little shine dot on the top-left of the glyph.
	for r in GH:
		for c in GW:
			if rows[r][c] == "1":
				var px := ox + PAD + c * CELL + 1
				var py := PAD + r * CELL + 1
				if atlas.get_pixel(px, py).a > 0.0 and (r == 1 or r == 2) and c < 3:
					atlas.set_pixel(px, py, Color(1, 1, 1, 0.9))
				break
