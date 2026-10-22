extends StaticBody2D
## A fire block: off, then a short warning flicker, then flames for `on_time`, then off again.
## The block itself is solid (you can stand on it while it's off); the flames above it hurt.
## The node's position is the bottom-middle of the block (put it on the ground).

@export var off_time := 1.6
@export var on_time := 1.2
@export var phase := 0.0  ## Seconds to wait before the first cycle (so rows don't fire together).
@export var damage := 20.0

var is_on := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var flames: Area2D = $Flames


func _ready() -> void:
	sprite.play("off")
	_run()


func _run() -> void:
	if phase > 0.0:
		await get_tree().create_timer(phase, false).timeout
	while is_inside_tree():
		await get_tree().create_timer(off_time, false).timeout
		sprite.play("hit")  # warning flicker
		await sprite.animation_finished
		is_on = true
		sprite.play("on")
		await get_tree().create_timer(on_time, false).timeout
		is_on = false
		sprite.play("off")


func _physics_process(_delta: float) -> void:
	if not is_on:
		return
	for body in flames.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(global_position, damage)
