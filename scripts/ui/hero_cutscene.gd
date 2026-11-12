extends ByteTalk
## The hero-rescue cutscene (started by the Level when a rescue flag is touched with all fruit):
##   1. the game pauses and the camera zooms in on the waiting hero
##   2. the hero flashes in, and Byte introduces them in a dialogue box
##   3. an ability card shows the hero performing their move on a loop, the key to press,
##      the stamina cost and how to switch to them in code
## Enter / Space / F (or the button) moves on; when it's over `finished` fires.
## Pausing, the camera and Byte's dialogue box come from ByteTalk (byte_talk.gd).

const PLAYER := preload("res://scripts/player/player.gd")
const SWAP_FX := preload("res://assets/shared/heroes/swap_fx/swap_fx_frames.tres")

## What each hero's card says, and which demo to play.
const ABILITIES := {
	"chelzy": {"ability": "WALL JUMP", "code": "Chelzy",
		"how": "Jump at a wall and press JUMP again while touching it to kick off and climb.",
		"cost": "Clinging and each wall jump use stamina."},
	"sarah": {"ability": "DASH", "code": "Sarah",
		"how": "Press SHIFT to dash forward - in the air it carries you over wide gaps.",
		"cost": "Each dash uses 35 stamina."},
	"april": {"ability": "DOUBLE JUMP", "code": "April",
		"how": "Press JUMP a second time while in the air to jump again, twice as high.",
		"cost": "Each double jump uses 35 stamina."},
	"kervin": {"ability": "SPRINT", "code": "Kervin",
		"how": "Hold SHIFT while running to sprint almost twice as fast.",
		"cost": "Sprinting drains stamina while you hold it."},
	"psalm": {"ability": "SHRINK", "code": "Psalm",
		"how": "Hold DOWN to shrink into tiny tunnels. Let go to grow back.",
		"cost": "Staying small drains stamina, but not while you're squeezed in a tunnel."},
}

const STAGE := Color("2b2a3a")

var _card: Control
var _demo_hero: AnimatedSprite2D
var _demo_stage: Control


func play(hero_id: String, checkpoint: Node, player: Node2D) -> void:
	var data: Dictionary = ABILITIES[hero_id]
	var hero_name: String = PLAYER.HERO_DATA[hero_id]["name"]
	begin(player)
	Sound.play("rescue")

	# 1. Camera zooms in on the waiting hero.
	var npc: AnimatedSprite2D = checkpoint.npc
	npc.process_mode = Node.PROCESS_MODE_ALWAYS
	await point_camera(npc.global_position, 1.7)

	# 2. The hero flashes in.
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = SWAP_FX
	fx.process_mode = Node.PROCESS_MODE_ALWAYS
	fx.z_index = 10
	npc.add_child(fx)
	fx.play("appearing")
	var flash := create_tween()
	flash.tween_property(npc, "modulate", Color.WHITE, 0.3)
	flash.parallel().tween_property(npc, "scale", Vector2(1.3, 1.3), 0.15)
	flash.tween_property(npc, "scale", Vector2.ONE, 0.15)
	npc.play("double_jump" if npc.sprite_frames.has_animation("double_jump") else "jump")
	await fx.animation_finished
	fx.queue_free()
	npc.play("idle")

	await say("%s JOINED THE TEAM!" % hero_name.to_upper())
	await say("Let me show you what %s can do..." % hero_name)
	hide_dialog()

	# 3. Ability card with a looping demo.
	_build_card(hero_id, hero_name, data)
	await _advance
	var fade := create_tween()
	fade.tween_property(_card, "modulate:a", 0.0, 0.25)
	await fade.finished
	_card.queue_free()
	_demo_hero = null

	# Back to the game.
	npc.process_mode = Node.PROCESS_MODE_INHERIT
	await end()


# ---------------- The ability card ----------------

func _build_card(hero_id: String, hero_name: String, data: Dictionary) -> void:
	# Full-screen holder: a dark backdrop with the card centred on top.
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_card)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.add_child(center)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _box(WOOD, INK, 1, Vector4(3, 3, 3, 3), WOOD_DARK))
	center.add_child(frame)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", _box(PAPER, WOOD_DARK, 1, Vector4(14, 10, 14, 10)))
	frame.add_child(paper)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	paper.add_child(col)

	var title := Label.new()
	title.text = "NEW HERO: %s" % hero_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", INK)
	col.add_child(title)
	var ability := Label.new()
	ability.text = "ABILITY: %s" % data.ability
	ability.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability.add_theme_color_override("font_color", WOOD_DARK)
	col.add_child(ability)

	# Demo stage: the hero performs the move on a loop.
	_demo_stage = Control.new()
	_demo_stage.custom_minimum_size = Vector2(260, 84)
	_demo_stage.clip_contents = true
	_demo_stage.draw.connect(_draw_stage.bind(hero_id))
	col.add_child(_demo_stage)
	_demo_hero = AnimatedSprite2D.new()
	_demo_hero.sprite_frames = load(PLAYER.HERO_DATA[hero_id]["frames"])
	_demo_hero.offset = PLAYER.SPRITE_OFFSET
	_demo_hero.scale = Vector2(1.5, 1.5)
	_demo_stage.add_child(_demo_hero)
	_run_demo.call_deferred(hero_id)

	for line in [data.how, data.cost]:
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size = Vector2(260, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", INK)
		col.add_child(l)
	var how_to := Label.new()
	how_to.text = "SWITCH TO THEM IN BYTE'S TERMINAL:"
	how_to.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how_to.add_theme_color_override("font_color", Color("2e7d32"))
	col.add_child(how_to)
	# Code in a monospace font, so capitals show exactly as Java needs them.
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Courier New", "Monospace"])
	var code := Label.new()
	code.text = "hero = \"%s\";" % data.code
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code.add_theme_font_override("font", mono)
	code.add_theme_font_size_override("font_size", 10)
	code.add_theme_color_override("font_color", Color("2e7d32"))
	col.add_child(code)

	var button := Button.new()
	button.text = "GOT IT!"
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func():
		_accept_ready = false
		_advance.emit())
	col.add_child(button)
	button.grab_focus()
	_accept_ready = true
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.25)


