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
signal closed
## A wrong line counted in `room` (`tries` = that room's wrong tries so far). The tutorial
## listens to it to explain hints and "Show answer".
signal wrong_try(room: Room, tries: int)

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
## Variables that already exist when the level starts. Level 2 starts with "hero" (you're
## already playing as someone), so switching is hero = "...", from the start.
@export var start_declared: Array[String] = []

var is_open := false
## While not empty the terminal won't open and Byte says this instead (Level 2's boss fight).
var locked_reason := ""
## Levels can set this; Byte says it the next time the terminal opens.
var pending_hint := ""
## The Room the player is standing in (set by Room). Its hints and answer are used.
var current_room: Room = null:
	set(value):
		current_room = value
		_reset_answer_button()
## Every variable the player declared so far, and its value as Java would print it.
var values := {}
## The same variables with their real values (hero as "Sarah"), for Level 2 rules to check.
var typed := {}
var _rooms_greeted: Array[Node] = []

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
	_declare_start_variables.call_deferred()


func _declare_start_variables() -> void:
	for var_name in start_declared:
		if var_name == "hero" and player:
			values["hero"] = _java_text("hero", player.hero_id)
			typed["hero"] = values["hero"]


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
		get_viewport().set_input_as_handled()
		if locked_reason != "":
			var hud := get_tree().get_first_node_in_group("hud")
			if hud:
				hud.show_message(locked_reason, 1.5)
			return
		open()


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
	_greet_rule_room()
	_reset_answer_button()


## Level 2: the first time the terminal opens in a room with rules, Byte says what's here.
## In the exam, the captain's broken rule goes in the input, ready to fix.
func _greet_rule_room() -> void:
	var room := current_room
	if room == null or room in _rooms_greeted or room.rule_runners().is_empty():
		return
	_rooms_greeted.append(room)
	var runner := room.player_runner()
	if runner == null:
		return
	var parts: Array[String] = []
	if not runner.reading_names.is_empty():
		parts.append("check " + ", ".join(runner.reading_names.map(_with_type)))
	if not runner.machine_vars.is_empty():
		parts.append("set " + ", ".join(runner.machine_vars.map(_with_type)))
	if not parts.is_empty():
		_hint_line("Rules here can " + " and ".join(parts) + ".")
	if runner.offer_start_rule and not runner.edited and not runner.offered:
		runner.offered = true
		_byte_line("This is the captain's rule. Find the bug, fix it, then press Enter!")
		input.text = runner.start_rule
		input.caret_column = input.text.length()


func _with_type(var_name: String) -> String:
	var spec: Dictionary = VariableLibrary.VARIABLES.get(var_name, {})
	return "%s (%s)" % [var_name, spec.get("type", "?")]


func close() -> void:
	is_open = false
	Sound.play("terminal_close")
	panel.visible = false
	open_hint.visible = true
	input.release_focus()
	if player:
		player.input_enabled = _player_input_before
	closed.emit()


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
	if Game.immune: unlocked = []  # IMMUNITY: any hero, rescued or not
	var result := _checker.check(text, _values_with_readings(), unlocked, values.keys())
	if result["ok"] and result["action"]["type"] == "rule":
		var misfit := _rule_misfit(result["action"]["rule"])
		if not misfit.is_empty():
			result["ok"] = false
			result["steps"].append({"label": "Fits this room", "ok": false})
			result["error"] = misfit["error"]
			result["no_count"] = misfit.get("no_count", false)

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
			var blank: int = input.text.find("___")
			input.caret_column = blank if blank != -1 else input.text.length()
		elif not result.get("no_count", false):
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
	if action["type"] == "rule":
		_install_rule(action)
		return

	var name: String = action["name"]
	var value = action["value"]
	if name == "hero" and value != player.hero_id and not player.can_change_hero():
		# Valid Java, but Psalm is shrunk in a tunnel where a bigger hero wouldn't fit.
		Sound.play("blocked")
		_byte_line("No room! Psalm is squeezed under a low ceiling. Get out of the tunnel first, then switch.")
		if byte:
			byte.react(false)
			byte.say("NO ROOM!", 1.5)
		return
	_apply_value(name, value)
	var joined_wheel: bool = name == "hero" and Game.add_wheel_hero(value)

	if name == "hasSword" and value:
		var slot: int = player.inventory.find("sword") + 1
		_byte_line("Nice! The sword is in slot %d of your hotbar. Close me with Esc, hold it, then left-click to swing!" % slot)
	elif action["declare"]:
		_byte_line("Nice! You made %s and stored %s in it." % [name, values[name]])
	else:
		_byte_line("Nice! %s changed to %s." % [name, values[name]])
	if joined_wheel:
		_byte_line("%s is on your hero wheel now! Close me, then hold Q to switch heroes without typing." % values[name])
	if byte:
		byte.react(true)
		byte.say("NICE!", 1.5)
	variable_set.emit(name, value)


## Stores a player variable and makes it happen (switch hero, give the sword...).
func _apply_value(name: String, value: Variant) -> void:
	values[name] = _java_text(name, value)
	typed[name] = values[name] if name == "hero" else value
	match name:
		"hero":
			player.set_hero(value)
		"speed":
			player.run_speed = _base_run_speed * value
		"hasSword":
			player.has_sword = value
		"jumpPower":
			player.jump_power = value


# ---------------- Level 2 rules ----------------

## The current values plus this room's readings (so println(tide) prints the tide).
func _values_with_readings() -> Dictionary:
	var out := values.duplicate()
	if current_room:
		for runner in current_room.rule_runners():
			for n in runner.reading_names:
				var v = runner.lookup(n)
				if v != null:
					out[n] = Rules.java_text(v) if not v is String else v
	return out


