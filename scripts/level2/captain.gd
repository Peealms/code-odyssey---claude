extends CharacterBody2D
## Captain Clown Nose, Level 1's final boss (docs/level2_design.md, Exam 3). He guards the
## treasure in his arena and picks an attack by how far away the hero is. He shouts it about a
## second before it lands, so the hero can switch to the one hero who dodges it (hold Q):
##   CHARGE (far away)  he runs across with his sword raised high: April's double jump clears it
##   THROW  (middle)    his sword spins across the arena at head height, sticks in the wall and
##                      comes back: tiny Psalm (hold Down) fits under it
##   SWING  (up close)  a wide swing: Sarah's dash gets away
## After each attack he's open for a moment (he glows): the hero's sword hurts him then, and
## bounces off at any other time. 60 HP = 6 hits. The fight starts when a hero with a sword
## walks past `start_x`; if the hero leaves the arena (or is sent back to the checkpoint), he
## resets.

signal started
signal stopped  ## The hero left the arena: he reset.
signal defeated

const FRAMES := preload("res://assets/level2_treasure_hunters/characters/captain_clown_nose/captain_clown_nose_frames.tres")
## He's drawn 1.5x bigger than the art, so he looks like a boss next to the heroes.
const ART_SCALE := 1.5
## The frames are 66 x 56 and drawn centred; his feet are on row 34, 6 px below the middle.
const FEET_BELOW_MIDDLE := 6.0
const TELL_TIME := 1.2  ## Seconds between shouting an attack and doing it.
const CHARGE_SPEED := 220.0
const SWORD_SPEED := 230.0
const HIT_DAMAGE := 25.0

@export var arena_left := 0.0  ## Global x of the arena's walls.
@export var arena_right := 640.0
@export var start_x := 0.0  ## Global x the hero passes to start the fight.
@export var max_health := 60.0

enum S { WAIT, THINK, TELL, CHARGE, THROW, SWING, OPEN, DEAD }

var health := 0.0
var fighting := false
var st := S.WAIT
var move := ""  ## The attack he's shouted: "C", "T" or "S".
var _timer := 0.0
var _home := Vector2.ZERO
var _facing := -1
var _sprite: AnimatedSprite2D
var _bubble: Label
var _bar: ProgressBar
var _contact: Area2D  ## Hurts during the charge (tall: the sword is raised).
var _swing: Area2D
var _sword: Area2D  ## The thrown sword.
var _sword_dir := 1
var _sword_phase := 0  ## 0 flying out, 1 stuck in the wall, 2 coming back
var _sword_timer := 0.0
var _warned := false
var _vulnerable := false


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	health = max_health
	_home = global_position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	add_child(shape)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = FRAMES
	_sprite.scale = Vector2(ART_SCALE, ART_SCALE)
	_sprite.position = Vector2(0, -FEET_BELOW_MIDDLE * ART_SCALE)  # feet on the floor
	_sprite.play("idle_s")
	add_child(_sprite)
	_contact = _hurt_area(Vector2(36, 64), Vector2(0, -32))  # up to his raised sword: a normal jump hits it
	_swing = _hurt_area(Vector2(72, 48), Vector2(0, -24))
	_bubble = Label.new()
	_bubble.position = Vector2(-50, -66)
	_bubble.size = Vector2(100, 14)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.add_theme_color_override("font_color", Color("ffe478"))
	_bubble.add_theme_color_override("font_shadow_color", Color("211f30"))
	_bubble.add_theme_constant_override("shadow_offset_x", 1)
	_bubble.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_bubble)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.max_value = max_health
	_bar.value = health
	_bar.position = Vector2(-20, -52)
	_bar.size = Vector2(40, 4)
	_bar.visible = false
	add_child(_bar)
	_make_sword()


func _hurt_area(size: Vector2, pos: Vector2) -> Area2D:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.monitoring = false
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	s.shape = r
	s.position = pos
	a.add_child(s)
	add_child(a)
	return a


