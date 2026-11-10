class_name ManualLibrary
extends RefCounted
## Every manual a chest can hold. Pick one in a Chest's "Manual Id" in the Inspector.
## In the game a manual is a book item ("manual_<id>"): take it from a chest, hold it, left-click to read.
##
## Each manual has a title, a book cover colour and a list of pages.
##   book   0 red, 1 blue, 2 green, 3 purple, 4 orange  (see tools/make_item_icons.gd)
## Pages use BBCode:
##   [b]bold[/b]   [code]String hero = "Sarah";[/code]   [color=#c0392b]red[/color]
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

[code]  String   hero   =   "Sarah"   ;[/code]
[code]  ------   ----   -   -------   -[/code]
[code]   type    name   |    value    end[/code]
[code]                  |[/code]
[code]            "store this in"[/code]

Read it out loud: [i]"Make a String called hero and store Sarah in it."[/i]""",

			"""[b]Rules Java is strict about[/b]
- Every statement ends with a semicolon [code];[/code]
- Java is [b]case-sensitive[/b]: [code]String[/code] works, [code]string[/code] does not.
- Names have no spaces: [code]myHero[/code], not [code]my hero[/code]
- Names can't start with a number: [code]hero2[/code] is fine, [code]2hero[/code] is not.

If you break a rule, Byte will tell you which step failed.""",

			"""[b]Try it![/b]
Press [b]E[/b] to open Byte's terminal. Your first line of Java prints a message:

[code]System.out.println("Hello Byte");[/code]

