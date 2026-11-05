# Chelzy - UI and Audio

## You explain: every screen and widget the player sees or hears.

### Screens (`scenes/ui/` + `scripts/ui/`)
- **Main menu** (`main_menu.gd`): play/continue, settings (volume sliders, fullscreen), reset progress. Starts Level 1.
- **Pause menu** (`pause_menu.gd`): resume, settings, quit to menu.
- **HUD** (`hud.gd`): health bar, stamina bar, fruit counter for the current room (e.g. FRUIT 3/15), room title popup.
- **Hotbar** (`hotbar.gd`): 5 inventory slots, selected slot highlight.
- **Code terminal** (`code_terminal.tscn`): the visual side (logic is Psalm's): output log with
  colors (white = your code, green = pass, red = fail, cyan = Byte, grey = hint, gold = answer),
  input line, Show answer button.
- **Hero cutscene** (`hero_cutscene.gd`): on rescue the game pauses, camera zooms, Byte introduces the hero,
  a looping card shows the ability, key, stamina cost and the `hero = "...";` line.
- **Level complete** (`level_complete.gd`): stars, fruit, time, mistakes.
- **Chest window** (`chest_window.gd`) and **manual reader** (`scripts/manuals/manual_reader.gd`): two-page
  book built in code; content comes from `manual_library.gd`. Manuals: Variables (red, before Room 0),
  Numbers int vs double (orange, Room 2), Booleans & chars (green, Room 4), Changing variables (purple, Room 6).
- **Damage numbers** (`damage_number.gd`): floating hit text.
- Theme: `scenes/ui/theme/ui_theme.tres`; pixel font `assets/shared/ui/fonts/pixel_font.fnt`.
  Item names and icons: `scripts/items/item_db.gd`.

### Audio (`scripts/autoload/sound.gd`, volume functions in `Game`)
- `Sound.play("jump")`, `Sound.play_at("rock_slam", pos)` (fades with distance from camera),
  `Sound.music("rooms")`, `Sound.loop_player(...)` for fans/saws (only heard nearby).
- Music: menu, rooms (Rooms 0-5), final_exam (Room 6). Fanfares for rescue and level complete.
- Buses: Master, Music, SFX with sliders; saved in settings. All audio is CC0 - see `assets/shared/audio/CREDITS.md`.

### Ideas to be able to say
- Viewport 640x360 scaled x2 with integer scaling = crisp pixel art.
- UI uses Godot **Control** nodes, a shared **Theme**, and signals from the Player (health_changed, etc.) to update.
- Why a book for manuals: players read the concept, then apply it in the terminal.

### Likely questions
- How does the HUD know the player's health? (signal)
- How are volume settings saved? (Game.save_settings -> user://settings.cfg)
- How did you design for readability? (colors, pixel font, game pauses while terminal is open)
