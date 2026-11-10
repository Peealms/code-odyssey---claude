class_name RuleChecker
extends RefCounted
## Checks a Level 2 rule step by step, the way Byte explains it (see docs/level2_design.md):
##
##   if (<condition>) { <statements> } [else if (<condition>) { <statements> }]... [else { <statements> }]
##
## A condition is  name op value  (or value op name, or name op name), a boolean on its own
## (awake), or  name.equals("text").  op is one of == != < > <= >=.
## Statements are assignments (machines or the player's own variables) and System.out.println(...),
## checked with CommandChecker's Level 1 rules.
##
## On success the action is { "type": "rule", "rule": <rule>, "text": <the line>, "notes": [...] }:
##   rule      { "branches": [<branch>, ...], "reads": [names], "sets": [names] }
##   branch    { "cond": <cond, or null for else>, "body": [<statement>, ...], "detached": bool }
##             detached = a ; ended the if, so the block always runs (only with allow_bugs,
##             for the captain's broken rules)
##   cond      { "kind": "cmp", "left": <operand>, "op": ">=", "right": <operand>, "text": "tide >= 4" }
##             { "kind": "bool", "name": "awake", "text": "awake" }
##             { "kind": "equals", "name": "word", "value": "ahoy", "text": "word.equals(\"ahoy\")" }
##   operand   { "name": "tide", "type": "int", "text": "tide" } or { "value": 4, "lit": "num", "text": "4" }
##   statement CommandChecker's set / print action plus "text", e.g. "gateOpen = false;"

const OPS := ["==", "!=", "<", ">", "<=", ">="]
const TWO_CHAR_OPS := ["==", "!=", "<=", ">=", "=>", "=<", "=!", "&&", "||"]
const ONE_CHAR_OPS := ["=", "<", ">", "!", "&", "|"]
const PUNCT := ["(", ")", "{", "}", ";", ".", ","]
const LEVEL_3 := "&& and || are coming in Level 3! Here, one condition per if - use else if to check another one."

var c: CommandChecker  # only set while check() runs (no reference cycle)
var _source := ""
var _toks: Array = []
var _values := {}
var _unlocked: Array = []
var _declared: Array = []
var _allow_bugs := false
var _notes: Array[String] = []
var _cond_start := 0  # where the condition being checked starts / ends in the source
var _cond_end := 0


## True if the line is meant to be a rule (starts with if / else, in any case).
static func is_rule(line: String) -> bool:
	var m := RegEx.create_from_string("^\\s*([A-Za-z]+)").search(line)
	return m != null and m.get_string(1).to_lower() in ["if", "else", "elseif", "elsif", "elif"]


func check(checker: CommandChecker, line: String, values: Dictionary, unlocked: Array, declared: Array, allow_bugs := false) -> Dictionary:
	c = checker
	_source = line
	_values = values
	_unlocked = unlocked
	_declared = declared
	_allow_bugs = allow_bugs
	_notes = []
	var result := _check()
	c = null
	return result


