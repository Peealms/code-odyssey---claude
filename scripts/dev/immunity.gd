extends Node
## IMMUNITY MODE - a secret testing mode. Nothing in the game shows or mentions it.
## Game adds this node only when the game runs from the Godot editor, so an exported game
## can never turn it on, even if someone knows the keys.
##
##   Ctrl+Shift+I   turn immunity on / off (anywhere: the menus or a level)
##
## While it's on:
##   - traps, enemies and pit spikes can't hurt you or send you back (falling off the map still does)
##   - Byte's terminal lets you switch to any hero, rescued or not
##   - every level is open in the level select
##   - finishing a level doesn't save its stars
##   - in a level:
##       Ctrl+Shift+R   the level's rooms: jump straight to one (or to the trophy)
##       Page Down      skip this room: finish it and go to the next one
##       Page Up        back to the previous room
##
## Jumping forward finishes every room you skip the way a player would: it runs the room's
## `answer` in Byte's terminal (so variables get declared, bridges built, gates opened, the
## ship's anchor raised...), rescues the room's hero and collects all its fruit or coins.
## The trophy jump also shows a goal the level is still hiding.
## Rooms you already walked through keep the code you typed; only their leftovers are collected.
## You arrive in the doorway from the room before. It's found from the Terrain tiles, so new
## rooms and levels work too; if you land somewhere odd, give that Room a Marker2D child named
## "Entry" and you'll arrive there instead.
##
## Before publishing: delete this file (and its .uid), then search the project for IMMUNITY
## and delete every line it finds - each hook is one whole line, so nothing else needs fixing
## (game.gd, player.gd, hazard.gd, code_terminal.gd, level_select.gd, hero_wheel.gd and
## water.gd).

const DOORWAY := 40.0  ## After a jump you may stand just outside the room's area, in its doorway.
const YELLOW := Color(1, 0.894118, 0.470588)
const DIM := Color(0.66, 0.64, 0.76)
const INK := Color(0.129412, 0.121569, 0.188235)
const EDGE := Color(0.952941, 0.835294, 0.607843, 0.7)

var on := false:
	set(value):
		on = value
		Game.immune = value

var _chip: CanvasLayer
var _chip_panel: PanelContainer
var _chip_keys: Label
var _menu: CanvasLayer
var _level_id := 0  ## The level the two below belong to (a new or restarted level forgets them).
var _room_index := -1  ## The room you last jumped to.
var _done := {}  ## Rooms finished by a jump: Room -> true.


func _init() -> void:
	name = "Immunity"


func _ready() -> void:
	_build_chip()


func _process(_delta: float) -> void:
	var terminal := _terminal()
	_chip.visible = on and not (terminal != null and terminal.is_open)
	var keys := "CTRL+SHIFT+R: ROOMS\nPGDN: NEXT   PGUP: BACK"  # narrow: the hotbar is next to it
	if not (get_tree().current_scene is Level):
		keys = "EVERY LEVEL IS OPEN"
	if _chip_keys.text != keys:
		_chip_keys.text = keys
		var fit := _chip_panel.get_combined_minimum_size()
		_chip_panel.offset_right = _chip_panel.offset_left + fit.x
		_chip_panel.offset_top = _chip_panel.offset_bottom - fit.y


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var chord := key.ctrl_pressed and key.shift_pressed
	if chord and key.keycode == KEY_I:
		_toggle()
	elif not on:
		return
	elif _menu:
		if key.keycode != KEY_ESCAPE and not (chord and key.keycode == KEY_R):
			return  # arrows and Enter go to the list
		_close_menu()
		Sound.play("terminal_close")
	elif chord and key.keycode == KEY_R:
		if not _open_menu():
			return
	elif key.keycode == KEY_PAGEDOWN or key.keycode == KEY_PAGEUP:
		var level := _level()
		if not _can_jump(level):
			return
		var here := _current_index(level, _rooms())
		_jump(here + 1 if key.keycode == KEY_PAGEDOWN else here - 1)
	else:
		return
	get_viewport().set_input_as_handled()


func _toggle() -> void:
	on = not on
	if not on:
		_close_menu()
	Sound.play("code_ok" if on else "terminal_close")
	var level := get_tree().current_scene as Level
	if level:
		level.hud.show_message("IMMUNITY ON" if on else "IMMUNITY OFF", 1.2)


# ---------------- Jumping between rooms ----------------

## The level being played (null in the menus).
func _level() -> Level:
	var level := get_tree().current_scene as Level
	if level and level.get_instance_id() != _level_id:
		_level_id = level.get_instance_id()
		_room_index = -1
		_done.clear()
	return level


