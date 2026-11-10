extends Node2D
## Level 2 water. The node's position is the left end of the surface at its lowest; the water
## is `width` wide and reaches `depth` px below that. A hero whose middle goes under the surface
## is sent back to the last checkpoint ("SPLASH!").
##   fixed  the surface stays put
##   tide   the surface rises `rise` px per step of the room's tide
##   flood  like tide, but only while a gate in the room is open (gateOpen) and the tide is
##          at least `flood_from`; otherwise the water drains back down

const WATER_COLOR := Color(0.62, 0.79, 0.86, 0.9)
const SURFACE_COLOR := Color(0.86, 0.94, 0.96, 1.0)

@export_enum("fixed", "tide", "flood") var mode := "fixed"
@export var width := 320.0
@export var depth := 96.0
@export var rise := 16.0  ## Pixels the surface rises per tide step.
@export var flood_from := 3  ## flood: the tide that starts flooding (each step above adds `rise`).
@export var flood_speed := 40.0  ## Pixels per second the surface moves.

var level := 0.0  ## How high the surface is above its lowest point (px).
var _room: Room
var _tide: Node
var _gates: Array = []
var _splash_cooldown := 0.0


func _ready() -> void:
	add_to_group("water")
	z_index = 5
	_find_room.call_deferred()


func _find_room() -> void:
	for room in get_tree().get_nodes_in_group("room"):
		if room.contains(global_position + Vector2(width / 2.0, -2.0)):
			_room = room
	for src in get_tree().get_nodes_in_group("reading_source"):
		if src.has_reading("tide") and (_room == null or _room.contains(src.global_position)):
			_tide = src
	for m in get_tree().get_nodes_in_group("rule_machine"):
		if m.handles("gateOpen") and (_room == null or _room.contains(m.global_position)):
			_gates.append(m)


## The surface's y in the world.
func surface_y() -> float:
	return global_position.y - level


func _target() -> float:
	if mode == "fixed" or _tide == null:
		return 0.0
	var tide: int = _tide.get_reading("tide")
	if mode == "tide":
		return tide * rise
	var open := false
	for g in _gates:
		if g.is_open:
			open = true
	if open and tide >= flood_from:
		return (tide - flood_from + 1) * rise
	return 0.0


func _physics_process(delta: float) -> void:
	level = move_toward(level, _target(), flood_speed * delta)
	queue_redraw()
	_splash_cooldown -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or _splash_cooldown > 0.0:
		return
	var p := player.global_position
	if p.x >= global_position.x and p.x <= global_position.x + width and p.y > surface_y() + 6.0 \
			and p.y < global_position.y + depth + 32.0:
		_splash_cooldown = 1.0
		Sound.play("fall")
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message("SPLASH!", 1.0)
		var level_node := get_tree().current_scene
		if level_node.has_method("respawn"):
			level_node.respawn()
			player.restore_vitals()


func _draw() -> void:
	if level < 1.0 and depth <= 0.0:
		return  # a dry flood
	var top := -level
	draw_rect(Rect2(0, top, width, depth + level), WATER_COLOR)
	draw_rect(Rect2(0, top, width, 2), SURFACE_COLOR)
	# A few moving glints on the surface.
	var t := Time.get_ticks_msec() / 1000.0
	var x := fmod(t * 14.0, 48.0)
	while x < width - 10:
		draw_rect(Rect2(x, top + 5, 10, 1), SURFACE_COLOR)
		x += 48.0