func _check() -> Dictionary:
	var tokens = _tokenize(_source)
	if tokens is String:
		if tokens == "str":
			return c._fail("Text", "Close the text with another double quote \".")
		return c._fail("Char", "Close the char with another single quote '.")
	_toks = tokens

	var first: String = _toks[0]["v"]
	if first.to_lower() in ["else", "elseif", "elsif", "elif"]:
		return c._fail("Starts with if", "else can't come first - it needs an if before it. Start with: if (...) { ... }")
	if first != "if":
		return c._fail("Starts with if", "Java is case-sensitive: write if in lowercase.")
	c._pass("Starts with if")

	var branches := []
	var i := 0  # always points at an "if" at the top of the loop
	while true:
		var cond := _condition(i + 1)
		if cond.has("fail"):
			return cond["fail"]
		i = cond["next"]
		var detached := false
		if i < _toks.size() and _toks[i]["t"] == ";":
			if not _allow_bugs:
				return c._fail("No ; after )", "Remove the ; after if (...) - it ends the if right there, so the code in { } would always run.")
			detached = true
			i += 1
		var block := _block(i, "if")
		if block.has("fail"):
			return block["fail"]
		branches.append({"cond": cond["cond"], "body": block["body"], "detached": detached})
		i = block["next"]

		if _ends_at(i):
			break
		var t: Dictionary = _toks[i]
		var word: String = t["v"] if t["t"] == "word" else ""
		if word.to_lower() in ["elseif", "elsif", "elif"]:
			return c._fail("else if", "else if is two words: else if (...) { ... }")
		if word != "else":
			if word.to_lower() == "else":
				return c._fail("else", "Java is case-sensitive: write else in lowercase.")
			return c._fail("After }", "I didn't expect %s after the }. A rule is if (...) { ... }, then optional else if (...) { ... } and else { ... } parts." % t["v"])
		if detached:
			return c._fail("else", "This else has no if: the ; after if (...) already ended the if.")
		if i + 1 >= _toks.size():
			return c._fail("else", "Put the code for else inside { }, like: else { gateOpen = true; }")
		var nt: Dictionary = _toks[i + 1]
		if nt["t"] == "word" and nt["v"].to_lower() == "if":
			if nt["v"] != "if":
				return c._fail("else if", "Java is case-sensitive: write else if in lowercase.")
			i += 1
			continue
		if nt["t"] == "(":
			return c._fail("else", "else has no condition. To check another one, use else if (...) { ... }")
		if nt["t"] == ";":
			return c._fail("else", "Remove the ; after else - put the code for else inside { }.")
		var last := _block(i + 1, "else")
		if last.has("fail"):
			return last["fail"]
		branches.append({"cond": null, "body": last["body"], "detached": false})
		i = last["next"]
		if not _ends_at(i):
			if _toks[i]["v"] == "else":
				return c._fail("else", "else is always the last part of a rule - nothing comes after it.")
			return c._fail("After }", "The rule ends at the else's } - take out what comes after it.")
		break

	var reads := []
	var sets := []
	for b in branches:
		if b["cond"] != null:
			for n in _cond_names(b["cond"]):
				if not n in reads:
					reads.append(n)
		for s in b["body"]:
			if s["type"] == "set" and not s["name"] in sets:
				sets.append(s["name"])
	var rule := {"branches": branches, "reads": reads, "sets": sets}
	return c._ok({"type": "rule", "rule": rule, "text": _source, "notes": _notes})


# ---------------- if ( ... ) ----------------

## The condition in brackets starting at token i. Returns { cond, next } or { fail }.
func _condition(i: int) -> Dictionary:
	if i >= _toks.size() or _toks[i]["t"] != "(":
		return {"fail": c._fail("Brackets", "Put the condition in brackets: if (tide > 3)")}
	var close := _match(i, "(", ")")
	if close == -1:
		return {"fail": c._fail("Brackets", "Close the condition with ).")}
	if close == i + 1:
		return {"fail": c._fail("Condition", "Put a condition inside the brackets, like: if (tide > 3)")}
	_cond_start = _toks[i + 1]["s"]
	_cond_end = _toks[close - 1]["e"]
	var parsed := _parse_condition(_toks.slice(i + 1, close))
	if parsed.has("fail"):
		return parsed
	c._pass("Condition: " + parsed["cond"]["text"])
	return {"cond": parsed["cond"], "next": close + 1}


