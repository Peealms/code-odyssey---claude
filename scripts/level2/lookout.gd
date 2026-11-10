extends ReadingSource
## The lookout in the crow's nest: gives the reading `word`, a new shout every `step_time`
## seconds. If a gate in the room (gateOpen) is open when the word isn't `password`, the lookout
## raises the alarm: the room's alarm cannon (a shooter.gd with on_call) fires down the
## gangplank, and the gate's rule failed (Byte explains, a wrong try).

const FRAMES := preload("res://assets/level2_treasure_hunters/enemies/fierce_tooth/fierce_tooth_frames.tres")

@export var words: Array[String] = ["avast", "ahoy", "arrr", "yo-ho", "ahoy", "avast", "arrr", "ahoy"]
@export var step_time := 3.0
@export var password := "ahoy"

var _index := 0
var _timer := 0.0
var _bubble: Label
var _sprite: AnimatedSprite2D
var _gates: Array = []
var _cannons: Array = []
var _wrong_open := 0.0
var _cooldown := 0.0


func _ready() -> void:
	super()
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = FRAMES
	_sprite.play("idle")
	_sprite.position = Vector2(0, -15)
	add_child(_sprite)
	_bubble = Label.new()
	_bubble.position = Vector2(-40, -50)
	_bubble.size = Vector2(80, 14)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var box := StyleBoxFlat.new()
	box.bg_color = Color("fff5e3")
	box.border_color = Color("3d2429")
	box.set_border_width_all(1)
	box.set_content_margin_all(1)
	_bubble.add_theme_stylebox_override("normal", box)
	_bubble.add_theme_color_override("font_color", Color("3d2429"))
	add_child(_bubble)
	_shout(words[0])
	_find.call_deferred()


func _find() -> void:
	var room: Room = null
	for r in get_tree().get_nodes_in_group("room"):
		if r.contains(global_position):
			room = r
	for m in get_tree().get_nodes_in_group("rule_machine"):
		if m.handles("gateOpen") and (room == null or room.contains(m.global_position)):
			_gates.append(m)
	for s in get_tree().get_nodes_in_group("alarm_cannon"):
		if room == null or room.contains(s.global_position):
			_cannons.append(s)


func _process(delta: float) -> void:
	_timer += delta
	_cooldown -= delta
	if _timer >= step_time:
		_timer = 0.0
		_index = (_index + 1) % words.size()
		_shout(words[_index])
	var open_gate: Node = null
	for g in _gates:
		if g.is_open:
			open_gate = g
	var word: String = get_reading("word")
	if open_gate and word != password:
		_wrong_open += delta
		if _wrong_open > 0.35 and _cooldown <= 0.0:
			_alarm(open_gate, word)
	else:
		_wrong_open = 0.0


func _shout(word: String) -> void:
	set_reading("word", word)
	_bubble.text = "\"%s\"" % word.to_upper()


func _alarm(gate: Node, word: String) -> void:
	_cooldown = step_time
	_bubble.text = "INTRUDER!"
	_sprite.play("attack")
	_sprite.animation_finished.connect(func(): _sprite.play("idle"), CONNECT_ONE_SHOT)
	for c in _cannons:
		c.fire()
	gate.fail("The gate was open when the lookout shouted \"%s\" - the cannon fired! Only \"%s\" is safe, so the gate must be shut for every other word." % [word, password])
