extends CanvasLayer
## The code terminal. Press E (or Tab) to open, type a line of Java, press Enter.
## Byte checks the line step by step (see CommandChecker), then reacts:
## correct code runs (e.g. swaps the hero), wrong code gets a friendly hint.
## Up / Down recall earlier lines. Esc closes.
##
## Each level picks its variables in "Allowed Variables" (names from VariableLibrary).
## Player variables (hero, speed, hasSword, jumpPower) are applied here; gadgets such as
## bridges and fans listen to `variable_set` instead.
##
## Inside a Room, wrong lines count up: 3 -> the room's hint + "Show answer" (costs a star),
## 5 -> the answer with blanks.

signal variable_set(name: String, value: Variant)

const STEP_DELAY := 0.18  ## Seconds between Byte's checklist lines.
const HINT_AT := 3  ## Wrong tries in a room before the hint and "Show answer".
const BLANKS_AT := 5  ## Wrong tries before Byte shows the answer with blanks.
const COLOR_CODE := "ffffff"
const COLOR_OK := "7cf07c"
const COLOR_BAD := "ff5c6c"
const COLOR_BYTE := "5ef2e0"
const COLOR_HINT := "8fa3bf"
const COLOR_ANSWER := "ffd34d"

@export var player: CharacterBody2D
@export var byte: Node2D
## Variables players can use in this level (names from VariableLibrary).
@export var allowed_variables: Array[String] = ["hero", "speed", "hasSword"]
## Only let the player switch to heroes they've rescued (off for the test room).
@export var require_unlocked_heroes := false
## Allow declaring the same variable twice (Java doesn't; leave off to teach `name = value;`).
@export var allow_redeclare := false

var is_open := false
## Levels can set this; Byte says it the next time the terminal opens.
var pending_hint := ""
## The Room the player is standing in (set by Room). Its hints and answer are used.
var current_room: Room = null:
	set(value):
		current_room = value
		_reset_answer_button()
## Every variable the player declared so far, and its value as Java would print it.
var values := {}

var _checker: CommandChecker
var _running := false
var _greeted := false
var _history: Array[String] = []
var _history_index := 0
var _base_run_speed := 0.0
var _player_input_before := true
var _confirming_answer := false

@onready var panel: PanelContainer = $Panel
@onready var portrait: AnimatedSprite2D = $Panel/HBox/Portrait/Sprite
@onready var log_label: RichTextLabel = $Panel/HBox/VBox/Log
@onready var input: LineEdit = $Panel/HBox/VBox/InputRow/Input
@onready var answer_button: Button = $Panel/HBox/VBox/HeaderRow/AnswerButton
@onready var open_hint: Label = $OpenHint


func _ready() -> void:
	add_to_group("code_terminal")
	panel.visible = false
	_checker = CommandChecker.new(VariableLibrary.pick(allowed_variables))
	_checker.allow_redeclare = allow_redeclare
	input.text_submitted.connect(_on_submitted)
	input.gui_input.connect(_on_input_gui_input)
	answer_button.pressed.connect(_on_answer_pressed)
	_reset_answer_button()
	if player:
		_base_run_speed = player.run_speed


func _process(_delta: float) -> void:
	# The panel can cover Byte in the level, so the portrait mirrors what Byte is doing.
	if is_open and byte:
		var anim: String = byte.sprite.animation
		if anim == "follow":
			anim = "idle"
		if portrait.animation != anim:
			portrait.play(anim)


func _input(event: InputEvent) -> void:
	# Runs before the LineEdit and the pause menu, so Esc closes the terminal instead of pausing.
	if is_open and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open and not get_tree().paused and event.is_action_pressed("open_terminal"):
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	is_open = true
	Sound.play("terminal_open")
	panel.visible = true
	open_hint.visible = false
	if player:
		_player_input_before = player.input_enabled
		player.input_enabled = false
	input.grab_focus()
	if not _greeted:
		_greeted = true
		_byte_line("Hi! I'm Byte. Type a line of Java and press Enter.")
		_hint_line("Variables you can use here: " + ", ".join(allowed_variables))
	if pending_hint != "":
		_byte_line(pending_hint)
		pending_hint = ""
	_reset_answer_button()


func close() -> void:
	is_open = false
	Sound.play("terminal_close")
	panel.visible = false
	open_hint.visible = true
	input.release_focus()
	if player:
		player.input_enabled = _player_input_before


# ---------------- Running a line ----------------

