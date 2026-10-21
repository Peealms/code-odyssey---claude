class_name CommandChecker
extends RefCounted
## Checks one line of Java-style code, step by step, the way Byte explains it.
## It never runs real Java: it only understands the statements listed below.
##
##   <Type> <name> = <value>;      declare a new variable    String hero = "PinkMan";
##   <name> = <value>;             change one you declared   hero = "MaskDude";
##   System.out.println(<value>);  print text / a number / a variable
##
## check() returns:
##   ok      true if every step passed
##   steps   [{ "label": String, "ok": bool }]  (the checklist Byte shows)
##   error   friendly explanation of the first failed step ("" when ok)
##   action  what the game should do, e.g. { "type": "set", "name": "hero", "value": "pink_man", "declare": true }
##
## The variables it knows come from VariableLibrary (a level picks which ones).

const TYPES := ["String", "int", "double", "boolean", "char"]

## Hero names as typed in code -> hero ids used by the Player.
const HERO_NAMES := {
	"NinjaFrog": "ninja_frog",
	"PinkMan": "pink_man",
	"MaskDude": "mask_dude",
	"VirtualGuy": "virtual_guy",
}

const ID_REGEX := "^[A-Za-z_$][A-Za-z0-9_$]*$"

## Variables this level allows: name -> spec (see VariableLibrary).
var variables: Dictionary
## When true, declaring the same variable twice is allowed (Java itself says no).
var allow_redeclare := false

var _steps: Array = []


func _init(level_variables: Dictionary = VariableLibrary.VARIABLES) -> void:
	variables = level_variables


## values:   current value of each declared variable (for println)
## unlocked: hero ids the player may switch to, or [] for all
## declared: names the player has already declared in this level
func check(source: String, values := {}, unlocked: Array = [], declared: Array = []) -> Dictionary:
	_steps = []
	var line := source.strip_edges()
	if line == "":
		return _fail("Code", "Type a line of code first. Try: String hero = \"PinkMan\";")
	if line.to_lower().begins_with("system."):
		return _check_print(line, values)
	return _check_assignment(line, unlocked, declared)


# ---------------- String hero = "PinkMan";   /   hero = "MaskDude"; ----------------

func _check_assignment(line: String, unlocked: Array, declared: Array) -> Dictionary:
	if not line.ends_with(";"):
		return _fail("Semicolon", "Every Java statement ends with a semicolon. Add ; at the end.")
	_pass("Ends with ;")

	var body := line.trim_suffix(";").strip_edges()
	var eq := body.find("=")
	if eq == -1:
		return _fail("Assignment", "I need an = to store a value, like: String hero = \"PinkMan\";")
	var left := body.substr(0, eq).strip_edges()
	var value_text := body.substr(eq + 1).strip_edges()
	if value_text == "":
		return _fail("Value", "Put a value after the =, like \"PinkMan\".")

	var parts := left.split(" ", false)
	if parts.size() > 2:
		return _fail("Variable name", "Variable names can't have spaces. Try joining the words: myHero.")
	if parts.is_empty():
		return _fail("Variable name", "Put a variable name before the =.")

	var declaring := parts.size() == 2
	var name: String = parts[-1]
	var type := ""

	if declaring:
		# Step: type
		type = parts[0]
		if not type in TYPES:
			for t in TYPES:
				if t.to_lower() == type.to_lower():
					return _fail("Type", "Java is case-sensitive. Write %s, not %s." % [t, type])
			return _fail("Type", "'%s' isn't a type I know. Try String, int, double, boolean or char." % type)
		_pass("Type is " + type)

	# Step: variable name
	var name_error := _check_name(name)
	if name_error != "":
		return _fail("Variable name", name_error)
	var spec: Dictionary = variables[name]

	if declaring:
		if type != spec["type"]:
			return _fail("Type matches", "%s is %s, so it must be a %s, not %s." % [name, spec["about"], spec["type"], type])
		if name in declared and not allow_redeclare:
			return _fail("New variable", "%s already exists, so Java won't make it again. To change it, leave out the type: %s = %s;" % [name, name, value_text])
		_pass("Name is " + name)
	else:
		if not name in declared:
			return _fail("Declared", "Java doesn't know %s yet. Make it first with its type: %s %s = %s;" % [name, spec["type"], name, value_text])
		type = spec["type"]
		_pass("Changing " + name)

	# Step: value matches the type
	var parsed := _parse_value(type, value_text)
	if parsed.has("error"):
		return _fail("Value", parsed["error"])
	_pass("Value fits " + type)

	# Step: value makes sense for this variable
	var value = parsed["value"]
	if name == "hero":
		if not HERO_NAMES.has(value):
			var squashed: String = value.replace(" ", "").to_lower()
			for h in HERO_NAMES:
				if h.to_lower() == squashed:
					return _fail("Hero", "Close! Hero names are written exactly like this: \"%s\"." % h)
			return _fail("Hero", "There's no hero called \"%s\". Try: %s." % [value, ", ".join(HERO_NAMES.keys())])
		value = HERO_NAMES[value]
		if not unlocked.is_empty() and not value in unlocked:
			return _fail("Hero", "%s hasn't been rescued yet!" % parsed["value"])
		_pass("Hero found")
	elif spec.has("min") and (value < spec["min"] or value > spec["max"]):
		return _fail("Range", "%s must be between %s and %s." % [name, spec["min"], spec["max"]])
	elif spec.has("choices") and not str(value) in spec["choices"]:
		var shown: Array = spec["choices"].map(func(c): return "'%s'" % c if type == "char" else "\"%s\"" % c)
		return _fail("Choice", "%s can only be %s." % [name, " or ".join(shown)])
	elif spec.has("min") or spec.has("choices"):
		_pass("Value allowed")

	return _ok({"type": "set", "name": name, "value": value, "declare": declaring})


