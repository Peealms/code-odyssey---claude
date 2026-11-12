extends Area2D
## A gold coin: Level 1's fruit. It's in the "fruit" group, so Rooms count it the same way
## (the HUD's COINS 3/12, rescue flags and the treasure).

signal collected

const FRAMES := preload("res://assets/level2_treasure_hunters/collectibles/gold_coin/gold_coin_frames.tres")
const EFFECT := preload("res://assets/level2_treasure_hunters/collectibles/coin_effect/coin_effect_frames.tres")

var _taken := false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("fruit")
	collision_layer = 8
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = FRAMES
	_sprite.play("idle")
	_sprite.frame = randi() % 4
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	collected.emit()
	Sound.play("fruit", 0.08)
	_sprite.sprite_frames = EFFECT
	_sprite.play("idle")
	await get_tree().create_timer(0.35).timeout
	queue_free()
