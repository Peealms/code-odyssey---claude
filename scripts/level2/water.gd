extends Node2D
## Treasure Hunters water. The node's position is the left end of the surface; the water is
## `width` wide and reaches `depth` px below that. A hero whose middle goes under the surface
## is sent back to the last checkpoint ("SPLASH!").

const WATER_COLOR := Color(0.62, 0.79, 0.86, 0.9)
const SURFACE_COLOR := Color(0.86, 0.94, 0.96, 1.0)

@export var width := 320.0
@export var depth := 96.0

var _splash_cooldown := 0.0


func _ready() -> void:
	add_to_group("water")
	z_index = 5


## The surface's y in the world.
func surface_y() -> float:
	return global_position.y


func _physics_process(delta: float) -> void:
	queue_redraw()
	_splash_cooldown -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or _splash_cooldown > 0.0:
		return
	var p := player.global_position
	if p.x >= global_position.x and p.x <= global_position.x + width and p.y > surface_y() + 6.0 \
			and p.y < global_position.y + depth + 32.0:
		if Game.immune: return  # IMMUNITY: no drowning
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
	draw_rect(Rect2(0, 0, width, depth), WATER_COLOR)
	draw_rect(Rect2(0, 0, width, 2), SURFACE_COLOR)
	# A few moving glints on the surface.
	var t := Time.get_ticks_msec() / 1000.0
	var x := fmod(t * 14.0, 48.0)
	while x < width - 10:
		draw_rect(Rect2(x, 5, 10, 1), SURFACE_COLOR)
		x += 48.0
