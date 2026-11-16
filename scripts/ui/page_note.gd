class_name PageNote
extends CanvasLayer
## The note that slides in at the top right when a room makes a new variable name usable:
##   [book]  NEW DICTIONARY PAGE
##           bridgeLength
##           Press 1, then left-click to read
## The name is in the code font, so camelCase reads right. It stays a few seconds; the NEW tag
## on the hotbar slot stays until the page is read. Level 1 makes one (scripts/level2/level2.gd).

const BOOKS := preload("res://assets/shared/items/books.png")
const DICTIONARY_BOOK := 1  ## Blue: the dictionary's cover in books.png (see ManualLibrary).
const PAPER := Color("f4e8cc")
const LEATHER := Color("6b3e26")
const INK := Color("3d2416")
const NEW_COLOR := Color("c0392b")
const NAME_COLOR := Color("1e6f66")
const SHOW_TIME := 6.0
const MARGIN := 8.0
const TOP := 30.0  ## Under the coin counter.

var _slide: Control  ## Full-screen holder: moving it slides the note in and out.
var _panel: PanelContainer
var _names: Label
var _how: Label
var _tween: Tween


func _ready() -> void:
	layer = 12
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = LEATHER
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.anti_aliasing = false
	style.content_margin_left = 6
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_offset = Vector2(2, 3)
	style.shadow_size = 1
	_panel.add_theme_stylebox_override("panel", style)
	_slide = Control.new()
	_slide.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slide)
	_slide.add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = -MARGIN
	_panel.offset_right = -MARGIN
	_panel.offset_top = TOP

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)
	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = BOOKS
	atlas.region = Rect2(DICTIONARY_BOOK * 16, 0, 16, 16)
	icon.texture = atlas
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var title := _label(column, GameFonts.TEXT_BOLD, GameFonts.TEXT_SIZE, NEW_COLOR)
	title.text = "NEW DICTIONARY PAGE"
	_names = _label(column, GameFonts.CODE_BOLD, GameFonts.CODE_SIZE + 1, NAME_COLOR)
	_how = _label(column, GameFonts.TEXT, GameFonts.TEXT_SIZE, INK)
	visible = false


## Slides the note in for these variables. `slot` is the dictionary's hotbar slot (1-6, or 0).
func show_pages(variables: Array, slot: int) -> void:
	_names.text = ", ".join(variables)
	var title: Label = _names.get_parent().get_child(0)
	title.text = "NEW DICTIONARY PAGES" if variables.size() > 1 else "NEW DICTIONARY PAGE"
	_how.text = "Press %d, then left-click to read" % slot if slot > 0 else "Open the Variable Dictionary"
	if _tween:
		_tween.kill()
	# The note is pinned to the right edge and grows to the left, so it fits whatever its text.
	# Sliding moves the whole layer in from off-screen.
	var away := _panel.get_viewport_rect().size.x
	_slide.position.x = away
	visible = true
	Sound.play("page_turn")
	_tween = create_tween()
	_tween.tween_property(_slide, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(SHOW_TIME)
	_tween.tween_property(_slide, "position:x", away, 0.3).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func(): visible = false)


## The note's text, for the tests: the title, the names and how to read them.
func text() -> String:
	return "%s %s %s" % [_names.get_parent().get_child(0).text, _names.text, _how.text] if visible else ""


func _label(parent: Node, font: Font, size: int, colour: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
