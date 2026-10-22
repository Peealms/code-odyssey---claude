extends CodeGadget
## A floor fan switched by the player's boolean: `boolean fanOn = true;` starts it and the air
## lifts the player up to `lift_height` above the fan. `false` turns it off again.
## The node's position is the bottom-middle of the fan (put it on the ground).

@export var start_on := false
@export var lift_height := 160.0  ## How tall the column of air is.
@export var width := 24.0  ## How wide the column of air is (put fans 2 tiles apart with 32 to make a wall of air).
@export var lift_speed := 220.0  ## Top upward speed the air gives the player.
@export var lift_accel := 2200.0  ## How hard the air pushes (must beat gravity, 900).

var is_on := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var air: Area2D = $Air
@onready var air_shape: CollisionShape2D = $Air/CollisionShape2D
@onready var streaks: CPUParticles2D = $Streaks


func _ready() -> void:
	if variable_name == "":
		variable_name = "fanOn"
	super()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, lift_height)
	air_shape.shape = rect
	air_shape.position = Vector2(0, -lift_height / 2.0)
	streaks.lifetime = lift_height / streaks.initial_velocity_min
	streaks.texture = _streak_texture()
	streaks.emission_rect_extents = Vector2(width / 2.0 - 2.0, 1)
	_set_on(start_on)


## A 1x6 pixel line, brighter at the top, for the rising air streaks.
func _streak_texture() -> ImageTexture:
	var img := Image.create(1, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		img.set_pixel(0, y, Color(1, 1, 1, 1.0 - y / 6.0))
	return ImageTexture.create_from_image(img)


func _on_value(value: Variant) -> void:
	_set_on(bool(value))


func _set_on(on: bool) -> void:
	is_on = on
	sprite.play("on" if on else "off")
	streaks.emitting = on


func _physics_process(delta: float) -> void:
	if not is_on:
		return
	for body in air.get_overlapping_bodies():
		if body is CharacterBody2D and body.is_in_group("player"):
			# Push up, a bit weaker near the top but always stronger than gravity, so the
			# player rides all the way up and bobs at the top of the column.
			var height := global_position.y - body.global_position.y
			var strength := clampf(1.0 - height / lift_height, 0.5, 1.0)
			body.velocity.y = maxf(body.velocity.y - lift_accel * strength * delta, -lift_speed)
