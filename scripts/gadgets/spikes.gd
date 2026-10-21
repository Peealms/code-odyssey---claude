@tool
extends Hazard
## A row of spikes. The node's position is the left end of the row, on the ground.
## Rotate the node 180 degrees for ceiling spikes (or 90 / -90 for walls).

const SPIKE_TEXTURE := preload("res://assets/level1_pixel_adventure/traps/spikes/idle.png")
const SIZE := 16

@export_range(1, 40) var count := 3:
	set(value):
		count = value
		_build()


func _ready() -> void:
	super()
	_build()


func _build() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if c.has_meta("built"):
			c.queue_free()
	for i in count:
		var s := Sprite2D.new()
		s.texture = SPIKE_TEXTURE
		s.centered = false
		s.position = Vector2(i * SIZE, -SIZE)
		s.set_meta("built", true)
		add_child(s)
	# Only the pointy bottom half hurts.
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(count * SIZE - 4, 7)
	shape.shape = rect
	shape.position = Vector2(count * SIZE / 2.0, -3.5)
	shape.set_meta("built", true)
	add_child(shape)


## Spikes knock you up and away from the row's middle.
func _hit_from(body: Node2D) -> Vector2:
	var middle := to_global(Vector2(count * SIZE / 2.0, 0))
	return Vector2(middle.x, body.global_position.y + 1)
