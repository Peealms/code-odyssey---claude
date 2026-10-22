extends Area2D
## A trampoline: landing on it (or walking into it) bounces the player high up.
## Use it to reach optional areas - never to skip a puzzle. The node's position is its base,
## sitting on the ground.

@export var bounce_speed := 480.0  ## 480 px/s launches about 8 tiles high.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.play("idle")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or body.velocity.y < -50.0:
		return  # already flying upward
	body.velocity.y = -bounce_speed
	sprite.play("jump")
	await sprite.animation_finished
	sprite.play("idle")
