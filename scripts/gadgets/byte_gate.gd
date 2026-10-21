extends CodeGadget
## Byte's gate: a column of blocks that breaks apart when the player prints something with
## System.out.println(...). Set `required_text` to need an exact message, or leave it empty
## so any printed text opens it. The node's position is the bottom-middle (put it on the ground).

const BLOCK := 22  ## Size of one block sprite.
const FRAMES := preload("res://assets/level1_pixel_adventure/traps/blocks/blocks_frames.tres")
const PART_1 := preload("res://assets/level1_pixel_adventure/traps/blocks/part_1.png")
const PART_2 := preload("res://assets/level1_pixel_adventure/traps/blocks/part_2.png")

@export_range(1, 8) var height := 3  ## Blocks stacked on top of each other.
@export var required_text := ""  ## Exact text to print, or empty for anything.

var is_open := false

@onready var body: StaticBody2D = $Body
@onready var shape: CollisionShape2D = $Body/CollisionShape2D


func _ready() -> void:
	variable_name = "println"
	super()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(BLOCK - 2, height * BLOCK)
	shape.shape = rect
	shape.position = Vector2(0, -height * BLOCK / 2.0)
	for i in height:
		var s := AnimatedSprite2D.new()
		s.sprite_frames = FRAMES
		s.play("idle")
		s.position = Vector2(0, -BLOCK / 2.0 - i * BLOCK)
		body.add_child(s)


func _on_value(value: Variant) -> void:
	if is_open:
		return
	if required_text != "" and str(value) != required_text:
		return
	_open()


func _open() -> void:
	is_open = true
	shape.set_deferred("disabled", true)
	var blocks := body.get_children().filter(func(c): return c is AnimatedSprite2D)
	for s in blocks:
		s.play("hitside")
	await get_tree().create_timer(0.25).timeout
	for s in blocks:
		_shatter(s)
	var byte := get_tree().get_first_node_in_group("byte")
	if byte:
		byte.say("GATE OPEN!", 2.0)


## Swap a block for its two halves, flying apart and fading.
func _shatter(block: AnimatedSprite2D) -> void:
	for i in 2:
		var part := Sprite2D.new()
		part.texture = PART_1 if i == 0 else PART_2
		part.position = block.position
		body.add_child(part)
		var dir := -1.0 if i == 0 else 1.0
		var tween := part.create_tween().set_parallel()
		tween.tween_property(part, "position:x", part.position.x + dir * randf_range(14, 26), 0.6)
		tween.tween_property(part, "position:y", part.position.y + 40.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(part, "rotation", dir * 2.5, 0.6)
		tween.tween_property(part, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(part.queue_free)
	block.queue_free()
