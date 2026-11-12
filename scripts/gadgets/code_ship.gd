extends CodeGadget
## The team's little ship (Treasure Hunters' merchant ship), driven by the player's boolean:
##   boolean anchorUp = true;   the anchor comes up and the ship sails back and forth between
##                              its dock and the far dock, waiting a moment at each end, so you
##                              can ride it across (and back for a coin you missed)
##   anchorUp = false;          the anchor drops: the ship sails home to its dock and stays
## The node sits where the deck rests at its dock; `trip` is how far away the far dock is.
## The deck is a platform you can jump up through, and it carries you as it moves.

const FRAMES := preload("res://assets/level2_treasure_hunters/objects/merchant_ship/ship/ship_frames.tres")
const SPEED := 70.0  ## Pixels per second.

@export var trip := Vector2(288, 0)
@export var wait_time := 1.5  ## Seconds the ship waits at each dock while the anchor is up.

var anchor_up := false
var progress := 0.0  ## 0 at its dock, 1 at the far dock.
var _dir := 1.0
var _wait := 0.0
var _deck: AnimatableBody2D
var _sail: AnimatedSprite2D
var _anchor: AnimatedSprite2D


func _ready() -> void:
	if variable_name == "":
		variable_name = "anchorUp"
	super()
	_deck = AnimatableBody2D.new()
	_deck.sync_to_physics = true  # so a hero standing on it moves with it
	_deck.collision_layer = 1
	_deck.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(66, 8)
	shape.shape = rect
	shape.position = Vector2(0, 4)
	shape.one_way_collision = true
	_deck.add_child(shape)
	add_child(_deck)
	_sprite("ship_idle")
	_sail = _sprite("no_wind")
	_anchor = _sprite("anchor")


func _sprite(anim: String) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = FRAMES
	s.play(anim)
	s.position = Vector2(0, -2)
	_deck.add_child(s)
	return s


func _on_value(value: Variant) -> void:
	anchor_up = value == true
	_anchor.visible = not anchor_up
	_sail.play("wind" if anchor_up else "no_wind")
	if anchor_up:
		_wait = 0.0
		Sound.play_at("chest_open", _deck.global_position)


func _physics_process(delta: float) -> void:
	var step := SPEED * delta / trip.length()
	if anchor_up:
		if _wait > 0.0:
			_wait -= delta
		else:
			progress += _dir * step
			if progress >= 1.0 or progress <= 0.0:
				progress = clampf(progress, 0.0, 1.0)
				_dir = -_dir
				_wait = wait_time
	else:
		progress = move_toward(progress, 0.0, step)
		_dir = 1.0
	_deck.position = trip * progress
