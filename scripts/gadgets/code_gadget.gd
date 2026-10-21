class_name CodeGadget
extends Node2D
## Base for level pieces that react to the player's code (bridges, fans, path platforms, gates).
## Set `variable_name` to the variable it listens to (e.g. "bridgeLength"); when the player
## sets that variable in Byte's terminal, `_on_value(value)` runs.
## The special name "println" reacts to System.out.println(...) with the printed text.

@export var variable_name := ""


func _ready() -> void:
	# The terminal may not be ready yet when this runs, so connect a frame later.
	_connect_terminal.call_deferred()


func _connect_terminal() -> void:
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal == null:
		push_warning("%s: no CodeTerminal in this level" % name)
		return
	terminal.variable_set.connect(_on_variable_set)


func _on_variable_set(var_name: String, value: Variant) -> void:
	if var_name == variable_name:
		_on_value(value)


## Override in each gadget.
func _on_value(_value: Variant) -> void:
	pass
