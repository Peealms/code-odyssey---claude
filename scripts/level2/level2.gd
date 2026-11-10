extends Level
## Level 2 - Treasure Hunters: conditionals (docs/level2_design.md). Built by tools/build_level2.gd.
## On top of Level: coins instead of fruit, Byte's tips (the sword; which key opens the other
## captain's door in Room 0), and the boss fight: Byte hides while the captain fights (no
## terminal), and the treasure appears when he's beaten.

@onready var captain: Node = get_node_or_null("Captain")


func _ready() -> void:
	hud.item_word = "COINS"
	super()
	hud.set_fruits(0)
	var terminal := get_node("CodeTerminal")
	terminal.pending_hint = "Crabs live on this island! Remember Level 1? Give yourself a sword with a boolean called hasSword."
	end_goal.visible = false
	end_goal.set_deferred("monitoring", false)
	for m in get_tree().get_nodes_in_group("rule_machine"):
		if m.handles("leftDoorOpen") or m.handles("rightDoorOpen"):
			m.opened.connect(_on_captain_door_opened.bind(m))
	if captain:
		captain.started.connect(_on_boss_started)
		captain.stopped.connect(_on_boss_stopped)
		captain.defeated.connect(_on_boss_defeated)


## Room 0: after the first door opens, Byte points at the other one (it hides coins too), so
## players try a second key and see the else run.
func _on_captain_door_opened(door: Node) -> void:
	var left: Node = null
	var right: Node = null
	for m in get_tree().get_nodes_in_group("rule_machine"):
		if m.handles("leftDoorOpen"):
			left = m
		elif m.handles("rightDoorOpen"):
			right = m
	var terminal := get_node("CodeTerminal")
	if left and right and left.is_open and right.is_open:
		terminal.byte_says("Both doors are open now, and they stay open. Get every coin and the crates by the exit break.")
		if byte:
			byte.say("BOTH DOORS OPEN!", 2.5)
		return
	if door == right:
		terminal.byte_says("key is 7, so the if ran and the RIGHT door opened. Stand in it and press W. The else didn't run, but there are coins behind the LEFT door too! The else runs when key is anything but 7 - try key = 3;")
	else:
		terminal.byte_says("key isn't 7, so the else ran and the LEFT door opened. Stand in it and press W to grab its coins. The way on is the RIGHT door - the if opens it when key is 7. Try key = 7;")
	if byte:
		byte.say("PRESS W IN THE DOOR!", 3.0)


func _on_boss_started() -> void:
	Sound.music("final_exam")
	if byte:
		byte.visible = false
	get_node("CodeTerminal").locked_reason = "BYTE IS HIDING!"
	hud.show_message("CAPTAIN CLOWN NOSE!", 2.0)


func _on_boss_stopped() -> void:
	if byte:
		byte.visible = true
	get_node("CodeTerminal").locked_reason = ""


func _on_boss_defeated() -> void:
	_on_boss_stopped()
	hud.show_message("THE TREASURE IS YOURS!", 2.5)
	Sound.play("rescue")
	end_goal.visible = true
	end_goal.set_deferred("monitoring", true)
	if byte:
		byte.react(true)
		byte.say("WE DID IT!", 3.0)
