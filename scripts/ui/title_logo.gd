extends Node2D
## The "{ CODE } ODYSSEY" title: one sprite per letter, cut from title_letters.png (made by
## tools/make_title_logo.gd), with Byte's teal code braces around CODE. The node's position is
## the top-centre of the logo. What makes it lively:
##   - the letters drop in one after another, bounce, and squash as they land
##   - then they ride a gentle wave over their own soft shadows, which stay on the ground
##   - every HOP_EVERY seconds a ripple of little hops runs along them, left to right
##   - every SHINE_EVERY seconds a band of light sweeps across (resources/shaders/title_shine.gdshader)
##   - sparkles twinkle on the letters
## Each letter's node sits at its bottom middle, so it squashes on its feet.

const LETTERS := preload("res://assets/shared/ui/menu/title_letters.png")
const SHINE := preload("res://resources/shaders/title_shine.gdshader")
const LETTER_W := 34  ## Keep in step with tools/make_title_logo.gd
const LETTER_H := 40
const STEP := 24.0  ## Horizontal distance between letters (a glyph is 21 wide).
const LINE_STEP := 32.0
const BRACE_GAP := 6.0  ## Extra room between a brace and CODE.
## The cells of each line in title_letters.png, left to right: C O D E = 0-3,
## O D Y S S E Y = 4-10, { = 11, } = 12.
const LINES := [[11, 0, 1, 2, 3, 12], [4, 5, 6, 7, 8, 9, 10]]
const BRACES := [11, 12]

const SHADOW_OFFSET := Vector2(2, 5)
const SHADOW_COLOR := Color(0.08, 0.05, 0.2, 0.28)
const HOP_EVERY := 7.0
const HOP_HEIGHT := 7.0
const SHINE_EVERY := 4.5
const SPARKLE_EVERY := 0.55  ## About how often a sparkle appears (seconds).
const SPARKLE_LIFE := 0.7
const SPARKLE_ARM := 4.0  ## Longest arm of a sparkle, in logo pixels.
const SPARKLE_CORE := Color("fff8e0")
const SPARKLE_ARMS := Color("ffe478")

## Every letter: {sprite, shadow, material, base (bottom middle), order, hop}.
var _letters: Array[Dictionary] = []
var _sparkle_layer: Node2D
var _sparkles: Array[Dictionary] = []  ## {pos, t}
var _time := 0.0
var _landed := false
var _next_hop := HOP_EVERY
var _next_shine := 1.0
var _next_sparkle := 0.3


func _ready() -> void:
	var shadows := Node2D.new()  # all shadows behind all letters
	add_child(shadows)
	var order := 0
	for line_i in LINES.size():
		for k in LINES[line_i].size():
			var cell: int = LINES[line_i][k]
			var base := _top_left(line_i, k) + Vector2(LETTER_W / 2.0, LETTER_H)
			var shadow := _sprite(cell)
			shadow.position = base + SHADOW_OFFSET
			shadow.modulate = Color(SHADOW_COLOR, 0.0)
			shadows.add_child(shadow)
			var sprite := _sprite(cell)
			var mat := ShaderMaterial.new()
			mat.shader = SHINE
			mat.set_shader_parameter("letter_pos", base)
			sprite.material = mat
			sprite.position = base + Vector2(0, -90)
			sprite.modulate.a = 0.0
			add_child(sprite)
			var letter := {"sprite": sprite, "shadow": shadow, "material": mat, "base": base, "order": order, "hop": 0.0}
			_letters.append(letter)
			_drop_in(letter, 0.07 * order)
			order += 1
	_sparkle_layer = Node2D.new()
	_sparkle_layer.draw.connect(_draw_sparkles)
	add_child(_sparkle_layer)
	get_tree().create_timer(0.07 * order + 0.75).timeout.connect(func(): _landed = true)


## The top-left of letter `k` of line `line_i`: the lines are centred, and the braces sit a
## little apart from CODE.
func _top_left(line_i: int, k: int) -> Vector2:
	var cells: Array = LINES[line_i]
	var letters := cells.filter(func(c): return not c in BRACES)
	var width := (letters.size() - 1) * STEP
	var first: float = -width * 0.5 - 15.5
	var y := line_i * LINE_STEP
	var cell: int = cells[k]
	if cell == BRACES[0]:
		return Vector2(first - STEP - BRACE_GAP, y)
	if cell == BRACES[1]:
		return Vector2(first + width + STEP + BRACE_GAP, y)
	return Vector2(first + letters.find(cell) * STEP, y)


