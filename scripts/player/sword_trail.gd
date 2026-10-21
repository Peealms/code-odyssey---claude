extends Node2D
## White crescent that follows the sword tip during a swing and fades out behind it.
## Sits at the sword's pivot (the hand) and reads the pivot's rotation every frame.

@export var inner_radius := 5.0  ## Where the trail starts, measured from the hand.
@export var outer_radius := 19.0  ## Just past the sword tip.
@export var max_arc := deg_to_rad(140.0)  ## Longest the trail gets while swinging.
@export var fade_speed := deg_to_rad(700.0)  ## How fast the tail catches up after the swing.
@export var color := Color(1, 1, 1, 1)

const SEGMENTS := 14

var pivot: Node2D
var _head := 0.0
var _tail := 0.0
var _active := false


func start() -> void:
	_head = pivot.rotation
	_tail = _head
	_active = true
	visible = true


func stop() -> void:
	_active = false


func cancel() -> void:
	_active = false
	visible = false


func _process(delta: float) -> void:
	if not visible or pivot == null:
		return
	_head = pivot.rotation
	if _active:
		_tail = maxf(_tail, _head - max_arc)
	else:
		_tail = move_toward(_tail, _head, fade_speed * delta)
		if absf(_head - _tail) < 0.01:
			visible = false
	queue_redraw()


func _draw() -> void:
	var arc := _head - _tail
	if arc < 0.02:
		return
	# A ribbon from tail (transparent, thin) to head (bright, full width), like a slash smear.
	for i in SEGMENTS:
		var t0 := float(i) / SEGMENTS
		var t1 := float(i + 1) / SEGMENTS
		var a0 := _tail + arc * t0
		var a1 := _tail + arc * t1
		# The trail gets wider toward the blade, so it reads as a crescent.
		var in0 := lerpf(outer_radius - 2.0, inner_radius, t0)
		var in1 := lerpf(outer_radius - 2.0, inner_radius, t1)
		var c0 := Color(color, color.a * (0.15 + 0.85 * t0) * 0.75)
		var c1 := Color(color, color.a * (0.15 + 0.85 * t1) * 0.75)
		draw_polygon(
			PackedVector2Array([
				Vector2.from_angle(a0) * outer_radius, Vector2.from_angle(a1) * outer_radius,
				Vector2.from_angle(a1) * in1, Vector2.from_angle(a0) * in0]),
			PackedColorArray([c0, c1, Color(c1, c1.a * 0.15), Color(c0, c0.a * 0.15)]))
		# Bright edge along the path of the tip.
		draw_line(Vector2.from_angle(a0) * outer_radius, Vector2.from_angle(a1) * outer_radius,
			Color(color, color.a * t1), 1.5)
