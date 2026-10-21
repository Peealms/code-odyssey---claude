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

const VARIABLES := {
	"hero": {"type": "String", "about": "the hero you play as"},
	"speed": {"type": "double", "about": "how fast you run", "min": 0.5, "max": 2.0},
	"hasSword": {"type": "boolean", "about": "whether you carry a sword"},
	"bridgeLength": {"type": "int", "about": "how many blocks the bridge has", "min": 0, "max": 12},
	"jumpPower": {"type": "double", "about": "how high you jump", "min": 1.0, "max": 2.0},
	"fanOn": {"type": "boolean", "about": "whether the fan is running"},
	"path": {"type": "char", "about": "which path appears", "choices": ["A", "B", "C"]},
}


## The specs for just these names (unknown names are skipped with a warning).
static func pick(names: Array) -> Dictionary:
	var out := {}
	for n in names:
		if VARIABLES.has(n):
			out[n] = VARIABLES[n]
		else:
			push_warning("VariableLibrary: unknown variable '%s'" % n)
	return out
