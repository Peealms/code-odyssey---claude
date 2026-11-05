extends CharacterBody2D
## The playable hero. One scene handles every hero (the five of us in the team):
## switching hero swaps the sprite and turns that hero's special trait on.
## Every trait uses stamina; if stamina runs out the hero is "exhausted"
## and can't use the trait until the bar is full again.
##
##   Chelzy -> Wall Jump   (gripping a wall drains stamina, each wall jump costs some)
##   Sarah  -> Short Dash  (costs stamina)
##   April  -> Double Jump (costs stamina)
##   Kervin -> Sprint      (hold Shift, drains stamina)
##   Psalm  -> Shrink      (hold Down to fit through 1-tile tunnels, drains stamina)
##
## Each hero only has the animations of their own trait (tools/make_team_heroes.gd).

signal hero_changed(hero_id: String)
signal inventory_changed
signal selected_slot_changed(slot: int)
signal health_changed(health: float, max_health: float)
signal stamina_changed(stamina: float, max_stamina: float, exhausted: bool)
signal died

## `hand`: where the sword is held (its pivot), in player pixels, facing right.
const HERO_DATA := {
	"chelzy": {
		"name": "Chelzy",
		"frames": "res://assets/shared/heroes/chelzy/chelzy_frames.tres",
		"trait": "wall_jump",
		"hand": Vector2(5, 1),
	},
	"sarah": {
		"name": "Sarah",
		"frames": "res://assets/shared/heroes/sarah/sarah_frames.tres",
		"trait": "dash",
		"hand": Vector2(5, 6),
	},
	"april": {
		"name": "April",
		"frames": "res://assets/shared/heroes/april/april_frames.tres",
		"trait": "double_jump",
		"hand": Vector2(5, 6),
	},
	"kervin": {
		"name": "Kervin",
		"frames": "res://assets/shared/heroes/kervin/kervin_frames.tres",
		"trait": "sprint",
		"hand": Vector2(5, 4),
	},
	"psalm": {
		"name": "Psalm",
		"frames": "res://assets/shared/heroes/psalm/psalm_frames.tres",
		"trait": "shrink",
		"hand": Vector2(5, 11),
	},
}

## The heroes' frames are 40x40 with the feet on the bottom row. Drawn centred, that puts the
## feet 4 px below the 16x24 hitbox, so every hero sprite is lifted by this much.
const SPRITE_OFFSET := Vector2(0, -4)
## Psalm's hitbox while he's shrunk: it fits a 1-tile (16 px) tunnel that stops everyone
## else. Its feet stay where the full hitbox's feet are.
const SMALL_SIZE := Vector2(10, 12)

@export_group("Health")
@export var max_health := 100.0
@export var invulnerable_time := 1.0  ## After a hit, the hero blinks and can't be hurt for this long.

@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina_regen := 40.0  ## Per second.
@export var stamina_regen_delay := 0.6  ## Seconds after using stamina before it refills.
@export var dash_stamina_cost := 35.0
@export var double_jump_stamina_cost := 35.0
@export var wall_jump_stamina_cost := 15.0
@export var wall_grip_stamina_drain := 15.0  ## Per second while sliding down a wall.
@export var sprint_stamina_drain := 30.0  ## Per second while sprinting.
## Per second while Psalm is small. It stops while a low ceiling keeps him small, so he
## can never run out halfway through a tunnel.
@export var shrink_stamina_drain := 20.0

@export_group("Movement")
@export var run_speed := 130.0
@export var sprint_multiplier := 1.9  ## Kervin holding Shift.
@export var acceleration := 900.0
@export var friction := 1100.0
@export var air_control := 0.75

@export_group("Jumping")
@export var jump_velocity := -300.0
@export var gravity := 900.0
@export var max_fall_speed := 380.0
@export var jump_cut_multiplier := 0.45  ## Release jump early = shorter jump.
@export var coyote_time := 0.1  ## Grace period to jump after walking off a ledge.
@export var jump_buffer_time := 0.12  ## Pressing jump slightly before landing still works.

@export_group("Traits")
@export var wall_slide_speed := 60.0
@export var wall_jump_push := 170.0
@export var dash_speed := 300.0
@export var dash_time := 0.3  ## 0.3 s at 300 px/s = 90 px: crosses the 5-tile crawlspace gaps with room to spare.
@export var dash_cooldown := 0.5
## Tiny Psalm's run speed. Slower legs also stop him hopping over a falling floor in a
## crawlspace (he'd have more headroom to hop than the others).
@export var small_speed_multiplier := 0.6

