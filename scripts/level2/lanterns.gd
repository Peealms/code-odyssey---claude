extends RuleMachine
## The hold's lanterns: lightsOn. While the hero is in this room and the lanterns are out, the
## whole level goes dark except a glow around Byte (a CanvasModulate plus a light on Byte).
## Lantern sprites are drawn at `spots` (offsets from this node).

const CANDLE := preload("res://assets/level2_treasure_hunters/objects/ship_decorations/candle/candle_frames.tres")
const GLOW := preload("res://assets/level2_treasure_hunters/objects/ship_decorations/candle_light/candle_light_frames.tres")
const DARK := Color(0.1, 0.1, 0.18)

@export var spots: Array[Vector2] = [Vector2.ZERO]
@export var start_lit := true

var lit := true
var _glows: Array[AnimatedSprite2D] = []
var _room: Room
var _modulate: CanvasModulate
var _byte_light: PointLight2D


func _ready() -> void:
	super()
	variables = ["lightsOn"]
	for p in spots:
		var c := AnimatedSprite2D.new()
		c.sprite_frames = CANDLE
		c.play("idle")
		c.position = p
		add_child(c)
		var g := AnimatedSprite2D.new()
		g.sprite_frames = GLOW
		g.play("idle")
		g.position = p + Vector2(0, -4)
		add_child(g)
		_glows.append(g)
	lit = start_lit
	_setup.call_deferred()


func _setup() -> void:
	for r in get_tree().get_nodes_in_group("room"):
		if r.contains(global_position):
			_room = r
	_modulate = get_tree().get_first_node_in_group("darkness")
	if _modulate == null:
		_modulate = CanvasModulate.new()
		_modulate.add_to_group("darkness")
		_modulate.color = Color.WHITE
		get_tree().current_scene.add_child(_modulate)
	var byte := get_tree().get_first_node_in_group("byte") as Node2D
	if byte:
		_byte_light = byte.get_node_or_null("Glow")
		if _byte_light == null:
			_byte_light = PointLight2D.new()
			_byte_light.name = "Glow"
			_byte_light.texture = _glow_texture()
			_byte_light.energy = 0.0
			byte.add_child(_byte_light)


func _on_set(_var_name: String, value: Variant) -> void:
	lit = value == true
	for g in _glows:
		g.visible = lit


func _process(delta: float) -> void:
	if _modulate == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var here := player != null and _room != null and _room.contains(player.global_position, 8.0)
	var dark := here and not lit
	_modulate.color = _modulate.color.lerp(DARK if dark else Color.WHITE, minf(delta * 6.0, 1.0))
	if _byte_light:
		_byte_light.energy = move_toward(_byte_light.energy, 1.2 if dark else 0.0, delta * 4.0)


func _glow_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.95, 0.8, 1))
	g.set_color(1, Color(1, 0.95, 0.8, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 160
	t.height = 160
	return t
