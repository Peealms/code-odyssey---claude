extends CanvasLayer
## Shows a manual from ManualLibrary as an open book: two parchment pages side by side, split by
## the spine (like Minecraft's book and quill), in a leather cover with Byte's teal bookmark.
## The game pauses while it's open.
## A / D (or the arrow keys, or the arrow buttons) turn two pages at a time; F or Esc closes it.
## Chests find this node through the "manual_reader" group, so put one in every level.
## The book is built in code below; change the colours and sizes in the constants.

signal closed

const FONT := preload("res://assets/shared/ui/fonts/minecraftia/Minecraftia-Regular.ttf")
const NEXT_ICON := preload("res://assets/shared/ui/buttons/next.png")
const PREV_ICON := preload("res://assets/shared/ui/buttons/previous.png")
const CLOSE_ICON := preload("res://assets/shared/ui/buttons/close.png")

const BOOK_SIZE := Vector2(540, 300)
const PAGE_SIZE := Vector2(244, 262)
const LEATHER := Color("6b3e26")
const LEATHER_DARK := Color("3b2114")
const GOLD := Color("e0b04a")
const PAPER := Color("f4e8cc")
const PAPER_EDGE := Color("c9b48a")
const INK := Color("3d2416")
const FADED := Color("a08868")
const TEAL := Color("2a9d8f")
const CODE_BG := Color("2b2135")
const CODE_INK := Color("7cf07c")
const INLINE_CODE := Color("1e6f66")
const FONT_SIZE := 8

var _manual: Dictionary = {}
var _spread := 0  ## Index of the left page being shown (always even).

var _book: Control
var _pages: Array[RichTextLabel] = []
var _headers: Array[Label] = []
var _prev: TextureButton
var _next: TextureButton
var _title: Label


func _ready() -> void:
	add_to_group("manual_reader")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 45
	visible = false
	_build()


func open(manual_id: String) -> void:
	_manual = ManualLibrary.get_manual(manual_id)
	if _manual.is_empty():
		push_warning("Unknown manual: %s" % manual_id)
		return
	_spread = 0
	_title.text = _manual["title"]
	_show_spread()
	visible = true
	get_tree().paused = true
	# Pop open.
	_book.pivot_offset = BOOK_SIZE / 2.0
	_book.scale = Vector2(0.85, 0.85)
	_book.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_book, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_book, "modulate:a", 1.0, 0.12)


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		_turn(-1)
	elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		_turn(1)
	elif event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _turn(step: int) -> void:
	var count: int = _manual["pages"].size()
	var spread := clampi(_spread + step * 2, 0, maxi(count - 1, 0) / 2 * 2)
	if spread == _spread:
		return
	_spread = spread
	# A quick fade of the text, as if the page turned.
	for p in _pages:
		p.modulate.a = 0.0
	_show_spread()
	var tween := create_tween().set_parallel()
	for p in _pages:
		tween.tween_property(p, "modulate:a", 1.0, 0.15)


func _show_spread() -> void:
	var pages: Array = _manual["pages"]
	for side in 2:
		var i := _spread + side
		if i < pages.size():
			_pages[side].text = _style_code(pages[i])
			_headers[side].text = "Page %d of %d" % [i + 1, pages.size()]
		else:
			_pages[side].text = ""
			_headers[side].text = ""
	_title.visible = _spread == 0
	# The first page starts lower, under the title.
	_pages[0].position.y = 40 if _spread == 0 else 22
	_pages[0].size.y = PAGE_SIZE.y - _pages[0].position.y - 26
	_prev.disabled = _spread == 0
	_next.disabled = _spread + 2 >= pages.size()
	_prev.modulate.a = 0.3 if _prev.disabled else 1.0
	_next.modulate.a = 0.3 if _next.disabled else 1.0


## A line that is only code is shown like Byte's terminal (green on a dark strip); code inside
## a sentence is just dark teal in the book font, so it lines up with the words around it.
func _style_code(text: String) -> String:
	var lines := text.split("\n")
	for i in lines.size():
		var line := lines[i].strip_edges()
		var code_only := line.begins_with("[code]") and line.ends_with("[/code]") and line.count("[code]") == 1
		if code_only:
			lines[i] = lines[i].replace("[code]", "[bgcolor=#%s][color=#%s][code]" % [CODE_BG.to_html(false), CODE_INK.to_html(false)]) \
				.replace("[/code]", "[/code][/color][/bgcolor]")
		else:
			lines[i] = lines[i].replace("[code]", "[color=#%s]" % INLINE_CODE.to_html(false)).replace("[/code]", "[/color]")
	return "\n".join(lines)


