extends Area2D
## The trophy at the end of a room. Touching it finishes the room.

signal reached

var _done := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _done or not body.is_in_group("player"):
		return
	_done = true
	sprite.play("pressed")
	reached.emit()
