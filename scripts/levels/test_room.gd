extends Node2D
## Test room for trying movement and hero traits.
## Paint new tiles on the "Terrain" TileMapLayer - camera limits update automatically.

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

@export var fall_limit_margin := 64.0  ## How far below the map the player can fall before respawning.

@onready var terrain: TileMapLayer = $Terrain
@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var hud: CanvasLayer = $HUD
@onready var end_goal: Area2D = $EndGoal
@onready var byte: Node2D = $Byte
@onready var terminal: CanvasLayer = $CodeTerminal
@onready var crab_zone: Area2D = $CrabZone
@onready var crabby: CharacterBody2D = $Crabby

var _map_bottom := 0.0
var _crab_warned := false


func _ready() -> void:
	_setup_camera_limits()
	player.global_position = spawn_point.global_position
	player.hero_changed.connect(_on_hero_changed)
	_on_hero_changed(player.hero_id)
	player.health_changed.connect(hud.set_health)
	player.stamina_changed.connect(hud.set_stamina)
	player.died.connect(_on_player_died)
	hud.set_health(player.health, player.max_health)
	hud.set_stamina(player.stamina, player.max_stamina, player.exhausted)
	for fruit in get_tree().get_nodes_in_group("fruit"):
		fruit.collected.connect(hud.add_fruit)
	end_goal.reached.connect(_on_room_clear)
	crab_zone.body_entered.connect(_on_crab_zone_entered)
	crabby.defeated.connect(_on_crabby_defeated)
	hud.show_message("TEST ROOM", 1.5)


func _physics_process(_delta: float) -> void:
	if player.global_position.y > _map_bottom + fall_limit_margin:
		_respawn()


func _setup_camera_limits() -> void:
	var used := terrain.get_used_rect()
	var tile := terrain.tile_set.tile_size
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = used.position.x * tile.x
	cam.limit_top = used.position.y * tile.y - 64
	cam.limit_right = used.end.x * tile.x
	cam.limit_bottom = used.end.y * tile.y
	_map_bottom = used.end.y * tile.y


func _respawn() -> void:
	player.velocity = Vector2.ZERO
	player.global_position = spawn_point.global_position
	player.get_node("Camera2D").reset_smoothing()


func _on_player_died() -> void:
	hud.show_message("OUCH! TRY AGAIN", 1.5)
	_respawn()
	player.restore_vitals()


func _on_hero_changed(hero_id: String) -> void:
	hud.show_hero(hero_id, player.HERO_DATA[hero_id])


## Walking up to the tunnel: Byte offers help, and the terminal gets a hint (not the answer).
func _on_crab_zone_entered(body: Node2D) -> void:
	if _crab_warned or body != player or player.has_sword:
		return
	_crab_warned = true
	byte.say("NEED A SWORD? PRESS E!", 4.0)
	terminal.pending_hint = "That crab is tough! Give yourself a sword with a boolean variable called hasSword."


func _on_crabby_defeated() -> void:
	hud.show_message("TUNNEL CLEAR!", 1.5)
	byte.react(true)
	byte.say("NICE SWORDWORK!", 2.5)


func _on_room_clear() -> void:
	player.input_enabled = false
	hud.show_message("ROOM CLEAR!", 2.0)
	await get_tree().create_timer(2.5).timeout
	Game.change_scene(MAIN_MENU)
