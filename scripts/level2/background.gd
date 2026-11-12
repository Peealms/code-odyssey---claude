extends CanvasLayer
## Level 1's sky: Treasure Hunters' sand-coloured sky, the sea on the horizon, and clouds that
## drift slowly. It stays put behind the level.

const SKY := preload("res://assets/level2_treasure_hunters/backgrounds/additional_sky.png")
const HORIZON := preload("res://assets/level2_treasure_hunters/backgrounds/bg_image.png")
const CLOUDS := preload("res://assets/level2_treasure_hunters/backgrounds/big_clouds.png")

var _clouds: TextureRect
var _offset := 0.0


func _ready() -> void:
	layer = -10
	var view := Vector2(640, 360)
	var sky := TextureRect.new()
	sky.texture = SKY
	sky.stretch_mode = TextureRect.STRETCH_TILE
	sky.size = view
	add_child(sky)
	var horizon := TextureRect.new()
	horizon.texture = HORIZON
	horizon.stretch_mode = TextureRect.STRETCH_TILE
	horizon.size = Vector2(view.x, HORIZON.get_height())
	horizon.position = Vector2(0, view.y - HORIZON.get_height())
	add_child(horizon)
	_clouds = TextureRect.new()
	_clouds.texture = CLOUDS
	_clouds.stretch_mode = TextureRect.STRETCH_TILE
	_clouds.size = Vector2(view.x + CLOUDS.get_width(), CLOUDS.get_height())
	_clouds.position = Vector2(0, view.y - HORIZON.get_height() - CLOUDS.get_height() + 24)
	add_child(_clouds)


func _process(delta: float) -> void:
	_offset = fposmod(_offset + delta * 6.0, CLOUDS.get_width())
	_clouds.position.x = -_offset
