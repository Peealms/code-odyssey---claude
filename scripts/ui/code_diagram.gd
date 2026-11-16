class_name CodeDiagram
extends Control
## One line of Java with every part labelled, like a textbook diagram: a title on top, the line
## in a dashed box, and an arrow from each label to its part. The manual books draw one for
## every page block like {"diagram": [...], "box": "Declaring a Variable"} (manual_library.gd).
##   parts  [[code, label, role], ...]  e.g. ["String", "Data Type", "type"]
##          `role` picks the colour (COLORS). A part whose label is "" gets no arrow.
##          No space goes before ";", ")" or a part that starts with "(".
##   box    the title over the diagram ("" for none)
## Labels take turns above and below the line (1st part above, 2nd below, ...). In each row
## they keep the order of their parts, so when a label has to slide sideways to make room its
## arrow leans a little, but arrows never cross.

const COLORS := {
	"type": Color("7b3fa0"),  # purple
	"name": Color("1e6f66"),  # teal
	"op": Color("3d2416"),  # ink
	"value": Color("b3541e"),  # orange-brown
	"end": Color("3d2416"),
	"cmd": Color("2a5d9f"),  # blue
}
const TITLE_COLOR := Color("c0392b")  ## Red, like a teacher's pen.
const BOX_COLOR := Color("4f8ca8")
const PAD := Vector2(6, 4)  ## Inside the box, around the code.
const ROW_H := 16.0  ## One row of labels (the text font's size).
const ARROW_GAP := 12.0  ## Between a label row and the box: where the arrows run.
const LABEL_GAP := 10.0  ## The least space between two labels in a row.

var _parts: Array = []
var _title := ""
var _code_x: Array[float] = []  # left edge of each part's code
var _code_w: Array[float] = []
## Each label: {text, part, up (above the line?), x, w}
var _labels: Array[Dictionary] = []
var _box := Rect2()
var _title_x := 0.0
var _offset_x := 0.0


## Lays the diagram out for a page `max_width` px wide and sets its height.
func setup(parts: Array, title: String, max_width: float) -> void:
	_parts = parts
	_title = title
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout(max_width)
	queue_redraw()


func _code_size() -> int:
	return GameFonts.CODE_SIZE + 1


