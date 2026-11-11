# Plan: a one-room tutorial and one final level

Written 2026-11-12. This replaces the earlier two-topic cut list.

**Progress:** section 1 (the tutorial) is **done** (2026-11-12, `tools/test_level1.gd` passes
26/26). Sections 2–5 haven't been started.

**Why:** a smaller game is easier to defend, because every one of us has to be able to explain
every part. This plan keeps Level 1's lessons (already designed and tested), moves them into
Treasure Hunters art, and drops conditionals. That removes the rule system and the Level 2
pieces built on it, over 2,000 lines, so the game has **one** code checker to explain instead
of two.

## The new game at a glance

| | Tutorial | Final level |
|---|---|---|
| Art | Pixel Adventure | Treasure Hunters |
| Built from | Level 1's Room 0, as it is now | Level 1's Rooms 1–6, redrawn |
| Teaches | moving, Byte, the terminal, the manuals, hints and Show answer; `System.out.println` | `String`, `int`, `double`, `boolean`, `char`, changing a variable |
| Rooms | 1 | 5 + the final exam |
| Heroes | starts with Chelzy, rescues Sarah at the end | starts with Chelzy and Sarah, rescues April, Kervin and Psalm |
| Id | `level1` | `level2` |

The game now teaches **one topic: variables and data types.** Conditionals, the rule system and
Captain Clown Nose are gone.

**Keep the ids `level1` and `level2`.** Saves, stars and the level select use them. The level
select's `level2` card already shows Treasure Hunters art and unlocks after `level1`. Only the
titles change ("TUTORIAL" and "VARIABLES").

## Before you start

1. **Commit or put away the uncommitted work first.** That's immunity mode (`scripts/dev/`, and
   its `# IMMUNITY` lines in 8 scripts) plus 12 changed `_frames.tres` files.
2. **Work in this order:** tutorial → delete conditionals → build the final level room by
   room → assets → docs. Re-run the builder and its test after each step.
3. **Delete files from Godot's FileSystem dock**, not from Windows Explorer. Godot warns you if
   something still uses the file.

---

## 1. The tutorial (one room, Pixel Adventure)

Room 0 stays as it is: Byte's gate (`println`), the spike corridor, Chelzy's wall-jump shaft,
the fruit gallery, the Variables manual chest (it already has the `println` page) and Sarah's
rescue flag.

### Change `tools/build_level1.gd`
- Keep only `R0`. Delete `R1`–`R5`, `S1`–`S6`, `ROOMS` entries 1–6 and their blocks in `_build()`.
- Close the `>` doorway on `R0`'s right edge. Put the goal `G` beside Sarah's flag `k`, with
  `rooms` set to Room 0 so all its fruit is needed first. (Done by widening `R0` by 4 tiles,
  so the trophy has room next to Sarah.)
- `level_title` → `"TUTORIAL"`. `starting_heroes` stays `["chelzy"]`.
- `allowed` variables → `["hero"]`. `println` needs none, and `hero` lets the player try
  switching to Sarah after the rescue.
- Keep only Room 0's potion spot.
- Remove the `SCENES` entries and helpers nothing uses any more: `bridge`, `fan`, `path`,
  `falling`, `saw`, `rock_head`, `spike_head`, `ball`, `fire`, `fruit_door`, and `_saw`,
  `_ball`, `_rock`, `_spike_head`, `_fruit_door`.
- `tools/test_level1.gd`: keep the Room 0 checks. The checks for Rooms 1–6 move to the final
  level's test (see 2).

### Add
- **An opening cutscene:** who Byte is and why you have to code.
- **A manual cutscene the first time the chest opens.** Reuse what the rescue cutscene already
  does in `scripts/ui/hero_cutscene.gd` (pause, camera zoom, Byte talks): show the book, how to
  turn pages, how to reopen it from the hotbar, and point at the `println` example.
- **Byte lines on the gate that teach hints and Show answer:** what happens after 3 and 5 wrong
  tries, and that Show answer costs a star.
- The ending already exists: Sarah's rescue cutscene, then the level-complete screen.

---

## 2. The final level (Level 1's lessons in Treasure Hunters)

**Same code, same order, same heroes.** Only the art and the maps change.

### Rooms

