# Kervin - Player, Heroes, Enemies, Traps, Items and Save

## You explain: everything the player controls and everything that can hurt or help them.

### Player (`scripts/player/player.gd`)
- `CharacterBody2D`. Run speed 130, gravity 900, jump velocity -300, max fall 380.
- Feel helpers: **coyote time** (0.1 s jump after leaving a ledge), **jump buffer** (0.12 s),
  **variable jump height** (release early = shorter, cut 0.45), air control 0.75,
  **step-up** onto lips up to 2 px (so a sinking falling platform can't stick you on a corner).
- Health 100; a hit gives 1 s blinking invulnerability. Stamina 100, regen 40/s after 0.6 s delay;
  hitting 0 = "exhausted" until full.
- `jump_power` (set by the code `jumpPower`) scales jump height: 1.0 = 50 px, 1.5 = 75 px, 2.0 = 100 px.
- Inventory: 5 slots (hotbar), sword (10 damage, windup 0.06 s, swing 0.14 s, cooldown 0.35 s).
- Signals: health_changed, stamina_changed, hero_changed, inventory_changed, died.

### Heroes and costs
| Hero | Trait | Notes |
|---|---|---|
| Chelzy | Wall jump / wall slide | 15 stamina per wall jump, grip drains 15/s |
| Sarah | Dash | 35 stamina, 0.3 s at 300 px/s = 90 px, cooldown 0.5 s |
| April | Double jump | 35 stamina; ignores jumpPower |
| Kervin | Sprint (hold Shift) | x1.9 speed, drains 30/s |
| Psalm | Shrink (hold Down) | hitbox 16x24 -> 10x12 fits 1-tile gaps; 0.6x speed; drains 20/s, but not while a low ceiling keeps him small |
Unlock order: Sarah after Room 0, April after Room 1, Kervin after Room 2, Psalm after Room 3.

### Hazards, enemies, traps (`scripts/gadgets/`, `scripts/enemies/`)
- `hazard.gd` is the damage base. Spikes 20 dmg, saw 20 dmg (slides along a chain), spiked ball,
  fire trap, Rock Head / Spike Head (`block_head.gd`), trampoline,
  falling platform (shakes 0.35 s, drops, returns after 2.5 s), Crabby enemy (`crabby.gd`).
- Pit spikes and wall spikes send you straight to the checkpoint (so Chelzy can't wall-climb through).

### Objects (`scripts/objects/`)
- Fruit (progress), red health potion (+30 HP, stays at full HP), checkpoint (respawn + optional
  hero unlock/rescue), end goal (needs all final-exam fruit), fruit door, manual chest.

### `Game` autoload (`scripts/autoload/game.gd`)
- Saves to `user://save.cfg` (progress, unlocked heroes, best stars) and `user://settings.cfg` (volume, fullscreen).
- `start_level`, `finish_level` (mistakes, answers shown, time), `stars_earned`, `change_scene` with fade.

### Anti-skip design (be ready to defend)
Hero-only obstacles sit in 2-tile crawlspaces (no jumping), dash gaps are 5 tiles over a spike trench,
falling floors need the sprint. `tools/test_level1.gd` tries every obstacle with the wrong heroes.

### Likely questions
- Why do heroes cost stamina? (balance, prevents spamming)
- How does damage and respawn work? (`take_hit`, `Level.respawn`)
- What does each hero do and why this order?
- Where is progress saved?
