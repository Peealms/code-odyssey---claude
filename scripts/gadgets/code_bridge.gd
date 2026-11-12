extends CodeGadget
## A bridge that builds itself from the player's int: `int bridgeLength = 6;` pops in 6
## planks, one by one, going right. Changing the number adds or removes blocks.
## If `gap_blocks` is set, the number must fit the gap exactly: too few leaves a hole, and too
## many jams against the far side so the whole bridge collapses (and Byte explains why).
## The node's position is the top-left corner of the first block (line it up with the ground).
## Each block is one Treasure Hunters plank.

const POP_TIME := 0.09  ## Seconds between blocks appearing.

@export var max_blocks := 12
@export var gap_blocks := 0  ## Width of the gap in blocks (0 = any length is fine).
@export var block_texture: Texture2D = preload("res://assets/level2_treasure_hunters/tiles/ship_platforms_32x32.png")
@export var block_region := Rect2(64, 65, 32, 10)  ## The part of block_texture one block shows.
@export var block_size := Vector2(32, 10)  ## One block's size (also its solid box).

var _blocks: Array[StaticBody2D] = []
var _target := 0
var _building := false
var _collapsing := false


func _ready() -> void:
	if variable_name == "":
		variable_name = "bridgeLength"
	super()


func _on_value(value: Variant) -> void:
	var wanted := clampi(int(value), 0, max_blocks)
	if gap_blocks > 0 and wanted > gap_blocks:
		_too_long(wanted)
		return
	_target = wanted
	if not _building:
		_build()


## Builds up to the far side, jams, then the whole bridge falls into the pit.
func _too_long(wanted: int) -> void:
	if _collapsing:
		return
	_collapsing = true
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal:
		terminal.report_wrong("Your Java is right, but %d blocks are too long - they don't fit in the gap and the bridge collapsed! Count the gap again." % wanted)
	_target = gap_blocks
	if not _building:
		await _build()
	else:
		while _building:
			await get_tree().process_frame
	Sound.play_at("bridge_collapse", global_position + Vector2(gap_blocks * block_size.x / 2.0, 0))
	# Jam: shake, then everything drops.
	for b in _blocks:
		var shake := b.create_tween()
		shake.tween_property(b, "position:x", b.position.x + 2, 0.05)
		shake.tween_property(b, "position:x", b.position.x - 2, 0.05)
		shake.tween_property(b, "position:x", b.position.x, 0.05)
	await get_tree().create_timer(0.3).timeout
	while not _blocks.is_empty():
		_remove_block(_blocks.pop_back())
	_target = 0
	_collapsing = false


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
	Sound.play_at("bridge_block", global_position + Vector2(index * block_size.x, 0), 0.0)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = Vector2(index * block_size.x, 0) + block_size / 2.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = block_size
	shape.shape = rect
	body.add_child(shape)
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = block_texture
	atlas.region = block_region
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
