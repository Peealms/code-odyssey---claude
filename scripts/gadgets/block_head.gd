extends AnimatableBody2D
## Rock Head / Spike Head from Pixel Adventure: a floating block face that blinks, then slams
## to the far end of its track, waits, and slams back. Rock Heads are solid platforms you can
## ride; Spike Heads (`spiky`) also hurt on touch.
## The node's position is one end of the track; `travel` is the offset to the other end.

@export var spiky := false
@export var travel := Vector2(0, 64)  ## Offset to the far end of the track.
@export var wait_time := 0.9  ## Seconds it rests (blinking) at each end.
@export var slam_speed := 240.0  ## Top speed while slamming, px/s.
@export var start_delay := 0.0  ## Offsets the timing so rows of heads don't move together.
@export var damage := 20.0

var _start := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	_start = position
	sprite.play("idle")
	hurtbox.monitoring = spiky
	_run()


func _run() -> void:
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay, false).timeout
	while is_inside_tree():
		await _rest()
		await _slam_to(_start + travel)
		await _rest()
		await _slam_to(_start)


func _rest() -> void:
	sprite.play("blink")
	await get_tree().create_timer(wait_time, false).timeout
	sprite.play("idle")


## Speeds up into the wall like a heavy block, then plays the hit for that side and shakes.
func _slam_to(target: Vector2) -> void:
	var dist := position.distance_to(target)
	if dist < 1.0:
		return
	var dir := (target - position).normalized()
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", target, dist / slam_speed * 1.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	Sound.play_at("spike_slam" if spiky else "rock_slam", global_position)
	if absf(dir.x) > absf(dir.y):
		sprite.play("right_hit" if dir.x > 0 else "left_hit")
	else:
		sprite.play("bottom_hit" if dir.y > 0 else "top_hit")
	var shake := create_tween()
	shake.tween_property(sprite, "position", dir * 2.0, 0.05)
	shake.tween_property(sprite, "position", Vector2.ZERO, 0.08)
	await sprite.animation_finished


func _physics_process(_delta: float) -> void:
	if not spiky:
		return
	for body in hurtbox.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(global_position, damage)
