class_name HealthPotion
extends Area2D
## A red potion. Touching it heals the player straight away (it never goes in the hotbar).
## At full HP it stays where it is, so it's still there when you need it.
## Place them in levels, or let a chest throw them out (ManualChest.potions).

const EFFECT := preload("res://assets/level2_treasure_hunters/collectibles/potion_effect/potion_effect_frames.tres")

@export var heal := 30.0

var _used := false
var _bob := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.play("idle")
	_bob = randf() * TAU


func _process(delta: float) -> void:
	_bob += delta * 3.0
	sprite.position.y = -8.0 + sin(_bob) * 1.5


## Checked every frame (not only on touch), so a potion you walked over at full HP still
## works once you get hurt while standing on it.
func _physics_process(_delta: float) -> void:
	if _used:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.health < body.max_health:
			_drink(body)
			return


func _drink(player: Node2D) -> void:
	_used = true
	player.heal(heal)
	DamageNumber.spawn(player, heal, DamageNumber.HEAL, 24.0, "+")
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = EFFECT
	fx.position = Vector2(0, -12)
	add_child(fx)
	fx.play("idle")
	sprite.visible = false
	await get_tree().create_timer(0.4).timeout
	queue_free()
