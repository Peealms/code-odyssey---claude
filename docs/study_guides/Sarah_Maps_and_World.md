# Sarah - Maps, Rooms and World Building

## You explain: how both levels are laid out, why each room teaches what it does, and how they are built.

### Structure
- `scripts/levels/level.gd` is the base for both levels: respawn, checkpoints, hero unlocks,
  camera limits, level complete. The tutorial's script is `tutorial.gd`, Level 1's is `level2.gd`.
- `Room` (`room.tscn`, `room.gd`): an area with size, title, hint, blanks, answer, background,
  zone, music; counts its fruit or coins; tracks wrong tries.
- **Tutorial** (`scenes/levels/level1/level1.tscn`, built by `tools/build_level1.gd`): one
  44 x 21 room of 16 px Pixel Adventure tiles (`resources/tilesets/level1_terrain_tileset.tres`),
  a closed box with a frame; `background_fader.gd` + `scrolling_background.gd` draw the sky.
- **Level 1** (`scenes/levels/level2/level2.tscn`, built by `tools/build_level2.gd`): 8 rooms of
  32 px Treasure Hunters tiles in a row, joined by doorways, solid rock around them; the tileset
  (`resources/tilesets/level2_tileset.tres`) is made by the builder; `level2/background.gd` draws
  the sky, sea and drifting clouds.

### The rooms
| Level | Room | Teaches | Hero obstacle |
|---|---|---|---|
| Tutorial | Wake up | the terminal, manuals, `println` | Chelzy's wall-jump shaft; rescues Sarah |
| Level 1 | 0 The wide gap | `String hero` | Chelzy's shaft, then Sarah's dash in a crawlspace; rescues April |
| | 1 The broken bridge | `int bridgeLength = 8` (9 collapses, 5.5 error) | April's double jump to planks 3 tiles up over water; rescues Kervin |
| | 2 The high ledge | `double jumpPower = 2.0` | Kervin's sprint over falling planks, April's double jump to planks 4 tiles up; rescues Psalm |
| | 3 The ship | `boolean anchorUp = true`, `boolean hasSword = true` | tiny Psalm under beams, the ship, a crab to fight, Chelzy's shaft |
| | 4 Three paths | `char path = 'B'` | Kervin's sprint over falling planks |
| | Exam 1 The low cave | `jumpPower = 1.0` (ceiling spikes) | tiny Psalm under a beam, Kervin's falling floor |
| | Exam 2 The low bridge | `bridgeLength = 6`, `path = 'C'` | Chelzy's shaft |
| | Exam 3 The treasure | `anchorUp = true`, `println("I can code!")` | Byte's gate, then Captain Clown Nose's arena (switch heroes to dodge him) |

Coins per Level 1 room: 7, 9, 7, 5, 5, then 3 / 5 / 3 in the exam. The tutorial has 16 fruit.

### The generators (be able to explain them)
Both builders read **text maps**: one character per tile. Level 1's legend: `#` ground, `=`
plank, `c` coin, `^` spikes (20 damage), `x` / `V` big floor / ceiling spikes (50 damage), `~`
water, `_` beam, `L` falling plank, `A B C` path planks, `K` checkpoint, `h` chest, `p` potion,
`<` `>` doorways; any other letter is an anchor the room's code puts something on (`S`/`Z` the
ship's two docks, `q` the bridge, `g` the gate, `a` the arena's edge, `X` the captain, `G` the
treasure, `k` a rescue flag, `e` a crab). Edit a map,
then re-run, e.g. `godot --headless --path . --script res://tools/build_level2.gd` (it
overwrites level2.tscn). `tools/test_level1.gd` and `tools/test_level2.gd` play every room
automatically and print PASS/FAIL checks.

### Design logic
Heroes unlock room by room and the next room's obstacle needs the new hero. Gadgets only react
inside their own room. Full details in `docs/level1_design.md` and `docs/level2_design.md`.

### Likely questions
- Why these rooms in this order? (one concept per room, the exam combines them)
- Why a generator? (fast iteration, consistent rooms)
- Why 32 px tiles in Level 1? (Treasure Hunters' art size; the numbers in the puzzles follow it)
- How do you stop players skipping puzzles? (crawlspaces, planks with no wall near them, tall shafts, beams, test scripts)
