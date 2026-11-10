extends SceneTree
## Checks Byte's rule checker and the rule runner's maths without opening the game.
## Run:  godot --headless --path . --script res://tools/test_rules.gd
## Every right rule from docs/level2_design.md must pass, and every mistake in its table must
## fail on the step the doc says. Prints PASS/FAIL per check and a total.

var checker := CommandChecker.new()
var passed := 0
var failed := 0
const DECLARED := ["hero"]


func _initialize() -> void:
	_right_rules()
	_mistakes()
	_orders_and_readings()
	_evaluation()
	_formatting()
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  %s" % ["PASS" if ok else "FAIL", name, detail])


func run(line: String, declared: Array = DECLARED, allow_bugs := false) -> Dictionary:
	return checker.check(line, {}, [], declared, allow_bugs)


func expect_ok(line: String, declared: Array = DECLARED) -> Dictionary:
	var r := run(line, declared)
	check("ok: " + line, r["ok"], r["error"])
	return r


## The line must fail on the step called `label`, and the error must contain `words`.
func expect_fail(line: String, label: String, words := "", declared: Array = DECLARED) -> Dictionary:
	var r := run(line, declared)
	var last: String = r["steps"][-1]["label"] if not r["steps"].is_empty() else ""
	var good: bool = not r["ok"] and last == label and (words == "" or words in r["error"])
	check("fails at %s: %s" % [label, line], good, "got [%s] %s" % [last, r["error"]])
	return r


func _right_rules() -> void:
	for line in [
		"if (tide >= 4) { anchorUp = true; }",
		"if (tide > 3) { anchorUp = true; }",
		"if (4 <= tide) { anchorUp = true; }",
		"if(tide>3){anchorUp=true;}",
		"if (tide >= 3) { gateOpen = false; } else { gateOpen = true; }",
		"if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; } else { sails = 2; }",
		"if (word.equals(\"ahoy\")) { gateOpen = true; } else { gateOpen = false; }",
		"if (awake) { lightsOn = false; } else { lightsOn = true; }",
		"if (move == 'C') { hero = \"April\"; } else if (move == 'T') { hero = \"Psalm\"; } else { hero = \"Sarah\"; }",
		"if (tide > 3) { anchorUp = true; System.out.println(\"Sail!\"); }",
		"if (tide > 3) { anchorUp = true; System.out.println(tide); }",
		"if (tide > 3) { anchorUp = true; };",
		"if (tide != 0) { gateOpen = false; } else { gateOpen = true; }",
	]:
		expect_ok(line)
	var r := expect_ok("if (awake == true) { lightsOn = false; }")
	check("== true gets Byte's tip", r["ok"] and not r["action"]["notes"].is_empty())
	r = expect_ok("if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; } else { sails = 2; }")
	var rule: Dictionary = r["action"]["rule"]
	check("3 branches", rule["branches"].size() == 3)
	check("reads wind", rule["reads"] == ["wind"])
	check("sets sails", rule["sets"] == ["sails"])
	r = run("if (tide >= 4); { anchorUp = true; }", DECLARED, true)
	check("captain's ; bug is accepted with allow_bugs", r["ok"] and r["action"]["rule"]["branches"][0]["detached"])


