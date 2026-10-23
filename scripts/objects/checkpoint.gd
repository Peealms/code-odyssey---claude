extends Area2D
## Checkpoint flag. Touching it raises the flag and makes it the respawn point.
##
## A rescue flag (`unlock_hero` set) also has the hero waiting next to it, greyed out, with a
## fruit counter above. Touching the flag rescues them only once every fruit in `room` is
## collected; until then it's just a checkpoint and says how much fruit is left.
## The Level script listens to `reached`, `rescued` and `rescue_blocked`.

signal reached(checkpoint: Area2D)
signal rescued(checkpoint: Area2D)
signal rescue_blocked(checkpoint: Area2D)

const PLAYER := preload("res://scripts/player/player.gd")
const LOCKED_TINT := Color(0.55, 0.55, 0.65, 1)

## Hero rescued here.
@export_enum("none", "pink_man", "mask_dude", "virtual_guy") var unlock_hero: String = "none"
## The room whose fruit must all be collected before the rescue (empty = no fruit needed).
@export var room: Node

var activated := false
var is_rescued := false
var npc: AnimatedSprite2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var _counter: Label


func _ready() -> void:
	add_to_group("checkpoint")
	sprite.play("no_flag")
	body_entered.connect(_on_body_entered)
	if unlock_hero != "none":
		_add_waiting_hero()


## Where the player reappears (a little above the ground, next to the pole).
func respawn_position() -> Vector2:
	return global_position + Vector2(0, -16)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not activated:
		activated = true
		sprite.play("flag_out")
		Sound.play("checkpoint")
		reached.emit(self)
		sprite.animation_finished.connect(func(): sprite.play("flag_idle"), CONNECT_ONE_SHOT)
	if unlock_hero != "none" and not is_rescued and not Game.is_hero_unlocked(unlock_hero):
		if room == null or room.all_fruit_collected():
			is_rescued = true
			rescued.emit(self)
		else:
			rescue_blocked.emit(self)


func fruit_left() -> int:
	return 0 if room == null else room.fruit_total - room.fruit_collected


# ---------------- The waiting hero ----------------

func _add_waiting_hero() -> void:
	npc = AnimatedSprite2D.new()
	npc.name = "WaitingHero"
	npc.sprite_frames = load(PLAYER.HERO_DATA[unlock_hero]["frames"])
	npc.play("idle")
	npc.position = Vector2(26, -16)
	npc.modulate = LOCKED_TINT
	npc.flip_h = true  # faces the flag and the player coming toward it
	add_child(npc)
	_counter = Label.new()
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter.add_theme_color_override("font_shadow_color", Color(0.129, 0.122, 0.188))
	_counter.add_theme_constant_override("shadow_offset_x", 1)
	_counter.add_theme_constant_override("shadow_offset_y", 1)
	_counter.size = Vector2(90, 12)
	_counter.position = Vector2(26 - 45, -52)
	_counter.z_index = 5
	add_child(_counter)
	if room:
		room.fruit_changed.connect(_on_fruit_changed)
	_on_fruit_changed(0, 0)


func _on_fruit_changed(collected: int, total: int) -> void:
	if _counter == null:
		return
	var hero_name: String = PLAYER.HERO_DATA[unlock_hero]["name"].to_upper()
	if room == null or total == 0:
		_counter.text = hero_name
	elif collected >= total:
		_counter.text = "RESCUE %s!" % hero_name
		_counter.add_theme_color_override("font_color", Color("7cf07c"))
		npc.modulate = Color.WHITE
	else:
		_counter.text = "FRUIT %d/%d" % [collected, total]


## Called by the Level after the rescue cutscene: the waiting hero joins the player.
func hero_joined() -> void:
	if _counter:
		_counter.visible = false
	if npc:
		var fade := create_tween()
		fade.tween_property(npc, "modulate:a", 0.0, 0.4)
