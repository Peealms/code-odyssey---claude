extends CharacterBody2D
## Captain Clown Nose, Level 2's final boss (docs/level2_design.md, exam section 6).
## He runs his own rule, shown on the sign beside the arena with the line he picked:
##     if (distance > 6) { move = 'C'; }  else if (distance > 2) { move = 'T'; }  else { move = 'S'; }
## (distance > 4 for the charge once he's at half health). He shouts each attack and the reading
## `move` changes a second before it lands, so the player's rule can switch hero in time:
##   'C' charge with the sword raised high: only April's double jump clears it
##   'T' the sword spins across the arena at head height, sticks in the wall, comes back:
##       only tiny Psalm fits under it
##   'S' a wide swing up close: Sarah's dash gets away
## After each attack he's open for a moment and the sword hurts him (60 HP = 6 hits); otherwise
## it bounces off. The fight starts when the hero walks past `start_x` with a rule saved for
## Byte (Byte hides during the fight); if the hero is sent back, he resets.

signal started
signal stopped  ## The hero was sent back: he reset.
signal defeated

const FRAMES := preload("res://assets/level2_treasure_hunters/characters/captain_clown_nose/captain_clown_nose_frames.tres")
const TELL_TIME := 1.0
const HIT_DAMAGE := 34.0

@export var arena_left := 0.0  ## Global x of the arena's walls.
@export var arena_right := 640.0
@export var start_x := 0.0  ## Global x the hero passes to start the fight.
@export var sign_position := Vector2.ZERO  ## Global top-left of the captain's rule sign.
@export var max_health := 60.0
@export var door_height := 64.0  ## Height of the arena's doorway at arena_left.

enum S { WAIT, THINK, TELL, CHARGE, THROW, SWING, OPEN, DEAD }

var brain: ReadingSource  ## Gives the readings `move` and `distance`.
var health := 0.0
var fighting := false
var st := S.WAIT
var _timer := 0.0
var _move := ""
var _home := Vector2.ZERO
var _facing := -1
var _sprite: AnimatedSprite2D
var _bubble: Label
var _sign: Label
var _bar: ProgressBar
var _contact: Area2D  ## Hurts during the charge (tall: sword raised).
var _swing: Area2D
var _sword: Area2D  ## The thrown sword.
var _sword_dir := 1
var _sword_phase := 0  ## 0 out, 1 stuck in the wall, 2 coming back
var _sword_timer := 0.0
var _runner: RuleRunner
var _warned := false
var _vulnerable := false
var _barrier: CollisionShape2D  ## Shuts the arena's doorway during the fight.


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	health = max_health
	_home = global_position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 34)
	shape.shape = rect
	shape.position = Vector2(0, -17)
	add_child(shape)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = FRAMES
	_sprite.position = Vector2(0, -24)
	_sprite.play("idle_s")
	add_child(_sprite)
	_contact = _hurt_area(Vector2(36, 80), Vector2(0, -40))
	_swing = _hurt_area(Vector2(72, 48), Vector2(0, -24))
	brain = ReadingSource.new()
	add_child(brain)
	brain.set_reading("move", "S")
	brain.set_reading("distance", 0)
	_bubble = Label.new()
	_bubble.position = Vector2(-40, -68)
	_bubble.size = Vector2(80, 14)
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
	_bar.position = Vector2(-20, -56)
	_bar.size = Vector2(40, 4)
	_bar.visible = false
	add_child(_bar)
	_make_sword()
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.top_level = true
	_barrier = CollisionShape2D.new()
	var wall_rect := RectangleShape2D.new()
	wall_rect.size = Vector2(16, door_height)
	_barrier.shape = wall_rect
	_barrier.disabled = true
	wall.add_child(_barrier)
	add_child(wall)
	wall.global_position = Vector2(arena_left - 8.0, global_position.y - door_height / 2.0)
	_make_sign.call_deferred()
	_find_runner.call_deferred()


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
	art.position = Vector2(0, -24)
	art.scale = Vector2(1.6, 1.6)
	_sword.add_child(art)
	_sword.visible = false
	_sword.monitoring = false
	_sword.top_level = true
	add_child(_sword)


