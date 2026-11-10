extends Node2D
## A trap that shoots: the seashell (pearls), a totem head (spikes) or a cannon (cannonballs).
## Fires every `interval` seconds in `direction`, or only when fire() is called (`on_call`,
## the lookout's alarm cannon). Projectiles hurt like Hazards and pop on walls.

const SEASHELL := preload("res://assets/level2_treasure_hunters/traps/seashell/seashell_frames.tres")
const TOTEM := preload("res://assets/level2_treasure_hunters/traps/totem_heads/totem_heads_frames.tres")
const CANNON := preload("res://assets/level2_treasure_hunters/traps/cannon/cannon_frames.tres")
const KINDS := {
	"seashell": {"frames": SEASHELL, "idle": "idle", "fire": "fire", "shot": "pearl", "muzzle": Vector2(14, -2)},
	"totem": {"frames": TOTEM, "idle": "head_1_idle_1", "fire": "head_1_attack_1", "shot": "spike", "muzzle": Vector2(16, 2)},
	"cannon": {"frames": CANNON, "idle": "idle", "fire": "fire", "shot": "ball", "muzzle": Vector2(18, 18)},
}

@export_enum("seashell", "totem", "cannon") var kind := "seashell"
@export_range(-1, 1, 2) var direction := -1  ## -1 shoots left, 1 shoots right.
@export var interval := 2.5
@export var delay := 0.0  ## Seconds before the first shot.
@export var speed := 110.0
@export var reach := 320.0
@export var damage := 20.0
@export var to_checkpoint := false  ## The shot sends the hero back to the last checkpoint.
@export var on_call := false  ## Only fires when fire() is called.

var _sprite: AnimatedSprite2D
var _timer := 0.0


func _ready() -> void:
	var k: Dictionary = KINDS[kind]
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = k["frames"]
	_sprite.play(k["idle"])
	_sprite.flip_h = direction > 0  # all three face left in the art
	add_child(_sprite)
	_timer = -delay
	if on_call:
		add_to_group("alarm_cannon")


func _process(delta: float) -> void:
	if on_call:
		return
	_timer += delta
	if _timer >= interval:
		_timer = 0.0
		fire()


func fire() -> void:
	var k: Dictionary = KINDS[kind]
	_sprite.play(k["fire"])
	_sprite.animation_finished.connect(func(): _sprite.play(k["idle"]), CONNECT_ONE_SHOT)
	var shot := Shot.new()
	shot.frames = k["frames"]
	shot.anim = k["shot"]
	shot.velocity = Vector2(direction * speed, 0)
	shot.reach = reach
	shot.damage = damage
	shot.send_to_checkpoint = to_checkpoint
	shot.flip = _sprite.flip_h
	get_parent().add_child(shot)
	var m: Vector2 = k["muzzle"]
	shot.global_position = global_position + Vector2(m.x * direction, m.y)
	Sound.play_at("rock_slam" if kind == "cannon" else "fire", global_position)


## The projectile.
class Shot extends Hazard:
	var frames: SpriteFrames
	var anim := ""
	var velocity := Vector2.ZERO
	var reach := 320.0
	var flip := false
	var _travelled := 0.0

	func _ready() -> void:
		super()
		collision_mask = 2 | 1
		var s := AnimatedSprite2D.new()
		s.sprite_frames = frames
		s.play(anim)
		s.flip_h = flip
		add_child(s)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 5.0
		shape.shape = circle
		add_child(shape)

	func _physics_process(delta: float) -> void:
		super(delta)
		var step := velocity * delta
		position += step
		_travelled += step.length()
		if _travelled > reach:
			queue_free()
			return
		if not get_overlapping_bodies().is_empty():
			queue_free()  # hit a wall or the hero (the Hazard part already hurt them)