func _draw_stage(hero_id: String) -> void:
	var s := _demo_stage.size
	_demo_stage.draw_rect(Rect2(Vector2.ZERO, s), STAGE)
	_demo_stage.draw_rect(Rect2(0, s.y - 10, s.x, 10), Color("5b8c3a"))
	_demo_stage.draw_rect(Rect2(0, s.y - 10, s.x, 2), Color("7cbf4a"))
	if hero_id == "chelzy":
		_demo_stage.draw_rect(Rect2(110, 0, 8, s.y - 10), Color("9aa3b5"))
		_demo_stage.draw_rect(Rect2(160, 0, 8, s.y - 10), Color("9aa3b5"))
	elif hero_id == "psalm":
		# A tunnel too low for him until he shrinks.
		_demo_stage.draw_rect(Rect2(110, 0, 60, s.y - 32), Color("9aa3b5"))


## Loops a short tween that acts out the ability.
func _run_demo(hero_id: String) -> void:
	var ground := _demo_stage.size.y - 10 - 24
	while is_instance_valid(_demo_hero):
		_demo_hero.position = Vector2(24, ground)
		_demo_hero.modulate.a = 1.0
		_demo_hero.flip_h = false
		# Bound to the demo sprite, so the loop stops by itself when the card is closed.
		var t := _demo_hero.create_tween()
		match hero_id:
			"sarah":
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 70.0, 0.5)
				t.tween_callback(_demo_hero.play.bind("jump"))
				t.tween_property(_demo_hero, "position", Vector2(95, ground - 26), 0.3).set_ease(Tween.EASE_OUT)
				t.tween_callback(_demo_hero.play.bind("dash"))  # the animation has its own afterimages
				t.tween_property(_demo_hero, "position:x", 185.0, 0.16)
				t.tween_callback(_demo_hero.play.bind("fall"))
				t.tween_property(_demo_hero, "position", Vector2(210, ground), 0.3).set_ease(Tween.EASE_IN)
				t.tween_callback(_demo_hero.play.bind("idle"))
			"april":
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 80.0, 0.5)
				t.tween_callback(_demo_hero.play.bind("jump"))
				t.tween_property(_demo_hero, "position", Vector2(115, ground - 26), 0.3).set_ease(Tween.EASE_OUT)
				t.tween_callback(_demo_hero.play.bind("double_jump"))
				t.tween_property(_demo_hero, "position", Vector2(150, ground - 50), 0.3).set_ease(Tween.EASE_OUT)
				t.tween_callback(_demo_hero.play.bind("fall"))
				t.tween_property(_demo_hero, "position", Vector2(200, ground), 0.45).set_ease(Tween.EASE_IN)
				t.tween_callback(_demo_hero.play.bind("idle"))
			"kervin":
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 100.0, 0.7)
				t.tween_callback(_demo_hero.play.bind("sprint"))
				t.tween_property(_demo_hero, "position:x", 236.0, 0.4)
				t.tween_callback(_demo_hero.play.bind("idle"))
			"psalm":
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 80.0, 0.45)
				t.tween_callback(_demo_hero.play.bind("shrink"))
				t.tween_interval(0.35)
				t.tween_callback(_demo_hero.play.bind("small_run"))
				t.tween_property(_demo_hero, "position:x", 196.0, 0.9)
				t.tween_callback(_demo_hero.play_backwards.bind("shrink"))  # grows back
				t.tween_interval(0.35)
				t.tween_callback(_demo_hero.play.bind("idle"))
			_:  # chelzy: climb between two walls
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 100.0, 0.4)
				for i in 3:
					var x := 152.0 if i % 2 == 0 else 126.0
					# Face the way the jump goes, so the wall pose grips the wall it lands on.
					t.tween_callback(func(): _demo_hero.flip_h = x < 140.0)
					t.tween_callback(_demo_hero.play.bind("jump"))
					t.tween_property(_demo_hero, "position", Vector2(x, ground - 18 - i * 16), 0.22)
					t.tween_callback(_demo_hero.play.bind("wall_jump"))
					t.tween_interval(0.12)
				t.tween_callback(_demo_hero.play.bind("fall"))
				t.tween_property(_demo_hero, "position", Vector2(140, ground), 0.35)
				t.tween_callback(_demo_hero.play.bind("idle"))
		t.tween_interval(0.6)
		t.tween_property(_demo_hero, "modulate:a", 0.0, 0.2)
		await t.finished
		if not is_instance_valid(_demo_hero) or not _demo_hero.is_inside_tree():
			return
