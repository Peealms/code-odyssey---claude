extends Area2D
## A chest holding a manual book. Walk up to it and press F: the padlock pops,
## the lid opens, and a Minecraft-style chest window shows what's inside.
## Click the book to move it to the hotbar; hold it and left-click to read.
## Write manuals in scripts/manuals/manual_library.gd, then pick one here.

signal first_opened(manual_id: String)

## Which manual from ManualLibrary is inside. Add new ids here when you add manuals.
@export_enum("variables_101", "data_types", "numbers", "booleans_chars", "changing_variables") var manual_id: String = "variables_101"

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
		await sprite.animation_finished
		_opened = true
		first_opened.emit(manual_id)
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
