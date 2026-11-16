class_name ManualLibrary
extends RefCounted
## Every manual a chest can hold, and the Variable Dictionary. Pick a manual in a Chest's
## "Manual Id" in the Inspector. In the game a manual is a book item ("manual_<id>"): take it
## from a chest, hold it, left-click to read.
##
## Each manual has a title, a book cover colour and a list of pages.
##   book   0 red, 1 blue, 2 green, 3 purple, 4 orange  (see tools/make_item_icons.gd)
## A page is BBCode text, or a list of blocks shown top to bottom:
##   "text"                                    [b]bold[/b]  [code]int x = 5;[/code]  [color=#c0392b]red[/color]
##   {"diagram": [[code, label, role], ...], "box": "Declaring a Variable"}
##                                             a line of code with every part labelled
##                                             (scripts/ui/code_diagram.gd; roles: type, name,
##                                             op, value, end, cmd)
## A dictionary page that waits for its room: {"needs": "<variable>", "blocks": [...]}.
## Pages hold about 14 lines of text; a diagram takes about 6.
## Byte's hint for the next challenge goes on the last page.

## The diagram of a declaration, e.g. decl("int", "bridgeLength", "10").
static func decl(type: String, name: String, value: String) -> Dictionary:
	return {"diagram": [[type, "Data Type", "type"], [name, "Variable Name", "name"], ["=", "Assignment", "op"],
		[value, "Value", "value"], [";", "Semicolon", "end"]], "box": "Declaring a Variable"}


## The diagram of changing a variable that already exists, e.g. change("jumpPower", "1.0").
static func change(name: String, value: String) -> Dictionary:
	return {"diagram": [[name, "Variable Name", "name"], ["=", "Assignment", "op"],
		[value, "New Value", "value"], [";", "Semicolon", "end"]], "box": "Changing a Variable"}


const PRINT := {"diagram": [["System.out.println", "Print Command", "cmd"], ["(\"Hello Byte\")", "Text to Print", "value"], [";", "Semicolon", "end"]], "box": "Printing a Message"}

const OK := "[color=#2e7d32][b]OK[/b][/color]"
const NO := "[color=#c0392b][b]NO[/b][/color]"
const HINT := "[color=#2e7d32][b]Byte's hint:[/b] "


