extends CanvasLayer
## Chest window in the wood & paper style of Pixel Frog's UI sheet:
## a "Chest" panel on top, the player's "Hotbar" panel below, and a close tab.
## Click an item to move it between the chest and the hotbar. F or Esc closes.
## Chests find this node through the "chest_window" group, so put one in every level.
## The whole window is built in code from the palette below, so colours are easy to tweak.

signal closed

const FONT := preload("res://assets/shared/ui/fonts/minecraftia/Minecraftia-Regular.ttf")
const SLOT_COUNT := 5
const SLOT_SIZE := 24
const TIP_TIME := 3.0
const DEFAULT_TIP := "F / Esc - Close"

# Palette sampled from assets/shared/ui/wood_paper/wood_paper_ui_sheet.png
const OUTLINE := Color("33323d")
const WOOD := Color("ae7764")
const WOOD_DARK := Color("833f4c")
const PANEL := Color("c57f69")
const PANEL_DARK := Color("985252")
const PAPER := Color("daab76")
const PAPER_EDGE := Color("b77357")
const PAPER_LIGHT := Color("e7cd8d")
const PAPER_DARK := Color("a04f45")
const BANNER := Color("eebd8a")

var _chest: Node  ## the ManualChest being looked at (holds `slots`)
var _player: CharacterBody2D
var _player_input_before := true
var _chest_slots: Array[Panel] = []
var _hotbar_slots: Array[Panel] = []
var _hovered: Panel
var _tip_id := 0

var tip: Label
var tooltip: Label


func _ready() -> void:
	add_to_group("chest_window")
	visible = false
	_build()


func open(chest: Node) -> void:
	_chest = chest
	_player = get_tree().get_first_node_in_group("player")
	_player_input_before = _player.input_enabled
	_player.input_enabled = false
	_player.inventory_changed.connect(_refresh)
	tip.text = DEFAULT_TIP
	visible = true
	_refresh()


func close() -> void:
	visible = false
	tooltip.visible = false
	_hovered = null
	_player.inventory_changed.disconnect(_refresh)
	_player.input_enabled = _player_input_before
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		close()
	# While the window is open, keys don't reach the game (no terminal, no hotbar keys).
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if tooltip.visible:
		tooltip.position = tooltip.get_viewport().get_mouse_position() + Vector2(8, -16)


# ---------------- Moving items ----------------

func _on_slot_clicked(kind: String, index: int) -> void:
	Sound.play("ui_select")
	if kind == "chest":
		var id: String = _chest.slots[index]
		if id == "":
			return
		var slot: int = _player.add_item(id)
		if slot == -1:
			_show_tip("Your hotbar is full!")
			return
		_chest.slots[index] = ""
		if id.begins_with(ItemDB.MANUAL_PREFIX):
			_show_tip("Press %d to hold it, left-click to read!" % (slot + 1))
		else:
			_show_tip("Moved to hotbar slot %d" % (slot + 1))
	else:
		var id: String = _player.inventory[index]
		if id == "":
			return
		var free: int = _chest.slots.find("")
		if free == -1:
			_show_tip("The chest is full!")
			return
		_player.remove_item(id)
		_chest.slots[free] = id
		_show_tip("Put back in the chest")
	_refresh()
	_update_tooltip()


## Shows a hint in the bottom tab for a few seconds, then goes back to "F / Esc - Close".
func _show_tip(text: String) -> void:
	_tip_id += 1
	var id := _tip_id
	tip.text = text
	await get_tree().create_timer(TIP_TIME).timeout
	if id == _tip_id:
		tip.text = DEFAULT_TIP


func _refresh() -> void:
	for s in _chest_slots + _hotbar_slots:
		s.queue_redraw()


func _slot_item(slot: Panel) -> String:
	if _chest == null or slot == null:
		return ""
	var index: int = slot.get_meta("index")
	return _chest.slots[index] if slot.get_meta("kind") == "chest" else _player.inventory[index]


func _update_tooltip() -> void:
	var id := _slot_item(_hovered)
	tooltip.visible = id != ""
	if id != "":
		tooltip.text = ItemDB.get_item(id)["name"]
		tooltip.size = tooltip.get_combined_minimum_size()


