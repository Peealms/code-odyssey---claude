class_name Room
extends Area2D
## One puzzle area of a level. While the player is inside, Byte's terminal uses this room's
## hints. Set `size` to cover the room (the node's position is the centre).
##
## Wrong lines typed in this room count up:
##   3 wrong -> Byte gives `hint`, and "Show answer" appears (costs a star)
##   5 wrong -> Byte shows `blanks` (the answer with gaps)

@export var size := Vector2(320, 240)  ## Width and height of the room's area.
@export var title := ""  ## Shown when the player first walks in, e.g. "THE WIDE GAP". Empty = no message.
@export_multiline var hint := ""  ## Bigger hint after 3 wrong tries.
@export var blanks := ""  ## The answer with gaps after 5 wrong tries, e.g. int bridgeLength = __;
@export var answer := ""  ## The exact line "Show answer" reveals.

var wrong_tries := 0
var answer_shown := false  ## Only the first "Show answer" in a room costs a star.
var _entered := false


func _ready() -> void:
	add_to_group("room")
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal:
		terminal.current_room = self
	if not _entered and title != "":
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message(title, 1.5)
	_entered = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal and terminal.current_room == self:
		terminal.current_room = null
