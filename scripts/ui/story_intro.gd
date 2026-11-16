extends Node2D
## The backstory. It plays before the tutorial the first time (the level select starts it) and
## again from STORY on the main menu. Five shots, built in code from the game's own art (no new
## art, like menu_stage.gd), drawn twice as big as the game so the pixel art is easy to see:
##   1. The lab: five IT students finish their game. Byte appears on their screen and calls for
##      someone who can code, and the screen pulls all five inside.
##   2. Byte's world: a variable builds a bridge, plank by plank.
##   3. The theft: Captain Clown Nose steals every variable, locks them in his treasure chest
##      and runs off with it. Without its variable, the bridge falls into the sea.
##   4. The fall: the trip through the screen scatters the team all over Byte's world.
##   5. Chelzy lands where the tutorial starts, and Byte asks for help. The tutorial picks up
##      from here ("Wake up, Chelzy!").
## Enter (or Space / F) moves the dialogue on and Esc skips. At the end the game remembers the
## story was seen (Game.story_seen) and goes to Game.story_next: the tutorial, or the main menu.
## Every wait and move is a tween of this node, so turning the node off freezes the shot.

signal _advance

const TUTORIAL := "res://scenes/levels/level1/level1.tscn"
const ZOOM := 2.0  ## The shot is drawn twice as big as the game...
const VIEW := Vector2(320, 180)  ## ...so it is 320 x 180 (640 x 360 on screen).
const GROUND := 112.0  ## Top of the island ground in Byte's world.
## The captain's frames leave room for his sword, so his body is 18 px off their middle (27 px
## at the 1.5x he's drawn at), on the side away from where he faces.
const CAPTAIN_SHIFT := 27.0
const LAND := 120.0  ## Top of the ground where Chelzy lands.

const PLAYER := preload("res://scripts/player/player.gd")
const ISLAND_SKY := preload("res://scripts/level2/background.gd")
const SCROLLING_SKY := preload("res://scripts/levels/scrolling_background.gd")
const WATER := preload("res://scripts/level2/water.gd")
const BYTE_FRAMES := preload("res://assets/shared/byte/byte_frames.tres")
const SWAP_FX := preload("res://assets/shared/heroes/swap_fx/swap_fx_frames.tres")
const CAPTAIN := preload("res://assets/level2_treasure_hunters/characters/captain_clown_nose/captain_clown_nose_frames.tres")
const CHEST := preload("res://assets/level2_treasure_hunters/objects/chest/chest_frames.tres")
const FLAG := preload("res://assets/level2_treasure_hunters/objects/flag/flag_frames.tres")
const GATE_BLOCK := preload("res://assets/level1_pixel_adventure/traps/blocks/blocks_frames.tres")
const ISLAND := preload("res://assets/level2_treasure_hunters/tiles/island_terrain_32x32.png")
const PLANKS := preload("res://assets/level2_treasure_hunters/tiles/ship_platforms_32x32.png")
const PLANK := Rect2(64, 65, 32, 10)  ## One bridge plank, as in code_bridge.gd.
const TERRAIN := preload("res://assets/level1_pixel_adventure/tiles/terrain_16x16.png")
const BLUE_SKY := preload("res://assets/level1_pixel_adventure/backgrounds/bg_blue.png")
const GREEN_SKY := preload("res://assets/level1_pixel_adventure/backgrounds/bg_green.png")

## The team as real people (tools/make_team_sprites.gd), left to right as in the group photo.
const LINEUP := ["april", "sarah", "psalm", "kervin", "chelzy"]
## What the team is typing on the lab's screen.
const LAB_CODE := "// our capstone game\nString game = \"Code Odyssey\";\nint bugsLeft = 0;\nSystem.out.println(\"Done!\");"
## The variables the captain steals from all over Byte's world (they fly in from off-screen).
const STOLEN := ["String hero = \"Chelzy\";", "double jumpPower = 2.0;", "boolean anchorUp = true;",
	"char path = 'B';"]
## Where each hero tumbles to in the fall, and where they fly off to.
const FALL_SPOTS := {"chelzy": Vector2(160, 96), "sarah": Vector2(70, 60), "april": Vector2(250, 56),
	"kervin": Vector2(92, 116), "psalm": Vector2(228, 118)}
