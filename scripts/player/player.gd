extends CharacterBody2D
## The playable hero. One scene handles all four heroes:
## switching hero swaps the sprite and turns that hero's special trait on.
## Every trait uses stamina; if stamina runs out the hero is "exhausted"
## and can't use the trait until the bar is full again.
##
##   Ninja Frog  -> Wall Jump   (gripping a wall drains stamina, each wall jump costs some)
##   Pink Man    -> Short Dash  (costs stamina)
##   Mask Dude   -> Double Jump (costs stamina)
##   Virtual Guy -> Sprint      (hold Shift, drains stamina)

signal hero_changed(hero_id: String)
signal inventory_changed
signal selected_slot_changed(slot: int)
signal health_changed(health: float, max_health: float)
signal stamina_changed(stamina: float, max_stamina: float, exhausted: bool)
signal died

const HERO_DATA := {
	"ninja_frog": {
		"name": "Ninja Frog",
		"frames": "res://assets/shared/heroes/ninja_frog/ninja_frog_frames.tres",
		"trait": "wall_jump",
	},
	"pink_man": {
		"name": "Pink Man",
		"frames": "res://assets/shared/heroes/pink_man/pink_man_frames.tres",
		"trait": "dash",
	},
	"mask_dude": {
		"name": "Mask Dude",
		"frames": "res://assets/shared/heroes/mask_dude/mask_dude_frames.tres",
		"trait": "double_jump",
	},
	"virtual_guy": {
		"name": "Virtual Guy",
		"frames": "res://assets/shared/heroes/virtual_guy/virtual_guy_frames.tres",
		"trait": "sprint",
	},
}

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

@export_group("Movement")
@export var run_speed := 130.0
@export var sprint_multiplier := 1.9  ## Virtual Guy holding Shift.
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
@export var dash_time := 0.16
@export var dash_cooldown := 0.5

@export_group("Sword")
@export var sword_damage := 10.0
@export var sword_windup_time := 0.06  ## Quick pull-back before the slash.
@export var sword_swing_time := 0.14
@export var sword_cooldown := 0.35
@export var sword_reach := 16.0  ## How far in front of the hero the sword hitbox sits.

@export_group("Debug")
## Lets you press 1-4 to switch heroes while testing. Turn off for the real game.
@export var debug_hero_keys := false

var hero_id := "ninja_frog"
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

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var swap_fx: AnimatedSprite2D = $SwapFx
@onready var sword_holder: Node2D = $SwordHolder
@onready var sword_pivot: Node2D = $SwordHolder/Pivot
@onready var sword_trail: Node2D = $SwordHolder/Trail
@onready var sword_hitbox: Area2D = $SwordHitbox


func _ready() -> void:
	sword_trail.pivot = sword_pivot
	set_hero(Game.current_hero, false)
	_refresh_held_item()
	restore_vitals()


func set_hero(new_hero: String, play_effect := true) -> void:
	if not HERO_DATA.has(new_hero):
		push_warning("Unknown hero: %s" % new_hero)
		return
	hero_id = new_hero
	sprite.sprite_frames = load(HERO_DATA[new_hero]["frames"])
	sprite.play("idle")
	Game.current_hero = new_hero
	if play_effect:
		swap_fx.visible = true
		swap_fx.play("appearing")
	hero_changed.emit(new_hero)


func has_trait(trait_name: String) -> bool:
	return HERO_DATA[hero_id]["trait"] == trait_name


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	var dir := Input.get_axis("move_left", "move_right") if input_enabled else 0.0

	if _dash_timer > 0.0:
		_process_dash(delta)
	else:
		_apply_gravity(delta, dir)
		_handle_jump()
		_handle_horizontal(dir, delta)
		_try_start_dash()

	move_and_slide()
	_update_animation(dir)
	_update_sword()


func _unhandled_input(event: InputEvent) -> void:
	if not debug_hero_keys:
		return
	for i in 4:
		if event.is_action_pressed("debug_hero_%d" % (i + 1)):
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
	elif has_trait("wall_jump") and is_on_wall_only() and can_use_stamina(wall_jump_stamina_cost):
		_spend_stamina(wall_jump_stamina_cost)
		var wall_dir := -signf(get_wall_normal().x)
		velocity.x = -wall_dir * wall_jump_push
		facing = int(-wall_dir)
		_wall_jump_lock = 0.18
		_do_jump()
	elif _air_jumps_left > 0 and can_use_stamina(double_jump_stamina_cost):
		_spend_stamina(double_jump_stamina_cost)
		_air_jumps_left -= 1
		_do_jump()
		sprite.play("double_jump")


func _do_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


func _handle_horizontal(dir: float, delta: float) -> void:
	if _wall_jump_lock > 0.0:
		return
	# Virtual Guy: hold Shift (the dash key) to sprint while stamina lasts.
	is_sprinting = has_trait("sprint") and input_enabled and dir != 0.0 \
		and Input.is_action_pressed("dash") and can_use_stamina(0.01)
	var speed := run_speed
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
		_dash_cooldown_timer = dash_cooldown
		velocity = Vector2(facing * dash_speed, 0.0)


func _process_dash(_delta: float) -> void:
	velocity = Vector2(facing * dash_speed, 0.0)
	if is_on_wall():
		_dash_timer = 0.0


func _is_wall_sliding(dir: float) -> bool:
	return has_trait("wall_jump") and is_on_wall_only() and velocity.y > 0.0 \
		and dir != 0.0 and signf(dir) == -signf(get_wall_normal().x) and can_use_stamina(0.01)


# ---------------- Health & stamina ----------------

## Full health and stamina (start of a level, or after respawning).
func restore_vitals() -> void:
	health = max_health
	stamina = max_stamina
	exhausted = false
	_invulnerable_timer = 0.0
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina, exhausted)


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
	if input_enabled and Input.is_action_just_pressed("attack") and _sword_cooldown_timer <= 0.0:
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
	sprite.speed_scale = 1.6 if is_sprinting else 1.0
	if _is_hit:
		return
	var anim := "idle"
	if not is_on_floor():
		if _is_wall_sliding(dir):
			anim = "wall_jump"
		elif sprite.animation == "double_jump" and sprite.is_playing():
			anim = "double_jump"
		else:
			anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 10.0:
		anim = "run"
	if sprite.animation != anim:
		sprite.play(anim)


## Call this when an enemy or trap hurts the player.
func take_hit(from_position: Vector2, damage := 20.0) -> void:
	if _is_hit or _invulnerable_timer > 0.0 or health <= 0.0:
		return
	health = maxf(health - damage, 0.0)
	health_changed.emit(health, max_health)
	DamageNumber.spawn(self, damage, DamageNumber.PLAYER_HIT)
	_invulnerable_timer = invulnerable_time
	if health <= 0.0:
		died.emit()
		return
	_is_hit = true
	velocity = Vector2(signf(global_position.x - from_position.x) * 160.0, -180.0)
	sprite.play("hit")
	await sprite.animation_finished
	_is_hit = false


func _on_swap_fx_animation_finished() -> void:
	swap_fx.visible = false
