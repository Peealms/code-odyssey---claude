extends RuleMachine
## A wooden door driven by a rule (gateOpen, leftDoorOpen, rightDoorOpen...).
##   block   it fills an opening (`size`, bottom-middle at the node) and blocks it while shut:
##           sea gates, the boarding gate, the vault
##   portal  a door you walk into: while it's open, stand in front of it and press Up (W) to
##           come out at `target` (Room 0's two doors and the way back from the closet)
## A shutting door waits until the hero is out of the way.

signal opened  ## The door opened because of a rule (not a door that starts open).

const FRAMES := preload("res://assets/level2_treasure_hunters/objects/ship_decorations/door/door_frames.tres")
const ART := Vector2(41, 49)  ## One frame of the door art.

@export_enum("block", "portal") var kind := "block"
@export var size := Vector2(32, 64)
@export var start_open := false
@export var target := Vector2.ZERO  ## portal: where you come out (global position).

var is_open := false
var _sprite: AnimatedSprite2D
var _shape: CollisionShape2D
var _area: Area2D
var _closing_wait := false
var _hint: Label


func _ready() -> void:
	super()
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = FRAMES
	var s := size.y / ART.y
	_sprite.scale = Vector2(s, s)
	_sprite.position = Vector2(0, -size.y / 2.0)
	_sprite.animation = "opening"
	_sprite.frame = 0
	add_child(_sprite)
	if kind == "block":
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		_shape = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		_shape.shape = rect
		_shape.position = Vector2(0, -size.y / 2.0)
		body.add_child(_shape)
		add_child(body)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var a_shape := CollisionShape2D.new()
	var a_rect := RectangleShape2D.new()
	a_rect.size = size + Vector2(8, 0)
	a_shape.shape = a_rect
	a_shape.position = Vector2(0, -size.y / 2.0)
	_area.add_child(a_shape)
	add_child(_area)
	if kind == "portal":
		_hint = Label.new()
		_hint.text = "W: ENTER"
		_hint.position = Vector2(-24, -size.y - 14)
		_hint.size = Vector2(48, 12)
		_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hint.add_theme_font_size_override("font_size", 8)
		_hint.visible = false
		add_child(_hint)
	if start_open:
		_set_open(true, true)


func _on_set(_var_name: String, value: Variant) -> void:
	_set_open(value == true)


func _set_open(open: bool, instant := false) -> void:
	if open == is_open and not _closing_wait:
		return
	if open:
		_closing_wait = false
		is_open = true
		if _shape:
			_shape.set_deferred("disabled", true)
		if instant:
			_sprite.animation = "opening"
			_sprite.frame = _sprite.sprite_frames.get_frame_count("opening") - 1
		else:
			_sprite.play("opening")
			Sound.play_at("chest_open", global_position)
			opened.emit()
	else:
		if _player_inside():
			_closing_wait = true  # shut as soon as the hero is out of the doorway
			return
		_closing_wait = false
		is_open = false
		if _shape:
			_shape.set_deferred("disabled", false)
		_sprite.play("closing")


func _physics_process(_delta: float) -> void:
	if _closing_wait and not _player_inside():
		_set_open(false)
	if kind == "portal":
		var inside := _player_inside()
		_hint.visible = inside and is_open
		if inside and is_open and Input.is_action_just_pressed("move_up"):
			_go_through()


func _player_inside() -> bool:
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _go_through() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not player.input_enabled:
		return
	Sound.play("hero_swap")
	player.global_position = target
	player.velocity = Vector2.ZERO
	player.get_node("Camera2D").reset_smoothing()
