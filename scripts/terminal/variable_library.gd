class_name VariableLibrary
extends RefCounted
## Every variable Byte's terminal can understand, in any level.
## A level picks the ones it uses in its CodeTerminal's "Allowed Variables" list.
##
##   type     the Java type the variable needs
##   about    finishes the sentence "hero is ..." in Byte's hints
##   min/max  allowed range for numbers
##   choices  allowed values (char / String)
##
## What a variable *does* is handled by the terminal (player variables) or by gadgets that
## listen to CodeTerminal.variable_set (bridges, fans, ...).
##
## Level 2 adds two kinds (see docs/level2_design.md):
##   kind "reading"  the world changes it by itself; rules can check it, nobody can set it.
##                   `noun` is how Byte names it ("the tide").
##   kind "machine"  runs by itself, so it only takes rules: if (...) { gateOpen = true; }
##                   `noun` is the machine ("gate").
## Variables without a kind are the player's own and take orders, as in Level 1.

const VARIABLES := {
	"hero": {"type": "String", "about": "the hero you play as"},
	"speed": {"type": "double", "about": "how fast you run", "min": 0.5, "max": 2.0},
	"hasSword": {"type": "boolean", "about": "whether you carry a sword"},
	"bridgeLength": {"type": "int", "about": "how many blocks the bridge has", "min": 0, "max": 12},
	"jumpPower": {"type": "double", "about": "how high you jump", "min": 1.0, "max": 2.0},
	"fanOn": {"type": "boolean", "about": "whether the fan is running"},
	"path": {"type": "char", "about": "which path appears", "choices": ["A", "B", "C"]},

	# ---- Level 2: yours ----
	"key": {"type": "int", "about": "the number the captain's doors check", "min": 0, "max": 99},
	# ---- Level 2: readings ----
	"tide": {"type": "int", "about": "how high the tide is", "kind": "reading", "noun": "the tide"},
	"wind": {"type": "int", "about": "how strong the wind is", "kind": "reading", "noun": "the wind"},
	"word": {"type": "String", "about": "the word the lookout shouts", "kind": "reading",
		"noun": "what the lookout shouts"},
	"awake": {"type": "boolean", "about": "whether the crew is awake", "kind": "reading",
		"noun": "whether the crew is awake"},
	"move": {"type": "char", "about": "the captain's next move", "kind": "reading",
		"noun": "the captain's move"},
	"distance": {"type": "int", "about": "how far you are from the captain", "kind": "reading",
		"noun": "the captain's distance"},
	"coins": {"type": "int", "about": "coins collected in this room", "kind": "reading",
		"noun": "your coins"},
	"coinsLeft": {"type": "int", "about": "coins still to find in this room", "kind": "reading",
		"noun": "the coins left"},
	# ---- Level 2: machines ----
	"leftDoorOpen": {"type": "boolean", "about": "whether the left door is open", "kind": "machine",
		"noun": "left door"},
	"rightDoorOpen": {"type": "boolean", "about": "whether the right door is open", "kind": "machine",
		"noun": "right door"},
	"doorOpen": {"type": "boolean", "about": "whether the exit door is open", "kind": "machine",
		"noun": "door"},
	"anchorUp": {"type": "boolean", "about": "whether the anchor is up", "kind": "machine",
		"noun": "anchor"},
	"gateOpen": {"type": "boolean", "about": "whether the gate is open", "kind": "machine",
		"noun": "gate"},
	"sails": {"type": "int", "about": "how much sail is up (0 down, 1 half, 2 full)", "kind": "machine",
		"noun": "sails", "min": 0, "max": 2},
	"lightsOn": {"type": "boolean", "about": "whether the lanterns are lit", "kind": "machine",
		"noun": "lanterns"},
}


## "reading", "machine" or "" (the player's own variable).
static func kind_of(spec: Dictionary) -> String:
	return spec.get("kind", "")


## The specs for just these names (unknown names are skipped with a warning).
static func pick(names: Array) -> Dictionary:
	var out := {}
	for n in names:
		if VARIABLES.has(n):
			out[n] = VARIABLES[n]
		else:
			push_warning("VariableLibrary: unknown variable '%s'" % n)
	return out
