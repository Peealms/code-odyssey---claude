extends CharacterBody2D
## Crabby, borrowed from Level 2. Patrols back and forth, pinches when the player is close,
## and hurts the player on touch. The sword (take_damage) wears down its health.
## A small health bar floats above it for a moment after each hit.

signal defeated

@export var max_health := 30.0  ## The sword does 10 per hit, so 3 hits.
@export var health_bar_time := 2.0  ## Seconds the health bar stays after a hit.
@export var speed := 40.0
@export var patrol_left := -120.0  ## Patrol limits, relative to where Crabby starts.
@export var patrol_right := 120.0
@export var attack_range := 52.0  ## How close the player must be before Crabby pinches.
@export var contact_damage := 20.0  ## Health the player loses per touch or pinch.

## Attack animation frames where the claws are stretched out and the ClawBox hurts.
const CLAW_FRAMES := [1, 2]
@export var gravity := 900.0

var health := 0.0
var _bar_id := 0
var _dir := -1
var _start_x := 0.0
var _stun := 0.0
var _attacking := false
var _dead := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var claw_box: Area2D = $ClawBox
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.visible = false
	_start_x = global_position.x
	sprite.play("run")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	_stun -= delta

	if _dead or _stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	elif _attacking:
		velocity.x = 0.0
	else:
		_patrol()
	move_and_slide()

	if not _dead:
		var hitting := hurtbox.get_overlapping_bodies()
		# The pinch reaches much further than Crabby's body.
		if sprite.animation == "attack" and sprite.frame in CLAW_FRAMES:
			hitting += claw_box.get_overlapping_bodies()
		for body in hitting:
			if body.has_method("take_hit"):
				body.take_hit(global_position, contact_damage)


func _patrol() -> void:
	var offset := global_position.x - _start_x
	if offset <= patrol_left:
		_dir = 1
	elif offset >= patrol_right:
		_dir = -1

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var to_player := player.global_position - global_position
		if absf(to_player.x) < attack_range and absf(to_player.y) < 32.0:
			_dir = int(signf(to_player.x)) if to_player.x != 0.0 else _dir
			_attack()
			return

	velocity.x = _dir * speed
	sprite.flip_h = _dir > 0
	_play("run")


func _attack() -> void:
	_attacking = true
	sprite.flip_h = _dir > 0
	sprite.play("anticipation")
	await sprite.animation_finished
	if not _dead and _stun <= 0.0:
		sprite.play("attack")
		await sprite.animation_finished
	_attacking = false


## Called by the player's sword.
func take_damage(from_position: Vector2, amount := 10.0) -> void:
	if _dead:
		return
	health = maxf(health - amount, 0.0)
	DamageNumber.spawn(self, amount, DamageNumber.ENEMY_HIT, 30.0)
	_show_health_bar()
	_stun = 0.3
	_attacking = false
	velocity.x = signf(global_position.x - from_position.x) * 140.0
	var flash := create_tween()
	sprite.modulate = Color(1, 0.45, 0.45)
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	if health <= 0:
		_die()
	else:
		sprite.play("hit")


## Shows the bar, slides it down to the new health, then fades it out after a while.
func _show_health_bar() -> void:
	_bar_id += 1
	var id := _bar_id
	health_bar.visible = true
	health_bar.modulate.a = 1.0
	create_tween().tween_property(health_bar, "value", health, 0.2)
	await get_tree().create_timer(health_bar_time).timeout
	if id != _bar_id or not is_inside_tree():
		return
	var fade := create_tween()
	fade.tween_property(health_bar, "modulate:a", 0.0, 0.4)
	await fade.finished
	if id == _bar_id:
		health_bar.visible = false


func _die() -> void:
	_dead = true
	collision_layer = 0
	hurtbox.set_deferred("monitoring", false)
	claw_box.set_deferred("monitoring", false)
	sprite.play("dead_hit")
	await sprite.animation_finished
	sprite.play("dead_ground")
	defeated.emit()
	await get_tree().create_timer(1.0).timeout
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.5)
	await fade.finished
	queue_free()


func _play(anim: String) -> void:
	if sprite.animation == "hit" and sprite.is_playing():
		return
	if sprite.animation != anim:
		sprite.play(anim)
