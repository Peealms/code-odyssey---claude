extends StaticBody2D
## A stack of crates blocking a doorway until every fruit in `room` is collected.
## A counter above it shows how much is left; when the last fruit is picked up the crates
## break apart and the way opens.
## The node's position is the bottom-middle of the doorway; `size` is the opening (px).

const FRAMES := preload("res://assets/level1_pixel_adventure/objects/boxes/box2/box2_frames.tres")
const PIECES := preload("res://assets/level1_pixel_adventure/objects/boxes/box2/break_pieces.png")
const APPLE := preload("res://assets/level1_pixel_adventure/collectibles/fruits/apple.png")

@export var room: Node  ## The Room whose fruit opens this door.
@export var size := Vector2(32, 48)

var is_open := false
var _crates: Array[AnimatedSprite2D] = []

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var counter: Label = $Counter


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2.0)
	# Crates stacked to fill the opening (28x24 each).
	var rows := ceili(size.y / 24.0)
	for i in rows:
		var crate := AnimatedSprite2D.new()
		crate.sprite_frames = FRAMES
		crate.play("idle")
		crate.position = Vector2(0, -12 - i * 24)
		add_child(crate)
		_crates.append(crate)
	counter.position = Vector2(-30, -size.y - 18)
	if room:
		room.fruit_changed.connect(_on_fruit_changed)


func _on_fruit_changed(collected: int, total: int) -> void:
	if is_open:
		return
	counter.text = "%d/%d" % [collected, total]
	if total > 0 and collected >= total:
		_open()


func _open() -> void:
	is_open = true
	Sound.play_at("crates_break", global_position)
	shape.set_deferred("disabled", true)
	counter.text = "OPEN!"
	counter.add_theme_color_override("font_color", Color("7cf07c"))
	for crate in _crates:
		crate.play("hit")
	await get_tree().create_timer(0.3, false).timeout
	for crate in _crates:
		_shatter(crate)
	var byte := get_tree().get_first_node_in_group("byte")
	if byte:
		byte.say("ALL FRUIT! DOOR OPEN!", 2.5)
	await get_tree().create_timer(1.5, false).timeout
	var fade := create_tween()
	fade.tween_property(counter, "modulate:a", 0.0, 0.5)


func _shatter(crate: AnimatedSprite2D) -> void:
	for i in 4:
		var piece := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = PIECES
		atlas.region = Rect2(i * 28, 0, 28, 24)
		piece.texture = atlas
		piece.position = crate.position
		add_child(piece)
		var dir := Vector2(-1.0 if i % 2 == 0 else 1.0, -1.0 if i < 2 else 0.3)
		var tween := piece.create_tween().set_parallel()
		tween.tween_property(piece, "position", piece.position + dir * randf_range(18, 30) + Vector2(0, 30), 0.6)
		tween.tween_property(piece, "rotation", dir.x * 3.0, 0.6)
		tween.tween_property(piece, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(piece.queue_free)
	crate.queue_free()
