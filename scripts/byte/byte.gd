extends Node2D
## Byte, the helper robot. Floats behind the player's shoulder and follows them around.
## Later the code terminal will call react() / talk() so Byte responds to the player's code.

@export var target: Node2D  ## Who Byte follows (the Player).
@export var offset := Vector2(-20, -22)  ## Where Byte floats, relative to the target facing right.
@export var follow_speed := 6.0  ## Higher = Byte catches up faster.
@export var moving_threshold := 8.0  ## Distance from the float spot before Byte uses the "follow" animation.
@export var snap_distance := 200.0  ## Further than this (e.g. after a respawn) and Byte teleports.

var _busy := false  ## True while a happy/error/talk animation is showing.
var _busy_id := 0  ## Bumped by each new reaction so an older one can't end a newer one early.
var _bubble_id := 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bubble: PanelContainer = $Bubble
@onready var bubble_label: Label = $Bubble/Label


func _ready() -> void:
	add_to_group("byte")
	sprite.play("idle")
	bubble.visible = false


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var facing: int = target.facing if "facing" in target else 1
	var goal := target.global_position + Vector2(offset.x * facing, offset.y)
	var to_goal := goal - global_position

	if to_goal.length() > snap_distance:
		global_position = goal
		to_goal = Vector2.ZERO
	else:
		# Smooth catch-up that is framerate independent.
		global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))

	if _busy:
		return
	if to_goal.length() > moving_threshold:
		sprite.flip_h = to_goal.x < 0.0
		_play("follow")
	else:
		sprite.flip_h = facing < 0
		_play("idle")


## Show a one-shot reaction: true = happy (correct code), false = error (wrong code).
func react(correct: bool) -> void:
	var id := _start_busy()
	sprite.play("happy" if correct else "error")
	await sprite.animation_finished
	_end_busy(id)


## Show the talking animation for a while (e.g. while a speech bubble is up).
func talk(seconds: float) -> void:
	var id := _start_busy()
	sprite.play("talk")
	_blips(seconds)
	await get_tree().create_timer(seconds).timeout
	_end_busy(id)


## Show a short speech bubble above Byte.
func say(text: String, seconds := 2.5) -> void:
	_bubble_id += 1
	var id := _bubble_id
	bubble_label.text = text if text.length() <= 40 else text.left(37) + "..."
	bubble.visible = true
	bubble.size = bubble.get_combined_minimum_size()
	bubble.position = Vector2(-bubble.size.x / 2.0, -16.0 - bubble.size.y)
	await get_tree().create_timer(seconds).timeout
	if id == _bubble_id:
		bubble.visible = false


func _start_busy() -> int:
	_busy_id += 1
	_busy = true
	return _busy_id


func _end_busy(id: int) -> void:
	if id == _busy_id:
		_busy = false


func _play(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


## Byte's voice: quick little bleeps while the talk animation plays.
func _blips(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end and is_inside_tree():
		Sound.play("byte_talk", 0.2)
		await get_tree().create_timer(0.09).timeout