## {} if the rule can be used in this room, otherwise { error, no_count }.
func _rule_misfit(rule: Dictionary) -> Dictionary:
	var room := current_room
	var runner: RuleRunner = room.player_runner() if room else null
	if runner == null:
		if room:
			for r in room.rule_runners():
				if r.locked_message != "":
					return {"error": r.locked_message, "no_count": true}
		return {"error": "Nothing here follows rules. Rules are for machines, like gates, anchors and sails.", "no_count": true}
	for n in rule["sets"]:
		var spec: Dictionary = VariableLibrary.VARIABLES.get(n, {})
		if VariableLibrary.kind_of(spec) == "machine" and not n in runner.machine_vars:
			return {"error": "There's no %s here. The machine here takes: %s." % [spec.get("noun", n), ", ".join(runner.machine_vars)]}
	for n in rule["reads"]:
		var spec: Dictionary = VariableLibrary.VARIABLES.get(n, {})
		if VariableLibrary.kind_of(spec) == "reading" and not n in runner.reading_names:
			return {"error": "You can't check %s here. Here you can check: %s." % [spec.get("noun", n), ", ".join(runner.reading_names)]}
	return {}


func _install_rule(action: Dictionary) -> void:
	var runner: RuleRunner = current_room.player_runner() if current_room else null
	if runner == null:
		_byte_line("You left the room before I could save that rule - go back and type it again.")
		return
	runner.edited = true
	runner.install(action["rule"], action["text"])
	var machine := "machine"
	for n in action["rule"]["sets"]:
		var spec: Dictionary = VariableLibrary.VARIABLES.get(n, {})
		if VariableLibrary.kind_of(spec) == "machine":
			machine = spec.get("noun", n)
			break
	var when := runner.trigger_text if runner.trigger_text != "" else "every time something it checks changes"
	_byte_line("Rule saved! The %s will follow it %s." % [machine, when])
	for note in action.get("notes", []):
		_byte_line(note)
	if byte:
		byte.react(true)
		byte.say("RULE SAVED!", 1.5)


## A rule changed one of the player's variables (e.g. the boss rule switching heroes).
func apply_from_rule(name: String, value: Variant) -> void:
	if name == "hero" and value != player.hero_id and not player.can_change_hero():
		return
	if name == "hero" and value == player.hero_id:
		return
	_apply_value(name, value)
	if name == "hero":
		Game.add_wheel_hero(value)  # the player typed hero = "..." inside the rule
	variable_set.emit(name, value)


## The hero wheel (hold Q) switches hero. If `hero` exists in the code it changes too, exactly
## like typing hero = "April"; (so rules that check hero run), and the line shows in the log.
## Returns false if Psalm is shrunk somewhere a bigger hero wouldn't fit.
func switch_from_wheel(hero_id: String) -> bool:
	if hero_id == player.hero_id:
		return true
	if not player.can_change_hero():
		return false
	if not values.has("hero"):
		return player.set_hero(hero_id)
	_apply_value("hero", hero_id)
	_append("[color=#%s]> hero = \"%s\";[/color]  [color=#%s](hero wheel)[/color]" % [COLOR_CODE, values["hero"], COLOR_HINT])
	variable_set.emit("hero", hero_id)
	return true


## What the player would type to switch to this hero: the type is left out once hero exists.
func hero_line(hero_id: String) -> String:
	var line := "hero = \"%s\";" % _java_text("hero", hero_id)
	return line if values.has("hero") else "String " + line


## System.out.println(...) inside a rule.
func print_from_rule(text: String) -> void:
	_byte_line("Printed: %s" % text)
	if byte:
		byte.say(text if text != "" else "...", 2.0)


## The value the way the player wrote it, e.g. hero -> Sarah (not sarah).
func _java_text(name: String, value) -> String:
	if name == "hero":
		for h in CommandChecker.HERO_NAMES:
			if CommandChecker.HERO_NAMES[h] == value:
				return h
	return str(value)


# ---------------- Hints, "Show answer" and stars ----------------

## For gadgets: the line was valid Java, but the value doesn't solve the puzzle (e.g. a bridge
## that's too long). Byte explains, and it counts as a wrong try for the room's hints.
## `room`: the room whose wrong tries count (default: the one the player is in). A Level 2
## machine can fail after the player has left its room.
func report_wrong(text: String, room: Room = null) -> void:
	Sound.play("code_error")
	_byte_line(text)
	if byte:
		byte.react(false)
		byte.say("OOPS!" if is_open else "OOPS! PRESS E", 2.5)
	_count_wrong_try(room)


## Byte tells the player something: in the log now if the terminal is open, otherwise the next
## time it opens.
func byte_says(text: String) -> void:
	if is_open:
		_byte_line(text)
	else:
		pending_hint = text


## A machine failed because of a rule the player didn't write (the captain's): Byte explains,
## but it doesn't count as a wrong try.
func explain_failure(text: String) -> void:
	Sound.play("code_error")
	_byte_line(text)
	if byte:
		byte.say("UH-OH! PRESS E" if not is_open else "UH-OH!", 2.0)


func _count_wrong_try(room: Room = null) -> void:
	Game.mistakes += 1
	if room == null:
		room = current_room
	if room == null:
		return
	room.wrong_tries += 1
	var tries := room.wrong_tries
	if tries == HINT_AT and room.hint != "":
		_byte_line("Hint: " + room.hint)
	if tries == BLANKS_AT and room.blanks != "":
		_byte_line("Fill in the blanks:")
		_append("[color=#%s]      %s[/color]" % [COLOR_ANSWER, _escape(room.blanks)])
	_reset_answer_button()
	wrong_try.emit(room, tries)


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
