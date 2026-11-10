class_name ReadingSource
extends Node2D
## Something in the world that gives Level 2 rules a reading: the tide post gives `tide`, the
## lookout gives `word`, the captain gives `move` and `distance` (see docs/level2_design.md).
## Readings change by themselves; rules can check them but nobody can set them from code.
## A RuleRunner uses the sources inside its Room (found by position).

signal reading_changed(reading_name: String, value: Variant)

var readings := {}


func _ready() -> void:
	add_to_group("reading_source")


func set_reading(reading_name: String, value: Variant) -> void:
	if readings.has(reading_name) and typeof(readings[reading_name]) == typeof(value) \
			and readings[reading_name] == value:
		return
	readings[reading_name] = value
	reading_changed.emit(reading_name, value)


func has_reading(reading_name: String) -> bool:
	return readings.has(reading_name)


func get_reading(reading_name: String) -> Variant:
	return readings.get(reading_name)
