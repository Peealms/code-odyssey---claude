# Kervin - Player, Heroes, Enemies, Traps, Items and Save

## You explain: everything the player controls and everything that can hurt or help them.

### Player (`scripts/player/player.gd`)
- `CharacterBody2D`. Run speed 130, gravity 900, jump velocity -300, max fall 380.
- Feel helpers: **coyote time** (0.1 s jump after leaving a ledge), **jump buffer** (0.12 s),
  **variable jump height** (release early = shorter, cut 0.45), air control 0.75,
  **step-up** onto lips up to 2 px (so a sinking falling plank can't stick you on a corner).
- Health 100; a hit gives 1 s blinking invulnerability. Stamina 100, regen 40/s after 0.6 s delay;
  hitting 0 = "exhausted" until full.
- `jump_power` (set by the code `jumpPower`) scales jump height: 1.0 = 50 px, 1.5 = 75 px, 2.0 = 100 px.
- Inventory: 5 slots (hotbar). The sword (`boolean hasSword = true;` in Level 1; Room 3's crab
  makes you get it): 10 damage, windup 0.06 s, swing 0.14 s, cooldown 0.35 s. Tiny Psalm can't swing.
- Signals: health_changed, stamina_changed, hero_changed, inventory_changed, died.

### Heroes and costs
| Hero | Trait | Notes |
|---|---|---|
| Chelzy | Wall jump / wall slide | 15 stamina per wall jump, grip drains 15/s |
| Sarah | Dash | 35 stamina, 0.3 s at 300 px/s = 90 px, cooldown 0.5 s |
| April | Double jump | 35 stamina; the double jump ignores jumpPower (+50 px) |
| Kervin | Sprint (hold Shift) | x1.9 speed, drains 30/s |
| Psalm | Shrink (hold Down) | hitbox 16x24 -> 10x12 fits under a beam; 0.6x speed; drains 20/s, but not while a low ceiling keeps him small |
Unlock order: Sarah at the end of the tutorial; in Level 1, April after Room 0, Kervin after
Room 1, Psalm after Room 2. Each hero has jobs in Level 1: Chelzy climbs three shafts, Kervin
sprints over three falling floors, April reaches two sets of high planks, Psalm crawls under
two sets of beams, Sarah dashes one gap - and each dodges one of the boss's attacks.

### Hazards, enemies, traps (`scripts/gadgets/`, `scripts/enemies/`, `scripts/level2/`)
- `hazard.gd` is the damage base. Spikes (`spikes.gd`) do 20 damage; Level 1's big floor and
  ceiling spikes do 50. Spikes only hurt - at 0 HP you're back at the last checkpoint.
- Shooters (`shooter.gd`): a totem head or seashell that fires every few seconds; the shots are hazards.
- Water (`water.gd`): falling in = "SPLASH!" and back to the checkpoint.
- Falling planks (`falling_platform.gd`): shake for `fall_delay`, drop, come back after 2 s.
  The delay is 0.14 s, so only Kervin's sprint gets across.
- Enemies: Crabby and Pink Star, the same script (`crabby.gd`) with other art. They patrol and
  hurt on touch (20); the sword takes 3 hits to beat one. The player can't walk through them,
  so a crab in a crawlspace (Room 3) has to be fought.
- **The boss, Captain Clown Nose** (`scripts/level2/captain.gd`): picks CHARGE (far), THROW
  (middle) or SWING (close) by distance, shouts it 1.2 s early, and can only be hurt while he's
  open after an attack (60 HP = 6 sword hits; his hits do 25). April jumps the charge, tiny
  Psalm ducks the thrown sword, Sarah dashes from the swing.

### Objects (`scripts/objects/`, `scripts/level2/coin.gd`)
- Fruit (tutorial) and coins (Level 1) count toward rescues and the goal. Red health potion
  (+30 HP, stays put at full HP). Checkpoint (respawn + optional hero rescue). End goal: the
  trophy (tutorial) or the treasure chest (Level 1). Manual chest.

### `Game` autoload (`scripts/autoload/game.gd`)
- Saves to `user://save.cfg` (progress, unlocked heroes, best stars) and `user://settings.cfg` (volume, fullscreen).
- `start_level`, `finish_level` (mistakes, answers shown, time), `stars_earned`, `change_scene` with fade.

### Anti-skip design (be ready to defend)
Hero-only obstacles sit in 1-tile crawlspaces (no jumping), April's planks float with no wall
near them (nothing for Chelzy to climb), shafts are taller than anyone but Chelzy can climb,
dash gaps are too wide to jump, falling floors need the sprint, and beams stop everyone but
tiny Psalm. `tools/test_level2.gd` tries every obstacle with the wrong heroes.

### Likely questions
- Why do heroes cost stamina? (balance, prevents spamming)
- How does damage and respawn work? (`take_hit`, `Level.respawn`)
- What does each hero do and why this order?
- Where is progress saved?
