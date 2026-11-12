# April - Documentation, Papers and Defense Prep

## You explain: the "why", the plan, the evidence, and you coordinate the defense.

### Your documents
- Manuscript: `docs/manuscript/Code_Odyssey_Manuscript.docx`.
- Design docs: `docs/level1_design.md` (the tutorial) and `docs/level2_design.md` (Level 1).
- Why the game was cut down from four levels to two: `docs/cut_list.md`.
- Asset credits: `assets/README.md`, `assets/shared/audio/CREDITS.md` (Pixel Frog art packs, CC0 audio).
- Test evidence: `tools/test_level1.gd` (26 checks) and `tools/test_level2.gd` (80 checks) play
  every room automatically and print PASS/FAIL, including every anti-skip obstacle.
- Study guides: this folder (`docs/study_guides/`).

### What the papers must clearly state
1. **Problem**: beginners find programming abstract and boring.
2. **Solution**: a platformer where typing Java variable lines changes the world.
3. **Objectives**: declare variables of each type; reassign an existing variable; read error messages.
4. **Target users**: beginner programming students; a session is about 15-20 minutes.
5. **Tools**: Godot 4.7, GDScript, Git/GitHub, Pixel Frog art assets, CC0 audio.
6. **Features**: Byte, a terminal with step-by-step checking, 5 heroes, a tutorial with Byte's
   lessons, an 8-room level (5 rooms + a 3-part exam), sword fighting and a final boss you beat
   by switching heroes, hints and stars, manuals, save, sound.
7. **Scope and limitations**: one topic, variables and data types; two levels (a tutorial and
   Level 1); only Java-style variable lines and `System.out.println`.
8. **Future work**: levels for conditionals, loops, methods.

### Defense coordination
- Demo script: menu -> tutorial (Byte's welcome, the manual, println opens the gate, the wall
  jump, Sarah's rescue) -> Level 1 Room 1 bridge (show 9 collapsing and the 5.5 error) -> the
  ship and the crab (`boolean anchorUp = true;`, `boolean hasSword = true;`) -> the boss
  (switch heroes with hold-Q to dodge Captain Clown Nose) -> the treasure.
- To jump straight to a room during the demo, run the game from the Godot editor and press
  Ctrl+Shift+I (immunity mode, `scripts/dev/immunity.gd`), then Ctrl+Shift+R to pick a room.
  It doesn't exist in an exported game.
- Build a Q&A sheet: collect the "likely questions" from each teammate's file and assign a first answerer.
- Make sure every member can give the 2-minute overview (`00_Team_Overview.md`).
- Rehearse once with a timer; prepare a fallback (screenshots or a recorded video) in case the game fails.

### Likely questions to own
- Why this topic and audience? How do you know it teaches? (stars, mistakes count, playtest)
- Why only two levels? (one topic taught well and fully explained by the team; see cut_list.md)
- Where did the assets come from? Are they licensed? (credits)
- Who did what? (the five role files)
- What would you improve?
