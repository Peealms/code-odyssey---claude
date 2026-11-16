extends "res://scripts/ui/story_intro.gd"
## The ending. It plays after Level 1's results (the CONTINUE button) and goes back to the main
## menu. Built like the backstory, with its helpers, in four shots:
##   1. The treasure: the captain is beaten, the chest opens and every stolen variable flies
##      back out. bridgeLength rebuilds the bridge the captain broke, and the team walks across.
##   2. Byte thanks the five of them, and a portal opens to take them home.
##   3. The lab, just after midnight: they're back at their screen, and Byte waves goodbye.
##   4. THE END, with who made the game.
## Enter (or Space / F) moves the dialogue on and Esc skips back to the menu.

const MENU := "res://scenes/ui/main_menu.tscn"
## What flies out of the chest, in the order the theft took them.
const FREED := ["String hero", "double jumpPower", "boolean anchorUp", "char path", "boolean hasSword"]
## Where the five stand on the left cliff before the bridge is back, and after crossing it.
const START_X := {"chelzy": 14.0, "sarah": 32.0, "april": 50.0, "kervin": 68.0, "psalm": 84.0}
const CROSSED_X := {"chelzy": 132.0, "sarah": 152.0, "april": 172.0, "kervin": 192.0, "psalm": 212.0}
const CREDITS := [
	"A game by Chelzy, Sarah, April, Kervin and Psalm",
	"",
	"Art: Pixel Frog (Pixel Adventure, Treasure Hunters)",
	"Fonts: Pixel Operator by Jayvee Enaguas, JetBrains Mono",
	"Sounds: Juhani Junkala, SubspaceAudio, cosmac (CC0)",
]

var _heroes := {}  ## hero id -> AnimatedSprite2D


func _play() -> void:
	await _treasure()
	await _thanks()
	await _home()
	await _the_end()
	_finish()


## Back to the main menu (Esc, or the last line).
func _finish() -> void:
	if _done:
		return
	_done = true
	process_mode = Node.PROCESS_MODE_DISABLED
	Game.change_scene(MENU)


# ---------------- 1. The treasure ----------------

func _treasure() -> void:
	_new_shot()
	_stage.add_child(ISLAND_SKY.new())
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
	for id in Game.HEROES:
		_heroes[id] = _hero(id, START_X[id])
	_byte = _anim(BYTE_FRAMES, &"idle", Vector2(258, 74))
	_byte.flip_h = true  # looking back at the team

	await _fade_in(0.8)
	_skip.visible = true
	Sound.music("menu")
	await _say("", "Captain Clown Nose was beaten, and his treasure chest was theirs at last.")
	_byte.play(&"talk")
	await _say("BYTE", "Every variable in my world is locked in there. Let's set them free!")
	_hush()

	# The chest opens and the variables fly back out, all over the world.
	_byte.play(&"happy")
	_chest.play(&"open")
	Sound.play("chest_open")
	await _wait(0.4)
	var mouth := _chest.position + Vector2(0, -6)
	for i in FREED.size():
		_free(_code_tag(FREED[i], mouth), Vector2(40 + i * 60, -20))
		await _wait(0.25)
	await _wait(0.4)

	# The bridge's variable comes back, and the bridge with it.
	var tag := _code_tag("int bridgeLength = 4;", mouth)
	tag.scale = Vector2(0.3, 0.3)
	var back := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	back.tween_property(tag, "position", Vector2(160, 84) * ZOOM - tag.size / 2.0, 0.7)
	back.tween_property(tag, "scale", Vector2.ONE, 0.7)
	await back.finished
	Sound.play("code_ok")
	_planks.clear()
	for i in 4:
		_planks.append(_plank(i))
		await _wait(0.12)
	await _wait(0.3)
	_byte.play(&"talk")
	await _say("BYTE", "Look! The bridge remembers how long to be. My world works again!")
	_hush()
	_move(tag, "modulate:a", 0.0, 0.4)

	# The five of them run across to Byte.
	_byte.play(&"idle")
	var run := create_tween().set_parallel()
	for id in Game.HEROES:
		var hero: AnimatedSprite2D = _heroes[id]
		hero.play(&"run")
		run.tween_property(hero, "position:x", CROSSED_X[id], 1.4)
	await run.finished
	for id in Game.HEROES:
		(_heroes[id] as AnimatedSprite2D).play(&"idle")
	await _wait(0.3)


## A hero standing on the ground at `x`, as in the game (feet 16 px below the middle).
func _hero(id: String, x: float) -> AnimatedSprite2D:
	var hero := _anim(load(PLAYER.HERO_DATA[id]["frames"]), &"idle", Vector2(x, GROUND - 16))
	hero.offset = PLAYER.SPRITE_OFFSET
	return hero