[color=#2e7d32][b]Byte's hint:[/b] my gate opens when I hear you say something! Then climb the narrow shaft - only Chelzy can wall-jump.
Later, when a gap is too wide, rescue a new hero and store their name in a [b]String[/b] called [code]hero[/code].[/color]""",
		],
	},
	"data_types": {
		"title": "MANUAL: DATA TYPES",
		"book": 1,
		"pages": [
			"""[b]Every value has a type[/b]
The type tells Java what kind of value a variable holds.

[code]String [/code] text, in double quotes   [code]"Sarah"[/code]
[code]int    [/code] whole numbers            [code]3[/code]  [code]-12[/code]
[code]double [/code] numbers with decimals    [code]1.5[/code]
[code]boolean[/code] only true or false       [code]true[/code]
[code]char   [/code] one letter, single quotes [code]'A'[/code]""",

			"""[b]Matching the type to the value[/b]
The value must fit the type, or Java refuses it:

[color=#2e7d32]OK[/color]   [code]double speed = 1.5;[/code]
[color=#c0392b]NO[/color]   [code]int speed = 1.5;[/code]   int can't hold decimals
[color=#c0392b]NO[/color]   [code]String hero = Sarah;[/code]   text needs quotes
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
	"numbers": {
		"title": "MANUAL: NUMBERS",
		"book": 4,
		"pages": [
			"""[b]Two kinds of numbers[/b]
Java keeps whole numbers and decimal numbers apart:

[code]int   [/code] whole numbers only     [code]0[/code]  [code]6[/code]  [code]-3[/code]  [code]100[/code]
[code]double[/code] numbers with a point   [code]1.5[/code]  [code]0.25[/code]  [code]2.0[/code]

Use [b]int[/b] for things you [i]count[/i] (blocks, lives, coins).
Use [b]double[/b] for things you [i]measure[/i] (speed, height, power).""",

			"""[b]Writing numbers[/b]
- No quotes: [code]6[/code] is a number, [code]"6"[/code] is text.
- No commas: [code]1000[/code], not [code]1,000[/code]
- An int can't hold a decimal:

[color=#2e7d32]OK[/color]   [code]int bridgeLength = 10;[/code]
[color=#c0392b]NO[/color]   [code]int bridgeLength = 9.5;[/code]
[color=#2e7d32]OK[/color]   [code]double jumpPower = 1.5;[/code]""",

			"""[color=#2e7d32][b]Byte's hint:[/b] the bridge ahead is broken. It builds one block for every 1 in its number.
Count how many blocks wide the gap is, and store that [b]whole number[/b] in an [b]int[/b] called [code]bridgeLength[/code].[/color]

Then the step on the other side is too high for one jump. Who can jump twice?
Remember: [code]hero[/code] already exists, so change it [i]without[/i] the type:
[code]hero = "...";[/code]""",
		],
	},
	"booleans_chars": {
		"title": "MANUAL: BOOLEANS & CHARS",
		"book": 2,
		"pages": [
			"""[b]boolean: on or off[/b]
A boolean has only two values: [code]true[/code] and [code]false[/code].
It's perfect for switches, doors and yes-or-no questions.

[code]boolean lightOn = true;[/code]
[code]boolean doorLocked = false;[/code]

Lowercase, and [b]no quotes[/b] - [code]"true"[/code] would be text, not a boolean.""",

			"""[b]char: one single character[/b]
A char holds exactly [b]one[/b] letter, digit or symbol, in [b]single quotes[/b]:

[code]char grade = 'A';[/code]
[code]char key = '7';[/code]

[color=#c0392b]NO[/color]   [code]char grade = "A";[/code]   double quotes make a String
[color=#c0392b]NO[/color]   [code]char grade = 'AB';[/code]  only one character fits""",

			"""[color=#2e7d32][b]Byte's hint:[/b] the fan below is switched off. Switch it on with a [b]boolean[/b] called [code]fanOn[/code], then ride the air up and step off onto the ledge.

Later, three paths cross a chasm and only one can hold you. Choose it with a [b]char[/b] called [code]path[/code]. Read the sign for the letter![/color]""",
		],
	},
	"changing_variables": {
		"title": "MANUAL: CHANGING VARIABLES",
		"book": 3,
		"pages": [
			"""[b]Making vs changing[/b]
You make (declare) a variable [b]once[/b], with its type:

[code]double jumpPower = 1.5;[/code]

After that, Java already knows its type. To change it, write just the name:

[code]jumpPower = 1.0;[/code]""",

			"""[b]Why not write the type again?[/b]
Writing the type means "make a [i]new[/i] variable". Java refuses to make two variables with the same name:

[color=#c0392b]NO[/color]   [code]double jumpPower = 1.0;[/code]   jumpPower already exists
[color=#2e7d32]OK[/color]   [code]jumpPower = 1.0;[/code]

The new value must still fit the type: [code]jumpPower = "low";[/code] won't work.""",

			"""[color=#2e7d32][b]Byte's hint:[/b] the tunnel ahead has spikes on the ceiling. With your big jumps from before, you'll hit your head!
Change [code]jumpPower[/code] back to a smaller number - and remember, it already exists.[/color]""",
		],
	},

	# ---------------- Level 2: conditionals ----------------
	"if_else": {
		"title": "MANUAL: IF AND ELSE",
		"book": 0,
		"pages": [
			"""[b]Programs make decisions[/b]
An [b]if[/b] asks a yes-or-no question - the [b]condition[/b] - and runs its code only when the answer is [b]true[/b]:

[code]if (key == 7) {[/code]
[code]    rightDoorOpen = true;[/code]
[code]}[/code]

The condition goes in ( ). The code it runs goes in { }.""",

			"""[b]else: otherwise[/b]
[b]else[/b] runs when the condition is [b]false[/b]. Exactly one of the two parts runs - never both:

[code]if (key == 7) {[/code]
[code]    rightDoorOpen = true;[/code]
[code]} else {[/code]
[code]    leftDoorOpen = true;[/code]
[code]}[/code]""",

			"""[b]= stores, == asks[/b]
[code]key = 7;[/code]    store 7 in key
[code]key == 7[/code]    is key 7? true or false

[color=#c0392b]NO[/color]   [code]if (key = 7)[/code]   that stores, it doesn't ask
[color=#2e7d32]OK[/color]   [code]if (key == 7)[/code]""",

			"""[color=#2e7d32][b]Byte's hint:[/b] the captain's two doors follow the rule on the sign. You can't change the captain's rule - but you can change [b]key[/b]!
Make an [b]int[/b] called [code]key[/code] and see which door opens. Then try another number... there are coins behind both doors.
Stand in front of an open door and press [b]W[/b] to go in.[/color]""",
		],
	},
	"comparing": {
		"title": "MANUAL: COMPARING VALUES",
		"book": 4,
		"pages": [
			"""[b]Six ways to compare[/b]
[code]==[/code]  is equal to          [code]tide == 4[/code]
[code]!=[/code]  is not equal to      [code]tide != 0[/code]
[code]> [/code]  is greater than      [code]tide > 3[/code]
[code]< [/code]  is less than         [code]tide < 2[/code]
[code]>=[/code]  greater than or equal [code]tide >= 4[/code]
[code]<=[/code]  less than or equal    [code]tide <= 1[/code]
Each one gives [b]true[/b] or [b]false[/b].""",

			"""[b]Read them out loud[/b]
[code]tide >= 4[/code]  "the tide is 4 [i]or more[/i]"
[code]tide > 4[/code]   "the tide is [i]more than[/i] 4" (5, not 4!)

The = always comes [b]last[/b]: [code]>=[/code] and [code]<=[/code], never [code]=>[/code].""",

			"""[b]Rules, not orders[/b]
The island's machines run by themselves, so they don't take orders like [code]anchorUp = true;[/code]
Give them a [b]rule[/b] instead. The rule runs again [b]every time[/b] the tide changes - like real game code, which checks its ifs over and over.""",

			"""[color=#2e7d32][b]Byte's hint:[/b] the reef needs a tide of 4 or more. Write a rule for the ship's anchor:
[code]if (tide ... ) { anchorUp = true; }[/code]
Then get on board and wait - the rule waits for the tide for you.[/color]""",
		],
	},
	"else_if": {
		"title": "MANUAL: ELSE IF",
		"book": 2,
		"pages": [
			"""[b]More than two choices[/b]
[b]else if[/b] checks another condition when the first one was false:

[code]if (wind >= 7) {[/code]
[code]    sails = 0;[/code]
[code]} else if (wind >= 3) {[/code]
[code]    sails = 1;[/code]
[code]} else {[/code]
[code]    sails = 2;[/code]
[code]}[/code]""",

			"""[b]Java checks from the top[/b]
It tries each condition in order and runs the [b]first[/b] one that is true - then skips the rest.

So the order matters! With [code]wind >= 3[/code] first, a wind of 8 runs that part, and [code]wind >= 7[/code] is never even checked.
[b]Put the biggest number first.[/b]""",

			"""[b]Don't forget the else[/b]
If no condition is true and there's no [b]else[/b], nothing runs at all - and the sails stay however they were.

[color=#2e7d32][b]Byte's hint:[/b] read the sailor's table at the dock and turn it into one rule with if, else if and else. Then get on board![/color]""",
		],
	},
	"strings_booleans": {
		"title": "MANUAL: STRINGS, CHARS & BOOLEANS",
		"book": 1,
		"pages": [
			"""[b]Strings use .equals[/b]
Compare text with [b].equals[/b], not ==:

[color=#2e7d32]OK[/color]   [code]if (word.equals("ahoy"))[/code]
[color=#c0392b]NO[/color]   [code]if (word == "ahoy")[/code]

== asks whether both are the very same String [i]object[/i], so it can say false even when every letter matches.
equals checks every letter - capitals too.""",

			"""[b]chars use ==[/b]
A char isn't an object, so == is right for it:

[code]if (move == 'C')[/code]   single quotes!

[b]booleans are already true or false[/b]
[code]if (awake == true)[/code] works, but [code]if (awake)[/code] says the same thing.""",

			"""[color=#2e7d32][b]Byte's hint:[/b] the lookout shouts a word every few seconds. The gate may only be open when he shouts [b]ahoy[/b] - any other word and he fires the cannon!
Later, in the hold, the crew wakes up now and then. Lights off when they're [b]awake[/b]...[/color]""",
		],
	},
	"fixing_bugs": {
		"title": "MANUAL: FIXING BUGS",
		"book": 3,
		"pages": [
			"""[b]The captain's five bugs[/b]
1. [code]if (tide = 0)[/code]  = stores. Compare with ==.
2. [code]if (tide >= 4);[/code]  the ; ends the if - the { } after it always runs.
3. [code]else if[/code]s in the wrong order - a smaller number first hides the bigger one.""",

			"""4. [code]word.equals("Treasure")[/code]  equals checks capitals too.
5. An if with no else never undoes its change.

Opening the terminal in each part of the cove puts the captain's rule in for you. Find the bug, fix it, press Enter.""",

			"""[color=#2e7d32][b]Byte's hint:[/b] at the end the captain fights you himself - and I'll have to hide! Leave me a rule that picks the right hero for each of his moves:
'C' charge - who can jump twice?
'T' thrown sword - who can shrink under it?
'S' swing - who can dash away?[/color]""",
		],
	},
}


static func has(id: String) -> bool:
	return MANUALS.has(id)


static func get_manual(id: String) -> Dictionary:
	return MANUALS.get(id, {})
