# CODE ODYSSEY - Team Overview (everyone reads this first)

## What the game is
A 2D pixel platformer made in **Godot 4.7** (GDScript). The player doesn't fight with code;
they **change the level by typing Java-style variable lines** into the terminal of Byte, a
floating robot companion. Example: `int bridgeLength = 11;` builds an 11-block bridge.
Goal: teach **declaring variables of each basic type** (`String`, `int`, `double`, `boolean`,
`char`) and **changing a variable that already exists** (`name = value;`). About 10-15 minutes.

## Level 1 in one minute
- 7 rooms (0-6). Room 6 is the "Final exam" (2x2 screens, 6 sections) that reuses every variable.
- You start with only Chelzy. Rescuing a hero unlocks them; the next room has an obstacle
  only that hero can pass, so you must switch with `String hero = "Sarah";`.
- Collect **fruit** to progress (rescue flags, crates and the final goal need it).
- Stars (best saved): 0 answers shown = 3 stars, 1 = 2, 2+ = 1.
- Wrong lines: Byte explains. 3 wrong tries = hint + "Show answer" (costs a star).
  5 wrong tries = the line with blanks, e.g. `int bridgeLength = __;`.
- Falling or 0 HP = back to the last checkpoint flag; variables you set stay set.

## How the pieces connect
main menu -> `Level` (level1.tscn) -> `Room`s -> Player + Byte + CodeTerminal + gadgets.
Typing a valid line -> `CommandChecker` validates -> `CodeTerminal` emits `variable_set(name, value)`
-> gadgets (bridge, fan, ...) listen and react, but only if the player is in their room/zone.
Two autoloads (global singletons): `Game` (save, heroes, stars, scene changes, volume) and
`Sound` (music and sound effects).

## The heroes (our team)
Chelzy (wall jump), Sarah (dash), April (double jump), Kervin (sprint), Psalm (shrink: hold
Down to fit through 1-tile gaps). All use stamina. Each hero only has the animations of their
own ability (`tools/make_team_heroes.gd`).

## Who owns what
| Person | Area | File |
|---|---|---|
| Psalm | Byte + code terminal + code gadgets, architecture | Psalm_Byte_and_Terminal.md |
| Kervin | Player, heroes, enemies/traps, items, save | Kervin_Gameplay.md |
| Chelzy | UI + audio | Chelzy_UI_and_Audio.md |
| Sarah | Maps, rooms, world building, level generator | Sarah_Maps_and_World.md |
| April | Documentation, papers, defense prep | April_Documentation.md |

## Everyone must be able to
1. Explain the game in 2 minutes (above).
2. Demo and explain this trace: player types `int bridgeLength = 11;` -> checker accepts ->
   Byte reacts happily -> bridge blocks pop in left to right -> player crosses.
3. Say where to find their own area and who to pass questions to.