# ---------------- Building the book ----------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var holder := Control.new()
	holder.custom_minimum_size = BOOK_SIZE + Vector2(0, 22)
	center.add_child(holder)

	# Leather cover with a dark border, gold corner studs and a drop shadow.
	_book = Panel.new()
	_book.size = BOOK_SIZE
	_book.add_theme_stylebox_override("panel", _box(LEATHER, LEATHER_DARK, 3, 6, true))
	holder.add_child(_book)
	for corner in [Vector2(6, 6), Vector2(BOOK_SIZE.x - 11, 6), Vector2(6, BOOK_SIZE.y - 11), Vector2(BOOK_SIZE.x - 11, BOOK_SIZE.y - 11)]:
		_rect(_book, corner, Vector2(5, 5), GOLD)

	# Two pages and the spine between them.
	var top := (BOOK_SIZE.y - PAGE_SIZE.y) / 2.0
	var left_x := BOOK_SIZE.x / 2.0 - PAGE_SIZE.x - 4
	var right_x := BOOK_SIZE.x / 2.0 + 4
	for side in 2:
		var page := Panel.new()
		page.position = Vector2(left_x if side == 0 else right_x, top)
		page.size = PAGE_SIZE
		page.add_theme_stylebox_override("panel", _box(PAPER, PAPER_EDGE, 1, 3, false))
		_book.add_child(page)
		# Shading toward the spine, so the pages look curved.
		var shade := ColorRect.new()
		shade.size = Vector2(10, PAGE_SIZE.y - 2)
		shade.position = Vector2(PAGE_SIZE.x - 11 if side == 0 else 1, 1)
		shade.color = Color(PAPER_EDGE, 0.35)
		page.add_child(shade)

		var header := _label(page, Vector2(0, 6), Vector2(PAGE_SIZE.x, 12), FADED)
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_headers.append(header)

		var body := RichTextLabel.new()
		body.bbcode_enabled = true
		body.scroll_active = false
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.position = Vector2(14, 22)
		body.size = PAGE_SIZE - Vector2(28, body.position.y + 26)
		body.add_theme_color_override("default_color", INK)
		body.add_theme_font_override("normal_font", FONT)
		body.add_theme_font_override("bold_font", _variation(0.7, 0.0))
		body.add_theme_font_override("italics_font", _variation(0.0, 0.2))
		body.add_theme_font_override("mono_font", _mono())
		for k in ["normal_font_size", "bold_font_size", "italics_font_size", "mono_font_size"]:
			body.add_theme_font_size_override(k, FONT_SIZE)
		body.add_theme_constant_override("line_separation", 1)
		page.add_child(body)
		_pages.append(body)

	# The first page's top holds the manual's title in Byte's teal, with an underline.
	_title = _label(_book, Vector2(left_x + 10, top + 20), Vector2(PAGE_SIZE.x - 20, 14), TEAL)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 8)
	_rect(_title, Vector2(20, 14), Vector2(PAGE_SIZE.x - 60, 1), Color(TEAL, 0.6))

	# Spine: a dark groove down the middle.
	_rect(_book, Vector2(BOOK_SIZE.x / 2.0 - 4, top - 2), Vector2(8, PAGE_SIZE.y + 4), LEATHER_DARK)
	_rect(_book, Vector2(BOOK_SIZE.x / 2.0 - 1, top), Vector2(2, PAGE_SIZE.y), Color(LEATHER, 0.8))

	# Byte's teal bookmark ribbon hanging over the top of the right page.
	var ribbon := Polygon2D.new()
	ribbon.color = TEAL
	ribbon.polygon = PackedVector2Array([Vector2(0, 0), Vector2(9, 0), Vector2(9, 34), Vector2(4.5, 29), Vector2(0, 34)])
	ribbon.position = Vector2(right_x + PAGE_SIZE.x - 30, top - 4)
	_book.add_child(ribbon)

	# Page arrows in the bottom corners, close button top right.
	_prev = _button(_book, PREV_ICON, Vector2(left_x + 6, top + PAGE_SIZE.y - 26), func(): _turn(-1))
	_next = _button(_book, NEXT_ICON, Vector2(right_x + PAGE_SIZE.x - 27, top + PAGE_SIZE.y - 26), func(): _turn(1))
	_button(_book, CLOSE_ICON, Vector2(BOOK_SIZE.x - 20, 4), close)

	var keys := _label(holder, Vector2(0, BOOK_SIZE.y + 6), Vector2(BOOK_SIZE.x, 12), Color(1, 1, 1, 0.85))
	keys.text = "A / D  TURN PAGES      F / ESC  CLOSE"
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _box(fill: Color, border: Color, width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = false
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = 1
		s.shadow_offset = Vector2(4, 5)
	return s


func _rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _label(parent: Node, pos: Vector2, size: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _button(parent: Node, icon: Texture2D, pos: Vector2, action: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = icon
	b.position = pos
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b


## Minecraftia made bolder or slanted (it has no bold or italic of its own).
func _variation(embolden: float, slant: float) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = FONT
	v.variation_embolden = embolden
	v.variation_transform = Transform2D(Vector2(1, 0), Vector2(slant, 1), Vector2.ZERO)
	return v


## Code keeps a monospace font so the lined-up examples in the manuals stay lined up.
func _mono() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Consolas", "Courier New", "Monospace"])
	return f