@export_group("Sword")
@export var sword_damage := 10.0
@export var sword_windup_time := 0.06  ## Quick pull-back before the slash.
@export var sword_swing_time := 0.14
@export var sword_cooldown := 0.35
@export var sword_reach := 16.0  ## How far in front of the hero the sword hitbox sits.

@export_group("Debug")
## Lets you press 1-5 to switch heroes while testing. Turn off for the real game.
@export var debug_hero_keys := false

var hero_id := "chelzy"
var facing := 1
var input_enabled := true
## Set by the code terminal (boolean hasSword = true;). Puts the sword in the hotbar.
var has_sword := false:
	set(value):
		has_sword = value
		if value:
			add_item("sword")
		else:
			remove_item("sword")

## Hotbar items by slot ("" = empty). The selected slot is the item in the hero's hand.
var inventory: Array[String] = ["", "", "", "", ""]
var selected_slot := 0

var health := 0.0
var stamina := 0.0
var exhausted := false  ## True after stamina hits 0, until it's full again.
var is_sprinting := false
## Psalm is shrunk (hold Down). He stays small under a low ceiling even after letting go.
var is_small := false
## Set by the code terminal (double jumpPower = 1.5;). 1.5 = jumps 1.5x as high.
var jump_power := 1.0

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _air_jumps_left := 0
var _wall_jump_lock := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _is_hit := false
var _invulnerable_timer := 0.0
var _stamina_regen_timer := 0.0
var _swing_timer := 0.0
var _sword_cooldown_timer := 0.0
var _hit_this_swing: Array = []
var _swing_tween: Tween
var _full_shape: RectangleShape2D
var _full_shape_pos := Vector2.ZERO
var _small_shape := RectangleShape2D.new()
var _grow_query := PhysicsShapeQueryParameters2D.new()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var swap_fx: AnimatedSprite2D = $SwapFx
@onready var sword_holder: Node2D = $SwordHolder
@onready var sword_pivot: Node2D = $SwordHolder/Pivot
@onready var sword_trail: Node2D = $SwordHolder/Trail
@onready var sword_hitbox: Area2D = $SwordHitbox


func _ready() -> void:
	sword_trail.pivot = sword_pivot
	sprite.offset = SPRITE_OFFSET
	_full_shape = body_shape.shape
	_full_shape_pos = body_shape.position
	_small_shape.size = SMALL_SIZE
	# Growing back is tested with the full hitbox 1 px smaller all round, so just touching
	# the floor or a wall doesn't count as being in the way.
	var grow_shape := RectangleShape2D.new()
	grow_shape.size = _full_shape.size - Vector2(2, 2)
	_grow_query.shape = grow_shape
	_grow_query.collision_mask = collision_mask
	_grow_query.exclude = [get_rid()]
	set_hero(Game.current_hero if HERO_DATA.has(Game.current_hero) else Game.HEROES[0], false)
	_refresh_held_item()
	restore_vitals()


## Returns false (and keeps the hero) if the name is unknown, or if Psalm is shrunk somewhere
## a full-size hero wouldn't fit.
func set_hero(new_hero: String, play_effect := true) -> bool:
	if not HERO_DATA.has(new_hero):
		push_warning("Unknown hero: %s" % new_hero)
		return false
	if is_small and new_hero != hero_id:
		var nudge = _room_to_grow()
		if nudge == null:
			return false
		_set_small(false, nudge, false)  # the swap effect covers it, no grow animation
	hero_id = new_hero
	sprite.sprite_frames = load(HERO_DATA[new_hero]["frames"])
	sprite.play("idle")
	# Short and tall heroes hold the sword at different heights.
	sword_pivot.position = HERO_DATA[new_hero]["hand"]
	sword_trail.position = sword_pivot.position
	Game.current_hero = new_hero
	if play_effect:
		swap_fx.visible = true
		swap_fx.play("appearing")
		Sound.play("hero_swap")
	hero_changed.emit(new_hero)
	return true


## False while Psalm is squeezed under a low ceiling: another hero wouldn't fit there.
func can_change_hero() -> bool:
	return not is_small or _room_to_grow() != null


func has_trait(trait_name: String) -> bool:
	return HERO_DATA[hero_id]["trait"] == trait_name


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	var dir := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	_update_shrink(delta)

	if _dash_timer > 0.0:
		_process_dash(delta)
	else:
		_apply_gravity(delta, dir)
		_handle_jump()
		_handle_horizontal(dir, delta)
		_try_start_dash()

	var falling_fast := velocity.y > 200.0
	move_and_slide()
	_step_onto_lip()
	if falling_fast and is_on_floor():
		Sound.play("land", 0.1)
	_update_animation(dir)
	_update_sword()