func _mistakes() -> void:
	expect_fail("If (tide > 3) { anchorUp = true; }", "Starts with if", "lowercase")
	expect_fail("else { gateOpen = true; }", "Starts with if", "needs an if")
	expect_fail("if tide > 3 { anchorUp = true; }", "Brackets", "brackets")
	expect_fail("if (tide > 3 { anchorUp = true; }", "Brackets", "Close")
	expect_fail("if () { anchorUp = true; }", "Condition", "Put a condition")
	expect_fail("if (tide = 3) { anchorUp = true; }", "Condition", "One = stores")
	expect_fail("if (tide => 3) { anchorUp = true; }", "Condition", ">=")
	expect_fail("if (tide =< 3) { anchorUp = true; }", "Condition", "<=")
	expect_fail("if (tide > \"3\") { anchorUp = true; }", "Condition", "no quotes")
	expect_fail("if (move == \"C\") { hero = \"April\"; }", "Condition", "single quotes")
	expect_fail("if (move == 'CT') { hero = \"April\"; }", "Condition", "ONE character")
	expect_fail("if (move > 'C') { hero = \"April\"; }", "Condition", "== or !=")
	expect_fail("if (tide > 3); { anchorUp = true; }", "No ; after )", "always run")
	expect_fail("if (tide > 3) anchorUp = true;", "Code in { }", "inside { }")
	expect_fail("if (tide > 3) { anchorUp = true; ", "Code in { }", "matching }")
	expect_fail("if (tide > 3) { anchorUp = true }", "Semicolon", "semicolon")
	expect_fail("if (tide > 3) { }", "Code in { }", "Put something")
	expect_fail("if (tide > 3) { anchorUp = true; } else (tide < 3) { anchorUp = false; }", "else", "no condition")
	expect_fail("if (tide > 3) { anchorUp = true; } elseif (tide < 3) { anchorUp = false; }", "else if", "two words")
	expect_fail("if (tide > 3) { anchorUp = true; } Else { anchorUp = false; }", "else", "lowercase")
	expect_fail("if (tide > 3) { anchorUp = true; } else { anchorUp = false; } else { anchorUp = true; }", "else", "last part")
	expect_fail("if (true) { anchorUp = true; }", "Condition", "always true")
	expect_fail("if (5 > 3) { anchorUp = true; }", "Condition", "always the same")
	expect_fail("if (awake = true) { lightsOn = false; }", "Condition", "= stores")
	expect_fail("if (tide > 3 && wind > 2) { sails = 1; }", "Condition", "Level 3")
	expect_fail("if (!awake) { lightsOn = true; }", "Condition", "Level 3")
	expect_fail("if (tide) { anchorUp = true; }", "Condition", "number")
	expect_fail("if (word.equals('ahoy')) { gateOpen = true; }", "Condition", "double quotes")
	expect_fail("if (word.equals(ahoy)) { gateOpen = true; }", "Condition", "double quotes")
	expect_fail("if (word.Equals(\"ahoy\")) { gateOpen = true; }", "Condition", "lowercase")
	expect_fail("if (move.equals(\"C\")) { hero = \"April\"; }", "Condition", "aren't objects")
	expect_fail("if (word != \"ahoy\") { gateOpen = false; }", "Condition", "else")
	expect_fail("if (word > \"ahoy\") { gateOpen = false; }", "Condition", "bigger or smaller")
	expect_fail("if (gateOpen) { anchorUp = true; }", "Condition", "readings")
	expect_fail("if (tyde > 3) { anchorUp = true; }", "Condition", "don't know")
	expect_fail("if (Tide > 3) { anchorUp = true; }", "Condition", "Did you mean tide")
	expect_fail("if (key == 7) { gateOpen = true; }", "Condition", "doesn't know key", [])
	expect_fail("if (tide > 3) { if (wind > 2) { sails = 1; } }", "One if", "Level 3")
	expect_fail("if (tide > 3) { boolean gateOpen = true; }", "No type", "leave out the type")
	expect_fail("if (tide > 3) { int depth = 3; }", "Variable name", "")
	expect_fail("if (tide > 3) { tide = 5; }", "Readings", "can't change")
	expect_fail("if (tide > 3) { hero = \"Bob\"; }", "Hero", "no hero")
	expect_fail("if (tide > 3) { sails = 3; }", "Range", "between")
	expect_fail("if (tide > 3) { anchorUp = \"true\"; }", "Value", "quotes")
	var r := expect_fail("if (word == \"ahoy\") { gateOpen = true; } else { gateOpen = false; }", "Strings use .equals", ".equals")
	check("Byte fixes == on Strings", r.get("fix", "") == "if (word.equals(\"ahoy\")) { gateOpen = true; } else { gateOpen = false; }", r.get("fix", "(no fix)"))


func _orders_and_readings() -> void:
	expect_fail("tide = 5;", "Readings", "can't change the tide")
	expect_fail("int tide = 5;", "Readings", "can't change")
	var r := expect_fail("gateOpen = true;", "Rules, not orders", "rule")
	check("Byte turns an order into a rule", r.get("fix", "") == "if (___) { gateOpen = true; }", r.get("fix", ""))
	r = expect_fail("boolean anchorUp = true;", "Rules, not orders", "")
	check("a declared machine order also gets the rule", r.get("fix", "") == "if (___) { anchorUp = true; }", r.get("fix", ""))
	expect_ok("int key = 7;", [])
	expect_ok("key = 3;", ["key"])
	expect_ok("hero = \"Psalm\";")
	var p := checker.check("System.out.println(tide);", {"tide": "3"}, [], DECLARED)
	check("println a reading", p["ok"] and p["action"]["text"] == "3", str(p["action"]))