func _make_sword() -> void:
	_sword = Area2D.new()
	_sword.collision_layer = 0
	_sword.collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(26, 84)  # from 15 px above the floor up: only tiny Psalm (12 px) fits under
	s.shape = r
	s.position = Vector2(0, -57)
	_sword.add_child(s)
	var art := AnimatedSprite2D.new()
	art.name = "Art"
	art.sprite_frames = FRAMES
	art.play("sword_spinning")
	art.position = Vector2(0, -15)  # the blade's lowest point (frame row 28, the middle) 15 px up, like its hurt box
	art.scale = Vector2(1.6, 1.6)
	_sword.add_child(art)
	_sword.visible = false
	_sword.monitoring = false
	_sword.top_level = true
	add_child(_sword)


# ---------------- The fight ----------------

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	if not is_on_floor():
		velocity.y += 900.0 * delta
	else:
		velocity.y = 0.0
	_timer -= delta
	match st:
		S.WAIT:
			velocity.x = 0.0
			if player.global_position.x > start_x:
				_try_start(player)
		S.THINK:
			velocity.x = 0.0
			if _timer <= 0.0:
				_think(player)
		S.TELL:
			velocity.x = 0.0
			if _timer <= 0.0:
				_attack()
		S.CHARGE:
			velocity.x = _facing * CHARGE_SPEED
			_play("run_s")
			var edge := arena_left + 20.0 if _facing < 0 else arena_right - 20.0
			if (_facing < 0 and global_position.x <= edge) or (_facing > 0 and global_position.x >= edge):
				velocity.x = 0.0
				_contact.set_deferred("monitoring", false)
				Sound.play_at("gate_break", global_position)
				_open(1.6, "DIZZY!", "hit")
		S.THROW:
			velocity.x = 0.0
			_move_sword(delta)
		S.SWING:
			velocity.x = 0.0
			if _timer <= 0.0:
				_swing.set_deferred("monitoring", false)
				_open(1.2, "WHOA!", "idle_s")
		S.OPEN:
			velocity.x = 0.0
			if _timer <= 0.0:
				_bubble.text = ""
				st = S.THINK
				_timer = 0.4
				_play("idle_s")
		S.DEAD:
			velocity.x = 0.0
	move_and_slide()
	_hurt_player(player)
	if fighting and player.global_position.x < arena_left:
		_reset()  # the hero left the arena, or was sent back to the checkpoint


## The fight starts only for a hero with a sword: without one there's nothing to hit him with.
func _try_start(player: CharacterBody2D) -> void:
	if fighting or st == S.DEAD:
		return
	if not player.has_sword:
		player.global_position.x = start_x - 24.0
		player.velocity = Vector2.ZERO
		if not _warned:
			_warned = true
			var byte := get_tree().get_first_node_in_group("byte")
			if byte:
				byte.say("A SWORD FIRST! hasSword = true;", 3.5)
		return
	fighting = true
	_bar.visible = true
	_bubble.text = "ARR! MY TREASURE!"
	started.emit()
	st = S.THINK
	_timer = 1.2


## Picks the next attack by distance and shouts it.
func _think(player: CharacterBody2D) -> void:
	_facing = -1 if player.global_position.x < global_position.x else 1
	_sprite.flip_h = _facing < 0
	var tiles := absf(player.global_position.x - global_position.x) / 32.0
	if tiles > 5.0:
		move = "C"
		_bubble.text = "CHARGE!"
	elif tiles > 2.0:
		move = "T"
		_bubble.text = "CATCH THIS!"
	else:
		move = "S"
		_bubble.text = "SWING!"
	st = S.TELL
	_timer = TELL_TIME
	_play("ground_s" if move == "C" else "idle_s")