func _unhandled_input(event: InputEvent) -> void:
	if not debug_hero_keys:
		return
	for i in Game.HEROES.size():
		var action := "debug_hero_%d" % (i + 1)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			set_hero(Game.HEROES[i])


# ---------------- Movement pieces ----------------

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
		_air_jumps_left = 1 if has_trait("double_jump") else 0
	else:
		_coyote_timer -= delta
	_jump_buffer_timer -= delta
	_wall_jump_lock -= delta
	_dash_timer -= delta
	_dash_cooldown_timer -= delta
	_swing_timer -= delta
	_sword_cooldown_timer -= delta
	_invulnerable_timer -= delta
	_regen_stamina(delta)
	if input_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time


func _apply_gravity(delta: float, dir: float) -> void:
	if is_on_floor():
		return
	velocity.y += gravity * delta
	var fall_cap := max_fall_speed
	if _is_wall_sliding(dir):
		fall_cap = wall_slide_speed
		_spend_stamina(wall_grip_stamina_drain * delta)
	velocity.y = minf(velocity.y, fall_cap)
	# Variable jump height: letting go of jump early cuts the jump short.
	if input_enabled and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _handle_jump() -> void:
	if _jump_buffer_timer <= 0.0:
		return
	if _coyote_timer > 0.0:
		_do_jump()
		Sound.play("jump", 0.05)
	elif has_trait("wall_jump") and is_on_wall_only() and can_use_stamina(wall_jump_stamina_cost):
		_spend_stamina(wall_jump_stamina_cost)
		var wall_dir := -signf(get_wall_normal().x)
		velocity.x = -wall_dir * wall_jump_push
		facing = int(-wall_dir)
		_wall_jump_lock = 0.18
		_do_jump()
		Sound.play("wall_jump", 0.05)
	elif _air_jumps_left > 0 and can_use_stamina(double_jump_stamina_cost):
		_spend_stamina(double_jump_stamina_cost)
		_air_jumps_left -= 1
		_do_jump(false)
		sprite.play("double_jump")
		Sound.play("double_jump")


## `powered`: the first jump (and wall jumps) use jumpPower; the double jump never does, so
## April at jumpPower 2.0 can't clear everything with 200 px double jumps.
func _do_jump(powered := true) -> void:
	# Jump height grows with the square of the speed, so sqrt makes jump_power scale the height.
	velocity.y = jump_velocity * (sqrt(jump_power) if powered else 1.0)
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


func _handle_horizontal(dir: float, delta: float) -> void:
	if _wall_jump_lock > 0.0:
		return
	# Kervin: hold Shift (the dash key) to sprint while stamina lasts.
	is_sprinting = has_trait("sprint") and input_enabled and dir != 0.0 \
		and Input.is_action_pressed("dash") and can_use_stamina(0.01)
	var speed := run_speed * (small_speed_multiplier if is_small else 1.0)
	var accel := acceleration if is_on_floor() else acceleration * air_control
	if is_sprinting:
		speed *= sprint_multiplier
		accel *= 1.5
		_spend_stamina(sprint_stamina_drain * delta)
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
		facing = int(signf(dir))
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


func _try_start_dash() -> void:
	if not has_trait("dash") or not input_enabled:
		return
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0 \
			and can_use_stamina(dash_stamina_cost):
		_spend_stamina(dash_stamina_cost)
		_dash_timer = dash_time
		Sound.play("dash")
		_dash_cooldown_timer = dash_cooldown
		velocity = Vector2(facing * dash_speed, 0.0)


## The dash drifts up very slightly (about 2 px in total) so it glides onto a floor at the
## same height instead of catching on its corner.
const DASH_LIFT := -8.0
## The highest lip the hero steps up onto without jumping (see _step_onto_lip).
const STEP_UP := 2.0


## A falling platform that has just started to sink leaves the ground next to it a hair higher,
## and a hero running across that edge could stick on the corner (Room 3: Kervin's sprint
## stopped at the last platform). So when running on the floor doesn't move the hero, they
## step up onto a lip up to STEP_UP px high. A real wall still blocks: after the lift the way
## is still shut, and pressing into a wall leaves no sideways velocity anyway.
func _step_onto_lip() -> void:
	if not is_on_floor() or absf(velocity.x) < 1.0 or absf(get_real_velocity().x) > 1.0:
		return
	var lift := Vector2(0.0, -STEP_UP)
	var ahead := Vector2(signf(velocity.x) * 2.0, 0.0)
	if test_move(global_transform, lift) or test_move(global_transform.translated(lift), ahead):
		return
	global_position += lift + ahead * 0.5


