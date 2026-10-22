class_name Level
extends Node2D
## Base script for every level (and the test room). It wires up what all levels share:
##   - camera limits from the "Terrain" TileMapLayer
##   - HUD: hero, health, stamina, fruits
##   - checkpoints: last flag touched = respawn point, and hero unlocks
##   - falling off the map / running out of HP -> back to the last checkpoint, full HP
##   - the EndGoal -> stars, then back to `next_scene`
## Expected child nodes: Terrain, Player, SpawnPoint, HUD, EndGoal, Byte (optional).
## Put Checkpoint scenes anywhere in the level; they're found through their group.

@export var level_id := "level"  ## Used for saving stars, e.g. "level1".
@export var level_title := ""  ## Shown when the level starts.
@export var level_number := 0  ## Shown on the level-complete screen (0 = use the title).
## Heroes the player has when this level starts (empty = keep whatever is unlocked).
## Level 1 starts with just Ninja Frog; the other heroes are rescued room by room.
@export var starting_heroes: Array[String] = []
@export var next_scene := "res://scenes/ui/main_menu.tscn"
@export var fall_limit_margin := 64.0  ## How far below the map the player can fall before respawning.
## Extra space the camera may show above the map (0 for framed rooms with a ceiling).
@export var camera_top_margin := 64.0

@onready var terrain: TileMapLayer = $Terrain
@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var hud: CanvasLayer = $HUD
@onready var end_goal: Area2D = $EndGoal
@onready var byte: Node2D = get_node_or_null("Byte")

const COMPLETE_SCREEN := preload("res://scenes/ui/level_complete.tscn")

var respawn_position := Vector2.ZERO
var _map_bottom := 0.0
var _finished := false
var _fruit_total := 0


func _ready() -> void:
	Game.start_level(level_id)
	if not starting_heroes.is_empty():
		Game.unlocked_heroes = starting_heroes.duplicate()
		if not Game.current_hero in starting_heroes:
			player.set_hero(starting_heroes[0], false)
	_setup_camera_limits()
	respawn_position = spawn_point.global_position
	player.global_position = respawn_position

	player.hero_changed.connect(_on_hero_changed)
	_on_hero_changed(player.hero_id)
	player.health_changed.connect(hud.set_health)
	player.stamina_changed.connect(hud.set_stamina)
	player.died.connect(_on_player_died)
	hud.set_health(player.health, player.max_health)
	hud.set_stamina(player.stamina, player.max_stamina, player.exhausted)

	_fruit_total = get_tree().get_nodes_in_group("fruit").size()
	for fruit in get_tree().get_nodes_in_group("fruit"):
		fruit.collected.connect(hud.add_fruit)
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		checkpoint.reached.connect(_on_checkpoint_reached)
	end_goal.reached.connect(_on_level_complete)
	if level_title != "":
		hud.show_message(level_title, 1.5)


func _physics_process(_delta: float) -> void:
	if not _finished and player.global_position.y > _map_bottom + fall_limit_margin:
		respawn()


func _setup_camera_limits() -> void:
	var used := terrain.get_used_rect()
	var tile := terrain.tile_set.tile_size
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = used.position.x * tile.x
	cam.limit_top = used.position.y * tile.y - int(camera_top_margin)
	cam.limit_right = used.end.x * tile.x
	cam.limit_bottom = used.end.y * tile.y
	_map_bottom = used.end.y * tile.y


## Back to the last checkpoint (or the start). Variables the player set stay set.
func respawn() -> void:
	player.velocity = Vector2.ZERO
	player.global_position = respawn_position
	player.get_node("Camera2D").reset_smoothing()


func _on_player_died() -> void:
	hud.show_message("OUCH! TRY AGAIN", 1.5)
	respawn()
	player.restore_vitals()


func _on_hero_changed(hero_id: String) -> void:
	hud.show_hero(hero_id, player.HERO_DATA[hero_id])


func _on_checkpoint_reached(checkpoint: Area2D) -> void:
	respawn_position = checkpoint.respawn_position()
	player.restore_vitals()
	var hero: String = checkpoint.unlock_hero
	if hero != "none" and not Game.is_hero_unlocked(hero):
		Game.unlock_hero(hero)
		var hero_name: String = player.HERO_DATA[hero]["name"]
		hud.show_message("%s JOINED!" % hero_name.to_upper(), 2.0)
		if byte:
			byte.react(true)
			byte.say("NEW HERO: %s!" % hero_name.to_upper(), 3.0)
	else:
		hud.show_message("CHECKPOINT", 1.0)


func _on_level_complete() -> void:
	_finished = true
	player.input_enabled = false
	var result := Game.finish_level()
	result["fruits"] = hud.fruits
	result["fruit_total"] = _fruit_total
	result["title"] = "LEVEL %d COMPLETE!" % level_number if level_number > 0 else "%s COMPLETE!" % level_title
	if byte:
		byte.react(true)
	await get_tree().create_timer(1.0).timeout
	var screen := COMPLETE_SCREEN.instantiate()
	add_child(screen)
	screen.show_results(result, scene_file_path, next_scene)
