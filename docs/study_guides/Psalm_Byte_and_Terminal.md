# Psalm - Byte, the Code Terminal and Architecture

## You explain: how typed code becomes gameplay.

### Files
- `scripts/byte/byte.gd` - Byte the companion. Follows the player (`follow_speed` 6), teleports
  if farther than 200 px (after respawn). `react(correct)` plays happy/error, `say(text)` shows
  a speech bubble with talk blips.
- `scripts/terminal/code_terminal.gd` - the terminal window. Opens/closes, takes the typed line,
  runs `CommandChecker`, shows Byte's checklist line by line (0.18 s apart), emits
  `variable_set(name, value)`, counts wrong tries, shows hint (3), blanks (5), Show answer.
  Has command history (up/down). Pauses player input while open. Signals: `variable_set`,
  `closed`, `wrong_try(room, tries)`. `locked_reason` keeps it shut during the boss fight
  (switching heroes there is the hero wheel's job, `CodeTerminal.switch_from_wheel`).
- `scripts/terminal/command_checker.gd` - the "mini Java compiler". Checks step by step:
  ends with `;` -> has `=` -> type is valid (`String int double boolean char`) -> name is a
  valid identifier (regex `^[A-Za-z_$][A-Za-z0-9_$]*$`) and one the level knows -> declared /
  not declared yet -> value fits the type -> value is allowed (range, hero rescued).
  Also checks `System.out.println(...)`. Returns pass/fail steps with an error message.
- `scripts/terminal/variable_library.gd` - every variable the game knows: hero, hasSword,
  bridgeLength, jumpPower, anchorUp, path, with its type and rules (e.g. jumpPower 1.0-2.0).
  Each level's terminal picks its **Allowed Variables**.
- `scripts/gadgets/code_gadget.gd` - base class for anything code-driven. Set `variable_name`,
  override `_on_value`. Children: `code_bridge` (int), `code_ship` (boolean), `path_platform`
  (char), `byte_gate` (println).
- `scripts/levels/tutorial.gd` - Byte's lessons in the tutorial (talks at the start, after the
  chest, after reading, on wrong lines, when the gate opens, after Sarah's rescue).

### Key ideas to be able to say
- **Redeclaration rule (Java's rule):** `String hero = "X";` when `hero` exists is refused.
  Byte explains and puts the fixed line `hero = "X";` in the input. It is not counted as a wrong try.
  (`allow_redeclare` switch exists.)
- **Type errors teach:** `int bridgeLength = 5.5;` -> Byte explains int can't hold decimals.
- **Gadgets only react in their own room** (or that room's doorway), so the exam can reuse
  `bridgeLength`, `anchorUp` and `path` without changing solved rooms. The exam's rooms share a **zone**.
- Puzzle code: tutorial `System.out.println("Hi");` | Level 1: R0 `String hero = "Sarah";` |
  R1 `int bridgeLength = 8;` | R2 `double jumpPower = 2.0;` | R3 `boolean anchorUp = true;` |
  R4 `char path = 'B';` | exam `jumpPower = 1.0;`, `bridgeLength = 6;`, `path = 'C';`,
  `anchorUp = true;`, `System.out.println("I can code!");`.
- **Signals** (Godot's event system) decouple everything: the terminal emits, gadgets listen.

### Architecture (you are the tech lead)
- Why Godot: free, scenes + nodes, GDScript is Python-like, 2D tools.
- Scene = reusable bundle of nodes; script attaches behavior; autoloads = global singletons (`Game`, `Sound`).
- An inherited scene (e.g. `byte_gate_island.tscn`) reuses a scene and only changes its art.
- Project settings: 640x360 viewport scaled 2x, integer scaling (crisp pixels), main scene = main menu.
- `tools/make_byte_sprites.gd` draws Byte's sprites by code.

### Likely questions
- How does the game know your code is right? (CommandChecker steps)
- What if you type it wrong? (Byte explains, tiers of help, star cost)
- How would you add a new variable/gadget? (add to VariableLibrary, new CodeGadget child)
- Why Java syntax? (the course language; the lesson transfers)
