class_name RuleRunner
extends Node
## One rule for some machines in a Room (Level 2, see docs/level2_design.md). Put it under the Room.
## The rule runs when it's set and again every time a value it checks changes - the way game code
## checks its ifs over and over. Machines (RuleMachine) and readings (ReadingSource) inside the
## Room are found by position. The machines keep following the rule after the player leaves.
##
## The player's rule replaces the current one when typed in the terminal (unless `locked`).
## A room can have several runners, e.g. a locked one for the captain's exit door and one for
## the player's rule; the terminal gives typed rules to the first runner that isn't locked.

signal ran(trace: Dictionary)
signal rule_changed

## The rule the room starts with, e.g. the captain's. It may be broken on purpose.
@export_multiline var start_rule := ""
## Only the start rule: the player can't replace it (Room 0's doors, the exit doors).
@export var locked := false
## What Byte says when the player types a rule here and every runner is locked.
@export var locked_message := ""
## Machine variables this rule may set, e.g. ["gateOpen"].
@export var machine_vars: Array[String] = []
## Readings the player can check here, e.g. ["tide"].
@export var reading_names: Array[String] = []
## Shown on the rule panel after "runs": "every time the tide changes".
@export var trigger_text := ""
## Show this rule on the HUD's rule panel.
@export var on_panel := true
## Exam: the first time the terminal opens here, the start rule goes in the input to be fixed.
@export var offer_start_rule := false

var room: Room
var rule := {}  ## The parsed rule ({} = none, or it can't run).
var source := ""  ## The rule's text as written.
var error := ""  ## Why the current rule can't run ("" = it can).
var last_trace := {}
var edited := false  ## The player has typed a rule here.
var offered := false  ## The start rule was put in the terminal's input already.

var _sources: Array[ReadingSource] = []
var _machines: Array[RuleMachine] = []
var _running := false


func _ready() -> void:
	add_to_group("rule_runner")
	room = get_parent() as Room
	_setup.call_deferred()


func _setup() -> void:
	for node in get_tree().get_nodes_in_group("reading_source"):
		if _in_my_room(node):
			_sources.append(node)
			node.reading_changed.connect(func(n, _v): _on_value_changed(n))
	for node in get_tree().get_nodes_in_group("rule_machine"):
		if _in_my_room(node) and _drives(node):
			_machines.append(node)
			node.runner = self
			node.failed.connect(_on_machine_failed)
	var terminal := _terminal()
	if terminal:
		terminal.variable_set.connect(func(n, _v): _on_value_changed(n))
	if room:
		room.fruit_changed.connect(func(_c, _t): _on_value_changed("coins"); _on_value_changed("coinsLeft"))
	if start_rule != "":
		set_rule_text(start_rule, true)


## Checks `text` as a rule and runs it. Returns Byte's error ("" if it runs).
## allow_bugs lets the captain's ; after if (...) through, the way Java does.
func set_rule_text(text: String, allow_bugs := false) -> String:
	var checker := CommandChecker.new(VariableLibrary.VARIABLES)
	var r := checker.check(text, {}, [], VariableLibrary.VARIABLES.keys(), allow_bugs)
	if r["ok"] and r["action"]["type"] == "rule":
		install(r["action"]["rule"], text)
		return ""
	rule = {}
	source = text
	error = r["error"]
	last_trace = {}
	rule_changed.emit()
	ran.emit(last_trace)
	return error


func install(new_rule: Dictionary, text: String) -> void:
	rule = new_rule
	source = text
	error = ""
	rule_changed.emit()
	run()


func run() -> void:
	if rule.is_empty() or _running:
		return
	for n in rule["reads"]:
		if lookup(n) == null:
			# Like Java, a rule can't use a variable that doesn't exist yet (e.g. key in Room 0).
			last_trace = {"waiting": n}
			ran.emit(last_trace)
			return
	_running = true
	var trace := Rules.evaluate(rule, lookup)
	last_trace = trace
	for s in trace["statements"]:
		_do(s)
	_running = false
	ran.emit(trace)


## A value the rule can check: readings first, then the room's coins, then the player's variables.
func lookup(var_name: String) -> Variant:
	for src in _sources:
		if src.has_reading(var_name):
			return src.get_reading(var_name)
	if room and var_name == "coins":
		return room.fruit_collected
	if room and var_name == "coinsLeft":
		return room.fruit_total - room.fruit_collected
	var terminal := _terminal()
	if terminal and terminal.typed.has(var_name):
		return terminal.typed[var_name]
	return null


## Byte's extra explanation of the last run, for a machine's failure message: an else if Java
## never reached that would have been true (wrong order), or no branch ran and there's no else.
func explain() -> String:
	if rule.is_empty() or not last_trace.has("conds"):
		return ""
	var conds: Array = last_trace["conds"]
	var branches: Array = rule["branches"]
	var ran: Array = last_trace["ran"]
	if ran.is_empty():
		if branches[-1]["cond"] != null:
			return "None of your conditions were true and there's no else, so nothing changed."
		return ""
	var first_true := -1
	for i in conds.size():
		if conds[i]["checked"] and conds[i]["result"] and conds[i]["text"] != "else":
			first_true = i
			break
	if first_true == -1:
		return ""
	for i in range(first_true + 1, branches.size()):
		var cond = branches[i]["cond"]
		if cond != null and Rules.eval_cond(cond, lookup)["result"]:
			return "Java checks from the top: %s was already true, so it never reached %s. Put the biggest number first." % [conds[first_true]["text"], cond["text"]]
	return ""


## Every name the rule panel or Byte can mention here: readings first, then machines.
func names_here() -> Array[String]:
	var out: Array[String] = []
	out.append_array(reading_names)
	out.append_array(machine_vars)
	return out


func machines() -> Array[RuleMachine]:
	return _machines


func _do(statement: Dictionary) -> void:
	var terminal := _terminal()
	match statement["type"]:
		"set":
			var var_name: String = statement["name"]
			var spec: Dictionary = VariableLibrary.VARIABLES.get(var_name, {})
			if VariableLibrary.kind_of(spec) == "machine":
				for m in _machines:
					if m.handles(var_name):
						m.apply(var_name, statement["value"])
			elif terminal:
				terminal.apply_from_rule(var_name, statement["value"])
		"print":
			var text: String = statement["text"]
			if statement.get("name", "") != "":
				var v = lookup(statement["name"])
				text = Rules.java_text(v) if not v is String else v
			if terminal:
				terminal.print_from_rule(text)


func _on_value_changed(var_name: String) -> void:
	if not rule.is_empty() and var_name in rule["reads"]:
		run()


func _on_machine_failed(text: String) -> void:
	var terminal := _terminal()
	if terminal == null:
		return
	if edited:
		terminal.report_wrong(text, room)
	elif terminal.current_room == room:
		# Still the captain's (broken) rule: Byte explains, but it's not the player's mistake.
		terminal.explain_failure("The captain's rule just failed: " + text)


## Machines this runner may set: its machine_vars (or, with none listed, every machine).
func _drives(machine: RuleMachine) -> bool:
	if machine_vars.is_empty():
		return true
	for v in machine.variables:
		if v in machine_vars:
			return true
	return false


func _in_my_room(node: Node) -> bool:
	if room == null:
		return true
	return room.contains((node as Node2D).global_position)


func _terminal() -> Node:
	return get_tree().get_first_node_in_group("code_terminal")