const FALL_EXITS := {"chelzy": Vector2(160, 250), "sarah": Vector2(-50, 30), "april": Vector2(370, 24),
	"kervin": Vector2(-50, 170), "psalm": Vector2(370, 180)}

const CODE_GREEN := Color("8ee99c")
const CODE_BG := Color("2b2a3a")
const CODE_EDGE := Color("45475e")
const OUTLINE := Color("1b1530")

var _stage: Node2D  ## The shot being shown, drawn ZOOM times as big. Rebuilt for each shot.
var _overlay: Control  ## Text on top of the shot at the game's size (code, names).
var _box: DialogueBox
var _skip: Label
var _flash: ColorRect
var _fade: ColorRect
var _mono: SystemFont
var _waiting := false  ## True while a line shows in full and waits for Enter.
var _done := false
var _snores := 0  ## Zs floated up so far.
# Byte's world, kept for the theft (the same place, straight after).
var _byte: AnimatedSprite2D
var _chest: AnimatedSprite2D
var _bridge_tag: PanelContainer
var _planks: Array[Sprite2D] = []


func _ready() -> void:
	# Code keeps a monospace font, so capitals show exactly as Java needs them.
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Consolas", "Courier New", "Monospace"])
	_build_ui()
	Sound.stop_music()
	_play()