func _text_width(font: Font, text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _layout(max_width: float) -> void:
	var font: Font = GameFonts.CODE_BOLD
	var size := _code_size()
	var space := _text_width(font, " ", size)
	var x := PAD.x
	_code_x.clear()
	_code_w.clear()
	for i in _parts.size():
		var code: String = _parts[i][0]
		if i > 0 and not (code == ";" or code == ")" or code.begins_with("(")):
			x += space
		_code_x.append(x)
		var w := _text_width(font, code, size)
		_code_w.append(w)
		x += w
	var box_w := x + PAD.x
	# The whole diagram is centred on the page; work it out in page coordinates.
	_offset_x = 0.0
	var box_left := floorf(maxf(0.0, (max_width - box_w) / 2.0))
	for i in _code_x.size():
		_code_x[i] += box_left

	# Labels take turns above and below, then each row is spread out without overlaps.
	_labels.clear()
	var n := 0
	for i in _parts.size():
		var text: String = _parts[i][1]
		if text == "":
			continue
		var w := _text_width(GameFonts.TEXT_BOLD, text, GameFonts.TEXT_SIZE)
		_labels.append({"text": text, "part": i, "up": n % 2 == 0, "x": 0.0, "w": w})
		n += 1
	var has_up := false
	var has_down := false
	for up in [true, false]:
		var row: Array = _labels.filter(func(l): return l["up"] == up)
		if row.is_empty():
			continue
		if up:
			has_up = true
		else:
			has_down = true
		_spread(row, max_width)

	var top := 0.0
	if _title != "":
		var w := _text_width(GameFonts.TEXT_BOLD, _title, GameFonts.TEXT_SIZE)
		_title_x = floorf(maxf(0.0, (max_width - w) / 2.0))
		top = ROW_H + 4.0
	var code_h := font.get_height(size)
	var box_top := top + (ROW_H + ARROW_GAP if has_up else 0.0)
	_box = Rect2(box_left, box_top, box_w, code_h + PAD.y * 2.0)
	var bottom := _box.end.y + (ARROW_GAP + ROW_H if has_down else 0.0)
	custom_minimum_size = Vector2(max_width, ceilf(bottom) + 2.0)


## Puts the labels of one row as close above (or below) their parts as they fit, in order.
func _spread(row: Array, max_width: float) -> void:
	for l in row:
		var centre := _code_x[l["part"]] + _code_w[l["part"]] / 2.0
		l["x"] = centre - l["w"] / 2.0
	# Push right past the label before...
	for k in row.size():
		if k > 0:
			row[k]["x"] = maxf(row[k]["x"], row[k - 1]["x"] + row[k - 1]["w"] + LABEL_GAP)
	# ...then back left, so the last one stays on the page, and nothing starts before 0.
	for k in range(row.size() - 1, -1, -1):
		var limit: float = max_width if k == row.size() - 1 else row[k + 1]["x"] - LABEL_GAP
		row[k]["x"] = minf(row[k]["x"], limit - row[k]["w"])
	for k in row.size():
		var floor_x: float = 0.0 if k == 0 else row[k - 1]["x"] + row[k - 1]["w"] + LABEL_GAP
		row[k]["x"] = roundf(maxf(row[k]["x"], floor_x))


func _draw() -> void:
	var label_font: Font = GameFonts.TEXT_BOLD
	var ascent := label_font.get_ascent(GameFonts.TEXT_SIZE)
	if _title != "":
		draw_string(label_font, Vector2(_title_x, ascent - 1.0), _title, HORIZONTAL_ALIGNMENT_LEFT, -1, GameFonts.TEXT_SIZE, TITLE_COLOR)

	# The dashed box and the code in it.
	var b := _box
	var corners := [b.position, Vector2(b.end.x, b.position.y), b.end, Vector2(b.position.x, b.end.y)]
	for k in 4:
		draw_dashed_line(corners[k], corners[(k + 1) % 4], BOX_COLOR, 1.0, 3.0, false)
	var font: Font = GameFonts.CODE_BOLD
	var size := _code_size()
	var baseline := b.position.y + PAD.y + font.get_ascent(size)
	for i in _parts.size():
		draw_string(font, Vector2(_code_x[i], baseline), _parts[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, size, _color(i))

	# Labels and their arrows: from the label (as near over its part as it reaches) to the part.
	for l in _labels:
		var i: int = l["part"]
		var colour := _color(i)
		var part_x := roundf(_code_x[i] + _code_w[i] / 2.0)
		var start_x := clampf(part_x, l["x"] + 4.0, l["x"] + l["w"] - 4.0)
		var y: float
		var from: Vector2
		var to: Vector2
		if l["up"]:
			y = b.position.y - ARROW_GAP - ROW_H
			from = Vector2(start_x, y + ROW_H - 1.0)
			to = Vector2(part_x, b.position.y + PAD.y - 1.0)
		else:
			y = b.end.y + ARROW_GAP
			from = Vector2(start_x, y + 1.0)
			to = Vector2(part_x, b.end.y - PAD.y + 1.0)
		draw_string(label_font, Vector2(l["x"], y + ascent - 1.0), l["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, GameFonts.TEXT_SIZE, colour)
		_arrow(from, to, colour)


func _color(part: int) -> Color:
	return COLORS.get(_parts[part][2] if _parts[part].size() > 2 else "op", COLORS["op"])


## A 1 px line with a little triangle head at `to`.
func _arrow(from: Vector2, to: Vector2, colour: Color) -> void:
	var dir := (to - from).normalized()
	var side := Vector2(-dir.y, dir.x)
	draw_line(from, to - dir * 3.0, colour, 1.0)
	draw_colored_polygon(PackedVector2Array([to, to - dir * 4.0 + side * 3.0, to - dir * 4.0 - side * 3.0]), colour)