## A freed variable flies up out of the chest and off to `to` (a point in the shot), and is gone.
func _free(tag: Control, to: Vector2) -> void:
	Sound.play("fruit", 0.1)
	tag.scale = Vector2(0.3, 0.3)
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(tag, "scale", Vector2.ONE, 0.4)
	t.tween_property(tag, "position", Vector2(tag.position.x, tag.position.y - 50.0), 0.4)
	t.chain().set_ease(Tween.EASE_IN).tween_property(tag, "position", to * ZOOM - tag.size / 2.0, 0.8)
	t.parallel().tween_property(tag, "modulate:a", 0.0, 0.8)
	t.chain().tween_callback(tag.queue_free)


# ---------------- 2. Thanks, and the way home ----------------

func _thanks() -> void:
	_byte.play(&"talk")
	await _say("BYTE", "Chelzy, Sarah, April, Kervin, Psalm: you wrote my world back, one variable at a time.")
	await _say("BYTE", "You make a variable once, you change it when you need to, and you pick the right type. You're real coders now!")
	await _say("BYTE", "It's time you went home. Thank you, friends!")
	_hush()

	# A portal opens, and it takes them one by one.
	_byte.play(&"happy")
	var portal := _anim(SWAP_FX, &"appearing", Vector2(172, 60))
	portal.animation_finished.connect(func(): portal.play(&"disappearing"))
	Sound.play("hero_swap")
	_shake(0.8, 1.5)
	for id in ["psalm", "kervin", "april", "sarah", "chelzy"]:
		var hero: AnimatedSprite2D = _heroes[id]
		hero.play(&"jump")
		var t := create_tween().set_parallel().set_ease(Tween.EASE_IN)
		t.tween_property(hero, "position", Vector2(172, 60), 0.45).set_trans(Tween.TRANS_BACK)
		t.tween_property(hero, "scale", Vector2(0.2, 0.2), 0.45)
		t.tween_property(hero, "modulate:a", 0.0, 0.45)
		Sound.play("hero_swap", 0.15)
		await _wait(0.2)
	await _wait(0.6)
	await _move(_flash, "color:a", 1.0, 0.15).finished
	_fade.color.a = 1.0
	await _move(_flash, "color:a", 0.0, 0.35).finished
	await _wait(0.3)


# ---------------- 3. Home ----------------

func _home() -> void:
	var lab := _lab_room("12:01")
	var screen: ColorRect = lab["screen"]
	var people: Array[Sprite2D] = lab["people"]
	var names: Array[Label] = lab["names"]
	for i in people.size():  # not back yet
		people[i].modulate.a = 0.0
		names[i].visible = false
	screen.color = Color("1d3b5c")
	var byte := _anim(BYTE_FRAMES, &"happy", Vector2(160, 34))
	byte.scale = Vector2(1.5, 1.5)
	_stage.move_child(byte, screen.get_index() + 1)  # on the screen, under its scan lines

	await _fade_in(0.6)
	# They drop back out of the screen, each in a swirl, into the lab.
	for i in [2, 1, 3, 0, 4]:
		var swirl := _anim(SWAP_FX, &"appearing", people[i].position)
		swirl.animation_finished.connect(swirl.queue_free)
		Sound.play("hero_swap", 0.15)
		_move(people[i], "modulate:a", 1.0, 0.3)
		names[i].visible = true
		await _wait(0.18)
	await _wait(0.5)
	await _say("", "Back in the lab, it was just after midnight. Their game was finished - and so was their adventure.")
	byte.play(&"talk")
	Sound.play("terminal_open")
	await _say("BYTE", "Goodbye, coders! Come back and write some Java with me any time.")
	_hush()
	byte.play(&"happy")
	var line := _code_label("System.out.println(\"I can code!\");", 10)
	line.position = Vector2(102, 46) * ZOOM
	_overlay.add_child(line)
	await _type(line, 0.04).finished
	Sound.play("code_ok")
	await _wait(1.2)
	await _fade_out(0.8)


# ---------------- 4. The end ----------------

func _the_end() -> void:
	_new_shot()
	_rect(Color("14112a"), Rect2(Vector2.ZERO, VIEW))
	var title := _caption("THE END", Vector2(160, 40), Color("ffe478"))
	title.add_theme_font_size_override("font_size", 30)
	title.size = Vector2(300, 40)
	title.position = Vector2(160, 40) * ZOOM - title.size / 2.0
	_caption("CODE ODYSSEY", Vector2(160, 62), Color("7cf07c"))
	for i in CREDITS.size():
		var l := _caption(CREDITS[i], Vector2(160, 86 + i * 12))
		l.size = Vector2(600, 12)
		l.position = Vector2(160, 86 + i * 12) * ZOOM - l.size / 2.0
	var press := _caption("PRESS ENTER", Vector2(160, 166), Color(1, 1, 1, 0.6))
	press.visible = false
	Sound.music("final_exam")
	await _fade_in(1.0)
	await _wait(1.0)
	press.visible = true
	_waiting = true
	await _advance
	await _fade_out(0.6)
