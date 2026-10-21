extends AnimatableBody2D
## A small platform that shakes when stood on, then drops. It comes back after `return_time`.
## A short `fall_delay` makes a row of them a sprint challenge (Virtual Guy's room).
## You can jump up through it from below.

@export var fall_delay := 0.35  ## Seconds after landing on it before it drops.
@export var return_time := 2.5  ## Seconds after falling before it reappears.

var _home := Vector2.ZERO
var _triggered := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var feet_check: Area2D = $FeetCheck


func _ready() -> void:
	_home = position
	sprite.play("on")
	feet_check.body_entered.connect(_on_feet_entered)


func _on_feet_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	# Only when the player lands on top, not when they bump it from below.
	if body.global_position.y > global_position.y - 4.0:
		return
	_triggered = true
	await _shake()
	await _fall()
	await get_tree().create_timer(return_time).timeout
	_reappear()


func _shake() -> Signal:
	var tween := create_tween()
	var steps := maxi(int(fall_delay / 0.05), 1)
	for i in steps:
		tween.tween_property(sprite, "position:x", 1.0 if i % 2 == 0 else -1.0, 0.05)
	tween.tween_property(sprite, "position:x", 0.0, 0.0)
	return tween.finished


func _fall() -> Signal:
	sprite.play("off")
	shape.set_deferred("disabled", true)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", _home.y + 160.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	return tween.finished


func _reappear() -> void:
	position = _home
	shape.set_deferred("disabled", false)
	sprite.play("on")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	_triggered = false
