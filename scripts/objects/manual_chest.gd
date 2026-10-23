extends Area2D
## A chest holding a manual book. Walk up to it and press F: the padlock pops,
## the lid opens, and a Minecraft-style chest window shows what's inside.
## Click the book to move it to the hotbar; hold it and left-click to read.
## Write manuals in scripts/manuals/manual_library.gd, then pick one here.

signal first_opened(manual_id: String)

const POTION := preload("res://scenes/objects/health_potion.tscn")

## Which manual from ManualLibrary is inside. Add new ids here when you add manuals.
@export_enum("variables_101", "data_types", "numbers", "booleans_chars", "changing_variables") var manual_id: String = "variables_101"
## Health potions that jump out the first time the chest is opened (touch one to heal 30 HP).
@export_range(0, 3) var potions := 1

## What's in the chest right now ("" = empty slot). Filled from manual_id at start.
var slots: Array[String] = ["", "", "", "", ""]

var _player_near := false
var _opened := false
var _busy := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt: Label = $Prompt


func _ready() -> void:
	slots[0] = ItemDB.manual_item(manual_id)
	sprite.play("idle")
	prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or _busy or get_tree().paused:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_open()


func _open() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and not player.input_enabled:
		return  # e.g. the code terminal is open
	_busy = true
	if not _opened:
		sprite.play("unlocked")
		Sound.play("chest_open")
		await sprite.animation_finished
		_opened = true
		first_opened.emit(manual_id)
		_throw_potions()
	var window := get_tree().get_first_node_in_group("chest_window")
	if window:
		window.open(self)
		await window.closed
	_busy = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		prompt.visible = false


## Potions hop out of the chest in an arc and land on the ground beside it.
func _throw_potions() -> void:
	for i in potions:
		var potion: Node2D = POTION.instantiate()
		get_parent().add_child(potion)
		var side := 1.0 if i % 2 == 0 else -1.0
		var land := global_position + Vector2(side * (34 + 14 * (i / 2)), 0)
		potion.global_position = global_position + Vector2(0, -10)
		var tween := potion.create_tween()
		tween.tween_property(potion, "global_position:x", land.x, 0.45)
		tween.parallel().tween_property(potion, "global_position:y", land.y - 30, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_property(potion, "global_position:y", land.y, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
