extends CodeGadget
## A bridge that builds itself from the player's int: `int bridgeLength = 6;` pops in 6
## crate blocks, one by one, going right. Changing the number adds or removes blocks.
## The node's position is the top-left corner of the first block (line it up with the ground).

const TILE := preload("res://assets/level1_pixel_adventure/tiles/terrain_16x16.png")
const BLOCK_REGION := Rect2(192, 144, 16, 16)  ## The orange crate tile.
const SIZE := 16
const POP_TIME := 0.09  ## Seconds between blocks appearing.

@export var max_blocks := 12

var _blocks: Array[StaticBody2D] = []
var _target := 0
var _building := false


func _ready() -> void:
	if variable_name == "":
		variable_name = "bridgeLength"
	super()


func _on_value(value: Variant) -> void:
	_target = clampi(int(value), 0, max_blocks)
	if not _building:
		_build()


## Adds or removes one block at a time until the bridge matches the latest number.
func _build() -> void:
	_building = true
	while _blocks.size() != _target:
		if _blocks.size() < _target:
			_add_block(_blocks.size())
		else:
			_remove_block(_blocks.pop_back())
		await get_tree().create_timer(POP_TIME).timeout
	_building = false


func _add_block(index: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(index * SIZE + SIZE / 2.0, SIZE / 2.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SIZE, SIZE)
	shape.shape = rect
	body.add_child(shape)
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = TILE
	atlas.region = BLOCK_REGION
	sprite.texture = atlas
	body.add_child(sprite)
	add_child(body)
	_blocks.append(body)
	# pop in: drop from slightly above and grow
	sprite.position.y = -6
	sprite.scale = Vector2(0.4, 0.4)
	var tween := body.create_tween().set_parallel()
	tween.tween_property(sprite, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _remove_block(body: StaticBody2D) -> void:
	body.get_child(0).set_deferred("disabled", true)
	var tween := body.create_tween().set_parallel()
	tween.tween_property(body, "position:y", body.position.y + 24.0, 0.2)
	tween.tween_property(body, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(body.queue_free)
