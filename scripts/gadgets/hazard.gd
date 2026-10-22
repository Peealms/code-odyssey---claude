class_name Hazard
extends Area2D
## Anything that hurts the player on touch (spikes, saws). The player blinks afterwards,
## so standing in a hazard costs `damage` about once a second, not every frame.

@export var damage := 20.0
## For spikes at the bottom of a pit: after the hit, send the player back to the last checkpoint.
@export var send_to_checkpoint := false


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
			var level := get_tree().current_scene
			if send_to_checkpoint and level.has_method("respawn"):
				level.respawn()


## Where the hit comes from (the player is knocked away from this point).
func _hit_from(_body: Node2D) -> Vector2:
	return global_position