func _on_submitted(text: String) -> void:
	if _running or text.strip_edges() == "":
		return
	_running = true
	input.clear()
	_history.append(text)
	_history_index = _history.size()
	_append("[color=#%s]> %s[/color]" % [COLOR_CODE, _escape(text)])

	var unlocked: Array = Game.unlocked_heroes if require_unlocked_heroes else []
	var result := _checker.check(text, values, unlocked, values.keys())

	if byte:
		byte.talk(STEP_DELAY * result["steps"].size() + 0.1)
	for step in result["steps"]:
		await get_tree().create_timer(STEP_DELAY).timeout
		if step["ok"]:
			_append("   [color=#%s]OK[/color]  %s" % [COLOR_OK, _escape(step["label"])])
		else:
			_append("   [color=#%s]X [/color]  %s" % [COLOR_BAD, _escape(step["label"])])

	if result["ok"]:
		Sound.play("code_ok")
		_run_action(result["action"])
	else:
		Sound.play("code_error")
		_byte_line(result["error"])
		if byte:
			byte.react(false)
			byte.say("OOPS!", 1.5)
		if result.has("fix"):
			# Byte types the corrected line for the player (e.g. the type left out).
			input.text = result["fix"]
			input.caret_column = input.text.length()
		else:
			_count_wrong_try()
	_running = false


func _run_action(action: Dictionary) -> void:
	if action["type"] == "print":
		_byte_line("Printed: %s" % action["text"])
		if byte:
			byte.react(true)
			byte.say(action["text"] if action["text"] != "" else "...", 3.0)
		variable_set.emit("println", action["text"])
		return

	var name: String = action["name"]
	var value = action["value"]
	values[name] = _java_text(name, value)
	match name:
		"hero":
			player.set_hero(value)
		"speed":
			player.run_speed = _base_run_speed * value
		"hasSword":
			player.has_sword = value
		"jumpPower":
			player.jump_power = value

	if name == "hasSword" and value:
		var slot: int = player.inventory.find("sword") + 1
		_byte_line("Nice! The sword is in slot %d of your hotbar. Close me with Esc, hold it, then left-click to swing!" % slot)
	elif action["declare"]:
		_byte_line("Nice! You made %s and stored %s in it." % [name, values[name]])
	else:
		_byte_line("Nice! %s changed to %s." % [name, values[name]])
	if byte:
		byte.react(true)
		byte.say("NICE!", 1.5)
	variable_set.emit(name, value)


## The value the way the player wrote it, e.g. hero -> PinkMan (not pink_man).
func _java_text(name: String, value) -> String:
	if name == "hero":
		for h in CommandChecker.HERO_NAMES:
			if CommandChecker.HERO_NAMES[h] == value:
				return h
	return str(value)


# ---------------- Hints, "Show answer" and stars ----------------

## For gadgets: the line was valid Java, but the value doesn't solve the puzzle (e.g. a bridge
## that's too long). Byte explains, and it counts as a wrong try for the room's hints.
func report_wrong(text: String) -> void:
	Sound.play("code_error")
	_byte_line(text)
	if byte:
		byte.react(false)
		byte.say("OOPS!", 1.5)
	_count_wrong_try()


func _count_wrong_try() -> void:
	Game.mistakes += 1
	if current_room == null:
		return
	current_room.wrong_tries += 1
	var tries := current_room.wrong_tries
	if tries == HINT_AT and current_room.hint != "":
		_byte_line("Hint: " + current_room.hint)
	if tries == BLANKS_AT and current_room.blanks != "":
		_byte_line("Fill in the blanks:")
		_append("[color=#%s]      %s[/color]" % [COLOR_ANSWER, _escape(current_room.blanks)])
	_reset_answer_button()


func _reset_answer_button() -> void:
	if answer_button == null:
		return
	_confirming_answer = false
	var room := current_room
	answer_button.visible = room != null and room.answer != "" and room.wrong_tries >= HINT_AT
	if room and room.answer_shown:
		answer_button.text = "SHOW ANSWER"
	else:
		answer_button.text = "SHOW ANSWER: -1 STAR"


## First click asks to confirm (it costs a star), the second click shows the answer.
func _on_answer_pressed() -> void:
	var room := current_room
	if room == null:
		return
	if not room.answer_shown and not _confirming_answer:
		_confirming_answer = true
		answer_button.text = "SURE? CLICK AGAIN"
		await get_tree().create_timer(3.0).timeout
		if _confirming_answer:
			_reset_answer_button()
		return
	if not room.answer_shown:
		room.answer_shown = true
		Game.answers_shown += 1
	_byte_line("Here's the answer. Read it, then press Enter to try it:")
	_append("[color=#%s]      %s[/color]" % [COLOR_ANSWER, _escape(room.answer)])
	input.text = room.answer
	input.caret_column = input.text.length()
	input.grab_focus()
	_reset_answer_button()


# ---------------- Log + history ----------------

func _byte_line(text: String) -> void:
	_append("[color=#%s]BYTE: %s[/color]" % [COLOR_BYTE, _escape(text)])


func _hint_line(text: String) -> void:
	_append("[color=#%s]%s[/color]" % [COLOR_HINT, _escape(text)])


func _append(bbcode: String) -> void:
	log_label.append_text(bbcode + "\n")


func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


func _on_input_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or _history.is_empty():
		return
	if event.keycode == KEY_UP:
		_history_index = maxi(_history_index - 1, 0)
	elif event.keycode == KEY_DOWN:
		_history_index = mini(_history_index + 1, _history.size())
	else:
		return
	input.text = _history[_history_index] if _history_index < _history.size() else ""
	input.caret_column = input.text.length()
	input.accept_event()