func _evaluation() -> void:
	var values := {}
	var lookup := func(n: String) -> Variant: return values.get(n)
	var sails := _rule("if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; } else { sails = 2; }")
	for pair in [[8, 0, 0], [5, 1, 1], [1, 2, 2], [7, 0, 0], [3, 1, 1]]:
		values["wind"] = pair[0]
		var t := Rules.evaluate(sails, lookup)
		check("wind %d runs branch %d" % [pair[0], pair[1]], t["ran"] == [pair[1]] and t["statements"][0]["value"] == pair[2], str(t["ran"]))
	values["wind"] = 8
	var wrong := _rule("if (wind >= 3) { sails = 1; } else if (wind >= 7) { sails = 0; } else { sails = 2; }")
	var t := Rules.evaluate(wrong, lookup)
	check("wrong order: wind 8 takes the first branch", t["ran"] == [0] and t["statements"][0]["value"] == 1)
	check("wrong order: Java never checks wind >= 7", t["conds"][1]["checked"] == false)
	check("shown with values", t["conds"][0]["shown"] == "8 >= 3", t["conds"][0]["shown"])

	var no_else := _rule("if (wind >= 7) { sails = 0; } else if (wind >= 3) { sails = 1; }")
	values["wind"] = 1
	check("no else: nothing runs in a calm", Rules.evaluate(no_else, lookup)["ran"] == [])

	values["tide"] = 1
	var bug: Dictionary = checker.check("if (tide >= 4); { anchorUp = true; }", {}, [], DECLARED, true)["action"]["rule"]
	t = Rules.evaluate(bug, lookup)
	check("captain's ; bug: false, but the block runs", t["conds"][0]["result"] == false and t["ran"] == [0])

	values["word"] = "avast"
	var word := _rule("if (word.equals(\"ahoy\")) { gateOpen = true; } else { gateOpen = false; }")
	check("avast runs the else", Rules.evaluate(word, lookup)["ran"] == [1])
	values["word"] = "ahoy"
	t = Rules.evaluate(word, lookup)
	check("ahoy runs the if", t["ran"] == [0] and t["conds"][0]["shown"] == "\"ahoy\".equals(\"ahoy\")", t["conds"][0]["shown"])

	values["move"] = "T"
	var boss := _rule("if (move == 'C') { hero = \"April\"; } else if (move == 'T') { hero = \"Psalm\"; } else { hero = \"Sarah\"; }")
	t = Rules.evaluate(boss, lookup)
	check("move 'T' picks Psalm", t["ran"] == [1] and t["statements"][0]["value"] == "psalm")
	check("char shown in quotes", t["conds"][0]["shown"] == "'T' == 'C'", t["conds"][0]["shown"])

	values["awake"] = false
	var crew := _rule("if (awake) { lightsOn = false; } else { lightsOn = true; }")
	check("asleep runs the else", Rules.evaluate(crew, lookup)["ran"] == [1])
	values.erase("tide")
	check("unknown value counts as false", Rules.evaluate(_rule("if (tide > 3) { anchorUp = true; }"), lookup)["ran"] == [])


func _formatting() -> void:
	var lines := Rules.format(_rule("if (tide >= 3) { gateOpen = false; } else { gateOpen = true; }"))
	var texts := lines.map(func(l): return l["text"])
	check("formatted on 5 lines", texts == ["if (tide >= 3) {", "    gateOpen = false;", "} else {", "    gateOpen = true;", "}"], str(texts))
	var broken := Rules.format_source("if (tide = 0) { gateOpen = true; } else { gateOpen = false; }")
	check("broken rule spread over lines", broken == ["if (tide = 0) {", "    gateOpen = true;", "} else {", "    gateOpen = false;", "}"], str(broken))


func _rule(line: String) -> Dictionary:
	var r := checker.check(line, {}, [], DECLARED)
	if not r["ok"]:
		check("parses: " + line, false, r["error"])
		return {"branches": []}
	return r["action"]["rule"]
