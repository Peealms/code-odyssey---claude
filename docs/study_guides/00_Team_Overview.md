# CODE ODYSSEY - Team Overview (everyone reads this first)

## What the game is
A 2D pixel platformer made in **Godot 4.7** (GDScript). The player doesn't fight with code;
they **change the level by typing Java-style variable lines** into the terminal of Byte, a
floating robot companion. Example: `int bridgeLength = 8;` builds an 8-plank bridge.
Goal: teach **declaring variables of each basic type** (`String`, `int`, `double`, `boolean`,
`char`) and **changing a variable that already exists** (`name = value;`). About 15-20 minutes.

## The game in one minute
- **Tutorial** (Pixel Adventure art, one room): Byte teaches moving, the terminal, reading a
  manual, hints and Show answer, and the first line of Java, `System.out.println("Hi");`, which
  opens his gate. Ends with rescuing Sarah.
- **Level 1** (Treasure Hunters art, 5 rooms + a 3-part exam): `String hero`, `int bridgeLength`,
  `double jumpPower`, `boolean anchorUp` (a ship) and `boolean hasSword` (fight a crab), `char path`,
  then the exam changes them again, `System.out.println("I can code!");` opens the way, and
  **Captain Clown Nose** guards the treasure: you dodge each attack by switching to the right
  hero (hold Q) and hit him with the sword while he's dizzy.
- You start with only Chelzy. Rescuing a hero unlocks them; the next room has an obstacle
  only that hero can pass, so you must switch with `hero = "April";`.
- Collect **fruit** (tutorial) or **coins** (Level 1): rescue flags and the goal need all of it.
- Stars (best saved): 0 answers shown = 3 stars, 1 = 2, 2+ = 1.
- Wrong lines: Byte explains. 3 wrong tries = hint + "Show answer" (costs a star).
  5 wrong tries = the line with blanks, e.g. `int bridgeLength = _;`.
- Falling, the sea or 0 HP = back to the last checkpoint flag; variables you set stay set.

## How the pieces connect
main menu -> level select -> `Level` (tutorial.gd / level2.gd) -> `Room`s -> Player + Byte +
CodeTerminal + gadgets.
Typing a valid line -> `CommandChecker` validates -> `CodeTerminal` emits `variable_set(name, value)`
-> gadgets (bridge, ship, path planks, Byte's gate) listen and react, but only if the player is
in their room/zone.
Two autoloads (global singletons): `Game` (save, heroes, stars, scene changes, volume) and
`Sound` (music and sound effects).

## The heroes (our team)
Chelzy (wall jump), Sarah (dash), April (double jump), Kervin (sprint), Psalm (shrink: hold
Down to fit under low beams). All use stamina. Each hero only has the animations of their
own ability (`tools/make_team_heroes.gd`).

## Who owns what
| Person | Area | File |
|---|---|---|
| Psalm | Byte + code terminal + code gadgets + the tutorial's lessons, architecture | Psalm_Byte_and_Terminal.md |
| Kervin | Player, heroes, enemies/traps, items, save | Kervin_Gameplay.md |
| Chelzy | UI + audio | Chelzy_UI_and_Audio.md |
| Sarah | Maps, rooms, world building, level generators | Sarah_Maps_and_World.md |
| April | Documentation, papers, defense prep | April_Documentation.md |

## Everyone must be able to
1. Explain the game in 2 minutes (above).
2. Demo and explain this trace: player types `int bridgeLength = 8;` -> `CommandChecker` accepts
   -> Byte reacts happily -> `variable_set` -> `code_bridge.gd` pops planks in left to right ->
   player crosses.
3. Say where to find their own area and who to pass questions to.
