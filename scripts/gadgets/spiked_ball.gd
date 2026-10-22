extends Node2D
## A spiked ball on a chain, hanging from this node's position (put it under a ceiling).
## It swings like a pendulum, or spins in a full circle when `spin` is on. Touching the ball hurts.

const CHAIN := preload("res://assets/level1_pixel_adventure/traps/spiked_ball/chain.png")

@export var length := 64.0  ## Chain length in px.
@export var swing_degrees := 60.0  ## How far it swings to each side (pendulum).
@export var period := 2.4  ## Seconds for one full swing (or one full turn when spinning).
@export var spin := false  ## Go round in a full circle instead of swinging.
@export var phase := 0.0  ## 0-1, offsets the timing so neighbours don't move together.

var _t := 0.0

@onready var ball: Area2D = $Ball


func _ready() -> void:
	_t = phase * period
	_place()


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


func _place() -> void:
	var k := TAU * _t / period
	var angle := k if spin else sin(k) * deg_to_rad(swing_degrees)
	ball.position = Vector2(0, length).rotated(angle)
	queue_redraw()


func _draw() -> void:
	var links := int(length / 8.0)
	for i in links:
		draw_texture(CHAIN, ball.position * (float(i) / links) - CHAIN.get_size() / 2.0)
