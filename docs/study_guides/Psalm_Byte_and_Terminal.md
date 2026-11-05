# Psalm - Byte, the Code Terminal and Architecture

## You explain: how typed code becomes gameplay.

### Files
- `scripts/byte/byte.gd` - Byte the companion. Follows the player (`follow_speed` 6), teleports
  if farther than 200 px (after respawn). `react(correct)` plays happy/error, `say(text)` shows
  a speech bubble with talk blips.
- `scripts/terminal/code_terminal.gd` - the terminal window. Opens/closes, takes the typed line,
  runs `CommandChecker`, shows Byte's checklist line by line (0.18 s apart), emits
  `variable_set(name, value)`, counts wrong tries, shows hint (3), blanks (5), Show answer.
  Has command history (up/down). Pauses player input while open.
- `scripts/terminal/command_checker.gd` - the "mini Java compiler". Checks step by step:
  type is valid (`String int double boolean char`) -> name is a valid identifier
  (regex `^[A-Za-z_$][A-Za-z0-9_$]*$`) -> `=` -> value fits the type -> ends with `;`.
  Also checks `System.out.println(...)`. Returns pass/fail steps with an error message.
- `scripts/terminal/variable_library.gd` - the list of every variable the game knows
  (hero, jumpPower, bridgeLength, fanOn, path, ...), with its type and rules (e.g. jumpPower 1.0-2.0).
  Each level's terminal picks its **Allowed Variables**.
- `scripts/gadgets/code_gadget.gd` - base class for anything code-driven. Set `variable_name`,
  override `_on_value`. Children: `code_bridge`, `code_fan`, `path_platform`, `byte_gate`.

### Key ideas to be able to say
- **Redeclaration rule (Java's rule):** `String hero = "X";` when `hero` exists is refused.
  Byte explains and puts the fixed line `hero = "X";` in the input. It is not counted as a wrong try.
  (`allow_redeclare` switch exists.)
- **Type errors teach:** `int bridgeLength = 5.5;` -> Byte explains int can't hold decimals.
- **Gadgets only react in their own room** (or that room's doorway), so the final exam can reuse
  `bridgeLength`, `fanOn`, `path` without breaking solved rooms. Exam sections share a **zone**.
- Puzzle code per room: R0 `System.out.println("Hi");` | R1 `String hero = "Sarah";` |
  R2 `int bridgeLength = 11;` | R3 `double jumpPower = 1.5;` | R4 `boolean fanOn = true;` |
  R5 `char path = 'B';` | R6 changes all of them.
- **Signals** (Godot's event system) decouple everything: terminal emits, gadgets listen.

### Architecture (you are the tech lead)
- Why Godot: free, scenes + nodes, GDScript is Python-like, 2D tools.
- Scene = reusable bundle of nodes; script attaches behavior; autoloads = global singletons (`Game`, `Sound`).
- Project settings: 640x360 viewport scaled 2x, integer scaling (crisp pixels), main scene = main menu.
- `tools/make_byte_sprites.gd` draws Byte's sprites by code.

### Likely questions
- How does the game know your code is right? (CommandChecker steps)
- What if you type it wrong? (Byte explains, tiers of help, star cost)
- How would you add a new variable/gadget? (add to VariableLibrary, new CodeGadget child)
- Why Java syntax? (the course language; the lesson transfers)