## Not in the menus, the pause menu, a cutscene or after the trophy.
func _can_jump(level: Level) -> bool:
	return level != null and not get_tree().paused and not level._finished


## The level's rooms, in the order they're played (their order in the scene).
func _rooms() -> Array[Node]:
	return get_tree().get_nodes_in_group("room")


func _terminal() -> Node:
	return get_tree().get_first_node_in_group("code_terminal")


func _close_terminal() -> void:
	var terminal := _terminal()
	if terminal and terminal.is_open:
		terminal.close()


func _title(room: Room) -> String:
	return room.title if room.title != "" else String(room.name)


## The room you're in: the one you last jumped to while you're still in (or at the door of)
## it, otherwise the nearest one.
func _current_index(level: Level, rooms: Array[Node]) -> int:
	var pos := level.player.global_position
	if _room_index >= 0 and _room_index < rooms.size() and rooms[_room_index].contains(pos, DOORWAY):
		return _room_index
	var best := 0
	var best_distance := INF
	for i in rooms.size():
		var room: Room = rooms[i]
		var area := Rect2(room.global_position - room.size / 2.0, room.size)
		var distance := pos.distance_to(pos.clamp(area.position, area.end))
		if distance < best_distance:
			best = i
			best_distance = distance
	return best


## Goes to room `target` (one past the last room = the trophy). Going forward first finishes
## every room on the way that isn't finished yet.
func _jump(target: int) -> void:
	var level := _level()
	var rooms := _rooms()
	if not _can_jump(level) or rooms.is_empty():
		return
	target = clampi(target, 0, rooms.size())
	var player := level.player
	var here := _current_index(level, rooms)
	_close_terminal()
	if player.is_small:
		player._set_small(false, 0.0, false)  # full size: it fits in every doorway
	if target > here:
		for i in target:
			if not _done.has(rooms[i]):
				_finish_room(level, rooms[i], i == here or not rooms[i]._entered)
	var spot: Vector2
	var title := "TROPHY"
	if target < rooms.size():
		spot = _entry(level, rooms, target)
		title = _title(rooms[target])
		_room_index = target
	else:
		spot = level.end_goal.global_position - Vector2(0, _feet(player))
		if not level.end_goal.monitoring:  # a goal the level hides until something happens
			level.end_goal.visible = true
			level.end_goal.set_deferred("monitoring", true)
	player.velocity = Vector2.ZERO
	player.global_position = spot
	player.get_node("Camera2D").reset_smoothing()
	player.restore_vitals()
	level.respawn_position = spot
	level.hud.show_message(title, 1.5)
	Sound.play("hero_swap")


## Finishes a room the way a player would: its code, its hero, all its fruit.
## `run_code` is off for rooms you already walked through: the code you typed there stays.
func _finish_room(level: Level, room: Room, run_code: bool) -> void:
	var player := level.player
	var terminal := _terminal()
	if run_code and room.answer != "" and terminal:
		var back := player.global_position
		player.global_position = room.global_position  # code gadgets only listen while you're in their room
		_run_code(terminal, room)
		player.global_position = back
	var flags: Array[Node] = []
	for flag in get_tree().get_nodes_in_group("checkpoint"):
		if flag.unlock_hero == "none" or flag.is_rescued:
			continue
		if flag.room == room or (flag.room == null and room.contains(flag.global_position)):
			flag.is_rescued = true  # before the fruit, so a door that also waits for this hero opens
			if not flag.unlock_hero in Game.unlocked_heroes:
				Game.unlocked_heroes.append(flag.unlock_hero)  # (Game.unlock_hero would save it)
			flags.append(flag)
	for fruit in get_tree().get_nodes_in_group("fruit"):
		if not fruit._taken and room.contains(fruit.global_position):
			fruit._taken = true  # picked up quietly: a pickup sound for every fruit would be a din
			fruit.collected.emit()
			fruit.queue_free()
	# A door that already had all its fruit and only waited for the rescue opens now.
	room.fruit_changed.emit(room.fruit_collected, room.fruit_total)
	for flag in flags:
		flag.hero_joined()
	room._entered = true  # no room title as you pass through
	_done[room] = true