static func _manuals() -> Dictionary:
	return {
	"variables_101": {
		"title": "MANUAL: VARIABLES",
		"book": 0,
		"pages": [
			"""[b]What is a variable?[/b]
A variable is a labelled box that holds one value. The game reads the box to know what to do, like which hero you are.

To make a box, Java needs three things:
[b]1. a data type[/b] - what kind of value fits in it
[b]2. a name[/b] - the label on the box
[b]3. a value[/b] - what you put inside""",

			["""[b]How a variable is made[/b]
Making a new variable is called [b]declaring[/b] it. Every part has a job:""",
			decl("String", "hero", "\"Sarah\""),
			"""Read it out loud: [i]"Make a String called hero, and store Sarah in it."[/i]"""],

			"""[b]The parts, one by one[/b]
[b]Data type[/b] [code]String[/code] means text. Text always goes in double quotes.
[b]Variable name[/b] [code]hero[/code] is the label. You'll use it again later.
[b]Assignment[/b] [code]=[/code] means "store this in", not "equals".
[b]Value[/b] [code]"Sarah"[/code] is what goes in the box.
[b]Semicolon[/b] [code];[/code] ends the line, like a full stop.""",

			"""[b]Rules Java is strict about[/b]
- Every line ends with a semicolon [code];[/code]
- Capitals matter: [code]String[/code] works, [code]string[/code] doesn't.
- No spaces in names: [code]myHero[/code], not [code]my hero[/code]
- Names can't start with a number: [code]hero2[/code] is fine, [code]2hero[/code] is not.

If you break a rule, Byte tells you which part was wrong.""",

			["""[b]Try it![/b]
Press [b]E[/b] to open Byte's terminal. Your first line of Java prints a message:""",
			PRINT,
			HINT + """my gates open when I hear you say something!
When a gap is too wide for you, switch to a hero who can cross it: store their name in a [b]String[/b] called [code]hero[/code].[/color]"""],
		],
	},
	"numbers": {
		"title": "MANUAL: NUMBERS",
		"book": 4,
		"pages": [
			"""[b]Two kinds of numbers[/b]
Java keeps whole numbers and decimal numbers apart:

[b]int[/b] - whole numbers only: [code]0[/code]  [code]6[/code]  [code]-3[/code]  [code]100[/code]
[b]double[/b] - numbers with a point: [code]1.5[/code]  [code]0.25[/code]  [code]2.0[/code]

Use [b]int[/b] for things you [i]count[/i] (planks, lives, coins).
Use [b]double[/b] for things you [i]measure[/i] (speed, height, power).""",

			["""[b]An int: counting[/b]
The bridge counts its planks, so its number is an [b]int[/b]:""",
			decl("int", "bridgeLength", "10"),
			"""No quotes and no decimal point: just the whole number."""],

			["""[b]A double: measuring[/b]
How high you jump is measured, so it's a [b]double[/b]:""",
			decl("double", "jumpPower", "1.2"),
			"""A double always has a point: write [code]2.0[/code], not [code]2[/code]."""],

			"""[b]Writing numbers[/b]
- No quotes: [code]6[/code] is a number, [code]"6"[/code] is text.
- No commas: [code]1000[/code], not [code]1,000[/code]
- An int can't hold a decimal:

%s   [code]int bridgeLength = 10;[/code]
%s   [code]int bridgeLength = 9.5;[/code]
%s   [code]double jumpPower = 1.2;[/code]""" % [OK, NO, OK],

			HINT + """the bridge ahead is broken. It builds one plank for every 1 in its number.
Count how many planks wide the gap is, and store that [b]whole number[/b] in an [b]int[/b] called [code]bridgeLength[/code].[/color]

Then the step on the other side is too high for one jump. Who can jump twice?
[code]hero[/code] already exists, so change it [i]without[/i] the type:
[code]hero = "...";[/code]""",
		],
	},
	"booleans_chars": {
		"title": "MANUAL: BOOLEANS & CHARS",
		"book": 2,
		"pages": [
			"""[b]boolean: yes or no[/b]
A boolean has only two values: [code]true[/code] and [code]false[/code].
It's perfect for switches, doors and yes-or-no questions: is the light on? Is the door locked?

Always lowercase, and [b]no quotes[/b]: [code]"true"[/code] would be text, not a boolean.""",

			["""[b]A boolean: a switch[/b]
The ship's anchor is either up or down:""",
			decl("boolean", "anchorUp", "false"),
			"""[code]false[/code]: the anchor is down and the ship stays. [code]true[/code] pulls it up."""],

			"""[b]char: one single character[/b]
A char holds exactly [b]one[/b] letter, digit or symbol, in [b]single quotes[/b]:

[code]char grade = 'A';[/code]

%s   [code]char grade = "A";[/code]
double quotes make a String
%s   [code]char grade = 'AB';[/code]
only one character fits""" % [NO, NO],

			["""[b]A char: one letter[/b]
Three paths are named A, B and C. Pick one:""",
			decl("char", "path", "'A'"),
			"""Single quotes around one letter, and a capital: [code]'A'[/code], not [code]'a'[/code]."""],

			HINT + """the ship ahead is anchored. Pull the anchor up with a [b]boolean[/b] called [code]anchorUp[/code], then ride it across the sea.

A crab blocks the way after that: another boolean, [code]hasSword[/code], gives you a sword.

Later, three paths cross the water and only one holds you. Choose it with a [b]char[/b] called [code]path[/code]. The sign says which letter![/color]""",
		],
	},
	"changing_variables": {
		"title": "MANUAL: CHANGING VARIABLES",
		"book": 3,
		"pages": [
			["""[b]Make it once...[/b]
You make (declare) a variable only [b]once[/b], with its data type:""",
			decl("double", "jumpPower", "1.5"),
			"""Now Java knows jumpPower is a double."""],

			["""[b]...then change it[/b]
To change it, write just its name and the new value:""",
			change("jumpPower", "1.0"),
			"""No data type! The new value replaces the old one in the box."""],

			"""[b]Why not write the type again?[/b]
Writing the type means "make a [i]new[/i] variable". Java won't make two variables with the same name:

%s   [code]double jumpPower = 1.0;[/code]
jumpPower already exists
%s   [code]jumpPower = 1.0;[/code]

The new value must still fit the type: [code]jumpPower = "low";[/code] won't work.""" % [NO, OK],

			HINT + """the tunnel ahead has spikes on the ceiling. With your big jumps from before, you'll hit your head!
Change [code]jumpPower[/code] back to a smaller number. It already exists, so leave out the type.[/color]""",
		],
	},
	"dictionary": {
		"title": "VARIABLE DICTIONARY",
		"book": 1,
		"pages": [
			"""[b]How to use this book[/b]
Every variable on this island has a page: what its name means, its data type, the values it can hold and how to change it.

New pages fill in as you reach new rooms.

[b]Reading names[/b]
Java names are words stuck together. Every word after the first starts with a capital:
[code]bridge[/code] + [code]Length[/code] = [code]bridgeLength[/code]
This is called [i]camelCase[/i]: the capitals are the camel's humps.""",

			{"needs": "hero", "blocks": [
				"""[font_size=14][code]hero[/code][/font_size]   [b]String[/b]
[b]The name:[/b] the hero you are playing as.
[b]Values:[/b] a rescued teammate's name, in double quotes with a capital first letter: [code]"Chelzy"[/code] [code]"Sarah"[/code] [code]"April"[/code] [code]"Kervin"[/code] [code]"Psalm"[/code]""",
				decl("String", "hero", "\"Sarah\""),
				"""[b]Change it:[/b] [code]hero = "April";[/code]
No type: hero already exists."""]},

			{"needs": "bridgeLength", "blocks": [
				"""[font_size=14][code]bridgeLength[/code][/font_size]   [b]int[/b]
[b]The name:[/b] bridge + Length: how long the bridge is, counted in planks.
[b]Values:[/b] a whole number from 0 to 12. Count the gap: the bridge must fit it exactly.""",
				decl("int", "bridgeLength", "5"),
				"""[b]Change it:[/b] [code]bridgeLength = 3;[/code]"""]},

			{"needs": "jumpPower", "blocks": [
				"""[font_size=14][code]jumpPower[/code][/font_size]   [b]double[/b]
[b]The name:[/b] jump + Power: how high your first jump goes.
[b]Values:[/b] 1.0 (normal) to 1.5 (one and a half times as high), with a decimal point: [code]1.2[/code], [code]1.35[/code]...""",
				decl("double", "jumpPower", "1.2"),
				"""[b]Change it:[/b] [code]jumpPower = 1.1;[/code]"""]},

			{"needs": "anchorUp", "blocks": [
				"""[font_size=14][code]anchorUp[/code][/font_size]   [b]boolean[/b]
[b]The name:[/b] anchor + Up: is the ship's anchor pulled up?
[b]Values:[/b] [code]true[/code] - up: the ship sails between its docks.
[code]false[/code] - down: the ship sails home and stays.""",
				decl("boolean", "anchorUp", "false"),
				"""[b]Change it:[/b] [code]anchorUp = true;[/code]"""]},

			{"needs": "hasSword", "blocks": [
				"""[font_size=14][code]hasSword[/code][/font_size]   [b]boolean[/b]
[b]The name:[/b] has + Sword: does your hero carry a sword? A boolean name often reads like a yes-or-no question.
[b]Values:[/b] [code]true[/code] puts the sword in your hotbar, [code]false[/code] takes it away.""",
				decl("boolean", "hasSword", "true"),
				"""Hold the sword (its number key) and left-click to swing."""]},

			{"needs": "path", "blocks": [
				"""[font_size=14][code]path[/code][/font_size]   [b]char[/b]
[b]The name:[/b] which path of planks appears over the water.
[b]Values:[/b] [code]'A'[/code] [code]'B'[/code] or [code]'C'[/code]: one capital letter in single quotes. Only the path on the sign is safe!""",
				decl("char", "path", "'A'"),
				"""[b]Change it:[/b] [code]path = 'C';[/code]"""]},

			["""[font_size=14][code]System.out.println[/code][/font_size]
[b]Not a variable:[/b] a command. It prints the text in the brackets. Byte's gates open when they hear the right words.""",
			PRINT,
			"""Print exactly what the sign says, capitals and all."""],
		],
	},
	}


static var _cache := {}


static func has(id: String) -> bool:
	return _all().has(id)


static func get_manual(id: String) -> Dictionary:
	return _all().get(id, {})


static func _all() -> Dictionary:
	if _cache.is_empty():
		_cache = _manuals()
	return _cache