func _parse_condition(ts: Array) -> Dictionary:
	for t in ts:
		if t["t"] == "op" and t["v"] in ["&&", "||", "&", "|"]:
			return _cfail(LEVEL_3)
	if ts[0]["t"] == "op" and ts[0]["v"] == "!":
		return _cfail("! (not) is coming in Level 3! Here, check the condition and put your code in the else.")
	if ts.size() >= 2 and ts[1]["t"] == ".":
		return _equals_condition(ts)
	if ts.size() == 1:
		return _single_condition(ts[0])

	var k := -1
	for j in ts.size():
		if ts[j]["t"] == "op":
			k = j
			break
	if k == -1:
		return _cfail("Compare with an operator (== != < > <= >=), like: if (tide >= 4)")
	var op: String = ts[k]["v"]
	var left := ts.slice(0, k)
	var right := ts.slice(k + 1)
	var left_text := _text_of(left)
	var right_text := _text_of(right)
	if op == "=":
		if left.size() == 1 and left[0]["t"] == "word" and c.variables.has(left[0]["v"]) \
				and c.variables[left[0]["v"]]["type"] == "boolean":
			var n: String = left[0]["v"]
			return _cfail("= stores %s in %s, so this if would always do the same thing. Compare with == - or just write if (%s)." % [right_text, n, n])
		return _cfail("One = stores a value. To compare, use ==: if (%s == %s)" % [left_text, right_text])
	if op in ["=>", "=<", "=!"]:
		return _cfail("The = goes last: write %s." % {"=>": ">=", "=<": "<=", "=!": "!="}[op])
	if not op in OPS:
		return _cfail("%s isn't a comparison. Use == != < > <= or >=." % op)
	if left.is_empty() or right.is_empty():
		return _cfail("Put something on both sides of %s, like: tide %s 4" % [op, op])
	for side in [left, right]:
		for t in side:
			if t["t"] == "op":
				return _cfail("Use one comparison per if, like: tide >= 4")
	if left.size() != 1 or right.size() != 1:
		return _cfail("Compare one thing with one value, like: tide >= 4")

	var a := _operand(left[0])
	if a.has("fail"):
		return a
	var b := _operand(right[0])
	if b.has("fail"):
		return b
	if a.has("value") and b.has("value"):
		return _cfail("That's always the same answer, so it doesn't decide anything. Check a reading, like: tide >= 4")
	var named: Dictionary = a if a.has("name") else b
	var other: Dictionary = b if a.has("name") else a
	var type_error := _type_check(named, op, other)
	if not type_error.is_empty():
		return type_error
	return {"cond": {"kind": "cmp", "left": a, "op": op, "right": b,
		"text": "%s %s %s" % [a["text"], op, b["text"]]}}


## if (awake)
func _single_condition(t: Dictionary) -> Dictionary:
	if t["t"] == "word":
		var w: String = t["v"]
		if w == "true" or w == "false":
			return _cfail("That's always %s, so it doesn't decide anything. Check a reading, like: if (awake)" % w)
		var o := _operand(t)
		if o.has("fail"):
			return o
		match o["type"]:
			"boolean":
				return {"cond": {"kind": "bool", "name": w, "text": w}}
			"int", "double":
				return _cfail("%s is a number, so compare it with something: if (%s > 3)" % [w, w])
			"String":
				return _cfail("%s is a String - compare it: if (%s.equals(\"...\"))" % [w, w])
			"char":
				return _cfail("%s is a char - compare it: if (%s == 'C')" % [w, w])
	return _cfail("A condition must be true or false. Compare something, like: if (tide > 3)")