func _make_sign() -> void:
	_sign = Label.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "Monospace"])
	_sign.add_theme_font_override("font", font)
	_sign.add_theme_font_size_override("font_size", 8)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.43, 0.29, 0.23, 0.95)
	box.border_color = Color("3d2429")
	box.set_border_width_all(2)
	box.set_content_margin_all(4)
	_sign.add_theme_stylebox_override("normal", box)
	_sign.top_level = true
	_sign.global_position = sign_position
	_sign.z_index = 6
	add_child(_sign)
	_update_sign()


func _find_runner() -> void:
	for r in get_tree().get_nodes_in_group("rule_runner"):
		if r.room and r.room.contains(global_position) and not r.locked:
			_runner = r


func _charge_at() -> int:
	return 6 if health > max_health / 2.0 else 4


func _update_sign() -> void:
	if _sign == null:
		return
	var marks := {"C": "  ", "T": "  ", "S": "  "}
	if fighting and st in [S.TELL, S.CHARGE, S.THROW, S.SWING]:
		marks[_move] = "> "
	_sign.text = "CAPTAIN'S RULE\n%sif (distance > %d) { move = 'C'; }\n%selse if (distance > 2) { move = 'T'; }\n%selse { move = 'S'; }" % [
		marks["C"], _charge_at(), marks["T"], marks["S"]]


# ---------------- the fight ----------------

func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	brain.set_reading("distance", int(roundf(absf(player.global_position.x - global_position.x) / 32.0)))
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
			velocity.x = _facing * 260.0
			_play("run_s")
			var edge := arena_left + 20.0 if _facing < 0 else arena_right - 20.0
			if (_facing < 0 and global_position.x <= edge) or (_facing > 0 and global_position.x >= edge):
				velocity.x = 0.0
				_contact.set_deferred("monitoring", false)
				Sound.play_at("rock_slam", global_position)
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
	if fighting and player.global_position.x < start_x - 48.0:
		_reset()  # the hero was sent back to the checkpoint


func _try_start(player: CharacterBody2D) -> void:
	if fighting or st == S.DEAD:
		return
	if _runner == null or _runner.rule.is_empty():
		player.global_position.x = start_x - 24.0
		player.velocity = Vector2.ZERO
		if not _warned:
			_warned = true
			var byte := get_tree().get_first_node_in_group("byte")
			if byte:
				byte.say("LEAVE ME A RULE FIRST! PRESS E", 3.0)
		return
	fighting = true
	_barrier.set_deferred("disabled", false)
	_bar.visible = true
	_bubble.text = "ARR! MY TREASURE!"
	started.emit()
	st = S.THINK
	_timer = 1.2


func _think(player: CharacterBody2D) -> void:
	_facing = -1 if player.global_position.x < global_position.x else 1
	_sprite.flip_h = _facing < 0
	var d: int = brain.get_reading("distance")
	if d > _charge_at():
		_move = "C"
		_bubble.text = "CHARGE!"
	elif d > 2:
		_move = "T"
		_bubble.text = "CATCH THIS!"
	else:
		_move = "S"
		_bubble.text = "SWING!"
	brain.set_reading("move", _move)
	st = S.TELL
	_timer = TELL_TIME
	_play("ground_s" if _move == "C" else "idle_s")
	_update_sign()


func _attack() -> void:
	match _move:
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
	_update_sign()


## The thrown sword: out to the wall, stuck there (the captain is open), then back.
func _move_sword(delta: float) -> void:
	var edge := arena_left + 14.0 if _sword_dir < 0 else arena_right - 14.0
	match _sword_phase:
		0:
			_sword.global_position.x += _sword_dir * 230.0 * delta
			if (_sword_dir < 0 and _sword.global_position.x <= edge) or (_sword_dir > 0 and _sword.global_position.x >= edge):
				_sword_phase = 1
				_sword_timer = 1.6
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
			_sword.global_position.x += signf(dx) * 230.0 * delta
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
func take_damage(from_position: Vector2, amount := 10.0) -> void:
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
	_update_sign()


func _die() -> void:
	st = S.DEAD
	fighting = false
	_barrier.set_deferred("disabled", true)
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
	_barrier.set_deferred("disabled", true)
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
	_update_sign()


func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.play(anim)
