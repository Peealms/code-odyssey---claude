extends ReadingSource
## The sleeping crew in the hold: gives the reading `awake`. They sleep `sleep_time` seconds,
## then wake for `awake_time`. If the room's lanterns (lanterns.gd) are lit while they're awake
## and the hero is in the room, they spot the hero: back to the last checkpoint, and the
## lanterns' rule failed. The crew are drawn at `spots` (offsets from this node).

const FIERCE := preload("res://assets/level2_treasure_hunters/enemies/fierce_tooth/fierce_tooth_frames.tres")
const STAR := preload("res://assets/level2_treasure_hunters/enemies/pink_star/pink_star_frames.tres")

@export var spots: Array[Vector2] = [Vector2.ZERO]
@export var sleep_time := 5.0
@export var awake_time := 3.0
@export var first_sleep := 4.0  ## The first nap is a bit shorter or longer to stagger rooms.

var _timer := 0.0
var _sprites: Array[AnimatedSprite2D] = []
var _labels: Array[Label] = []
var _lanterns: Node
var _room: Room
var _spotted := false


func _ready() -> void:
	super()
	for i in spots.size():
		var s := AnimatedSprite2D.new()
		s.sprite_frames = FIERCE if i % 2 == 0 else STAR
		s.position = spots[i] + Vector2(0, -14)
		add_child(s)
		_sprites.append(s)
		var l := Label.new()
		l.position = spots[i] + Vector2(-10, -44)
		l.size = Vector2(20, 12)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
		_labels.append(l)
	_timer = sleep_time - first_sleep
	_set_awake(false)
	_find.call_deferred()


func _find() -> void:
	for r in get_tree().get_nodes_in_group("room"):
		if r.contains(global_position):
			_room = r
	for m in get_tree().get_nodes_in_group("rule_machine"):
		if m.handles("lightsOn") and (_room == null or _room.contains(m.global_position)):
			_lanterns = m


func _process(delta: float) -> void:
	_timer += delta
	var awake: bool = get_reading("awake")
	if not awake and _timer >= sleep_time:
		_timer = 0.0
		_set_awake(true)
	elif awake and _timer >= awake_time:
		_timer = 0.0
		_set_awake(false)
	awake = get_reading("awake")
	for l in _labels:
		l.text = "!" if awake else ("z" if int(Time.get_ticks_msec() / 400) % 2 == 0 else "Z")
	if awake and not _spotted and _timer > 0.3 and _lanterns and _lanterns.lit and _player_here():
		_spot()


func _set_awake(awake: bool) -> void:
	_spotted = false
	set_reading("awake", awake)
	for s in _sprites:
		s.play("anticipation" if awake else "idle")
		s.speed_scale = 1.0 if awake else 0.3
	for l in _labels:
		l.add_theme_color_override("font_color", Color("ff5c6c") if awake else Color("d7e6ff"))


func _player_here() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return player != null and _room != null and _room.contains(player.global_position, -24.0)


func _spot() -> void:
	_spotted = true
	if Game.immune: return  # IMMUNITY: not spotted
	for s in _sprites:
		s.play("attack")
	Sound.play("blocked")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_message("SPOTTED!", 1.2)
	_lanterns.fail("The lanterns were lit while the crew was awake, so they spotted you! The lights must go off whenever awake is true.")
	var level := get_tree().current_scene
	if level.has_method("respawn"):
		level.respawn()
