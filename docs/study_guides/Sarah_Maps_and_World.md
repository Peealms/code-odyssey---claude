# Sarah - Maps, Rooms and World Building

## You explain: how Level 1 is laid out, why each room teaches what it does, and how it is built.

### Structure
- `scenes/levels/level1/level1.tscn` = the whole level. `scripts/levels/level.gd` (base for any level):
  respawn, checkpoints, hero unlocks, camera limits, level-complete.
- `Room` (`room.tscn`, `room.gd`): an area with size, title, hint, blanks, answer, background, zone, music;
  counts its fruit; tracks wrong tries.
- Each room is a closed box with a frame, joined by a 2-tile doorway. The camera follows the player.
- Tileset: `resources/tilesets/level1_terrain_tileset.tres` (Pixel Adventure terrain, bevelled blocks).
- Backgrounds: `scrolling_background.gd` (+ `resources/shaders/scroll_tile.gdshader`) and
  `background_fader.gd` (crossfades to the room's color as you enter).

### The rooms
| Room | Size (tiles) | Frame/Ground | Trap | Teaches |
|---|---|---|---|---|
| 0 Wake up | 40x21 | stone/grass | spikes | print + wall jump (Chelzy) |
| 1 Wide gap | 40x32 | wood/orange | saws | `String hero` + dash (Sarah) |
| 2 Bridge | 40x21 | teal/pink | spiked balls | `int` (11 ok, 12 collapses, 5.5 error) + double jump |
| 3 High ledge | 40x32 | stone/grass | falling platforms | `double jumpPower` + sprint (rescues Psalm) |
| 4 Fan shaft | 40x43 | wood/orange | Rock Heads, saw, Spike Heads | `boolean fanOn` + Psalm's vents (1-tile gaps, a saw and Spike Heads to stay tiny under) |
| 5 Three paths | 40x21 | teal/pink | Spike Heads | `char path` (A/B/C) |
| 6 Final exam | 80x42 | stone/orange | everything + fire | change every variable (6 sections) |

Rooms have **floors**: some go bottom-to-top, some top-to-bottom. Rooms of different heights line up by doorway rows.
Fruit per room: 16, 22, 20, 23, 29, 26, then 15/12/12/11/15/20 in the exam sections.
Optional corners (galleries, balconies, shelves) still hold needed fruit but never lead past a puzzle.
Room 4's drop is one way down, so a Rock Head elevator rides back up through its bananas (a fruit you fall past isn't lost).

### Final exam sections
1 High wall `jumpPower = 2.0` | 2 Low tunnel `jumpPower = 1.0` (at 2.0 you hit deadly ceiling spikes), then Psalm shrinks under a wall |
3 Short bridge `bridgeLength = 9` | 4 Fan trap `fanOn = false` | 5 Last path `path = 'C'` |
6 Final gate `System.out.println("I can code!");`

### The generator (be able to explain it)
`tools/build_level1.gd` builds the whole level from **text maps**: one character per tile
(`#` ground, `B` block, `f` fruit, `^` spikes, `x` pit spikes, `w` wall spikes, `L` falling platform,
`a b c` path platforms, `F` fire, `K` checkpoint, `<` `>` doorways). Edit a map, then re-run:
`godot --headless --path . --script res://tools/build_level1.gd` (it overwrites level1.tscn).
`tools/test_level1.gd` plays every room automatically and prints PASS/FAIL checks.

### Design logic
Heroes unlock room by room and the next room's obstacle needs the new hero. Gadgets only react inside
their own room. Full details in `docs/level1_design.md`.

### Likely questions
- Why 7 rooms in this order? (one concept per room, the exam combines them)
- Why a generator? (fast iteration, consistent rooms)
- How do rooms differ from each other? (frame, ground, blocks, background colors, trap type)
- How do you stop players skipping puzzles? (crawlspaces, spike pits, test script)
