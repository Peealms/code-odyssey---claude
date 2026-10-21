class_name ManualLibrary
extends RefCounted
## Every manual a chest can hold. Pick one in a Chest's "Manual Id" in the Inspector.
## In the game a manual is a book item ("manual_<id>"): take it from a chest, hold it, left-click to read.
##
## Each manual has a title, a book cover colour and a list of pages.
##   book   0 red, 1 blue, 2 green, 3 purple, 4 orange  (see tools/make_item_icons.gd)
## Pages use BBCode:
##   [b]bold[/b]   [code]String hero = "PinkMan";[/code]   [color=#c0392b]red[/color]
## Keep pages short - about 8 lines fit on one page.
## Byte's hint for the next challenge goes on the last page.

const MANUALS := {
	"variables_101": {
		"title": "MANUAL: VARIABLES",
		"book": 0,
		"pages": [
			"""[b]What is a variable?[/b]
A variable is a labelled box that stores one value.
Your game reads the box to know what to do - like which hero you are!

Java needs three things to make a box:
  1. its [b]type[/b] - what kind of value goes inside
  2. its [b]name[/b] - the label on the box
  3. its [b]value[/b] - what you put in it""",

			"""[b]The structure of a declaration[/b]

[code]  String   hero   =   "PinkMan"   ;[/code]
[code]  ------   ----   -   ---------   -[/code]
[code]   type    name   |     value     end[/code]
[code]                  |[/code]
[code]            "store this in"[/code]

Read it out loud: [i]"Make a String called hero and store PinkMan in it."[/i]""",

			"""[b]Rules Java is strict about[/b]
- Every statement ends with a semicolon [code];[/code]
- Java is [b]case-sensitive[/b]: [code]String[/code] works, [code]string[/code] does not.
- Names have no spaces: [code]myHero[/code], not [code]my hero[/code]
- Names can't start with a number: [code]hero2[/code] is fine, [code]2hero[/code] is not.

If you break a rule, Byte will tell you which step failed.""",

			"""[b]Try it![/b]
Press [b]E[/b] to open Byte's terminal and type:

[code]String hero = "MaskDude";[/code]

[color=#2e7d32][b]Byte's hint:[/b] the gap ahead is too wide for Ninja Frog. Which hero could cross it? Store their name in [code]hero[/code]![/color]""",
		],
	},
	"data_types": {
		"title": "MANUAL: DATA TYPES",
		"book": 1,
		"pages": [
			"""[b]Every value has a type[/b]
The type tells Java what kind of value a variable holds.

[code]String [/code] text, in double quotes   [code]"PinkMan"[/code]
[code]int    [/code] whole numbers            [code]3[/code]  [code]-12[/code]
[code]double [/code] numbers with decimals    [code]1.5[/code]
[code]boolean[/code] only true or false       [code]true[/code]
[code]char   [/code] one letter, single quotes [code]'A'[/code]""",

			"""[b]Matching the type to the value[/b]
The value must fit the type, or Java refuses it:

[color=#2e7d32]OK[/color]   [code]double speed = 1.5;[/code]
[color=#c0392b]NO[/color]   [code]int speed = 1.5;[/code]   int can't hold decimals
[color=#c0392b]NO[/color]   [code]String hero = PinkMan;[/code]   text needs quotes
[color=#c0392b]NO[/color]   [code]boolean ready = "true";[/code]   no quotes on true/false""",

			"""[b]boolean: the yes-or-no type[/b]
A boolean answers a yes-or-no question. Its name often starts with [b]is[/b] or [b]has[/b]:

[code]boolean isHappy = true;[/code]
[code]boolean hasKey = false;[/code]

Write [code]true[/code] and [code]false[/code] in lowercase, with no quotes.""",

			"""[color=#2e7d32][b]Byte's hint:[/b] a crab guards the tunnel ahead, and your hands are empty!
Do you [i]have[/i] a sword? That's a yes-or-no question...
Try a [b]boolean[/b] called [code]hasSword[/code].[/color]

Once you have it, pick it from your hotbar with [b]1-5[/b] and [b]left-click[/b] to swing.""",
		],
	},
}


static func has(id: String) -> bool:
	return MANUALS.has(id)


static func get_manual(id: String) -> Dictionary:
	return MANUALS.get(id, {})
