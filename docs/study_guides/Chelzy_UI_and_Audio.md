# Chelzy - UI and Audio

## You explain: every screen and widget the player sees or hears.

### Screens (`scenes/ui/` + `scripts/ui/`)
- **Main menu** (`main_menu.gd`, animated stage `menu_stage.gd`): play/continue, settings
  (volume sliders, fullscreen), reset progress. Play starts the tutorial.
- **Level select** (`level_select.gd`): two cards, TUTORIAL and LEVEL 1, each with an animated
  preview made from that level's art. Level 1 unlocks once the tutorial has a star.
- **Pause menu** (`pause_menu.gd`): resume, settings, quit to menu.
- **HUD** (`hud.gd`): health bar, stamina bar, the counter for the current room (FRUIT 3/16 in
  the tutorial, COINS 3/9 in Level 1), room title popup.
- **Hotbar** (`hotbar.gd`): 5 inventory slots, selected slot highlight.
- **Code terminal** (`code_terminal.tscn`): the visual side (logic is Psalm's): output log with
  colors (white = your code, green = pass, red = fail, cyan = Byte, grey = hint, gold = answer),
  input line, Show answer button.
- **Byte talks** (`byte_talk.gd`): the game pauses, the HUD hides, the camera glides to what Byte
  is talking about, and his lines appear in a dialogue box (Enter moves on). The tutorial's
  lessons use it, and so does the **hero cutscene** (`hero_cutscene.gd`): on a rescue the camera
  zooms in, Byte introduces the hero, then a looping card shows the ability, key, stamina cost
  and the `hero = "...";` line.
- **The boss fight on screen:** Captain Clown Nose's health bar and his shouts (CHARGE!, CATCH
  THIS!, SWING!) float over him (`captain.gd`); the HUD says CAPTAIN CLOWN NOSE!; the hero wheel
  (`hero_wheel.gd`, hold Q, slow motion) is how you switch heroes while the terminal is locked.
- **Level complete** (`level_complete.gd`): stars, fruit or coins, time, mistakes; CONTINUE goes
  from the tutorial to Level 1.
- **Chest window** (`chest_window.gd`) and **manual reader** (`scripts/manuals/manual_reader.gd`): a
  two-page book built in code; content comes from `manual_library.gd`. Manuals: Variables (red,
  the tutorial and Level 1 Room 0), Numbers (orange, Room 1), Booleans & chars (green, Room 3),
  Changing variables (purple, Exam 1).
- **Damage numbers** (`damage_number.gd`): floating hit text.
- Theme: `scenes/ui/theme/ui_theme.tres`; pixel font `assets/shared/ui/fonts/pixel_font.fnt`.
  Item names and icons: `scripts/items/item_db.gd`.

### Audio (`scripts/autoload/sound.gd`, volume functions in `Game`)
- `Sound.play("jump")`, `Sound.play_at("fire", pos)` (fades with distance from the camera),
  `Sound.music("rooms")`.
- Music: menu, rooms, final_exam (Level 1's exam). Fanfares for rescue and level complete.
- Buses: Master, Music, SFX with sliders; saved in settings. All audio is CC0 - see `assets/shared/audio/CREDITS.md`.

### Ideas to be able to say
- Viewport 640x360 scaled x2 with integer scaling = crisp pixel art.
- UI uses Godot **Control** nodes, a shared **Theme**, and signals from the Player (health_changed, etc.) to update.
- Why a book for manuals: players read the concept, then apply it in the terminal.
- Why the tutorial pauses for Byte: one idea at a time, at the moment the player needs it.

### Likely questions
- How does the HUD know the player's health? (signal)
- How are volume settings saved? (Game.save_settings -> user://settings.cfg)
- How did you design for readability? (colors, pixel font, the game pauses while the terminal is open)
