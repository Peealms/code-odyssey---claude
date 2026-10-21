extends Area2D
## A collectible fruit. Pick which fruit in the Inspector.

signal collected

@export_enum("apple", "bananas", "cherries", "kiwi", "melon", "orange", "pineapple", "strawberry")
var fruit := "apple"

var _taken := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.play(fruit)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	collected.emit()
	sprite.play("collected")
	await sprite.animation_finished
	queue_free()