func _process_dash(_delta: float) -> void:
	velocity = Vector2(facing * dash_speed, DASH_LIFT)
	if is_on_wall():
		_dash_timer = 0.0


func _is_wall_sliding(dir: float) -> bool:
	return has_trait("wall_jump") and is_on_wall_only() and velocity.y > 0.0 \
		and dir != 0.0 and signf(dir) == -signf(get_wall_normal().x) and can_use_stamina(0.01)


## Psalm: hold Down to shrink. Letting go (or running out of stamina) grows him back, but only
## where the full-size hitbox fits. Under a low ceiling he stays small and the stamina bar
## holds still until he's out.
func _update_shrink(delta: float) -> void:
	if not has_trait("shrink"):
		return
	var holding := input_enabled and Input.is_action_pressed("move_down")
	if not is_small:
		if holding and can_use_stamina(0.01):
			_set_small(true)
		return
	var nudge = _room_to_grow()
	if nudge == null:
		_stamina_regen_timer = stamina_regen_delay  # no drain, no refill
		return
	if holding and can_use_stamina(0.01):
		_spend_stamina(shrink_stamina_drain * delta)
		if not exhausted:
			return
	_set_small(false, nudge)


## Swaps the hitbox. `nudge` moves Psalm sideways as he grows, off a wall he's pressed against.
func _set_small(small: bool, nudge := 0.0, animate := true) -> void:
	is_small = small
	body_shape.shape = _small_shape if small else _full_shape
	body_shape.position = _full_shape_pos
	if small:
		# Same feet: the small box sits at the bottom of the full one.
		body_shape.position.y += (_full_shape.size.y - SMALL_SIZE.y) / 2.0
		_cancel_swing()  # tiny Psalm can't hold the sword
	else:
		position.x += nudge
	if animate:
		if small:
			sprite.play("shrink")
		else:
			sprite.play_backwards("shrink")
		Sound.play("shrink" if small else "grow")


## How far Psalm must move sideways for the full-size hitbox to fit where he is: 0, a few px
## off a wall he's pressed against, or null if there's no room (a ceiling is in the way).
func _room_to_grow() -> Variant:
	var space := get_world_2d().direct_space_state
	var side := (_full_shape.size.x - SMALL_SIZE.x) / 2.0
	for dx in [0.0, -side, side]:
		_grow_query.transform = Transform2D(0.0, global_position + _full_shape_pos + Vector2(dx, 0.0))
		if space.intersect_shape(_grow_query, 1).is_empty():
			return dx
	return null


# ---------------- Health & stamina ----------------

## Full health and stamina (start of a level, or after respawning).
func restore_vitals() -> void:
	health = max_health
	stamina = max_stamina
	exhausted = false
	_invulnerable_timer = 0.0
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina, exhausted)


## Gives back up to `amount` HP (health potions).
func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)
	Sound.play("heal")


func can_use_stamina(cost: float) -> bool:
	return not exhausted and stamina >= cost


func _spend_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)
	_stamina_regen_timer = stamina_regen_delay
	if stamina <= 0.0:
		exhausted = true
	stamina_changed.emit(stamina, max_stamina, exhausted)


func _regen_stamina(delta: float) -> void:
	_stamina_regen_timer -= delta
	if _stamina_regen_timer > 0.0 or stamina >= max_stamina:
		return
	stamina = minf(stamina + stamina_regen * delta, max_stamina)
	if stamina >= max_stamina:
		exhausted = false
	stamina_changed.emit(stamina, max_stamina, exhausted)


# ---------------- Inventory ----------------

## Puts an item in the first empty hotbar slot. Returns the slot, or -1 if full / already owned.
func add_item(id: String) -> int:
	if id in inventory:
		return inventory.find(id)
	var slot := inventory.find("")
	if slot == -1:
		return -1
	inventory[slot] = id
	inventory_changed.emit()
	_refresh_held_item()
	return slot


func remove_item(id: String) -> void:
	var slot := inventory.find(id)
	if slot == -1:
		return
	inventory[slot] = ""
	inventory_changed.emit()
	_refresh_held_item()


func select_slot(slot: int) -> void:
	slot = wrapi(slot, 0, inventory.size())
	if slot == selected_slot:
		return
	selected_slot = slot
	selected_slot_changed.emit(slot)
	_refresh_held_item()


func held_item() -> String:
	return inventory[selected_slot]