## if (word.equals("ahoy"))
func _equals_condition(ts: Array) -> Dictionary:
	if ts[0]["t"] != "word":
		return _cfail("Put the variable first: word.equals(\"ahoy\")")
	var name: String = ts[0]["v"]
	if ts.size() < 3 or ts[2]["t"] != "word":
		return _cfail("After the dot, write equals: %s.equals(\"...\")" % name)
	var method: String = ts[2]["v"]
	if method != "equals":
		if method.to_lower() == "equals":
			return _cfail("Java is case-sensitive: write equals in lowercase.")
		return _cfail("The only method here is .equals(...), for comparing Strings.")
	var o := _operand(ts[0])
	if o.has("fail"):
		return o
	match o["type"]:
		"char":
			return _cfail("%s is a char - chars aren't objects, so compare them with ==, like: %s == 'C'" % [name, name])
		"int", "double":
			return _cfail("%s is a number - compare it with == or < >, like: %s == 4" % [name, name])
		"boolean":
			return _cfail("%s is already true or false - just write if (%s)" % [name, name])
	if ts.size() < 4 or ts[3]["t"] != "(":
		return _cfail("equals needs brackets: %s.equals(\"ahoy\")" % name)
	if ts[-1]["t"] != ")" or ts.size() < 5:
		return _cfail("Close equals with ): %s.equals(\"...\")" % name)
	var args := ts.slice(4, ts.size() - 1)
	if args.is_empty():
		return _cfail("Put the text to compare inside equals( ), in double quotes: %s.equals(\"ahoy\")" % name)
	if args.size() > 1:
		return _cfail("equals takes one value: %s.equals(\"ahoy\")" % name)
	var a: Dictionary = args[0]
	if a["t"] == "chr":
		return _cfail("Text uses double quotes: %s.equals(\"%s\")" % [name, a["v"]])
	if a["t"] != "str":
		return _cfail("Text needs double quotes: %s.equals(\"%s\")" % [name, a["v"]])
	return {"cond": {"kind": "equals", "name": name, "value": a["v"],
		"text": "%s.equals(\"%s\")" % [name, a["v"]]}}


## One side of a comparison: a variable, or a literal value.
func _operand(t: Dictionary) -> Dictionary:
	match t["t"]:
		"num":
			var v: String = t["v"]
			if v.is_valid_int():
				return {"value": v.to_int(), "lit": "num", "text": v}
			if v.is_valid_float():
				return {"value": v.to_float(), "lit": "num", "text": v}
			return _cfail("%s isn't a number I can read." % v)
		"str":
			return {"value": t["v"], "lit": "str", "text": "\"%s\"" % t["v"]}
		"chr":
			return {"value": t["v"], "lit": "chr", "text": "'%s'" % t["v"]}
		"word":
			var w: String = t["v"]
			if w == "true" or w == "false":
				return {"value": w == "true", "lit": "bool", "text": w}
			if w.to_lower() == "true" or w.to_lower() == "false":
				return _cfail("Write true or false in lowercase.")
			var err := c._check_name(w)
			if err != "":
				return {"fail": c._fail("Condition", err)}
			var spec: Dictionary = c.variables[w]
			var kind := VariableLibrary.kind_of(spec)
			if kind == "machine":
				return _cfail("%s is something the %s does. A rule checks readings, like the tide." % [w, spec.get("noun", w)])
			if kind == "" and not w in _declared:
				return _cfail("Java doesn't know %s yet. Make it first: %s %s = ...;" % [w, spec["type"], w])
			return {"name": w, "type": spec["type"], "text": w}
	return _cfail("I can't read %s in a condition." % t["v"])


