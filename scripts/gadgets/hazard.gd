class_name Hazard
extends Area2D
## Anything that hurts the player on touch (spikes, saws). The player blinks afterwards,
## so standing in a hazard costs `damage` about once a second, not every frame.

@export var damage := 20.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player
	monitorable = false


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for body in get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(_hit_from(body), damage)


## Where the hit comes from (the player is knocked away from this point).
func _hit_from(_body: Node2D) -> Vector2:
	return global_position
