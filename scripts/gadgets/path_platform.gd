extends CodeGadget
## One platform of path A, B or C, picked with the player's char: `char path = 'B';`
## makes every 'B' platform solid. The other paths stay as faint see-through outlines,
## so the player can see all three choices but only the chosen one can be stood on.
## Put several with the same letter in a row to make a path.
##
## Only the path on the room's sign is `safe`. A wrong path appears like the right one, but the
## moment the player lands on any of its planks, the whole path cracks and drops at once, so
## no dash or sprint gets across: SPLASH, back to the checkpoint, and Byte says why. The planks
## come back a moment later.

signal collapsed(letter: String)

@export_enum("A", "B", "C") var letter: String = "A"
@export var show_letter := true  ## Draw the letter above this platform (put it on the first one).
@export var safe := true  ## False for the paths the sign doesn't name.

const GHOST := Color(1, 1, 1, 0.25)
const CRACK_TIME := 0.15  ## The shake before a wrong path drops.
const RETURN_TIME := 2.5

var solid := false
var _falling := false

@onready var body: StaticBody2D = $Body
@onready var shape: CollisionShape2D = $Body/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var label: Label = $Letter


func _ready() -> void:
	if variable_name == "":
		variable_name = "path"
	super()
	add_to_group("path_platform")
	label.text = letter
	label.visible = show_letter
	_set_solid(false)


func _physics_process(_delta: float) -> void:
	if safe or not solid or _falling:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and player.is_on_floor() and _stands_on_me(player):
		_collapse_path()


## The player's feet are on this plank's top (the player's feet are 16 px below its origin).
func _stands_on_me(player: Node2D) -> bool:
	var feet := player.global_position + Vector2(0, 16)
	var top := global_position.y - 3.0
	return absf(feet.x - global_position.x) <= 22.0 and feet.y > top - 4.0 and feet.y < top + 4.0


## Every plank of this wrong path in this room drops at the same time.
func _collapse_path() -> void:
	for p in get_tree().get_nodes_in_group("path_platform"):
		if p.letter == letter and p._room == _room and not p.safe:
			p._drop()
	collapsed.emit(letter)
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal:
		terminal.wrong_path(letter)


func _drop() -> void:
	if _falling:
		return
	_falling = true
	var shake := create_tween()
	for i in 3:
		shake.tween_property(sprite, "position:x", 1.0 if i % 2 == 0 else -1.0, CRACK_TIME / 3.0)
	await shake.finished
	sprite.position.x = 0.0
	Sound.play_at("platform_crumble", global_position)
	shape.set_deferred("disabled", true)
	var home := body.position
	var tween := create_tween().set_parallel()
	tween.tween_property(body, "position:y", home.y + 160.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(body, "modulate:a", 0.0, 0.8)
	await get_tree().create_timer(RETURN_TIME).timeout
	body.position = home
	_falling = false
	_set_solid(solid)


func _on_value(value: Variant) -> void:
	_set_solid(str(value) == letter)


func _set_solid(on: bool) -> void:
	solid = on
	if _falling:
		return  # it comes back in the right state when it returns
	shape.set_deferred("disabled", not on)
	sprite.play("brown_on" if on else "brown_off")
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color.WHITE if on else GHOST, 0.25)
