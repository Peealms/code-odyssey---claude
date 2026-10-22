class_name CodeGadget
extends Node2D
## Base for level pieces that react to the player's code (bridges, fans, path platforms, gates).
## Set `variable_name` to the variable it listens to (e.g. "bridgeLength"); when the player
## sets that variable in Byte's terminal, `_on_value(value)` runs.
## The special name "println" reacts to System.out.println(...) with the printed text.
##
## A gadget inside a Room only reacts while the player is in that room (or its zone, or the
## doorway next to it), so a later room can reuse a variable (e.g. bridgeLength) without
## changing the gadgets of rooms already solved.

const DOORWAY := 40.0  ## Standing this close to the room (in its doorway) still counts.

@export var variable_name := ""

var _room: Room = null


func _ready() -> void:
	# The terminal may not be ready yet when this runs, so connect a frame later.
	_connect_terminal.call_deferred()


func _connect_terminal() -> void:
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal == null:
		push_warning("%s: no CodeTerminal in this level" % name)
		return
	terminal.variable_set.connect(_on_variable_set)
	for room in get_tree().get_nodes_in_group("room"):
		if room.contains(global_position):
			_room = room
			break


func _on_variable_set(var_name: String, value: Variant) -> void:
	if var_name == variable_name and _player_is_here():
		_on_value(value)


func _player_is_here() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if _room == null or player == null:
		return true
	for room in get_tree().get_nodes_in_group("room"):
		if _room.same_place(room) and room.contains(player.global_position, DOORWAY):
			return true
	return false


## Override in each gadget.
func _on_value(_value: Variant) -> void:
	pass
