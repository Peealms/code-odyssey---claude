class_name LevelSave
extends Node
## Saves a level at its checkpoints, so CONTINUE (main menu, level select) and the pause menu's
## LAST CHECKPOINT start you back at the last flag you touched, with the level as it was then.
## The Level adds it (only when its `saves_progress` is on; the tutorial is too short to need it).
##
## What a save holds (see snapshot()): the checkpoint, the code that ran and where you stood
## when it ran, the coins taken, the flags raised and heroes rescued, each room's wrong tries
## and Show answers, the dictionary pages, the hotbar, the opened chests, and the level's stats.
##
## Code is saved as a list instead of as gadget states: restore() runs it again, quietly, with
## the hero standing where it was typed, so every gadget (bridge, ship, paths, gate) rebuilds
## itself through its own code. Only the last value per variable per place is kept, because
## that's all a gadget remembers.
##
## Not saved: the boss fight (every save is from before his arena), health potions, and where
## the ship was on its trip.

const SFX_QUIET_TIME := 1.5  ## Seconds of silence while restored gadgets rebuild (bridge planks...).

var level: Level
var terminal: Node
var reader: Node
var _code: Array = []  ## {name, value, pos, key}, oldest first.
var _coins_taken: Array[String] = []


func _init(owner_level: Level) -> void:
	name = "LevelSave"
	level = owner_level


func _ready() -> void:
	terminal = level.get_node_or_null("CodeTerminal")
	reader = level.get_node_or_null("ManualReader")
	if terminal:
		terminal.variable_set.connect(_on_variable_set)
	for coin in get_tree().get_nodes_in_group("fruit"):
		coin.collected.connect(_on_coin_collected.bind(_path(coin)))


func _path(node: Node) -> String:
	return String(level.get_path_to(node))


func _node(path: String) -> Node:
	return level.get_node_or_null(NodePath(path))


# ---------------- Recording ----------------

func _on_variable_set(var_name: String, value: Variant) -> void:
	var room: Room = terminal.current_room
	var place := ""
	if room:
		place = room.zone if room.zone != "" else _path(room)
	var key := "%s@%s" % [var_name, place]
	if var_name == "println":
		key += "=" + str(value)  # every different text, so the one that opened the gate stays
	for i in range(_code.size() - 1, -1, -1):
		if _code[i]["key"] == key:
			_code.remove_at(i)
	_code.append({"name": var_name, "value": value, "pos": level.player.global_position, "key": key})


func _on_coin_collected(path: String) -> void:
	if not path in _coins_taken:
		_coins_taken.append(path)


# ---------------- Saving ----------------

## Saves the level as it is now, to come back at `checkpoint`.
func save_at(checkpoint: Area2D) -> void:
	Game.save_checkpoint(snapshot(checkpoint))


func snapshot(checkpoint: Area2D) -> Dictionary:
	var player := level.player
	var flags: Array[String] = []
	var rescued: Array[String] = []
	for flag in get_tree().get_nodes_in_group("checkpoint"):
		if flag.activated:
			flags.append(_path(flag))
		if flag.is_rescued:
			rescued.append(_path(flag))
	var rooms := {}
	for room in get_tree().get_nodes_in_group("room"):
		rooms[_path(room)] = [room.wrong_tries, room.answer_shown, room._entered]
	var chests := {}
	for chest in level.find_children("*", "Area2D", true, false):
		if chest.has_method("_throw_potions") and chest._opened:
			chests[_path(chest)] = Array(chest.slots)
	return {
		"level_id": level.level_id,
		"scene": level.scene_file_path,
		"checkpoint": _path(checkpoint),
		"flags": flags,
		"rescued": rescued,
		"heroes": Game.unlocked_heroes.duplicate(),
		"hero": player.hero_id,
		"code": _code.duplicate(true),
		"coins": _coins_taken.duplicate(),
		"rooms": rooms,
		"pages": reader.unlocked.keys() if reader else [],
		"unread": Array(reader.unread) if reader else [],
		"items": Array(player.inventory),
		"slot": player.selected_slot,
		"chests": chests,
		"answers_shown": Game.answers_shown,
		"mistakes": Game.mistakes,
		"seconds": Game.level_seconds(),
	}


# ---------------- Coming back ----------------

## Puts the level back the way `data` saved it and the player at its checkpoint.
func restore(data: Dictionary) -> void:
	# Gadgets find the terminal and rooms count their coins a frame after the level starts.
	await get_tree().process_frame
	await get_tree().process_frame
	var player := level.player
	var sfx := AudioServer.get_bus_index("SFX")
	if sfx != -1:
		AudioServer.set_bus_mute(sfx, true)

	Game.unlocked_heroes = data.get("heroes", Game.unlocked_heroes).duplicate()

	# The code, each line where it was typed (gadgets only listen in their own room).
	if terminal:
		terminal.replaying = true
		for line in data.get("code", []):
			player.global_position = line["pos"]
			terminal.replay(line["name"], line["value"])
		terminal.replaying = false

	for path in data.get("coins", []):
		var coin := _node(path)
		if coin and not coin._taken:
			coin._taken = true
			coin.collected.emit()
			coin.queue_free()

	var rooms: Dictionary = data.get("rooms", {})
	for path in rooms:
		var room := _node(path) as Room
		if room:
			room.wrong_tries = rooms[path][0]
			room.answer_shown = rooms[path][1]
			room._entered = rooms[path][2]
			room.fruit_changed.emit(room.fruit_collected, room.fruit_total)

	for path in data.get("flags", []):
		var flag := _node(path)
		if flag:
			flag.activated = true
			flag.sprite.play("flag_idle")
	for path in data.get("rescued", []):
		var flag := _node(path)
		if flag:
			flag.is_rescued = true
			flag.hero_joined()

	if reader:
		for v in data.get("pages", []):
			reader.unlocked[v] = true
		reader.unread.assign(data.get("unread", []))
		reader.unread_changed.emit(reader.unread.size())

	var chests: Dictionary = data.get("chests", {})
	for path in chests:
		var chest := _node(path)
		if chest:
			chest._opened = true
			chest.slots.assign(chests[path])
			chest.sprite.play("unlocked")
			chest.sprite.set_frame_and_progress(chest.sprite.sprite_frames.get_frame_count("unlocked") - 1, 1.0)

	if data.has("items"):
		player.inventory.assign(data["items"])
		player.inventory_changed.emit()
		player.select_slot(int(data.get("slot", 0)))

	Game.answers_shown = data.get("answers_shown", 0)
	Game.mistakes = data.get("mistakes", 0)
	Game.set_level_seconds(data.get("seconds", 0.0))

	player.set_hero(data.get("hero", player.hero_id), false, true)
	var checkpoint := _node(data.get("checkpoint", ""))
	if checkpoint:
		level.respawn_position = checkpoint.respawn_position()
	level.respawn()
	player.restore_vitals()
	level.hud.show_message("BACK AT THE CHECKPOINT", 1.5)

	await get_tree().create_timer(SFX_QUIET_TIME).timeout
	if sfx != -1:
		Game.set_sfx_volume(Game.sfx_volume)  # unmutes, unless the slider is at 0
