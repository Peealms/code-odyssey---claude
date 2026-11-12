extends Level
## The tutorial: one Pixel Adventure room (Level 1's old Room 0) where Byte teaches how the game
## works. Built by tools/build_level1.gd. Byte talks (the game pauses, see ByteTalk):
##   1. at the start: moving, Sarah waiting at her flag, the gate and the chest
##   2. after the manual goes into the hotbar: how to hold it and read it
##   3. after the first read: the manual's example is how to open the gate
##   4. in the terminal: wrong lines, the hint and "Show answer" (in the terminal's log)
##   5. when the gate opens: the wall jump and freeing Sarah
##   6. after Sarah's rescue: the trophy

const SHAFT := Vector2(520, 200)  ## Middle of the wall-jump shaft (see the map in build_level1.gd).

var _told_hotbar := false
var _told_reading := false
var _gate_open := false

@onready var terminal: CanvasLayer = $CodeTerminal
@onready var chest: Area2D = $Chests.get_child(0)
@onready var chest_window: CanvasLayer = $ChestWindow
@onready var reader: CanvasLayer = $ManualReader


func _ready() -> void:
	super()
	chest.first_opened.connect(_on_chest_first_opened)
	player.inventory_changed.connect(_on_inventory_changed)
	reader.closed.connect(_on_reader_closed)
	terminal.wrong_try.connect(_on_wrong_try)
	terminal.variable_set.connect(_on_code_ran)
	_intro()


# ---------------- 1. The start ----------------

func _intro() -> void:
	await get_tree().create_timer(0.8).timeout  # let the level title show first
	var talk := await _talk()
	await talk.point_camera(player.global_position, 1.8)
	await talk.say("Wake up, Chelzy! I'm Byte, your robot helper.")
	await talk.say("Move with A and D, and jump with Space.")
	await talk.point_camera(_sarah_flag().npc.global_position)
	await talk.say("Our team is lost in this world. Sarah is waiting up there!")
	await talk.say("To free her, collect every fruit in this room, then touch her flag.")
	await talk.point_camera(_gate().global_position + Vector2(0, -24))
	await talk.say("My gate blocks the way. It only opens for code.")
	await talk.point_camera(chest.global_position + Vector2(0, -12))
	await talk.say("This chest holds a manual that shows you the code. Walk up to it and press F.")
	await talk.end()


# ---------------- 2 and 3. The manual ----------------

## The chest window opens right after this: say what to do in it.
func _on_chest_first_opened(_manual_id: String) -> void:
	await get_tree().process_frame
	chest_window.tip.text = "Click the book to put it in your hotbar"


## The manual is in the hotbar: once the chest window is closed, explain how to read it.
func _on_inventory_changed() -> void:
	var slot: int = player.inventory.find(ItemDB.manual_item(chest.manual_id))
	if _told_hotbar or slot == -1:
		return
	_told_hotbar = true
	if chest_window.visible:
		await chest_window.closed
	var talk := await _talk()
	await talk.say("You got the manual! It's in slot %d of your hotbar, at the bottom of the screen." % (slot + 1))
	await talk.say("Press %d to hold it, then left-click to read it. A and D turn the pages, and F or Esc closes the book." % (slot + 1))
	await talk.end()


func _on_reader_closed() -> void:
	if _told_reading:
		return
	_told_reading = true
	await get_tree().create_timer(0.2).timeout  # let the key that closed the book go first
	var talk := await _talk()
	await talk.say("That's how manuals work: they explain the code and show an example.")
	if _gate_open:
		await talk.say("You've already opened my gate! Read a manual again whenever you're stuck.")
	else:
		await talk.point_camera(_gate().global_position + Vector2(0, -24))
		await talk.say("The last page shows a println line. Open my terminal with E and print a message of your own.")
		await talk.say("Any message opens my gate. Type the line, then press Enter!")
	await talk.end()


# ---------------- 4. Wrong lines, the hint and "Show answer" ----------------

func _on_wrong_try(_room: Room, tries: int) -> void:
	if tries == 1:
		terminal.byte_says("Wrong lines are fine! Each OK or X is a step I checked. Fix the first X and try again.")
	elif tries == terminal.HINT_AT:
		terminal.byte_says("Still stuck? SHOW ANSWER at the top of my terminal types the line for you, but it costs a star at the end.")


# ---------------- 5. The gate opens ----------------

func _on_code_ran(var_name: String, _value: Variant) -> void:
	if var_name != "println" or _gate_open:
		return
	_gate_open = true
	if terminal.is_open:
		await terminal.closed
	await get_tree().create_timer(0.4).timeout
	var talk := await _talk()
	await talk.say("You did it! That was your first line of Java.")
	await talk.point_camera(SHAFT)
	await talk.say("Only a wall jump climbs this shaft: jump at a wall, then press Space again while you touch it.")
	await talk.say("Wall jumps use stamina. If the bar runs out, land and let it fill up again.")
	await talk.end()


# ---------------- 6. Sarah is free ----------------

func _on_hero_rescued(checkpoint: Area2D) -> void:
	await super(checkpoint)
	var talk := await _talk()
	await talk.say("Sarah is free! In the next level you'll switch to her with code.")
	await talk.point_camera(end_goal.global_position + Vector2(0, -24))
	await talk.say("Touch the trophy to finish the tutorial.")
	await talk.end()


# ---------------- Helpers ----------------

## Starts a Byte talk (waiting for any other one to finish first). The game is paused until
## the talk's end().
func _talk() -> ByteTalk:
	var other := get_tree().get_first_node_in_group("byte_talk")
	while other:
		await other.finished
		await get_tree().process_frame
		other = get_tree().get_first_node_in_group("byte_talk")
	var talk := ByteTalk.new()
	talk.auto_advance = 0.0  # tutorial lines wait for Enter, so nobody misses one
	add_child(talk)
	talk.begin(player)
	return talk


func _sarah_flag() -> Node:
	for flag in get_tree().get_nodes_in_group("checkpoint"):
		if flag.unlock_hero == "sarah":
			return flag
	return null


func _gate() -> Node2D:
	for n in $Gadgets.get_children():
		if n.get_script() and n.get_script().resource_path.ends_with("byte_gate.gd"):
			return n
	return null
