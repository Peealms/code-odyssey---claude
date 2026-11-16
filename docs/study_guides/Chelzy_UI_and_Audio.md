# Chelzy - UI and Audio

## You explain: every screen and widget the player sees or hears.

### Screens (`scenes/ui/` + `scripts/ui/`)
- **Main menu** (`main_menu.gd`, animated stage `menu_stage.gd`: one runner swaps heroes for
  each obstacle - Sarah dashes over spikes, Chelzy wall-jumps up a pillar, April double-jumps a
  saw, Kervin sprints over bars that drop behind him, Psalm shrinks under a slab): play/continue, STORY (watch
  the backstory again), settings (volume sliders, fullscreen), reset progress. Play goes to the
  level select. (The floating topic tags beside the title were removed: the game teaches one
  topic, variables.)
- **The backstory** (`story_intro.gd`, scene `story_intro.tscn`): five shots built in code from
  the game's own art, drawn 2x so the pixel art is big. The lab (the five of us at 11:59 PM;
  Byte appears on our screen and it pulls us in), Byte's world (`int bridgeLength = 4;` builds
  a bridge), the theft (Captain Clown Nose steals every variable into his chest, and the bridge
  falls), the fall (we scatter), and Chelzy landing where the tutorial starts. It plays the
  first time the tutorial is started from the level select (`Game.story_seen`, saved), Enter
  moves on, Esc skips. `Game.play_story(next_scene)` starts it and says where to go after.
- **Level select** (`level_select.gd`): two cards, TUTORIAL and LEVEL 1, each with an animated
  preview made from that level's art. Level 1 unlocks once the tutorial has a star.
- **Pause menu** (`pause_menu.gd`): resume, settings, quit to menu.
- **HUD** (`hud.gd`): health bar, stamina bar, the counter for the current room (FRUIT 3/16 in
  the tutorial, COINS 3/9 in Level 1), room title popup.
- **Hotbar** (`hotbar.gd`): 6 inventory slots (keys 1-6), selected slot highlight. In Level 1,
  slot 1 holds the Variable Dictionary from the start.
- **Code terminal** (`code_terminal.tscn`): the visual side (logic is Psalm's): output log with
  colors (white = your code, green = pass, red = fail, cyan = Byte, grey = hint, gold = answer),
  input line, Show answer button.
- **The dialogue box** (`dialogue_box.gd`): the paper box at the bottom of the screen, with a
  face, a name and the line typed out letter by letter. Byte's talks and the backstory both use
  it (with no face it's the narrator's caption).
- **Byte talks** (`byte_talk.gd`): the game pauses, the HUD hides, the camera glides to what Byte
  is talking about, and his lines appear in the dialogue box (Enter moves on). The tutorial's
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
  Changing variables (purple, Exam 1), and the **Variable Dictionary** (blue, Level 1's hotbar):
  one page per variable - what its name means, its type, its values, how to change it - that
  fills in when you reach the room that needs it.
- **Code diagrams** (`scripts/ui/code_diagram.gd`): a line of code in a dashed box, with an
  arrow from each label (Data Type, Variable Name, Assignment, Value, Semicolon) to its part,
  like a textbook figure. Labels take turns above and below the line so they never overlap.
- **Signs** (`scripts/objects/sign_board.gd`): the clue, and on a dark code strip the name of
  the variable to use - only its name, and only on the first sign that needs it. Level 1's are
  Treasure Hunters parchment (`paper`, a stretched texture); the tutorial's are half-size wooden
  boards. Drawn over the rock, under coins and heroes.
- **New dictionary page** (`scripts/ui/page_note.gd`): a note slides in at the top right naming
  the new variable, and the hotbar puts a bobbing NEW tag on the dictionary's slot
  (`hotbar.set_badge`) until the page is seen; the book opens at it, marked NEW PAGE!.
- **Fonts** (`scripts/ui/game_fonts.gd`): Pixel Operator (words; drawn on a 16 px grid, so it
  stays sharp at the game's 2x and 3x sizes) and JetBrains Mono (code, also in the terminal).
- **Damage numbers** (`damage_number.gd`): floating hit text.
- Theme: `scenes/ui/theme/ui_theme.tres`; pixel font `assets/shared/ui/fonts/pixel_font.fnt`.
  Item names and icons: `scripts/items/item_db.gd`.

### Audio (`scripts/autoload/sound.gd`, volume functions in `Game`)
- `Sound.play("jump")`, `Sound.play_at("fire", pos)` (fades with distance from the camera),
  `Sound.music("rooms")`.
- Music: menu, rooms, final_exam (Level 1's exam). Fanfares for rescue and level complete.
- **Crossfade:** two music players take turns. `Sound` remembers which one is current
  (`_current`), fades the other out over 1 s and keeps one fade tween (`_fade`), killed when a
  new switch starts. (The old version only ever checked player A, so a track playing on player
  B was never faded out and two songs played at once - in the backstory and the tutorial.)
  `tools/test_sound.gd` replays those switches and checks only one track is heard.
- Buses: Master, Music, SFX with sliders; saved in settings. All audio is CC0 - see `assets/shared/audio/CREDITS.md`.

### Ideas to be able to say
- Viewport 640x360 scaled x2 with integer scaling = crisp pixel art.
- UI uses Godot **Control** nodes, a shared **Theme**, and signals from the Player (health_changed, etc.) to update.
- Why a book for manuals: players read the concept, then apply it in the terminal.
- Why the tutorial pauses for Byte: one idea at a time, at the moment the player needs it.
- Why a backstory: it gives the player a reason to code. The world runs on variables, the
  captain stole them, and Byte can check code but can't type it, so the player has to.

### Likely questions
- How does the HUD know the player's health? (signal)
- How are volume settings saved? (Game.save_settings -> user://settings.cfg)
- How did you design for readability? (beta testers found the old font and books hard to read:
  a clearer pixel font, a real coding font for code, labelled diagrams, the dictionary; colors;
  the game pauses while the terminal is open)
