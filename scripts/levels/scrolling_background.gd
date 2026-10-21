extends TextureRect
## A tiled background that slowly scrolls forever.
## Put it inside a CanvasLayer with a negative layer so it stays behind the level.

@export var scroll_speed := Vector2(0, 12)  ## Pixels per second.

var _offset := Vector2.ZERO


func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_TILE
	var tile := texture.get_size()
	var view := get_viewport_rect().size
	size = view + tile * 2.0
	position = -tile


func _process(delta: float) -> void:
	var tile := texture.get_size()
	_offset = (_offset + scroll_speed * delta)
	_offset = Vector2(fposmod(_offset.x, tile.x), fposmod(_offset.y, tile.y))
	position = -tile + _offset
