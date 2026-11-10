class_name Rules
extends RefCounted
## Runs and prints the rules RuleChecker makes (see docs/level2_design.md).
## Rules are plain Dictionaries, so they can be stored, compared and shown on the rule panel.


## Runs a rule against the values `lookup` gives (Callable(name) -> value, null if unknown).
## Returns the trace the rule panel shows:
##   conds       one per branch: { text, shown ("3 >= 4"), result, checked }
##               checked = false when Java never got to it (an earlier branch ran)
##   ran         indices of the branches whose code ran
##   statements  the statements to run, in order
static func evaluate(rule: Dictionary, lookup: Callable) -> Dictionary:
	var conds := []
	var ran := []
	var statements := []
	var chosen := false
	var branches: Array = rule["branches"]
	for i in branches.size():
		var b: Dictionary = branches[i]
		if b["cond"] == null:
			conds.append({"text": "else", "shown": "", "result": not chosen, "checked": not chosen})
			if not chosen:
				chosen = true
				ran.append(i)
				statements.append_array(b["body"])
			continue
		if chosen:
			conds.append({"text": b["cond"]["text"], "shown": "", "result": false, "checked": false})
			continue
		var ev := eval_cond(b["cond"], lookup)
		conds.append({"text": b["cond"]["text"], "shown": ev["shown"], "result": ev["result"], "checked": true})
		if b.get("detached", false):
			# A ; ended the if: the { } after it is just a block, so it always runs.
			ran.append(i)
			statements.append_array(b["body"])
		elif ev["result"]:
			chosen = true
			ran.append(i)
			statements.append_array(b["body"])
	return {"conds": conds, "ran": ran, "statements": statements}


## { result, shown } for one condition, e.g. tide >= 4 with tide 3 -> { false, "3 >= 4" }.
static func eval_cond(cond: Dictionary, lookup: Callable) -> Dictionary:
	match cond["kind"]:
		"bool":
			var v = lookup.call(cond["name"])
			return {"result": v == true, "shown": java_text(v, "boolean")}
		"equals":
			var v = lookup.call(cond["name"])
			return {"result": v is String and v == cond["value"],
				"shown": "%s.equals(\"%s\")" % [java_text(v, "String"), cond["value"]]}
		"cmp":
			var a = _operand_value(cond["left"], lookup)
			var b = _operand_value(cond["right"], lookup)
			return {"result": compare(a, cond["op"], b),
				"shown": "%s %s %s" % [_operand_text(cond["left"], a), cond["op"], _operand_text(cond["right"], b)]}
	return {"result": false, "shown": "?"}


static func compare(a: Variant, op: String, b: Variant) -> bool:
	if a == null or b == null:
		return false
	var numbers := (a is int or a is float) and (b is int or b is float)
	if not numbers and typeof(a) != typeof(b):
		return op == "!="
	match op:
		"==":
			return a == b
		"!=":
			return a != b
	if not numbers:
		return false
	match op:
		"<":
			return a < b
		">":
			return a > b
		"<=":
			return a <= b
		">=":
			return a >= b
	return false


## A value written the way Java would show it: 'C' for a char, "ahoy" for a String.
static func java_text(v: Variant, type := "") -> String:
	if v == null:
		return "?"
	if v is bool:
		return "true" if v else "false"
	match type:
		"char":
			return "'%s'" % v
		"String":
			return "\"%s\"" % v
	return str(v)


static func _operand_value(o: Dictionary, lookup: Callable) -> Variant:
	return lookup.call(o["name"]) if o.has("name") else o["value"]


static func _operand_text(o: Dictionary, v: Variant) -> String:
	if o.has("name"):
		return java_text(v, o.get("type", ""))
	return o["text"]


## The rule on several lines, the way the rule panel shows it.
## Returns [{ "text": line, "branch": index, "part": "head" | "body" | "end" }].
static func format(rule: Dictionary) -> Array:
	var lines := []
	var branches: Array = rule["branches"]
	for i in branches.size():
		var b: Dictionary = branches[i]
		if i == 0:
			if b.get("detached", false):
				lines.append({"text": "if (%s);" % b["cond"]["text"], "branch": i, "part": "head"})
				lines.append({"text": "{", "branch": i, "part": "head"})
			else:
				lines.append({"text": "if (%s) {" % b["cond"]["text"], "branch": i, "part": "head"})
		elif b["cond"] == null:
			lines.append({"text": "} else {", "branch": i, "part": "head"})
		else:
			lines.append({"text": "} else if (%s) {" % b["cond"]["text"], "branch": i, "part": "head"})
		for s in b["body"]:
			lines.append({"text": "    " + s.get("text", "?"), "branch": i, "part": "body"})
	lines.append({"text": "}", "branch": -1, "part": "end"})
	return lines


## A rule that can't run (e.g. the captain's if (tide = 0)), spread over lines anyway.
static func format_source(source: String) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	var depth := 0
	for ch in source:
		if ch == "{":
			cur += "{"
			out.append(cur.strip_edges(false, true))
			depth += 1
			cur = "    ".repeat(depth)
		elif ch == "}":
			if cur.strip_edges() != "":
				out.append(cur.strip_edges(false, true))
			depth = maxi(depth - 1, 0)
			cur = "    ".repeat(depth) + "}"
		elif ch == ";" and depth > 0:
			cur += ";"
			out.append(cur.strip_edges(false, true))
			cur = "    ".repeat(depth)
		elif ch == " " and cur.strip_edges() == "":
			continue
		else:
			cur += ch
	if cur.strip_edges() != "":
		out.append(cur.strip_edges(false, true))
	return out
