extends CodeGadget
## One platform of path A, B or C, picked with the player's char: `char path = 'B';`
## makes every 'B' platform solid. The other paths stay as faint see-through outlines,
## so the player can see all three choices but only the chosen one can be stood on.
## Put several with the same letter in a row to make a path.

@export_enum("A", "B", "C") var letter: String = "A"
@export var show_letter := true  ## Draw the letter above this platform (put it on the first one).

const GHOST := Color(1, 1, 1, 0.25)

@onready var body: StaticBody2D = $Body
@onready var shape: CollisionShape2D = $Body/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var label: Label = $Letter


func _ready() -> void:
	if variable_name == "":
		variable_name = "path"
	super()
	label.text = letter
	label.visible = show_letter
	_set_solid(false)


func _on_value(value: Variant) -> void:
	_set_solid(str(value) == letter)


func _set_solid(solid: bool) -> void:
	shape.set_deferred("disabled", not solid)
	sprite.play("brown_on" if solid else "brown_off")
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color.WHITE if solid else GHOST, 0.25)