## Runs the room's `answer` in Byte's terminal, without the checklist. Like Java wants, the type
## is left out if the variable already exists, and added if it doesn't exist yet.
## The terminal briefly treats the room as the one you're in, so its gadgets listen.
func _run_code(terminal: Node, room: Room) -> void:
	var checker: CommandChecker = terminal._checker
	var was_in: Room = terminal.current_room
	terminal.current_room = room
	var line := room.answer
	var result := checker.check(line, terminal.values, [], terminal.values.keys())
	if not result["ok"]:
		var variable := line.get_slice("=", 0).strip_edges()
		if result.has("fix"):
			line = result["fix"]
		elif checker.variables.has(variable):
			line = "%s %s" % [checker.variables[variable]["type"], line]
		result = checker.check(line, terminal.values, [], terminal.values.keys())
	if result["ok"]:
		terminal._hint_line("IMMUNITY: " + line)
		terminal._run_action(result["action"])
	else:
		push_warning("Immunity: the answer of %s didn't run (%s): %s" % [_title(room), line, result["error"]])
	terminal.current_room = was_in


# ---------------- Where you arrive in a room ----------------

## Room i's Entry marker, the level's start for the first room, or else standing in the
## doorway from the room before.
func _entry(level: Level, rooms: Array[Node], i: int) -> Vector2:
	var room: Room = rooms[i]
	var marker := room.get_node_or_null("Entry") as Node2D
	if marker:
		return marker.global_position
	if i == 0:
		return level.spawn_point.global_position
	var t := level.terrain
	var a := _cells(t, rooms[i - 1])
	var b := _cells(t, room)
	var cell: Variant = null
	if a.end.x <= b.position.x:
		cell = _side_door(t, a, b, 1)
	elif b.end.x <= a.position.x:
		cell = _side_door(t, a, b, -1)
	elif a.end.y <= b.position.y:
		cell = _floor_door(t, a, b, false)
	elif b.end.y <= a.position.y:
		cell = _floor_door(t, a, b, true)
	if cell == null:
		push_warning("Immunity: couldn't find the way into %s - give the Room a Marker2D called Entry." % _title(room))
		return room.global_position
	return _stand_at(level, cell)


## The tiles a room covers.
func _cells(t: TileMapLayer, room: Room) -> Rect2i:
	var half := room.size / 2.0 - Vector2.ONE  # 1 px in, so the edge tiles count as the room's
	var first := t.local_to_map(t.to_local(room.global_position - half))
	var last := t.local_to_map(t.to_local(room.global_position + half))
	return Rect2i(first, last - first + Vector2i.ONE)


## Rooms side by side (`dir` 1: the new room `b` is right of `a`). A doorway row is open from
## b's first column back to a's last one, through the wall between them if there is one.
## Stand on the lowest doorway row that has a floor, as far into b as possible.
func _side_door(t: TileMapLayer, a: Rect2i, b: Rect2i, dir: int) -> Variant:
	var first := b.position.x if dir > 0 else b.end.x - 1
	var last := a.end.x - 1 if dir > 0 else a.position.x
	var cols := range(first, last - dir, -dir)
	for row in range(mini(a.end.y, b.end.y) - 1, maxi(a.position.y, b.position.y) - 1, -1):
		if cols.any(func(c: int) -> bool: return _solid(t, Vector2i(c, row))):
			continue
		for c in cols:
			if _standable(t, Vector2i(c, row)):
				return Vector2i(c, row)
	return null


## Rooms on top of each other: the hole is the columns that are open between them. Coming up
## into b, stand on the ledge nearest the hole; going down, land on the floor under it.
func _floor_door(t: TileMapLayer, a: Rect2i, b: Rect2i, up: bool) -> Variant:
	var top := b.end.y - 1 if up else a.end.y - 1
	var bottom := a.position.y if up else b.position.y
	var hole: Array[int] = []
	for c in range(maxi(a.position.x, b.position.x), mini(a.end.x, b.end.x)):
		var open := true
		for r in range(top, bottom + 1):
			if _solid(t, Vector2i(c, r)):
				open = false
				break
		if open:
			hole.append(c)
	if hole.is_empty():
		return null
	var mid := (hole[0] + hole[-1]) / 2.0
	if not up:
		for row in range(b.position.y, b.end.y):
			if _standable(t, Vector2i(roundi(mid), row)):
				return Vector2i(roundi(mid), row)
		return null
	for row in range(b.end.y - 1, b.position.y - 1, -1):
		var best: Variant = null
		for c in range(maxi(b.position.x, hole[0] - 4), mini(b.end.x, hole[-1] + 5)):
			if _standable(t, Vector2i(c, row)) and (best == null or absf(c - mid) < absf(best - mid)):
				best = c
		if best != null:
			return Vector2i(best, row)
	return null


func _solid(t: TileMapLayer, cell: Vector2i) -> bool:
	return t.get_cell_source_id(cell) != -1