## "" (as {}) if the two sides can be compared with op, otherwise a fail (sometimes with a fix).
func _type_check(named: Dictionary, op: String, other: Dictionary) -> Dictionary:
	var name: String = named["name"]
	var type: String = named["type"]
	if other.has("name"):
		var other_type: String = other["type"]
		if type in ["int", "double"] and other_type in ["int", "double"]:
			return {}
		if type == other_type and type in ["char", "boolean"] and op in ["==", "!="]:
			return {}
		if type == "String" and other_type == "String":
			return _cfail("Strings are compared with .equals: %s.equals(%s)" % [name, other["name"]])
		return _cfail("%s is a %s and %s is a %s - they can't be compared." % [name, type, other["name"], other_type])

	var lit: String = other["lit"]
	match type:
		"int", "double":
			if lit == "num":
				return {}
			if lit in ["str", "chr"]:
				return _cfail("%s is a number, so compare it with a number - no quotes: %s %s %s" % [name, name, op, other["value"]])
			return _cfail("%s is a number - compare it with a number, not true or false." % name)
		"char":
			if lit == "chr":
				if other["value"].length() != 1:
					return _cfail("A char holds only ONE character, like 'C'.")
				if not op in ["==", "!="]:
					return _cfail("Compare chars with == or != here, like: %s == '%s'" % [name, other["value"]])
				return {}
			if lit == "str":
				return _cfail("%s is a char: use single quotes, '%s'." % [name, other["value"]])
			return _cfail("%s is a char: compare it with one letter in single quotes, like %s == 'C'." % [name, name])
		"String":
			if lit != "str":
				if lit == "chr":
					return _cfail("Text uses double quotes: \"%s\"." % other["value"])
				return _cfail("%s is a String - compare it with text in double quotes, using %s.equals(\"...\")." % [name, name])
			var text: String = other["value"]
			if op == "==":
				var fixed := _source.substr(0, _cond_start) + "%s.equals(\"%s\")" % [name, text] + _source.substr(_cond_end)
				var result := c._fail("Strings use .equals", "Strings are compared with .equals, not ==. == asks whether both are the very same String object, so it can say false even when every letter matches. I put %s.equals(\"%s\") in for you - press Enter." % [name, text])
				result["fix"] = fixed
				return {"fail": result}
			if op == "!=":
				return _cfail("Strings are compared with .equals. For 'not %s', check %s.equals(\"%s\") and put that code in the else." % [text, name, text])
			return _cfail("Strings can't be bigger or smaller here - compare them with %s.equals(\"...\")." % name)
		"boolean":
			if lit != "bool":
				return _cfail("%s is true or false - compare it with true or false, or just write if (%s)." % [name, name])
			if not op in ["==", "!="]:
				return _cfail("true and false can't be bigger or smaller. Use == - or just write if (%s)." % name)
			if op == "==" and other["value"] == true:
				_notes.append("Works! %s is already true or false, so if (%s) says the same thing." % [name, name])
			return {}
	return {}


# ---------------- { ... } ----------------

## The block starting at token i ("{"). Returns { body, next } or { fail }.
func _block(i: int, part: String) -> Dictionary:
	if i >= _toks.size() or _toks[i]["t"] != "{":
		if part == "if":
			return {"fail": c._fail("Code in { }", "Put the code the if runs inside { }, like: if (tide > 3) { gateOpen = false; }")}
		return {"fail": c._fail("Code in { }", "Put the code for else inside { }, like: else { gateOpen = true; }")}
	var close := _match(i, "{", "}")
	if close == -1:
		return {"fail": c._fail("Code in { }", "Every { needs a matching }.")}
	var start: int = _toks[i]["e"]
	var inner := _source.substr(start, _toks[close]["s"] - start)
	var body := _statements(inner)
	if body.has("fail"):
		return body
	return {"body": body["body"], "next": close + 1}


func _statements(inner: String) -> Dictionary:
	var pieces := _split_statements(inner)
	var rest: String = pieces.pop_back().strip_edges()
	var body := []
	for piece in pieces:
		var stmt: String = piece.strip_edges()
		if stmt == "":
			continue
		var stmt_fail := _check_statement_shape(stmt)
		if not stmt_fail.is_empty():
			return stmt_fail
		var line := stmt + ";"
		var saved: Array = c._steps
		c._steps = []
		var r: Dictionary
		if line.to_lower().begins_with("system."):
			r = c._check_print(line, _values)
		else:
			r = c._check_assignment(line, _unlocked, _declared, true)
		var sub_steps: Array = c._steps
		c._steps = saved
		if not r["ok"]:
			var label: String = sub_steps[-1]["label"] if not sub_steps.is_empty() else "Statement"
			return {"fail": c._fail(label, r["error"])}
		var action: Dictionary = r["action"]
		action["text"] = line
		c._pass(line)
		body.append(action)
	if rest != "":
		var rest_fail := _check_statement_shape(rest)
		if not rest_fail.is_empty():
			return rest_fail
		return {"fail": c._fail("Semicolon", "Every statement inside { } ends with a semicolon: %s;" % rest)}
	if body.is_empty():
		return {"fail": c._fail("Code in { }", "Put something inside { } for the rule to do, like { gateOpen = true; }")}
	return {"body": body}


