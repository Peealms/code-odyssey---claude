extends Level
## Level 1 on Treasure Island: Level 1's variables lessons (String, int, double, boolean, char,
## changing a variable) in Treasure Hunters art, ending with Captain Clown Nose. The level id is
## still "level2" (it comes after the tutorial, "level1"). Built by tools/build_level2.gd;
## design in docs/level2_design.md.
## On top of Level: coins instead of fruit, Byte's tip about the sword, and the boss fight:
## Byte hides and the terminal locks while the captain fights (there's no time to type - the
## hero wheel switches heroes), and the treasure appears when he's beaten.
## The Variable Dictionary starts in the hotbar; each room fills in the pages of the variables
## it needs (Room.teaches). A new page shows a note naming the variable (PageNote) and a NEW tag
## on the dictionary's hotbar slot until it's read.

const DICTIONARY := "manual_dictionary"

@onready var captain: Node = get_node_or_null("Captain")
@onready var terminal: CanvasLayer = $CodeTerminal
@onready var reader: CanvasLayer = $ManualReader
@onready var hotbar: CanvasLayer = $Hotbar

var page_note: PageNote
var _new_pages: Array[String] = []


func _ready() -> void:
	hud.item_word = "COINS"
	page_note = PageNote.new()
	add_child(page_note)
	reader.page_unlocked.connect(_on_page_unlocked)
	reader.unread_changed.connect(_on_unread_changed)
	terminal.first_declaration.connect(_on_first_declaration)
	super()
	hud.set_fruits(0)
	player.add_item(DICTIONARY)
	terminal.pending_hint = "Crabs live on this island! Jump over them, or give yourself a sword: boolean hasSword = true; Stuck on a name? My Variable Dictionary in slot 1 explains every variable."
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


## The first variable is made (Room 0's hero, usually): once the terminal is closed, Byte
## stops the game to say a variable is made only once, before Room 1 asks to change it.
func _on_first_declaration(variable: String) -> void:
	if terminal.is_open:
		await terminal.closed
	await get_tree().create_timer(0.3).timeout
	var type: String = VariableLibrary.VARIABLES.get(variable, {}).get("type", "String")
	var talk := ByteTalk.new()
	talk.auto_advance = 0.0  # wait for Enter, so nobody misses it
	add_child(talk)
	talk.begin(player)
	await talk.say("You made %s! It exists now, so Java remembers its type." % variable)
	await talk.say("Java makes a variable only ONCE. To change it later, leave out the type: %s = ...;" % variable)
	await talk.say("Writing %s %s again would try to make a second one, and Java says it already exists." % [type, variable])
	await talk.end()


## A room made new variable names usable: the dictionary's slot gets its NEW tag at once, and
## once the room's title has gone the note slides in naming them.
func _on_page_unlocked(variable: String) -> void:
	_new_pages.append(variable)
	if _new_pages.size() > 1:
		return  # already waiting to show the note
	await get_tree().create_timer(1.7).timeout
	var slot: int = player.inventory.find(DICTIONARY) + 1
	page_note.show_pages(_new_pages.duplicate(), slot)
	_new_pages.clear()


## The NEW tag on the dictionary's hotbar slot stays until every new page has been seen.
func _on_unread_changed(count: int) -> void:
	hotbar.set_badge(DICTIONARY, count > 0)
