extends Hazard
## A spinning saw. Set `travel` to make it slide back and forth (e.g. (96, 0) = 96 px right
## and back); a dotted chain shows its track.

const CHAIN := preload("res://assets/level1_pixel_adventure/traps/saw/chain.png")

@export var travel := Vector2.ZERO  ## Offset of the far end of its track (zero = stays put).
@export var speed := 60.0  ## Pixels per second along the track.

var _start := Vector2.ZERO
var _t := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	super()
	_start = position
	sprite.play("on")
	queue_redraw()


func _physics_process(delta: float) -> void:
	super(delta)
	if travel == Vector2.ZERO:
		return
	_t += delta * speed / travel.length()
	# ping-pong 0 -> 1 -> 0 along the track
	var k := pingpong(_t, 1.0)
	position = _start + travel * smoothstep(0.0, 1.0, k)
	queue_redraw()


func _draw() -> void:
	if travel == Vector2.ZERO:
		return
	# Chain dots from one end of the track to the other, drawn in the saw's own space.
	var a := _start - position
	var b := a + travel
	var steps := int(travel.length() / 8.0)
	for i in steps + 1:
		var p := a.lerp(b, float(i) / maxi(steps, 1))
		draw_texture(CHAIN, p - CHAIN.get_size() / 2.0)