| Room | Code (as in Level 1) | Hero obstacle | Level 1 had | Treasure Hunters version | Rescues |
|---|---|---|---|---|---|
| 0 The wide gap | `String hero = "Sarah";` | Sarah's dash | saws | seashells shooting pearls | April |
| 1 The broken bridge | `int bridgeLength = 11;`, `hero = "April";` | April's double jump | crate bridge, spiked balls | plank bridge, totem heads | Kervin |
| 2 The high ledge | `double jumpPower = 2.0;` | Kervin's sprint, then April | falling platforms | falling planks | Psalm |
| 3 The ship (was the fan shaft) | a `boolean` that makes the ship sail | Psalm's crawlspace | fan, 4 Rock Heads, a saw, Spike Heads | the ship sails across the water when it's true; low beams only tiny Psalm fits under; crabs | – |
| 4 Three paths | `char path = 'B';` | Sarah's dash | A/B/C platforms, Spike Heads | A/B/C planks, cannons | – |
| 5 Final exam | every variable again, then `println("I can code!")` | all five | every trap + fire | all of the above, crabs, Pink Star | level complete |

### Rules for the conversion
- **Tiles are 32 px now** (one screen = 20 × 11 tiles, against Level 1's 40 × 22). Every map
  has to be redrawn.
- **Keep the bridge's numbers.** `code_bridge.gd` builds 16 px blocks, so give it a 16 px piece
  of plank art and the gap can stay 11 blocks. The lesson stays word for word.
- **`jumpPower` is in pixels** (1.0 = 50 px, 2.0 = 100 px, about 3 tiles), so the code doesn't
  change. Only the ledge heights in the maps do.
- **Psalm's 1-tile gaps become beams.** At 32 px a one-tile gap is taller than Psalm at full
  size. Use Level 2's `_beam` (a 14 px plank) so only tiny Psalm fits under it.
- **Pits become water.** `water.gd`'s `"fixed"` mode already sends you back to the checkpoint
  ("SPLASH!"). Wall spikes stay Pixel Adventure spikes, because Treasure Hunters has none
  (Level 2 does the same).
- **Fruit becomes gold coins.** `coin.gd` is already in the `"fruit"` group, so rooms and the
  HUD count coins the same way (set the HUD's `item_word` to `"COINS"`).
- **Manuals don't carry over between levels** (nothing saves them), so the final level needs
  its own chests: Variables (Room 0), Numbers (Room 1), Booleans & chars (Room 3) and
  Changing variables (the exam).
- **Starting heroes:** set `starting_heroes` to `["chelzy", "sarah"]`. `level.gd` overwrites the
  unlocked heroes with this list. Level 2's builder gives all five, so change it.
- **Don't pre-declare `hero`:** remove `start_declared`. Room 0 is where the player declares it.

### Gadgets: new art, same code
These gadgets hard-code Pixel Adventure art. Give each an `@export` for its art (or a second
`.tscn`), so the tutorial keeps Pixel Adventure and the final level uses Treasure Hunters:

| Gadget | Pixel Adventure art now | Treasure Hunters art |
|---|---|---|
| `scripts/gadgets/byte_gate.gd` | `traps/blocks` | wooden door or crates (`objects/ship_decorations/door`) |
| `scripts/gadgets/code_bridge.gd` | crate tile from `terrain_16x16.png` | 16 px piece of `ship_platforms_32x32.png` |
| `scenes/gadgets/path_platform.tscn` | `traps/platforms` | planks with A/B/C |
| `scenes/gadgets/falling_platform.tscn` | `traps/falling_platforms` | planks |
| `scenes/objects/checkpoint.tscn`, `scenes/objects/end_goal.tscn` | `objects/checkpoints` | `objects/flag` |
| `scripts/gadgets/fruit_door.gd` | fruit + `objects/boxes` | coins + crates or a door |

### New: the ship gadget
Level 2's `ship.gd` runs on rules, tide and wind, so it's deleted. Write a small
**`scripts/gadgets/code_ship.gd`** that extends `CodeGadget`, like the bridge and the fan do.
When its boolean becomes `true`, it sails from A to B carrying the player. Use the
`merchant_ship` art and `water.gd` in `"fixed"` mode.

Suggested name: `boolean anchorUp = true;` (the exam: `anchorUp = false;` stops it before the
spikes). Any name works, as long as the lesson stays "a boolean switches a machine on or off".

The exam's Rock Head elevator becomes a moving plank. Either cut `block_head.gd` down to its
travel-and-wait part with plank art, or draw the exam so it doesn't need a lift.

### Rewrite `tools/build_level2.gd`
- **Keep its Treasure Hunters world code:** `_read_maps`, `_place_rooms`, `_make_tileset`
  (island style only), `_paint`, `_shape`, `_beam`, `_water`, `_shooter`, `_enemy`, `_sign`
  and the small helpers.
- **Delete its rule code:** `_runner`, `_exit_door`, `_door`, `_tide`, `_wind`, `_ship`,
  `_lookout`, `_crew`, `_lanterns`, the captain block and the `RulePanel`.
- **Add Level 1's gadget placement** (gate, bridge, paths, falling planks, coin doors, rescue
  flags with `unlock_hero`), the new ship and the six maps redrawn at 32 px.
- Use the plain `scripts/levels/level.gd` as the level script, like Level 1. `level2.gd` only
  held rule and captain code.
- `allowed` variables → `["hero", "bridgeLength", "jumpPower", "anchorUp", "path"]`.
- `tools/test_level2.gd`: rewrite it from `test_level1.gd`'s Room 1–6 checks.

---

## 3. Delete: conditionals and the rule system

| File | Lines | What it was |
|---|---|---|
| `scripts/terminal/rule_checker.gd` | 551 | reads and checks `if` rules |
| `scripts/terminal/rules.gd` | 160 | runs and prints a rule |
| `scripts/levels/rule_runner.gd` | 220 | a room's rule |
| `scripts/ui/rule_panel.gd` | 133 | the rule shown on screen |
| `scripts/levels/reading_source.gd` | 30 | gives readings like `tide` |
| `scripts/gadgets/rule_machine.gd` | 42 | base for rule-driven machines |
| `scripts/level2/captain.gd` | 425 | the boss |
| `scripts/level2/ship.gd` | 182 | rule-driven ship (replaced by `code_ship.gd`) |
| `scripts/level2/code_door.gd`, `pirate_door.gd` | 213 | rule-driven doors |
| `scripts/level2/tide.gd`, `wind.gd` | 119 | readings |
| `scripts/level2/lookout.gd`, `crew.gd`, `lanterns.gd` | 273 | Rooms 4–5 |
| `scripts/level2/level2.gd` | 75 | rule and captain hooks |
| `tools/test_rules.gd` | 198 | rule checker tests |

**Keep and reuse:** `scripts/level2/background.gd`, `coin.gd`, `shooter.gd`, `water.gd` (delete
its `"tide"` and `"flood"` modes) and `scripts/enemies/crabby.gd`.

**Pixel Adventure traps nobody uses any more** (the tutorial only has spikes):
`scripts/gadgets/code_fan.gd`, `saw.gd`, `spiked_ball.gd`, `fire_trap.gd`, `trampoline.gd`,
`block_head.gd` (unless you reuse it for the plank lift), and their scenes in `scenes/gadgets/`
(`code_fan`, `saw`, `spiked_ball`, `fire_trap`, `trampoline`, `rock_head`, `spike_head`). Keep
`hazard.gd`, because spikes use it.

### Change
- **`scripts/terminal/command_checker.gd`**: remove the `if (...)` path that hands lines to
  `RuleChecker`, plus `allow_bugs`, `in_rule` and the "reading" / "machine" checks.
- **`scripts/terminal/code_terminal.gd`** (about 50 rule lines):
  - the room greeting for rule runners and `offer_start_rule`
  - `_values_with_readings` (use plain `values`)
  - installing a rule ("Rule saved!")
  - the captain's-rule failure message
- **`scripts/levels/room.gd`**: remove `rule_runners()` and `player_runner()`.
- **`scripts/terminal/variable_library.gd`**:
  - remove Level 2's variables: `key`, `tide`, `wind`, `word`, `awake`, `move`, `distance`,
    `coins`, `coinsLeft`, `leftDoorOpen`, `rightDoorOpen`, `doorOpen`, `gateOpen`, `sails`,
    `lightsOn`
  - remove `fanOn` (replaced by the ship's boolean)
  - remove the `"reading"` / `"machine"` kinds
  - keep `anchorUp` as a plain boolean
- **`scripts/manuals/manual_library.gd`** and the enum in **`scripts/objects/manual_chest.gd`**:
  remove `if_else`, `comparing`, `else_if`, `strings_booleans` and `fixing_bugs`. In
  `booleans_chars`, change the fan example to the ship.
- **`scripts/dev/immunity.gd`**: it calls `terminal._values_with_readings()` and saves rules into
  machines when skipping rooms. Change those lines to plain values.
- **`scripts/autoload/sound.gd`**: remove `rock_slam`, `spike_slam`, `fire`, `fan_loop`,
  `saw_loop` and `trampoline`.

### Clean-up from before (still applies)
- **Test room:** delete `scenes/levels/test/test_room.tscn`, `scripts/levels/test_room.gd`, the
  `data_types` manual and the `speed` variable (also in `code_terminal.gd`'s default
  `allowed_variables` and its `"speed":` case).
- **`scripts/ui/level_select.gd`:** rename the two cards, and remove the `level3` / `level4`
  entries and `P3` / `P4`. This has to happen before deleting those asset folders.
- **`scripts/autoload/game.gd`:** delete `OLD_HERO_IDS` and its 3 uses.

---

## 4. Assets

**Whole folders**
- `assets/level3_kings_and_pigs/`, `assets/level4_pirate_bomb/` (after the level select change)
- `ASSETS CODE ODYSSEY/`: the original downloads. Check you still have them somewhere else first.
- `assets/shared/heroes/mask_dude`, `ninja_frog`, `pink_man`, `virtual_guy`: the old heroes

**Pixel Adventure** (`assets/level1_pixel_adventure/traps/`): everything except `spikes` and
`blocks` (the tutorial's spikes and gate). That's `fan`, `platforms`, `falling_platforms`,
`rock_head`, `spike_head`, `saw`, `spiked_ball`, `fire`, `trampoline`, `arrow` and
`sand_mud_ice`. Delete `falling_platforms` and `platforms` only after their gadgets have
Treasure Hunters art.

**Treasure Hunters** (`assets/level2_treasure_hunters/`)
- `characters/captain_clown_nose`: the boss is gone
- `objects/ship_decorations/candle`, `candle_light`: the lanterns
- `tiles/ship_terrain_and_backwall_32x32.png`: only if you don't build ship-interior rooms
- Never used: `objects/ship_helm`, `backgrounds/front_palm_tree_top`,
  `backgrounds/palm_trees_animated`, `backgrounds/water_reflect`, and from `collectibles/`:
  `big_map`, `small_map_1`–`4`, `map_effect`, `blue_diamond`, `green_diamond`, `red_diamond`,
  `diamond_effect`, `golden_skull`, `skull_effect`, `green_bottle`, `blue_potion`, `silver_coin`
- `_reference/`: the artist's example scenes (also in Kings and Pigs, which goes anyway)
- **Keep** `enemies/crabby`, `pink_star`, `fierce_tooth`, `traps/seashell`, `totem_heads`,
  `cannon`, `objects/flag`, `merchant_ship`, `chest` and the rest of `ship_decorations`:
  they're the final level's stand-ins

**Shared** (`assets/shared/`): `fx/dust_particles`, `ui/level_numbers`, `ui/speech_bubbles` are
never used. Optional: `team/small` (`tools/make_team_sprites.gd` writes it, but the game never
loads it).

---

## 5. Docs to update afterwards

- `docs/level1_design.md`: the one-room tutorial and its cutscenes
- `docs/level2_design.md`: rewrite it as the final level. Level 1's room design moves here, with
  the Treasure Hunters stand-ins
- `assets/README.md`: two packs, the new folder list, credits (Pixel Frog for Pixel Adventure
  and Treasure Hunters)
- `docs/study_guides/`: each guide should only describe code that still exists
- `docs/manuscript/Code_Odyssey_Manuscript.docx`: objectives, scope and limitations (one topic,
  variables and data types), and the level descriptions

## Your calls

- **The ship's boolean name:** `anchorUp` is only a suggestion.
- **`hasSword`:** Level 2 let you type `boolean hasSword = true;` to fight crabs. The crabs can
  just be avoided, so either drop it or keep it as a second boolean.
- **Immunity mode:** I'd keep it. It only runs from the editor, and it lets you jump straight
  to any room during the defense. Whoever demos must be able to explain it.

## Defense check, once it's all done

Everyone should be able to trace these without notes:
1. **Typing a line:** `code_terminal.gd` → `command_checker.gd` → the `variable_set` signal →
   a gadget reacts (`code_bridge.gd`, `code_ship.gd`).
2. **Building a level:** a text map in `tools/build_level2.gd` → tiles, gadgets and rooms →
   the saved `.tscn`.
3. **Rescuing a hero:** coins → the rescue flag in `checkpoint.gd` → `level.gd` plays
   `hero_cutscene.gd` → the hero is unlocked and saved by `game.gd`.
4. **Opening a chest:** `manual_chest.gd` → `chest_window.gd` → the book in `manual_reader.gd`.
5. **Finishing a level:** `end_goal.gd` (`reached`) → `level.gd` → `Game.finish_level` → stars →
   `level_complete.gd`.
