extends Area2D
## The trophy at the end of a level. Touching it finishes the level - if `room` is set,
## only once every fruit in that room is collected (otherwise `blocked` fires).

signal reached
signal blocked(fruit_left: int)

@export var room: Node  ## Room whose fruit must be collected first (empty = none).

var _done := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _done or not body.is_in_group("player"):
		return
	if room and not room.all_fruit_collected():
		blocked.emit(room.fruit_total - room.fruit_collected)
		return
	_done = true
	sprite.play("pressed")
	reached.emit()
