extends Area2D
## Checkpoint flag. Touching it raises the flag and makes it the respawn point.
## It can also unlock a hero - put it at the end of a room so clearing the room
## rescues the hero the next room needs. The Level script listens to `reached`.

signal reached(checkpoint: Area2D)

## Hero rescued when this flag is first touched.
@export_enum("none", "pink_man", "mask_dude", "virtual_guy") var unlock_hero: String = "none"

var activated := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("checkpoint")
	sprite.play("no_flag")
	body_entered.connect(_on_body_entered)


## Where the player reappears (a little above the ground, next to the pole).
func respawn_position() -> Vector2:
	return global_position + Vector2(0, -16)


func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player"):
		return
	activated = true
	sprite.play("flag_out")
	reached.emit(self)
	await sprite.animation_finished
	sprite.play("flag_idle")