# ---------------- Building the window ----------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)

	column.add_child(_section("Chest", PANEL, PAPER, PAPER_EDGE, "chest", _chest_slots))
	column.add_child(_section("Hotbar", PANEL_DARK, PANEL, WOOD_DARK, "hotbar", _hotbar_slots))

	var tab_holder := CenterContainer.new()
	tab_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(tab_holder)
	var tab := _banner(DEFAULT_TIP)
	tip = tab.get_child(0)
	tab_holder.add_child(tab)

	tooltip = Label.new()
	tooltip.add_theme_font_override("font", FONT)
	tooltip.add_theme_font_size_override("font_size", 8)
	tooltip.add_theme_color_override("font_color", OUTLINE)
	tooltip.add_theme_stylebox_override("normal", _box(BANNER, OUTLINE, 1, 2, Vector4(4, 2, 4, 0)))
	tooltip.z_index = 5
	tooltip.visible = false
	add_child(tooltip)


## A wooden panel with a ribbon title overlapping its top edge.
func _section(title: String, inside: Color, slot_bg: Color, slot_edge: Color,
		kind: String, slots: Array[Panel]) -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", -7)  # ribbon overlaps the panel
	section.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title_holder := CenterContainer.new()
	title_holder.z_index = 1
	title_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_holder.add_child(_banner(title))
	section.add_child(title_holder)

	# wood frame -> inner panel -> row of slots
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(WOOD, OUTLINE, 1, 4, Vector4(3, 3, 3, 3), WOOD_DARK))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(frame)
	var inner := PanelContainer.new()
	inner.add_theme_stylebox_override("panel", _box(inside, WOOD_DARK, 1, 3, Vector4(7, 10, 7, 6)))
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(inner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(row)

	for i in SLOT_COUNT:
		slots.append(_make_slot(row, kind, i, slot_bg, slot_edge))
	return section


func _banner(text: String) -> PanelContainer:
	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel", _box(BANNER, OUTLINE, 1, 2, Vector4(8, 3, 8, 1), PAPER_EDGE))
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", OUTLINE)
	banner.add_child(label)
	return banner


func _make_slot(row: HBoxContainer, kind: String, index: int, bg: Color, edge: Color) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.set_meta("kind", kind)
	slot.set_meta("index", index)
	slot.set_meta("bg", bg)
	slot.set_meta("edge", edge)
	slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	slot.draw.connect(_draw_slot.bind(slot))
	slot.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_slot_clicked(kind, index))
	slot.mouse_entered.connect(func():
		_hovered = slot
		slot.queue_redraw()
		_update_tooltip())
	slot.mouse_exited.connect(func():
		if _hovered == slot:
			_hovered = null
		slot.queue_redraw()
		_update_tooltip())
	row.add_child(slot)
	return slot


## Rounded slot like the reference: dark edge, thicker at the bottom, item icon in the middle.
func _draw_slot(slot: Panel) -> void:
	var hovered := slot == _hovered
	var bg: Color = PAPER_LIGHT if hovered else slot.get_meta("bg")
	var style := _box(bg, slot.get_meta("edge"), 1, 3, Vector4.ZERO)
	style.border_width_bottom = 2
	slot.draw_style_box(style, Rect2(Vector2.ZERO, slot.size))
	var id := _slot_item(slot)
	if id == "":
		return
	var item := ItemDB.get_item(id)
	var region: Rect2 = item["region"]
	var angle := -PI / 4.0 if item.get("diagonal", false) else 0.0
	slot.draw_set_transform(slot.size / 2.0 + Vector2(0, -0.5), angle)
	slot.draw_texture_rect_region(item["texture"], Rect2(-region.size / 2.0, region.size), region)
	slot.draw_set_transform(Vector2.ZERO)


## Flat pixel-art box: fill, outline, rounded corners, inner padding (left, top, right, bottom),
## and an optional darker bottom edge for a bit of depth.
func _box(fill: Color, border: Color, width: int, radius: int, padding: Vector4,
		bottom := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.corner_detail = 2
	s.anti_aliasing = false
	s.content_margin_left = padding.x
	s.content_margin_top = padding.y
	s.content_margin_right = padding.z
	s.content_margin_bottom = padding.w
	if bottom.a > 0.0:
		s.shadow_color = bottom
		s.shadow_size = 0
		s.shadow_offset = Vector2(0, 2)
	return s