func _sprite(cell: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = LETTERS
	s.region_enabled = true
	s.region_rect = Rect2(cell * LETTER_W, 0, LETTER_W, LETTER_H)
	s.centered = false
	s.offset = Vector2(-LETTER_W / 2.0, -LETTER_H)  # the node is the letter's bottom middle
	return s


## Drops a letter in from above with a bounce; it squashes and its shadow appears as it lands.
func _drop_in(letter: Dictionary, delay: float) -> void:
	var sprite: Sprite2D = letter["sprite"]
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(sprite, "modulate:a", 1.0, 0.05)
	tw.tween_property(sprite, "position", letter["base"], 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_squash(sprite, 1.0)
		var shadow: Sprite2D = letter["shadow"]
		shadow.create_tween().tween_property(shadow, "modulate:a", SHADOW_COLOR.a, 0.2))


## Squash and stretch on landing: wide and flat, a little tall, then back.
func _squash(sprite: Node2D, amount: float) -> void:
	var t := sprite.create_tween()
	t.tween_property(sprite, "scale", Vector2(1.0 + 0.18 * amount, 1.0 - 0.2 * amount), 0.06)
	t.tween_property(sprite, "scale", Vector2(1.0 - 0.06 * amount, 1.0 + 0.08 * amount), 0.08)
	t.tween_property(sprite, "scale", Vector2.ONE, 0.08)


func _process(delta: float) -> void:
	_time += delta
	if not _landed:
		return
	for letter in _letters:
		var wave := roundf(sin(_time * 3.0 + letter["order"] * 0.55) * 2.0)
		(letter["sprite"] as Sprite2D).position = letter["base"] + Vector2(0, wave + roundf(letter["hop"]))
	_next_hop -= delta
	if _next_hop <= 0.0:
		_next_hop = HOP_EVERY
		_hop_ripple()
	_next_shine -= delta
	if _next_shine <= 0.0:
		_next_shine = SHINE_EVERY
		_shine()
	_next_sparkle -= delta
	if _next_sparkle <= 0.0:
		_next_sparkle = SPARKLE_EVERY * randf_range(0.6, 1.4)
		_add_sparkle()
	for s in _sparkles:
		s["t"] += delta
	_sparkles = _sparkles.filter(func(s): return s["t"] < SPARKLE_LIFE)
	_sparkle_layer.queue_redraw()


## A ripple of hops along the letters, left to right across both lines.
func _hop_ripple() -> void:
	var by_x := _letters.duplicate()
	by_x.sort_custom(func(a, b): return a["base"].x < b["base"].x)
	for i in by_x.size():
		var letter: Dictionary = by_x[i]
		var t := create_tween()
		t.tween_interval(i * 0.045)
		t.tween_method(func(v): letter["hop"] = v, 0.0, -HOP_HEIGHT, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_method(func(v): letter["hop"] = v, -HOP_HEIGHT, 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(_squash.bind(letter["sprite"], 0.6))


## A band of light across the whole logo, left to right, then off.
func _shine() -> void:
	var t := create_tween()
	t.tween_method(_set_shine, -120.0, 150.0, 0.9)
	t.tween_callback(_set_shine.bind(-1000.0))


func _set_shine(at: float) -> void:
	for letter in _letters:
		(letter["material"] as ShaderMaterial).set_shader_parameter("shine", at)


## A sparkle on the top half of a random letter.
func _add_sparkle() -> void:
	var letter: Dictionary = _letters.pick_random()
	var at: Vector2 = letter["base"] + Vector2(randf_range(-9.0, 9.0), randf_range(-36.0, -22.0))
	_sparkles.append({"pos": at.round(), "t": 0.0})


## Each sparkle is a little plus that grows and shrinks: a bright middle, yellow arms.
func _draw_sparkles() -> void:
	for s in _sparkles:
		var arm := roundf(sin(s["t"] / SPARKLE_LIFE * PI) * SPARKLE_ARM)
		var p: Vector2 = s["pos"]
		for k in range(1, int(arm) + 1):
			var c := SPARKLE_CORE if k < arm else SPARKLE_ARMS
			for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				_sparkle_layer.draw_rect(Rect2(p + d * k, Vector2.ONE), c)
		_sparkle_layer.draw_rect(Rect2(p, Vector2.ONE), SPARKLE_CORE)