func _check_statement_shape(stmt: String) -> Dictionary:
	if RuleChecker.is_rule(stmt):
		return {"fail": c._fail("One if", "An if inside an if comes in Level 3! Here, use else if (...) for another condition.")}
	if "{" in stmt or "}" in stmt:
		return {"fail": c._fail("Code in { }", "Only one pair of { } per part of the rule.")}
	return {}


## Splits on ; outside quotes. The last piece is whatever comes after the last ;.
func _split_statements(text: String) -> Array:
	var out := []
	var cur := ""
	var quote := ""
	for ch in text:
		if quote != "":
			cur += ch
			if ch == quote:
				quote = ""
		elif ch == "\"" or ch == "'":
			quote = ch
			cur += ch
		elif ch == ";":
			out.append(cur)
			cur = ""
		else:
			cur += ch
	out.append(cur)
	return out


# ---------------- helpers ----------------

func _cfail(error: String) -> Dictionary:
	return {"fail": c._fail("Condition", error)}


func _ends_at(i: int) -> bool:
	for j in range(i, _toks.size()):
		if _toks[j]["t"] != ";":  # a ; after the last } is an empty statement, which Java allows
			return false
	return true


## Index of the token closing the one at i, or -1.
func _match(i: int, open: String, close: String) -> int:
	var depth := 0
	for j in range(i, _toks.size()):
		if _toks[j]["t"] == open:
			depth += 1
		elif _toks[j]["t"] == close:
			depth -= 1
			if depth == 0:
				return j
	return -1


func _text_of(ts: Array) -> String:
	if ts.is_empty():
		return "..."
	return _source.substr(ts[0]["s"], ts[-1]["e"] - ts[0]["s"])


func _cond_names(cond: Dictionary) -> Array:
	match cond["kind"]:
		"cmp":
			var names := []
			for side in [cond["left"], cond["right"]]:
				if side.has("name"):
					names.append(side["name"])
			return names
		_:
			return [cond["name"]]


## Tokens: { t: kind, v: text, s: start, e: end }. Kinds: word num str chr op bad and the
## punctuation itself. Returns "str" / "chr" for text that isn't closed.
func _tokenize(src: String) -> Variant:
	var toks := []
	var i := 0
	var n := src.length()
	while i < n:
		var ch := src[i]
		if ch in [" ", "\t", "\n", "\r"]:
			i += 1
			continue
		var start := i
		if _is_letter(ch):
			while i < n and (_is_letter(src[i]) or src[i].is_valid_int()):
				i += 1
			toks.append({"t": "word", "v": src.substr(start, i - start), "s": start, "e": i})
		elif ch.is_valid_int() or (ch == "-" and i + 1 < n and src[i + 1].is_valid_int() and _expects_value(toks)):
			i += 1
			while i < n and (src[i].is_valid_int() or src[i] == "."):
				i += 1
			toks.append({"t": "num", "v": src.substr(start, i - start), "s": start, "e": i})
		elif ch == "\"" or ch == "'":
			var close := src.find(ch, i + 1)
			if close == -1:
				return "str" if ch == "\"" else "chr"
			toks.append({"t": "str" if ch == "\"" else "chr", "v": src.substr(i + 1, close - i - 1), "s": start, "e": close + 1})
			i = close + 1
		elif src.substr(i, 2) in TWO_CHAR_OPS:
			toks.append({"t": "op", "v": src.substr(i, 2), "s": i, "e": i + 2})
			i += 2
		elif ch in ONE_CHAR_OPS:
			toks.append({"t": "op", "v": ch, "s": i, "e": i + 1})
			i += 1
		elif ch in PUNCT:
			toks.append({"t": ch, "v": ch, "s": i, "e": i + 1})
			i += 1
		else:
			toks.append({"t": "bad", "v": ch, "s": i, "e": i + 1})
			i += 1
	return toks


func _expects_value(toks: Array) -> bool:
	return toks.is_empty() or toks[-1]["t"] in ["op", "(", ","]


func _is_letter(ch: String) -> bool:
	return (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or ch == "_" or ch == "$"
