extends CanvasLayer
## The code terminal. Press E (or Tab) to open, type a line of Java, press Enter.
## Byte checks the line step by step (see CommandChecker), then reacts:
## correct code runs (e.g. swaps the hero), wrong code gets a friendly hint.
## Up / Down recall earlier lines. Esc closes.

const STEP_DELAY := 0.18  ## Seconds between Byte's checklist lines.
const COLOR_CODE := "ffffff"
const COLOR_OK := "7cf07c"
const COLOR_BAD := "ff5c6c"
const COLOR_BYTE := "5ef2e0"
const COLOR_HINT := "8fa3bf"

@export var player: CharacterBody2D
@export var byte: Node2D
## Only let the player switch to heroes they've rescued (off for the test room).
@export var require_unlocked_heroes := false

var is_open := false
## Levels can set this; Byte says it the next time the terminal opens.
var pending_hint := ""

var _checker := CommandChecker.new()
var _running := false
var _greeted := false
var _history: Array[String] = []
var _history_index := 0
var _base_run_speed := 0.0
var _speed := 1.0
var _player_input_before := true

@onready var panel: PanelContainer = $Panel
@onready var portrait: AnimatedSprite2D = $Panel/HBox/Portrait/Sprite
@onready var log_label: RichTextLabel = $Panel/HBox/VBox/Log
@onready var input: LineEdit = $Panel/HBox/VBox/InputRow/Input
@onready var open_hint: Label = $OpenHint


func _ready() -> void:
	panel.visible = false
	input.text_submitted.connect(_on_submitted)
	input.gui_input.connect(_on_input_gui_input)
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
	panel.visible = true
	open_hint.visible = false
	if player:
		_player_input_before = player.input_enabled
		player.input_enabled = false
	input.grab_focus()
	if not _greeted:
		_greeted = true
		_byte_line("Hi! I'm Byte. Type a line of Java and press Enter.")
		_hint_line("Try:  String hero = \"PinkMan\";   double speed = 1.5;   System.out.println(\"Hi\");")
	if pending_hint != "":
		_byte_line(pending_hint)
		pending_hint = ""


func close() -> void:
	is_open = false
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
	var result := _checker.check(text, _current_values(), unlocked)

	if byte:
		byte.talk(STEP_DELAY * result["steps"].size() + 0.1)
	for step in result["steps"]:
		await get_tree().create_timer(STEP_DELAY).timeout
		if step["ok"]:
			_append("   [color=#%s]OK[/color]  %s" % [COLOR_OK, _escape(step["label"])])
		else:
			_append("   [color=#%s]X [/color]  %s" % [COLOR_BAD, _escape(step["label"])])

	if result["ok"]:
		_run_action(result["action"])
	else:
		_byte_line(result["error"])
		if byte:
			byte.react(false)
			byte.say("OOPS!", 1.5)
	_running = false


func _run_action(action: Dictionary) -> void:
	match action["type"]:
		"set":
			match action["name"]:
				"hero":
					player.set_hero(action["value"])
					_byte_line("Nice! hero is now %s." % player.HERO_DATA[action["value"]]["name"])
				"speed":
					_speed = action["value"]
					player.run_speed = _base_run_speed * _speed
					_byte_line("Nice! speed is now %s." % _speed)
				"hasSword":
					player.has_sword = action["value"]
					if action["value"]:
						var slot: int = player.inventory.find("sword") + 1
						if player.held_item() == "sword":
							_byte_line("Nice! The sword is in slot %d of your hotbar and you're holding it. Close me with Esc, then left-click to swing!" % slot)
						else:
							_byte_line("Nice! The sword is in slot %d of your hotbar. Close me with Esc, press %d (or scroll) to hold it, then left-click to swing!" % [slot, slot])
					else:
						_byte_line("Okay, sword put away.")
			if byte:
				byte.react(true)
				byte.say("NICE!", 1.5)
		"print":
			_byte_line("Printed: %s" % action["text"])
			if byte:
				byte.react(true)
				byte.say(action["text"] if action["text"] != "" else "...", 3.0)


## Current variable values, so println(hero) can print them.
func _current_values() -> Dictionary:
	var hero_name := ""
	if player:
		for h in CommandChecker.HERO_NAMES:
			if CommandChecker.HERO_NAMES[h] == player.hero_id:
				hero_name = h
	return {"hero": hero_name, "speed": _speed, "hasSword": player.has_sword if player else false}


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
