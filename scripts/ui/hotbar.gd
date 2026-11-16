extends CanvasLayer
## Minecraft-style hotbar: 6 slots at the bottom of the screen.
## Keys 1-6 or the mouse wheel pick a slot; the selected slot is the item in the hero's hand.
## Item names and icons come from ItemDB.
## set_badge(item, true) puts a bobbing NEW tag on that item's slot (the Variable Dictionary,
## while it has a page the player hasn't read).

const SLOT_SIZE := 22
const ICON_SCALE := 1.0

const SLOT_BG := Color(0.12, 0.12, 0.14, 0.6)
const SLOT_BORDER := Color(0.55, 0.55, 0.6, 0.9)
const SELECTED_BORDER := Color(1, 1, 1, 1)
const BADGE := Color("c0392b")
const BADGE_EDGE := Color("33323d")

@export var player: CharacterBody2D

var _slots: Array[Panel] = []
var _icons: Array[Control] = []
var _name_tween: Tween
var _last_held := ""
var _badges := {}  ## Item ids whose slot shows the NEW tag.
var _time := 0.0

@onready var bar: HBoxContainer = $Bar
@onready var item_name: Label = $ItemName


func _ready() -> void:
	item_name.modulate.a = 0.0
	for i in player.inventory.size():
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(slot)
		var icon := Control.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.draw.connect(_draw_icon.bind(icon, i))
		slot.add_child(icon)
		_slots.append(slot)
		_icons.append(icon)
	player.inventory_changed.connect(_on_inventory_changed)
	player.selected_slot_changed.connect(_on_selected_slot_changed)
	_last_held = player.held_item()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not player.input_enabled or get_tree().paused:
		return
	for i in _slots.size():
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			player.select_slot(i)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			player.select_slot(player.selected_slot + 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			player.select_slot(player.selected_slot - 1)


## Shows or hides the NEW tag on the slot holding `item_id` (it follows the item if it moves).
func set_badge(item_id: String, on: bool) -> void:
	if on:
		_badges[item_id] = true
	else:
		_badges.erase(item_id)
	_refresh()


func has_badge(item_id: String) -> bool:
	return _badges.has(item_id)


func _process(delta: float) -> void:
	if _badges.is_empty():
		return
	_time += delta
	for i in _icons.size():
		if player.inventory[i] in _badges:
			_icons[i].queue_redraw()


func _refresh() -> void:
	for i in _slots.size():
		var selected: bool = i == player.selected_slot
		_slots[i].add_theme_stylebox_override("panel", _slot_style(selected))
		_icons[i].queue_redraw()


func _on_inventory_changed() -> void:
	_refresh()
	_show_held_name()


func _on_selected_slot_changed(_slot: int) -> void:
	_refresh()
	_show_held_name()


## Like Minecraft: when the item in hand changes, its name shows briefly above the hotbar.
func _show_held_name() -> void:
	var id: String = player.held_item()
	if id == _last_held:
		return
	_last_held = id
	if id == "":
		item_name.modulate.a = 0.0
		return
	item_name.text = ItemDB.get_item(id)["name"]
	if _name_tween:
		_name_tween.kill()
	item_name.modulate.a = 1.0
	_name_tween = create_tween()
	_name_tween.tween_interval(1.2)
	_name_tween.tween_property(item_name, "modulate:a", 0.0, 0.5)


func _draw_icon(icon: Control, slot: int) -> void:
	var id: String = player.inventory[slot]
	if id == "":
		return
	var item := ItemDB.get_item(id)
	var region: Rect2 = item["region"]
	var center := icon.size / 2.0
	var angle := -PI / 4.0 if item.get("diagonal", false) else 0.0
	icon.draw_set_transform(center, angle, Vector2.ONE * ICON_SCALE)
	icon.draw_texture_rect_region(item["texture"], Rect2(-region.size / 2.0, region.size), region)
	icon.draw_set_transform(Vector2.ZERO)
	if id in _badges:
		# A red NEW tag over the slot's top edge, bobbing a pixel up and down.
		var bob := 1.0 if fmod(_time, 0.8) < 0.4 else 0.0
		var tag := Rect2(icon.size.x - 15.0, -8.0 - bob, 19.0, 9.0)
		icon.draw_rect(tag, BADGE)
		icon.draw_rect(tag, BADGE_EDGE, false, 1.0)
		icon.draw_string(GameFonts.TEXT_BOLD, tag.position + Vector2(3, 7), "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, GameFonts.SMALL_TEXT_SIZE, Color.WHITE)


func _slot_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.anti_aliasing = false
	style.set_border_width_all(2 if selected else 1)
	style.border_color = SELECTED_BORDER if selected else SLOT_BORDER
	if selected:
		style.set_expand_margin_all(1)
	return style
