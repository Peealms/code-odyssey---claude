extends CanvasLayer
## Full-screen background behind the level that slowly scrolls and crossfades to a new texture
## when the player walks into another room (Room calls show_background). No seams between rooms.

const SHADER := preload("res://resources/shaders/scroll_tile.gdshader")
const FADE_TIME := 0.6

@export var scroll_speed := Vector2(0.0, 0.25)  ## Tiles per second.

var _front: TextureRect
var _back: TextureRect
var _tween: Tween


func _ready() -> void:
	add_to_group("background_fader")
	layer = -10
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep fading/scrolling during cutscenes and pauses
	_back = _make_rect()
	_front = _make_rect()


func show_background(texture: Texture2D) -> void:
	if _front.texture == texture:
		return
	if _front.texture == null:
		_front.texture = texture  # first room: no fade
		return
	# Old picture goes to the back, new one fades in on top.
	_back.texture = _front.texture
	_back.modulate.a = 1.0
	_front.texture = texture
	_front.modulate.a = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_front, "modulate:a", 1.0, FADE_TIME)


func _make_rect() -> TextureRect:
	var r := TextureRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("speed", scroll_speed)
	r.material = mat
	add_child(r)
	return r
