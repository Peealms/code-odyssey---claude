# Level 1 – Pixel Adventure: Variables & Data Types

Status: **planned** (agreed with Psalm, 2026-10-21). Update this file when the design changes.

## Goal
The player learns to **declare variables of each basic type** and to **change a variable they
already made**. Instead of fighting, the player changes the level by writing variables in
Byte's terminal. About 10–15 minutes.

## Heroes are unlocked room by room
The game starts with **only Ninja Frog**. Clearing a room unlocks the next hero, and the very
next room has an obstacle **only that new hero can pass** – so the player must switch with
`String hero = "...";`.

| Hero | Trait | Unlocked after |
|---|---|---|
| Ninja Frog | Wall jump (stamina) | start |
| Pink Man | Dash (stamina) | Room 0 |
| Mask Dude | Double jump (stamina) | Room 1 |
| Virtual Guy | Sprint (stamina) | Room 2 |

## Rooms

| Room | Teaches | Puzzle code | Hero-only obstacle | Unlocks |
|---|---|---|---|---|
| 0 Wake-up | A statement, `;`, Byte's checks | `System.out.println("Hi");` opens Byte's gate | Wall-jump shaft → **Ninja Frog** | Pink Man |
| 1 Wide gap | Declaration structure, `String` + quotes | `String hero = "PinkMan";` | Gap only the dash crosses → **Pink Man** | Mask Dude |
| 2 Broken bridge | `int` (whole numbers) | `int bridgeLength = 6;` builds 6 blocks over spikes | Step after the bridge → **Mask Dude** double jump | Virtual Guy |
| 3 High ledge | `double` (decimals) | `double jumpPower = 1.5;` (range 1.0–2.0) | Falling platforms → **Virtual Guy** sprint | – |
| 4 Fan shaft | `boolean`, lowercase, no quotes | `boolean fanOn = true;` | Wall-jump climb above the fan → **Ninja Frog** | – |
| 5 Three paths | `char`, single quotes | `char path = 'B';` (clue tells the letter) | Gap at the end of path B → **Pink Man** | – |
| 6 Final | **Changing** a variable (no type) | `jumpPower = 1.0;` – stop hitting the spike ceiling | Mixed: saws + timing | Level complete |

Notes
- Room 2: the sign says how many blocks the gap is. Too few blocks = you fall; `5.5` = Byte
  explains int can't hold decimals.
- Room 6 reuses the `jumpPower` from Room 3 – the lesson is that a variable that already
  exists is changed with `name = value;` (writing `double` again is a redeclaration error).
- The terminal follows Java here from the start: once `hero` is declared (Room 1), switching
  again in Room 2 must be `hero = "MaskDude";`. Byte explains this the first time
  ("hero already exists... leave out the type"), so Room 6 is the *practice* of it, not the
  first sight. (CodeTerminal has an "Allow Redeclare" switch if we ever want to relax this.)

## How it's built (step 1 - done)
- `VariableLibrary` lists every variable; each level's CodeTerminal picks its
  **Allowed Variables**. Gadgets listen to `CodeTerminal.variable_set(name, value)`.
- `Room` (scenes/levels/room.tscn): size, title, hint, blanks, answer.
- `Checkpoint` (scenes/objects/checkpoint.tscn): respawn point + optional **Unlock Hero**.
- `Level` (scripts/levels/level.gd): base script for every level - respawn, checkpoints,
  hero unlocks, HUD, stars. `Game.start_level / finish_level` track answers shown & mistakes.
- jumpPower scales jump **height**: 1.0 = 50 px, 1.5 = 75 px, 2.0 = 100 px.

## Manual chests
| Before | Manual | Book colour |
|---|---|---|
| Room 0 | Variables (exists) | red |
| Room 2 | Numbers: int vs double | blue |
| Room 4 | Booleans & chars | green |
| Room 6 | Changing variables | purple |

## Hints, "Show answer" and stars
- Every wrong line: Byte explains the failed step (as now).
- 3 wrong tries in a room: Byte gives that room's puzzle hint.
- 5 wrong tries: Byte shows the line with blanks, e.g. `int bridgeLength = __;`.
- From 3 wrong tries a **Show answer** option appears. It asks first: *"This costs a star. Show?"*
- Stars when the level is finished (best result is saved):
  - 0 answers shown → 3 stars
  - 1 answer shown → 2 stars
  - 2 or more → 1 star

## Failing
Falling or reaching 0 HP → back to the last **checkpoint flag** with full HP.
Variables already set **stay set**.

## Level complete screen
Stars, fruits collected, time, and mistakes made.

## To build (in order)
1. Systems: per-level variable list in the terminal, reassignment (`name = value;`),
   hint tiers + Show answer + star counting, hero unlocks per room, checkpoints.
2. Gadgets: self-building bridge, jumpPower, fan, A/B/C platforms, spikes/saws that damage,
   falling platforms, Byte's gate.
3. The level map (rooms 0–6), manuals, level-complete screen.
4. Playtest, tune, commit.
