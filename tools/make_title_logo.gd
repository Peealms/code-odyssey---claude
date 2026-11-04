extends SceneTree
## Draws the "CODE ODYSSEY" title logo into assets/shared/ui/menu/title_logo.png.
## The letters are hand-made 5x7 bitmaps defined below (no font files used): chunky
## "circuit block" letters with a bevel, a dark outline, and a glowing terminal-green
## underline made of binary digits.
## Run:  godot --headless --path . --script res://tools/make_title_logo.gd
## Then: godot --headless --path . --import

const OUT := "res://assets/shared/ui/menu/title_logo.png"
const CELL := 3  ## Pixels per letter-bitmap dot.

const GLYPHS := {
	"C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
}

const OUTLINE := Color("1b1530")
const TOP_A := Color("ffe477")
const TOP_B := Color("ffb347")
const SIDE := Color("c4552b")
const GREEN := Color("8ee89c")
const GREEN_DIM := Color("3f8f5a")

var img: Image


func _init() -> void:
	var line1 := "CODE"
	var line2 := "ODYSSEY"
	var w1 := _line_width(line1)
	var w2 := _line_width(line2)
	var pad := 8
	var width := maxi(w1, w2) + pad * 2
	var line_h := 7 * CELL
	var height := pad + line_h + 8 + line_h + 6 + 10 + pad
	img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var y1 := pad
	var y2 := pad + line_h + 8
	_draw_line(line1, (width - w1) / 2, y1)
	_draw_line(line2, (width - w2) / 2, y2)
	_draw_binary_bar((width - w2) / 2, y2 + line_h + 6, w2)

	img.save_png(ProjectSettings.globalize_path(OUT))
	print("Saved ", OUT, " ", img.get_size())
	quit()


func _line_width(text: String) -> int:
	return text.length() * (5 * CELL + CELL) - CELL


func _draw_line(text: String, x0: int, y0: int) -> void:
	# Pass 1: outline + drop side; pass 2: bevelled face.
	var x := x0
	for ch in text:
		_glyph_pass(ch, x, y0, 0)
		x += 6 * CELL
	x = x0
	for ch in text:
		_glyph_pass(ch, x, y0, 1)
		x += 6 * CELL


func _glyph_pass(ch: String, gx: int, gy: int, pass_index: int) -> void:
	var rows: Array = GLYPHS[ch]
	for r in 7:
		for c in 5:
			if rows[r][c] != "1":
				continue
			var px := gx + c * CELL
			var py := gy + r * CELL
			if pass_index == 0:
				# thick outline plus a 2px extruded shadow down-right
				_rect(px - 2, py - 2, CELL + 4, CELL + 4, OUTLINE)
				_rect(px + 1, py + 2, CELL + 1, CELL + 2, SIDE)
			else:
				var t := float(r) / 6.0
				var face := TOP_A.lerp(TOP_B, t)
				_rect(px, py, CELL, CELL, face)
				# highlight on top edge of a block, "pixel" rivet in the middle
				var above_empty: bool = r == 0 or rows[r - 1][c] != "1"
				if above_empty:
					_rect(px, py, CELL, 1, Color(1, 1, 0.85))
				var left_empty: bool = c == 0 or rows[r][c - 1] != "1"
				if left_empty:
					_rect(px, py, 1, CELL, Color(1, 0.96, 0.7))
				var below_empty: bool = r == 6 or rows[r + 1][c] != "1"
				if below_empty:
					_rect(px, py + CELL - 1, CELL, 1, Color("d9812f"))


func _draw_binary_bar(x0: int, y: int, w: int) -> void:
	_rect(x0 - 2, y - 2, w + 4, 11, OUTLINE)
	_rect(x0, y, w, 7, Color("14241f"))
	# Tiny 3x5 digits "0" and "1" repeating across the bar.
	var zero := ["111", "101", "101", "101", "111"]
	var one := ["010", "110", "010", "010", "111"]
	var x := x0 + 2
	var i := 0
	while x + 3 < x0 + w - 1:
		var g: Array = zero if (i * 7 + i / 3) % 3 != 0 else one
		var col := GREEN if i % 4 != 3 else GREEN_DIM
		for r in 5:
			for c in 3:
				if g[r][c] == "1":
					img.set_pixel(x + c, y + 1 + r, col)
		x += 4
		i += 1


func _rect(x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(maxi(y, 0), mini(y + h, img.get_height())):
		for xx in range(maxi(x, 0), mini(x + w, img.get_width())):
			img.set_pixel(xx, yy, col)