## The sword is only drawn mid-swing, so switching away just cancels a swing in progress.
func _refresh_held_item() -> void:
	if is_node_ready() and held_item() != "sword":
		_cancel_swing()


func _cancel_swing() -> void:
	if _swing_tween:
		_swing_tween.kill()
	_swing_timer = 0.0
	sword_pivot.visible = false
	sword_trail.cancel()


# ---------------- Sword ----------------

## Left click uses the held item: the sword swings, a manual opens for reading.
func _update_sword() -> void:
	var held := held_item()
	if held.begins_with(ItemDB.MANUAL_PREFIX):
		if input_enabled and Input.is_action_just_pressed("attack"):
			var reader := get_tree().get_first_node_in_group("manual_reader")
			if reader:
				reader.open(ItemDB.get_item(held)["manual"])
		return
	if held != "sword":
		return
	sword_holder.scale.x = facing
	sword_hitbox.position.x = sword_reach * facing
	if input_enabled and Input.is_action_just_pressed("attack") and _sword_cooldown_timer <= 0.0 \
			and not is_small:
		_swing()
	if _swing_timer > 0.0:
		for body in sword_hitbox.get_overlapping_bodies():
			if body.has_method("take_damage") and not body in _hit_this_swing:
				_hit_this_swing.append(body)
				body.take_damage(global_position, sword_damage)


## Wind up behind the head, slash fast to low-forward (easing out), hold for a beat, then put away.
## The white trail follows the blade during the slash and fades after it.
func _swing() -> void:
	_sword_cooldown_timer = sword_cooldown
	Sound.play("sword", 0.08)
	_hit_this_swing.clear()
	if _swing_tween:
		_swing_tween.kill()
	sword_trail.cancel()
	sword_pivot.visible = true
	sword_pivot.rotation_degrees = -100.0
	_swing_tween = create_tween()
	_swing_tween.tween_property(sword_pivot, "rotation_degrees", -135.0, sword_windup_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_callback(func():
		_swing_timer = sword_swing_time  # the hitbox only hurts during the slash
		sword_trail.start())
	_swing_tween.tween_property(sword_pivot, "rotation_degrees", 80.0, sword_swing_time) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_swing_tween.tween_callback(sword_trail.stop)
	_swing_tween.tween_interval(0.08)
	_swing_tween.tween_callback(func(): sword_pivot.visible = false)


# ---------------- Animation ----------------

func _update_animation(dir: float) -> void:
	sprite.flip_h = facing < 0
	# Blink while invulnerable after a hit.
	var blinking := _invulnerable_timer > 0.0 and int(_invulnerable_timer * 12.0) % 2 == 0
	sprite.modulate.a = 0.35 if blinking else 1.0
	if _is_hit:
		return
	# Psalm's shrink (or grow: the same animation backwards) plays to the end first.
	if sprite.animation == "shrink" and sprite.is_playing():
		return
	var anim := "idle"
	if is_small:
		if not is_on_floor():
			anim = "small_jump" if velocity.y < 0.0 else "small_fall"
		elif absf(velocity.x) > 10.0:
			anim = "small_run"
		else:
			anim = "small_idle"
	elif _dash_timer > 0.0 and _has_animation("dash"):
		anim = "dash"  # Sarah
	elif not is_on_floor():
		if _is_wall_sliding(dir):
			anim = "wall_jump"  # Chelzy
		elif sprite.animation == "double_jump" and sprite.is_playing():
			anim = "double_jump"  # April
		else:
			anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 10.0:
		anim = "sprint" if is_sprinting and _has_animation("sprint") else "run"  # Kervin
	if sprite.animation != anim:
		sprite.play(anim)


func _has_animation(anim: StringName) -> bool:
	return sprite.sprite_frames.has_animation(anim)


## Call this when an enemy or trap hurts the player.
func take_hit(from_position: Vector2, damage := 20.0) -> void:
	if _is_hit or _invulnerable_timer > 0.0 or health <= 0.0:
		return
	health = maxf(health - damage, 0.0)
	health_changed.emit(health, max_health)
	DamageNumber.spawn(self, damage, DamageNumber.PLAYER_HIT)
	Sound.play("hurt", 0.05)
	_invulnerable_timer = invulnerable_time
	if health <= 0.0:
		died.emit()
		return
	velocity = Vector2(signf(global_position.x - from_position.x) * 160.0, -180.0)
	if is_small:
		return  # tiny Psalm has no hurt frames: he's knocked back and blinks
	_is_hit = true
	sprite.play("hit")
	await sprite.animation_finished
	_is_hit = false


func _on_swap_fx_animation_finished() -> void:
	swap_fx.visible = false
