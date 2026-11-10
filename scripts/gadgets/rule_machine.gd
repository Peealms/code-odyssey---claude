class_name RuleMachine
extends Node2D
## Base for Level 2 machines (sea gates, the anchor, sails, lanterns, doors). They run by
## themselves, so they take rules, not orders: a RuleRunner in the same Room calls apply()
## with each value its rule sets. See docs/level2_design.md.
## When a wrong rule makes the machine fail (the ship runs aground...), call fail() with Byte's
## explanation - it counts as a wrong try, like Level 1's bridge that was too long.

signal failed(text: String)

## The machine variables this machine listens to, e.g. ["gateOpen"].
@export var variables: Array[String] = []

var runner: RuleRunner  ## Set by the runner that drives this machine.
var state := {}  ## The last value set for each variable.


func _ready() -> void:
	add_to_group("rule_machine")


func handles(var_name: String) -> bool:
	return var_name in variables


func apply(var_name: String, value: Variant) -> void:
	state[var_name] = value
	_on_set(var_name, value)


## Override: react to a value the rule set.
func _on_set(_var_name: String, _value: Variant) -> void:
	pass


## A reading's value right now (e.g. lookup("tide")), for explanations.
func lookup(reading_name: String) -> Variant:
	return runner.lookup(reading_name) if runner else null


func fail(text: String) -> void:
	failed.emit(text)
