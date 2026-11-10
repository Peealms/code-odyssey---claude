class_name HeroHead
extends Control
## A hero's head, cut out of their idle animation: the HUD portrait and the hero wheel's faces.
## Where the head sits in the frame is "head" in the Player's HERO_DATA. It's drawn at the
## biggest whole-number scale that fits the control (so the pixels stay crisp), centred.
## The idle animation plays in real time, so it doesn't slow down with the hero wheel's slow motion.

enum Look {
	NORMAL,
	DIM,  ## Grey and dark: a rescued hero who isn't on the hero wheel yet.
	SILHOUETTE,  ## One flat colour: a hero who hasn't been rescued yet.
}

const HERO_DATA: Dictionary = preload("res://scripts/player/player.gd").HERO_DATA
const SILHOUETTE_COLOR := Color(0.36, 0.33, 0.48)

const SHADER_CODE := """
shader_type canvas_item;
uniform int look = 0;
uniform vec4 flat_color : source_color = vec4(0.27, 0.25, 0.36, 1.0);
void fragment() {
	// COLOR already holds the texture's colour (times modulate).
	if (look == 1) {
		float grey = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
		COLOR.rgb = vec3(grey) * 0.55;
	} else if (look == 2) {
		COLOR.rgb = flat_color.rgb;
	}
}
"""

static var _shader: Shader

@export var hero_id := "chelzy":
	set(value):
		hero_id = value
		_load_hero()
@export var look := Look.NORMAL:
	set(value):
		look = value
		if _material:
			_material.set_shader_parameter("look", look)
		queue_redraw()
@export var animate := true

var _frames: SpriteFrames
var _head := Rect2()
var _frame := 0
var _material: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = _shader
	_material.set_shader_parameter("look", look)
	_material.set_shader_parameter("flat_color", SILHOUETTE_COLOR)
	material = _material
	_load_hero()


func _load_hero() -> void:
	var data: Dictionary = HERO_DATA.get(hero_id, {})
	if data.is_empty():
		_frames = null
	else:
		_frames = load(data["frames"])
		_head = data["head"]
	_frame = 0
	queue_redraw()


func _process(_delta: float) -> void:
	if not animate or _frames == null or not is_visible_in_tree():
		return
	var count := _frames.get_frame_count("idle")
	var speed := _frames.get_animation_speed("idle")
	var frame := int(Time.get_ticks_msec() / 1000.0 * speed) % maxi(count, 1)
	if frame != _frame:
		_frame = frame
		queue_redraw()


func _draw() -> void:
	if _frames == null:
		return
	var texture := _frames.get_frame_texture("idle", _frame if animate else 0)
	if texture == null:
		return
	var scale := maxf(1.0, floorf(minf(size.x / _head.size.x, size.y / _head.size.y)))
	var drawn := _head.size * scale
	draw_texture_rect_region(texture, Rect2(((size - drawn) / 2.0).floor(), drawn), _head)