## Two empty tiles for the player, with ground right under them.
func _standable(t: TileMapLayer, cell: Vector2i) -> bool:
	return not _solid(t, cell) and not _solid(t, cell + Vector2i.UP) and _solid(t, cell + Vector2i.DOWN)


## The player's position when standing on the ground under `cell`.
func _stand_at(level: Level, cell: Vector2i) -> Vector2:
	var t := level.terrain
	var ground := t.to_global(t.map_to_local(cell + Vector2i.DOWN) - Vector2(0, t.tile_set.tile_size.y / 2.0))
	return ground - Vector2(0, _feet(level.player))


## How far the player's feet are below its position.
func _feet(player: Node) -> float:
	var shape: CollisionShape2D = player.body_shape
	return shape.position.y + (shape.shape as RectangleShape2D).size.y / 2.0


# ---------------- The room list (Ctrl+Shift+R) ----------------

## Every room of the level, the one you're in highlighted, rooms finished by a jump dimmed.
## Pauses the game while it's open.
func _open_menu() -> bool:
	var level := _level()
	var rooms := _rooms()
	if not _can_jump(level) or rooms.is_empty():
		return false
	_close_terminal()
	var here := _current_index(level, rooms)
	_menu = CanvasLayer.new()
	_menu.layer = 60  # over the terminal and the pause menu
	add_child(_menu)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(shade)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color(INK, 0.96), 8, 6, EDGE))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	column.add_child(_label("IMMUNITY: JUMP TO A ROOM", YELLOW))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	for i in rooms.size() + 1:
		var text := "TROPHY: FINISH THE LEVEL"
		var color := Color.WHITE
		if i < rooms.size():
			text = "%d  %s" % [i + 1, _title(rooms[i])]
			if _done.has(rooms[i]):
				color = DIM
		if i == here:
			color = YELLOW
		var row := _row(("> " if i == here else "   ") + text, color)
		row.pressed.connect(_on_row_pressed.bind(i))
		list.add_child(row)
	scroll.custom_minimum_size.y = minf(list.get_combined_minimum_size().y, 236.0)
	column.add_child(_label("ENTER: GO   ESC: CLOSE   PGDN / PGUP: NEXT / BACK", DIM))
	list.get_child(here).grab_focus()
	get_tree().paused = true
	Sound.play("terminal_open")
	return true


func _close_menu() -> void:
	if _menu == null:
		return
	_menu.queue_free()
	_menu = null
	get_tree().paused = false


func _on_row_pressed(i: int) -> void:
	_close_menu()
	_jump(i)


## A compact row of the room list: an outline when picked with the arrows, lit under the mouse.
func _row(text: String, color: Color) -> Button:
	var row := Button.new()
	row.text = text
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var flat := _box(Color(0, 0, 0, 0), 4, 1)
	var lit := _box(Color(0.3, 0.26, 0.45), 4, 1)
	var outline := _box(Color(0, 0, 0, 0), 4, 1, YELLOW)
	outline.draw_center = false
	row.add_theme_stylebox_override("normal", flat)
	row.add_theme_stylebox_override("hover", lit)
	row.add_theme_stylebox_override("pressed", lit)
	row.add_theme_stylebox_override("hover_pressed", lit)
	row.add_theme_stylebox_override("focus", outline)
	for item in ["font_color", "font_focus_color", "font_pressed_color"]:
		row.add_theme_color_override(item, color)
	for item in ["font_hover_color", "font_hover_pressed_color"]:
		row.add_theme_color_override(item, Color.WHITE)
	return row


# ---------------- The "IMMUNITY ON" tag ----------------

## A small tag in the bottom-left corner while immunity is on, so you never forget it.
func _build_chip() -> void:
	_chip = CanvasLayer.new()
	_chip.layer = 99  # over the game and its menus, under Game's fade
	_chip.visible = false
	add_child(_chip)
	_chip_panel = PanelContainer.new()
	_chip_panel.add_theme_stylebox_override("panel", _box(Color(INK, 0.85), 5, 2, EDGE))
	_chip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_chip_panel.offset_left = 6.0
	_chip_panel.offset_bottom = -6.0
	_chip.add_child(_chip_panel)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip_panel.add_child(lines)
	lines.add_child(_label("IMMUNITY ON", YELLOW))
	_chip_keys = _label("", DIM)
	lines.add_child(_chip_keys)


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label


func _box(bg: Color, margin_x: float, margin_y: float, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.content_margin_left = margin_x
	box.content_margin_right = margin_x
	box.content_margin_top = margin_y
	box.content_margin_bottom = margin_y
	if border.a > 0.0:
		box.set_border_width_all(1)
		box.border_color = border
	box.anti_aliasing = false
	return box
