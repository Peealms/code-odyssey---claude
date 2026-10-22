class_name Room
extends Area2D
## One puzzle area of a level. While the player is inside:
##   - Byte's terminal uses this room's hints
##   - the HUD shows this room's fruit (e.g. FRUIT 3/15)
##   - the background fades to this room's `background`
## Set `size` to cover the room (the node's position is the centre).
##
## Wrong lines typed in this room count up:
##   3 wrong -> Byte gives `hint`, and "Show answer" appears (costs a star)
##   5 wrong -> Byte shows `blanks` (the answer with gaps)
##
## Fruit inside the room is counted automatically. Rescue flags, fruit doors and the end goal
## can require all of it (see all_fruit_collected()).

signal fruit_changed(collected: int, total: int)

@export var size := Vector2(320, 240)  ## Width and height of the room's area.
@export var title := ""  ## Shown when the player first walks in, e.g. "THE WIDE GAP". Empty = no message.
@export_multiline var hint := ""  ## Bigger hint after 3 wrong tries.
@export var blanks := ""  ## The answer with gaps after 5 wrong tries, e.g. int bridgeLength = __;
@export var answer := ""  ## The exact line "Show answer" reveals.
@export var background: Texture2D  ## Fades in behind the level while the player is in this room.
## Rooms with the same zone (e.g. the sections of a big final room) count as one place for
## code gadgets: code typed anywhere in the zone reaches every gadget in it.
@export var zone := ""

var wrong_tries := 0
var answer_shown := false  ## Only the first "Show answer" in a room costs a star.
var fruit_total := 0
var fruit_collected := 0
var _entered := false


func _ready() -> void:
	add_to_group("room")
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_count_fruit.call_deferred()


## True if `point` is inside the room (or within `margin` px of it).
func contains(point: Vector2, margin := 0.0) -> bool:
	return Rect2(global_position - size / 2.0, size).grow(margin).has_point(point)


## True if `other` is this room or shares its zone.
func same_place(other: Room) -> bool:
	return other == self or (zone != "" and other.zone == zone)


## The title without its "EXAM 1:" style prefix, e.g. "THE LOW TUNNEL".
func short_title() -> String:
	return title.get_slice(":", 1).strip_edges() if ":" in title else title


func all_fruit_collected() -> bool:
	return fruit_collected >= fruit_total


func _count_fruit() -> void:
	for fruit in get_tree().get_nodes_in_group("fruit"):
		if contains(fruit.global_position):
			fruit_total += 1
			fruit.collected.connect(_on_fruit_collected)
	fruit_changed.emit(fruit_collected, fruit_total)


func _on_fruit_collected() -> void:
	fruit_collected += 1
	fruit_changed.emit(fruit_collected, fruit_total)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal:
		terminal.current_room = self
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.track_room(self)
		if not _entered and title != "":
			hud.show_message(title, 1.5)
	var fader := get_tree().get_first_node_in_group("background_fader")
	if fader and background:
		fader.show_background(background)
	_entered = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var terminal := get_tree().get_first_node_in_group("code_terminal")
	if terminal and terminal.current_room == self:
		terminal.current_room = null
