extends Level
## Level 1 on Treasure Island: Level 1's variables lessons (String, int, double, boolean, char,
## changing a variable) in Treasure Hunters art, ending with Captain Clown Nose. The level id is
## still "level2" (it comes after the tutorial, "level1"). Built by tools/build_level2.gd;
## design in docs/level2_design.md.
## On top of Level: coins instead of fruit, Byte's tip about the sword, and the boss fight:
## Byte hides and the terminal locks while the captain fights (there's no time to type - the
## hero wheel switches heroes), and the treasure appears when he's beaten.

@onready var captain: Node = get_node_or_null("Captain")
@onready var terminal: CanvasLayer = $CodeTerminal


func _ready() -> void:
	hud.item_word = "COINS"
	super()
	hud.set_fruits(0)
	terminal.pending_hint = "Crabs live on this island! Jump over them, or give yourself a sword: boolean hasSword = true;"
	if captain:
		end_goal.visible = false
		end_goal.set_deferred("monitoring", false)
		captain.started.connect(_on_boss_started)
		captain.stopped.connect(_on_boss_stopped)
		captain.defeated.connect(_on_boss_defeated)


func _on_boss_started() -> void:
	if byte:
		byte.visible = false
	terminal.locked_reason = "NO TIME TO TYPE! HOLD Q TO SWITCH HEROES"
	hud.show_message("CAPTAIN CLOWN NOSE!", 2.0)


func _on_boss_stopped() -> void:
	if byte:
		byte.visible = true
	terminal.locked_reason = ""


func _on_boss_defeated() -> void:
	_on_boss_stopped()
	hud.show_message("THE TREASURE IS YOURS!", 2.5)
	Sound.play("rescue")
	end_goal.visible = true
	end_goal.set_deferred("monitoring", true)
	if byte:
		byte.react(true)
		byte.say("WE DID IT!", 3.0)