func _play() -> void:
	await _lab()
	await _byte_world()
	await _theft()
	await _fall()
	await _landing()
	_finish()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _skip.visible:
		get_viewport().set_input_as_handled()
		_finish()
	elif _waiting and (event.is_action_pressed("ui_accept") or event.is_action_pressed("jump")
			or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		_waiting = false
		_advance.emit()


## Remembers that the story was seen and moves on. Skipping calls it too: turning this node off
## stops every tween, so the shot freezes while the screen fades out.
func _finish() -> void:
	if _done:
		return
	_done = true
	process_mode = Node.PROCESS_MODE_DISABLED
	if not Game.story_seen:
		Game.story_seen = true
		Game.save_progress()
	Game.change_scene(Game.story_next if Game.story_next != "" else TUTORIAL)


# ---------------- 1. The lab ----------------

func _lab() -> void:
	_new_shot()
	# The lab at night: a wall with a window and a clock, the floor, and the big screen.
	_rect(Color("262438"), Rect2(0, 0, 320, 128))
	for x in [30, 110, 210, 290]:
		_rect(Color("2b2940"), Rect2(x, 0, 2, 128))
	_rect(Color("3b3d52"), Rect2(14, 16, 50, 40))  # window frame
	_rect(Color("121733"), Rect2(17, 19, 44, 34))  # the night outside
	_rect(Color("3b3d52"), Rect2(38, 19, 2, 34))
	_disc(Vector2(21, 23), Color("f3e9c6"))  # the moon, cut into a crescent...
	_disc(Vector2(24, 21), Color("121733"))
	for star in [Vector2(46, 24), Vector2(54, 31), Vector2(44, 42), Vector2(57, 47), Vector2(27, 45)]:
		_rect(Color("c9d3ff"), Rect2(star, Vector2.ONE))
	_rect(Color("3b3d52"), Rect2(256, 20, 46, 20))  # clock
	_rect(Color("121216"), Rect2(258, 22, 42, 16))
	_caption("11:59", Vector2(279, 30), Color("ff5a5a"))
	_rect(Color("1a1828"), Rect2(0, 128, 320, 52))  # floor
	_rect(Color("3b3d52"), Rect2(0, 128, 320, 2))
	_rect(Color("45475e"), Rect2(94, 6, 132, 56))  # the screen
	var screen := _rect(Color("0f1320"), Rect2(98, 10, 124, 48))
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([Vector2(98, 58), Vector2(222, 58), Vector2(296, 150), Vector2(24, 150)])
	glow.color = Color(0.56, 0.89, 1.0, 0.0)
	_stage.add_child(glow)
	var code := _code_label(LAB_CODE, 9)
	code.position = Vector2(102, 12) * ZOOM
	code.visible_characters = 0
	_overlay.add_child(code)
	for y in range(10, 58, 3):  # scan lines
		_rect(Color(0, 0, 0, 0.2), Rect2(98, y, 124, 1))
	# The five of us, with our names.
	var people: Array[Sprite2D] = []
	var names: Array[Label] = []
	for i in LINEUP.size():
		var person := Sprite2D.new()
		person.texture = load("res://assets/shared/team/%s.png" % LINEUP[i])
		person.position = Vector2(72 + i * 44, 106)  # the middle: feet on the floor at y = 140
		_stage.add_child(person)
		people.append(person)
		names.append(_caption(PLAYER.HERO_DATA[LINEUP[i]]["name"].to_upper(), Vector2(72 + i * 44, 66)))

	await _fade_in(1.0)
	_skip.visible = true
	var typing := _type(code, 0.03)
	await _say("", "Late one night, five IT students were finishing their game in the computer lab.")
	if typing.is_running():
		await typing.finished
	_hush()
	await _wait(0.5)

	# The screen flickers, and Byte looks out of it.
	Sound.play("code_error")
	var flicker := create_tween()
	for i in 3:
		flicker.tween_property(screen, "color", Color("6fd3ff"), 0.05)
		flicker.tween_property(screen, "color", Color("0f1320"), 0.08)
	await flicker.finished
	code.visible = false
	screen.color = Color("1d3b5c")
	var byte := _anim(BYTE_FRAMES, &"talk", Vector2(160, 34))
	byte.scale = Vector2(1.5, 1.5)
	_stage.move_child(byte, screen.get_index() + 1)  # on the screen, under its scan lines
	Sound.play("terminal_open")
	await _say("BYTE", "Hello? Can anyone hear me? My world needs someone who can code!")
	_hush()

	# The screen pulls them in, from the middle outwards.
	byte.play(&"happy")
	screen.color = Color("8fe3ff")
	_move(glow, "color:a", 0.25, 0.4)
	_shake(1.2, 2.0)
	for i in [2, 1, 3, 0, 4]:
		_pull_in(people[i], names[i])
		await _wait(0.18)
	await _wait(0.6)
	await _move(_flash, "color:a", 1.0, 0.15).finished
	_fade.color.a = 1.0
	await _move(_flash, "color:a", 0.0, 0.35).finished
	await _wait(0.3)


## A swirl where the person stood, then they stretch thin and fly into the screen.
func _pull_in(person: Sprite2D, name_label: Label) -> void:
	var swirl := _anim(SWAP_FX, &"disappearing", person.position)
	swirl.animation_finished.connect(swirl.queue_free)
	Sound.play("hero_swap", 0.15)
	name_label.visible = false
	var t := create_tween().set_parallel().set_ease(Tween.EASE_IN)
	t.tween_property(person, "position", Vector2(160, 34), 0.45).set_trans(Tween.TRANS_BACK)
	t.tween_property(person, "scale", Vector2(0.15, 0.5), 0.45)
	t.tween_property(person, "modulate:a", 0.0, 0.45)


# ---------------- 2. Byte's world ----------------

func _byte_world() -> void:
	_new_shot()
	_stage.add_child(ISLAND_SKY.new())  # Level 1's sky, sea and clouds, behind everything
	_cliff(0, 3, false, true)
	_cliff(224, 3, true, false)
	var water: Node2D = WATER.new()
	water.width = 128.0
	water.depth = 60.0
	water.position = Vector2(96, 132)
	_stage.add_child(water)
	_anim(FLAG, &"idle", Vector2(310, GROUND - 46))
	_chest = _anim(CHEST, &"open", Vector2(282, GROUND - 17))
	_chest.stop()  # frame 0: shut
	_byte = _anim(BYTE_FRAMES, &"follow", Vector2(-20, 58))

	await _fade_in(0.8)
	Sound.music("menu")
	await _move(_byte, "position", Vector2(150, 58), 1.2).finished
	_byte.play(&"idle")
	await _say("BYTE", "Welcome to my world! Everything here runs on Java code.")
	_hush()

	# A variable builds the bridge.
	_bridge_tag = _code_tag("int bridgeLength = 4;", Vector2(160, 88))
	await _type(_bridge_tag.get_child(0) as Label, 0.05, "byte_talk").finished
	Sound.play("code_ok")
	_byte.play(&"happy")
	_planks.clear()
	for i in 4:
		_planks.append(_plank(i))
		await _wait(0.12)
	await _wait(0.4)
	_byte.play(&"idle")
	await _say("BYTE", "Variables tell my bridges how long to be, my gates when to open and my ships when to sail.")
	_hush()


## Island ground `cols` tiles wide from `x`, from GROUND to the bottom of the shot. A side that
## is an edge gets the cliff's edge tiles; the other side carries on past the screen.
func _cliff(x: float, cols: int, left_edge: bool, right_edge: bool) -> void:
	for row in ceili((VIEW.y - GROUND) / 32.0):
		for c in cols:
			var col := 1
			if c == 0 and left_edge:
				col = 0
			elif c == cols - 1 and right_edge:
				col = 2
			_tile(ISLAND, Rect2(col * 32, mini(row, 1) * 32, 32, 32), Vector2(x + c * 32, GROUND + row * 32))


## Bridge plank `i` across the gap, popping in like code_bridge.gd's blocks.
func _plank(i: int) -> Sprite2D:
	Sound.play("bridge_block")
	var plank := _tile(PLANKS, PLANK, Vector2(96 + i * 32, GROUND))
	var home := plank.position
	plank.position.y -= 6
	plank.scale = Vector2(0.4, 0.4)
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(plank, "position", home, 0.15)
	t.tween_property(plank, "scale", Vector2.ONE, 0.15)
	return plank


# ---------------- 3. The theft ----------------

func _theft() -> void:
	Sound.music("final_exam")
	# He's drawn 1.5x, as in the boss fight. His feet are 6 px below the middle of his frames,
	# and his body is CAPTAIN_SHIFT px off their middle, away from the way he faces.
	var captain := _anim(CAPTAIN, &"run", Vector2(350, GROUND - 9))
	captain.scale = Vector2(1.5, 1.5)
	captain.flip_h = true  # facing left, so his body is right of the node
	await _move(captain, "position:x", 246.0 - CAPTAIN_SHIFT, 1.1, Tween.TRANS_LINEAR).finished
	captain.play(&"idle")
	_byte.play(&"error")
	_move(_byte, "position", Vector2(118, 44), 0.4)
	await _say("CAPTAIN", "Har har! Every variable in this world is mine now!")
	_hush()

	# One swing of his sword pulls the bridge's variable, and all the others, into his chest.
	captain.play(&"attack_1")
	Sound.play("sword")
	_chest.play(&"open")
	Sound.play("chest_open")
	var mouth := (_chest.position + Vector2(0, -6)) * ZOOM
	_steal(_bridge_tag, mouth, 0.6)
	await _wait(0.3)
	for i in STOLEN.size():
		_steal(_code_tag(STOLEN[i], Vector2(-70, 24 + i * 15)), mouth, 1.0)
		await _wait(0.2)
	await _wait(1.0)
	captain.play(&"idle")

	# Without its variable, the bridge falls into the sea.
	Sound.play("bridge_collapse")
	for plank in _planks:
		_sink(plank)
		await _wait(0.06)
	_chest.play(&"close")
	Sound.play("chest_open")
	await _wait(0.7)

	# He lifts the chest over his head and runs off with it. Turning round, the node moves so
	# his body stays where it is.
	await _move(_chest, "position", captain.position + Vector2(CAPTAIN_SHIFT, -44), 0.3).finished
	captain.flip_h = false
	captain.position.x += CAPTAIN_SHIFT * 2.0
	captain.play(&"run")
	var away := create_tween().set_parallel()
	away.tween_property(captain, "position:x", 400.0 + CAPTAIN_SHIFT, 1.0)
	away.tween_property(_chest, "position:x", 400.0, 1.0)
	_byte.play(&"idle")
	_move(_byte, "position", Vector2(150, 58), 0.6)
	await away.finished
	await _say("BYTE", "Captain Clown Nose stole every variable in my world and locked them in his treasure chest!")
	await _say("BYTE", "Without variables, nothing here works. That's why I called for help!")
	_hush()
	await _fade_out()


## A code tag flies into the chest's mouth (`to`, on screen), shrinking, and is gone.
func _steal(tag: Control, to: Vector2, seconds: float) -> void:
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(tag, "position", to - tag.size / 2.0, seconds)
	t.tween_property(tag, "scale", Vector2(0.2, 0.2), seconds)
	t.tween_property(tag, "modulate:a", 0.3, seconds)
	t.chain().tween_callback(func():
		Sound.play("fruit", 0.1)
		tag.queue_free())


## A plank drops into the sea (the water is drawn over it) and fades away.
func _sink(plank: Sprite2D) -> void:
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(plank, "position:y", plank.position.y + 48.0, 0.7)
	t.tween_property(plank, "rotation", randf_range(-0.6, 0.6), 0.7)
	t.tween_property(plank, "modulate:a", 0.0, 0.7)


# ---------------- 4. The fall ----------------

func _fall() -> void:
	_new_shot()
	_scrolling_sky(BLUE_SKY, Vector2(0, -150))  # the sky rushes up: we're falling
	Sound.music("menu")
	await _fade_in(0.3)
	var portal := _anim(SWAP_FX, &"appearing", Vector2(160, 40))
	portal.animation_finished.connect(portal.queue_free)
	Sound.play("hero_swap")
	var heroes: Array[Node2D] = []
	for id in Game.HEROES:
		var hero := _falling_hero(id)
		hero.position = Vector2(160, 40)
		hero.scale = Vector2(0.2, 0.2)
		var t := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(hero, "position", FALL_SPOTS[id], 0.6)
		t.tween_property(hero, "scale", Vector2.ONE, 0.6)
		heroes.append(hero)
		await _wait(0.08)
	Sound.play("fall")
	await _say("", "But the trip through the screen scattered the five friends all over Byte's world.")
	_hush()
	Sound.play("fall")
	for i in heroes.size():
		var exit: Vector2 = FALL_EXITS[Game.HEROES[i]]
		_move(heroes[i], "position", exit, 0.7, Tween.TRANS_QUAD, Tween.EASE_IN)
	await _wait(0.9)
	await _fade_out(0.4)


## A hero tumbling through the sky with their name under them. Move the returned node.
func _falling_hero(id: String) -> Node2D:
	var holder := Node2D.new()
	_stage.add_child(holder)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load(PLAYER.HERO_DATA[id]["frames"])
	sprite.play(&"fall")
	holder.add_child(sprite)
	var spin := sprite.create_tween().set_loops()  # stops by itself when the shot is freed
	var turn := TAU if id in ["chelzy", "april", "psalm"] else -TAU
	spin.tween_property(sprite, "rotation", turn, randf_range(1.6, 2.4)).as_relative()
	var label := _stage_label(PLAYER.HERO_DATA[id]["name"].to_upper())
	label.position = Vector2(-label.size.x * label.scale.x / 2.0, 20)
	holder.add_child(label)
	return holder


# ---------------- 5. Chelzy lands ----------------

func _landing() -> void:
	_new_shot()
	_scrolling_sky(GREEN_SKY, Vector2(0, 12))  # the tutorial's background
	for x in range(0, int(VIEW.x), 16):
		_tile(TERRAIN, Rect2(112, 0, 16, 16), Vector2(x, LAND))
		for row in range(1, 4):
			_tile(TERRAIN, Rect2(112, 16, 16, 16), Vector2(x, LAND + row * 16))
	for i in 3:  # Byte's gate, where the tutorial begins
		_anim(GATE_BLOCK, &"idle", Vector2(248, LAND - 11 - i * 22))

	await _fade_in(0.5)
	var chelzy := _anim(load(PLAYER.HERO_DATA["chelzy"]["frames"]), &"fall", Vector2(120, -30))
	chelzy.offset = PLAYER.SPRITE_OFFSET  # feet 16 px below the middle, as in the game
	await _move(chelzy, "position:y", LAND - 16, 0.45, Tween.TRANS_QUAD, Tween.EASE_IN).finished
	Sound.play("land")
	Sound.play("hurt")
	_shake(0.25, 3.0)
	chelzy.play(&"hit")
	await chelzy.animation_finished
	# Out cold: Chelzy lies on the ground, snoring.
	chelzy.play(&"idle")
	_move(chelzy, "rotation", -PI / 2.0, 0.2)
	_move(chelzy, "position:y", LAND - 9, 0.2)
	_snore(Vector2(106, LAND - 22))  # above the head, which is now on the left
	await _wait(0.8)

	_byte = _anim(BYTE_FRAMES, &"follow", Vector2(350, 50))
	_byte.flip_h = true
	await _move(_byte, "position", Vector2(146, 76), 1.2).finished
	_byte.play(&"talk")
	await _say("BYTE", "A coder, at last! I can check code, but I can't type it. I have no hands!")
	await _say("BYTE", "Let's write those variables back, find your friends and win back the treasure!")
	_hush()
	_byte.play(&"happy")
	Sound.play("code_ok")
	await _wait(0.8)


## Little Zs float up from `at` while Chelzy sleeps.
func _snore(at: Vector2) -> void:
	var stage := _stage
	var timer := Timer.new()
	timer.wait_time = 0.7
	timer.autostart = true
	stage.add_child(timer)
	timer.timeout.connect(func():
		var z := _stage_label("Z")
		_snores += 1
		if _snores % 2 == 0:
			z.scale *= 2.0  # every other Z is twice as big: z Z z Z
		var start := at - Vector2(z.size.x * z.scale.x / 2.0, 0)  # the Z is in the label's middle
		z.position = start
		stage.add_child(z)
		var t := z.create_tween().set_parallel()
		t.tween_property(z, "position", start + Vector2(6, -16), 1.2)
		t.tween_property(z, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(z.queue_free))


# ---------------- Dialogue ----------------

## Shows a line in the dialogue box and waits for Enter. `who` is "BYTE", "CAPTAIN", or "" for
## the narrator (no face, no name). The box stays up until _hush().
func _say(who: String, text: String) -> void:
	match who:
		"BYTE":
			_box.set_speaker("BYTE", BYTE_FRAMES)
			_box.voice = "byte_talk"
		"CAPTAIN":
			var face := _box.set_speaker("CAPTAIN CLOWN NOSE", CAPTAIN, &"idle")
			face.scale = Vector2.ONE
			face.position = Vector2(38, 30)  # his body is left of and above his frames' middle
			_box.voice = "byte_talk"
		_:
			_box.set_speaker("")
			_box.voice = ""
	_box.visible = true
	await _box.type_line(text)
	_waiting = true
	await _advance


func _hush() -> void:
	_box.visible = false


# ---------------- Building shots ----------------

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_overlay)
	_box = DialogueBox.new()
	_box.visible = false
	ui.add_child(_box)
	_skip = Label.new()
	_skip.text = "ESC: SKIP"
	_skip.anchor_left = 1.0
	_skip.anchor_right = 1.0
	_skip.offset_left = -100
	_skip.offset_right = -8
	_skip.offset_top = 6
	_skip.offset_bottom = 18
	_skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_skip.add_theme_color_override("font_outline_color", OUTLINE)
	_skip.add_theme_constant_override("outline_size", 4)
	_skip.visible = false  # until the first shot has faded in
	ui.add_child(_skip)
	_flash = _cover(ui, Color(1, 1, 1, 0))
	_fade = _cover(ui, Color(0, 0, 0, 1))  # starts black


func _cover(parent: Node, color: Color) -> ColorRect:
	var c := ColorRect.new()
	c.color = color
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


## Throws the last shot away and starts an empty one.
func _new_shot() -> void:
	if _stage:
		_stage.queue_free()
	for c in _overlay.get_children():
		c.queue_free()
	_stage = Node2D.new()
	_stage.scale = Vector2(ZOOM, ZOOM)
	add_child(_stage)


## A tiled background that keeps moving (scrolling_background.gd), behind the shot.
func _scrolling_sky(texture: Texture2D, speed: Vector2) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	_stage.add_child(layer)
	var sky: TextureRect = SCROLLING_SKY.new()
	sky.texture = texture
	sky.scroll_speed = speed
	layer.add_child(sky)


## A round blob 9 px across, made of three overlapping rectangles.
func _disc(top_left: Vector2, color: Color) -> void:
	_rect(color, Rect2(top_left + Vector2(2, 0), Vector2(5, 9)))
	_rect(color, Rect2(top_left + Vector2(1, 1), Vector2(7, 7)))
	_rect(color, Rect2(top_left + Vector2(0, 2), Vector2(9, 5)))


func _rect(color: Color, rect: Rect2) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(r)
	return r


## Part of a texture (a tile) with its top-left corner at `top_left`.
func _tile(texture: Texture2D, region: Rect2, top_left: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.region_enabled = true
	s.region_rect = region
	s.position = top_left + region.size / 2.0
	_stage.add_child(s)
	return s


func _anim(frames: SpriteFrames, anim: StringName, at: Vector2) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames
	s.play(anim)
	s.position = at
	_stage.add_child(s)
	return s


## Pixel-font text over the shot, centred on `at` (a point in the shot).
func _caption(text: String, at: Vector2, color := Color("fff5e3")) -> Label:
	var l := _outlined(text, color)
	l.size = Vector2(120, 12)
	l.position = at * ZOOM - l.size / 2.0
	_overlay.add_child(l)
	return l


## Pixel-font text that moves with the shot, at the game's size (half of the shot's zoom).
## Not added yet: put it where it goes.
func _stage_label(text: String) -> Label:
	var l := _outlined(text, Color("fff5e3"))
	l.size = Vector2(80, 12)
	l.scale = Vector2(1.0 / ZOOM, 1.0 / ZOOM)
	return l


func _outlined(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _code_label(code: String, font_size := 10) -> Label:
	var l := Label.new()
	l.text = code
	l.add_theme_font_override("font", _mono)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", CODE_GREEN)
	return l


## A line of code on a dark strip, like Byte's terminal, centred on `at` (a point in the shot).
func _code_tag(code: String, at: Vector2) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", DialogueBox.style(CODE_BG, CODE_EDGE, 1, Vector4(5, 2, 5, 2)))
	tag.add_child(_code_label(code))
	_overlay.add_child(tag)
	tag.reset_size()
	tag.pivot_offset = tag.size / 2.0
	tag.position = at * ZOOM - tag.size / 2.0
	return tag


# ---------------- Moving things ----------------

func _wait(seconds: float) -> void:
	await create_tween().tween_interval(seconds).finished


## Tweens `what`'s `property` to `to`. Await the result's `finished` to wait for it.
func _move(what: Object, property: String, to: Variant, seconds: float,
		trans := Tween.TRANS_SINE, easing := Tween.EASE_IN_OUT) -> Tween:
	var t := create_tween()
	t.tween_property(what, property, to, seconds).set_trans(trans).set_ease(easing)
	return t


## Types out a label's text, `per_letter` seconds a letter, with `click` every other letter.
func _type(label: Label, per_letter: float, click := "ui_move") -> Tween:
	label.visible_characters = 0
	var t := create_tween()
	t.tween_method(_type_letters.bind(label, click), 0.0, float(label.text.length()),
		label.text.length() * per_letter)
	return t


func _type_letters(count: float, label: Label, click: String) -> void:
	var shown := int(count)
	if shown > label.visible_characters and shown % 2 == 0 and label.text[shown - 1] != " ":
		Sound.play(click, 0.15)
	label.visible_characters = shown


## Shakes the shot, less and less, for `seconds`. `strength` is in screen pixels.
func _shake(seconds: float, strength: float) -> void:
	var t := create_tween()
	var steps := maxi(1, int(seconds / 0.04))
	for i in steps:
		var power := strength * (1.0 - float(i) / steps)
		t.tween_property(_stage, "position", Vector2(randf_range(-power, power), randf_range(-power, power)).round(), 0.04)
	t.tween_property(_stage, "position", Vector2.ZERO, 0.04)


func _fade_in(seconds := 0.6) -> void:
	await _move(_fade, "color:a", 0.0, seconds).finished


func _fade_out(seconds := 0.5) -> void:
	await _move(_fade, "color:a", 1.0, seconds).finished