func _attack() -> void:
	match move:
		"C":
			st = S.CHARGE
			_contact.set_deferred("monitoring", true)
		"T":
			st = S.THROW
			_play("throw_sword")
			_sword_dir = _facing
			_sword_phase = 0
			_sword.global_position = global_position + Vector2(_facing * 20.0, 0)
			_sword.visible = true
			_sword.set_deferred("monitoring", true)
			_sword.get_node("Art").play("sword_spinning")
			Sound.play_at("sword", global_position)
		"S":
			st = S.SWING
			_play("attack_1")
			_swing.position = Vector2(_facing * 30.0, 0)
			_swing.set_deferred("monitoring", true)
			_timer = 0.3
			Sound.play_at("sword", global_position)


## The thrown sword: out to the wall, stuck there (he's open meanwhile), then back to him.
func _move_sword(delta: float) -> void:
	var edge := arena_left + 14.0 if _sword_dir < 0 else arena_right - 14.0
	match _sword_phase:
		0:
			_sword.global_position.x += _sword_dir * SWORD_SPEED * delta
			if (_sword_dir < 0 and _sword.global_position.x <= edge) or (_sword_dir > 0 and _sword.global_position.x >= edge):
				_sword_phase = 1
				_sword_timer = 1.2
				_sword.set_deferred("monitoring", false)
				_sword.get_node("Art").play("sword_embedded")
				_bubble.text = "MY SWORD!"
				_play("idle")
				_open_window(true)
		1:
			_sword_timer -= delta
			if _sword_timer <= 0.0:
				_sword_phase = 2
				_open_window(false)
				_sword.set_deferred("monitoring", true)
				_sword.get_node("Art").play("sword_spinning")
		2:
			var dx := global_position.x - _sword.global_position.x
			_sword.global_position.x += signf(dx) * SWORD_SPEED * delta
			if absf(dx) < 8.0:
				_sword.visible = false
				_sword.set_deferred("monitoring", false)
				_bubble.text = ""
				st = S.THINK
				_timer = 0.5
				_play("idle_s")


func _open(seconds: float, shout: String, anim: String) -> void:
	st = S.OPEN
	_timer = seconds
	_bubble.text = shout
	_play(anim)
	_open_window(true)
	await get_tree().create_timer(seconds).timeout
	_open_window(false)


func _open_window(open: bool) -> void:
	_vulnerable = open
	_sprite.modulate = Color(1.2, 1.2, 0.8) if open else Color.WHITE


func _hurt_player(player: CharacterBody2D) -> void:
	for a in [_contact, _swing, _sword]:
		if a.monitoring:
			for body in a.get_overlapping_bodies():
				if body == player:
					player.take_hit(a.global_position, HIT_DAMAGE)


## Called by the hero's sword.
func take_damage(_from_position: Vector2, amount := 10.0) -> void:
	if not fighting or st == S.DEAD:
		return
	if not _vulnerable:
		Sound.play_at("blocked", global_position)
		_bubble.text = "HA! MISSED!"
		return
	health = maxf(health - amount, 0.0)
	_bar.value = health
	DamageNumber.spawn(self, amount, DamageNumber.ENEMY_HIT, 40.0)
	var flash := create_tween()
	_sprite.modulate = Color(1, 0.45, 0.45)
	flash.tween_property(_sprite, "modulate", Color(1.2, 1.2, 0.8), 0.2)
	if health <= 0.0:
		_die()


func _die() -> void:
	st = S.DEAD
	fighting = false
	_vulnerable = false
	for a in [_contact, _swing, _sword]:
		a.set_deferred("monitoring", false)
	_sword.visible = false
	_bubble.text = "ARR... YOU WIN!"
	_bar.visible = false
	_play("dead_hit")
	await _sprite.animation_finished
	_play("dead_ground")
	defeated.emit()


func _reset() -> void:
	fighting = false
	stopped.emit()
	st = S.WAIT
	health = max_health
	_bar.value = health
	_bar.visible = false
	_bubble.text = ""
	_open_window(false)
	for a in [_contact, _swing, _sword]:
		a.set_deferred("monitoring", false)
	_sword.visible = false
	global_position = _home
	velocity = Vector2.ZERO
	_play("idle_s")


func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.play(anim)