## "" if `name` is a variable this level knows, otherwise Byte's explanation.
func _check_name(name: String) -> String:
	if not _is_identifier(name):
		if name[0].is_valid_int():
			return "Variable names can't start with a number."
		return "Variable names can only use letters, numbers, _ and $."
	if variables.has(name):
		return ""
	if name in TYPES:
		return "%s is a type, not a name. Write the type and then a name, like: %s myValue = ...;" % [name, name]
	for v in variables:
		if v.to_lower() == name.to_lower():
			return "Names are case-sensitive. Did you mean %s?" % v
	return "I don't know a variable called '%s' here. Try: %s." % [name, ", ".join(variables.keys())]


func _parse_value(type: String, text: String) -> Dictionary:
	var quoted_double := text.length() >= 2 and text.begins_with("\"") and text.ends_with("\"")
	var quoted_single := text.length() >= 2 and text.begins_with("'") and text.ends_with("'")
	match type:
		"String":
			if quoted_double and text.count("\"") == 2:
				return {"value": text.substr(1, text.length() - 2)}
			if quoted_single:
				return {"error": "Single quotes are for char. Use double quotes for a String: \"%s\"." % text.substr(1, text.length() - 2)}
			if text.begins_with("\""):
				return {"error": "Close the text with another double quote \"."}
			if text.ends_with("\""):
				return {"error": "Open the text with a double quote \" too."}
			return {"error": "Text values need double quotes, like \"%s\"." % text}
		"int":
			if text.is_valid_int():
				return {"value": text.to_int()}
			if text.is_valid_float():
				return {"error": "%s has a decimal point. int only holds whole numbers - use double." % text}
			if quoted_double or quoted_single:
				return {"error": "Numbers don't use quotes. Write it without the quotes."}
			return {"error": "int needs a whole number, like 3."}
		"double":
			if text.is_valid_float():
				return {"value": text.to_float()}
			if quoted_double or quoted_single:
				return {"error": "Numbers don't use quotes. Write it without the quotes."}
			return {"error": "double needs a number, like 1.5."}
		"boolean":
			if text == "true" or text == "false":
				return {"value": text == "true"}
			if text.to_lower() == "true" or text.to_lower() == "false":
				return {"error": "Write true or false in lowercase."}
			if quoted_double or quoted_single:
				return {"error": "true and false don't use quotes. Write it without the quotes."}
			return {"error": "boolean can only be true or false."}
		"char":
			if quoted_single and text.length() == 3:
				return {"value": text[1]}
			if quoted_single:
				return {"error": "A char holds only ONE character, like 'B'."}
			if quoted_double:
				return {"error": "Double quotes are for String. A char uses single quotes, like 'A'."}
			return {"error": "A char is one character in single quotes, like 'A'."}
	return {"error": "I can't read that value."}


# ---------------- System.out.println(...); ----------------

func _check_print(line: String, values: Dictionary) -> Dictionary:
	if not line.begins_with("System."):
		return _fail("Spelling", "Java is case-sensitive. System starts with a capital S.")
	var method := ""
	for m in ["System.out.println", "System.out.print"]:
		if line.begins_with(m):
			method = m
			break
	if method == "":
		return _fail("Spelling", "To print, write System.out.println(...);")
	_pass("Spelled " + method)

	if not line.ends_with(";"):
		return _fail("Semicolon", "Every Java statement ends with a semicolon. Add ; at the end.")
	_pass("Ends with ;")

	var inside := line.trim_prefix(method).trim_suffix(";").strip_edges()
	if not (inside.begins_with("(") and inside.ends_with(")")):
		return _fail("Brackets", "Put what you want to print inside ( ), like println(\"Hi\");")
	_pass("Has ( )")

	var arg := inside.substr(1, inside.length() - 2).strip_edges()
	var text := ""
	if arg == "":
		text = ""
	elif arg.begins_with("\"") or arg.ends_with("\""):
		var parsed := _parse_value("String", arg)
		if parsed.has("error"):
			return _fail("Value", parsed["error"])
		text = parsed["value"]
	elif arg.is_valid_float():
		text = arg
	elif values.has(arg):
		text = str(values[arg])
	elif variables.has(arg):
		return _fail("Value", "%s hasn't been made yet. Declare it first: %s %s = ...;" % [arg, variables[arg]["type"], arg])
	elif _is_identifier(arg):
		return _fail("Value", "I don't know '%s'. Print text in quotes, a number, or a variable you made." % arg)
	else:
		return _fail("Value", "I can print text in quotes, numbers, or variables you made.")
	_pass("Value can print")
	return _ok({"type": "print", "text": text})


# ---------------- helpers ----------------

func _is_identifier(text: String) -> bool:
	var re := RegEx.create_from_string(ID_REGEX)
	return re.search(text) != null


func _pass(label: String) -> void:
	_steps.append({"label": label, "ok": true})


func _fail(label: String, error: String) -> Dictionary:
	_steps.append({"label": label, "ok": false})
	return {"ok": false, "steps": _steps, "error": error, "action": {}}


func _ok(action: Dictionary) -> Dictionary:
	return {"ok": true, "steps": _steps, "error": "", "action": action}
