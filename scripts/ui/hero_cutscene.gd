extends CanvasLayer
## The hero-rescue cutscene (started by the Level when a rescue flag is touched with all fruit):
##   1. the game pauses and the camera zooms in on the waiting hero
##   2. the hero flashes in, and Byte introduces them in a dialogue box
##   3. an ability card shows the hero performing their move on a loop, the key to press,
##      the stamina cost and how to switch to them in code
## Enter / Space / F (or the button) moves on; when it's over `finished` fires.

signal finished
signal _advance

const PLAYER := preload("res://scripts/player/player.gd")
const BYTE_FRAMES := preload("res://assets/shared/byte/byte_frames.tres")
const SWAP_FX := preload("res://assets/shared/heroes/swap_fx/swap_fx_frames.tres")

## What each hero's card says, and which demo to play.
const ABILITIES := {
	"ninja_frog": {"ability": "WALL JUMP", "code": "NinjaFrog",
		"how": "Jump at a wall and press JUMP again while touching it to kick off and climb.",
		"cost": "Clinging and each wall jump use stamina."},
	"pink_man": {"ability": "DASH", "code": "PinkMan",
		"how": "Press SHIFT to dash forward - in the air it carries you over wide gaps.",
		"cost": "Each dash uses 35 stamina."},
	"mask_dude": {"ability": "DOUBLE JUMP", "code": "MaskDude",
		"how": "Press JUMP a second time while in the air to jump again, twice as high.",
		"cost": "Each double jump uses 35 stamina."},
	"virtual_guy": {"ability": "SPRINT", "code": "VirtualGuy",
		"how": "Hold SHIFT while running to sprint almost twice as fast.",
		"cost": "Sprinting drains stamina while you hold it."},
}

const INK := Color("33323d")
const WOOD := Color("ae7764")
const WOOD_DARK := Color("833f4c")
const PAPER := Color("eebd8a")
const PAPER_EDGE := Color("b77357")
const STAGE := Color("2b2a3a")

var _dialog: PanelContainer
var _dialog_text: Label
var _card: Control
var _demo_hero: AnimatedSprite2D
var _demo_stage: Control
var _accept_ready := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 70


func play(hero_id: String, checkpoint: Node, player: Node2D) -> void:
	var data: Dictionary = ABILITIES[hero_id]
	var hero_name: String = PLAYER.HERO_DATA[hero_id]["name"]
	get_tree().paused = true
	# Hide the HUD, hotbar and other screen layers so the scene is clean.
	var hidden: Array[CanvasLayer] = []
	for n in get_parent().get_children():
		if n is CanvasLayer and n != self and n.visible and n.layer >= 0:
			n.visible = false
			hidden.append(n)

	# 1. Camera zooms in on the waiting hero.
	var cam: Camera2D = player.get_node("Camera2D")
	var old_mode := cam.process_mode
	cam.process_mode = Node.PROCESS_MODE_ALWAYS
	var npc: AnimatedSprite2D = checkpoint.npc
	npc.process_mode = Node.PROCESS_MODE_ALWAYS
	var focus := npc.global_position - (player.global_position + cam.position)
	var zoom_in := create_tween().set_parallel()
	zoom_in.tween_property(cam, "offset", focus, 0.7).set_trans(Tween.TRANS_SINE)
	zoom_in.tween_property(cam, "zoom", Vector2(1.7, 1.7), 0.7).set_trans(Tween.TRANS_SINE)
	await zoom_in.finished

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

	_build_dialog()
	await _say("%s JOINED THE TEAM!" % hero_name.to_upper())
	await _say("Let me show you what %s can do..." % hero_name)
	_dialog.queue_free()

	# 3. Ability card with a looping demo.
	_build_card(hero_id, hero_name, data)
	await _advance
	var fade := create_tween()
	fade.tween_property(_card, "modulate:a", 0.0, 0.25)
	await fade.finished
	_card.queue_free()
	_demo_hero = null

	# Back to the game.
	var zoom_out := create_tween().set_parallel()
	zoom_out.tween_property(cam, "offset", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_SINE)
	zoom_out.tween_property(cam, "zoom", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	await zoom_out.finished
	cam.process_mode = old_mode
	npc.process_mode = Node.PROCESS_MODE_INHERIT
	for n in hidden:
		if is_instance_valid(n):
			n.visible = true
	get_tree().paused = false
	finished.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if not _accept_ready:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_accept_ready = false
		_advance.emit()


## Shows a line in Byte's dialogue box, typed out letter by letter, then waits for a key
## (or moves on by itself after a few seconds).
func _say(text: String) -> void:
	_dialog_text.text = text
	_dialog_text.visible_characters = 0
	for i in text.length():
		_dialog_text.visible_characters = i + 1
		await get_tree().create_timer(0.02).timeout
	_accept_ready = true
	var auto := get_tree().create_timer(3.0)
	auto.timeout.connect(func():
		if _accept_ready:
			_accept_ready = false
			_advance.emit())
	await _advance


# ---------------- Building the boxes ----------------

func _build_dialog() -> void:
	_dialog = PanelContainer.new()
	_dialog.add_theme_stylebox_override("panel", _box(PAPER, INK, 2, Vector4(8, 6, 10, 6), PAPER_EDGE))
	_dialog.anchor_left = 0.5
	_dialog.anchor_right = 0.5
	_dialog.anchor_top = 1.0
	_dialog.anchor_bottom = 1.0
	_dialog.offset_left = -200
	_dialog.offset_right = 200
	_dialog.offset_top = -72
	_dialog.offset_bottom = -12
	add_child(_dialog)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_dialog.add_child(row)
	var face_box := Control.new()
	face_box.custom_minimum_size = Vector2(40, 40)
	row.add_child(face_box)
	var face := AnimatedSprite2D.new()
	face.sprite_frames = BYTE_FRAMES
	face.play("talk")
	face.scale = Vector2(1.5, 1.5)
	face.position = Vector2(20, 22)
	face_box.add_child(face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var who := Label.new()
	who.text = "BYTE"
	who.add_theme_color_override("font_color", WOOD_DARK)
	col.add_child(who)
	_dialog_text = Label.new()
	_dialog_text.add_theme_color_override("font_color", INK)
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_dialog_text.custom_minimum_size = Vector2(320, 0)
	col.add_child(_dialog_text)


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
	if hero_id == "ninja_frog":
		_demo_stage.draw_rect(Rect2(110, 0, 8, s.y - 10), Color("9aa3b5"))
		_demo_stage.draw_rect(Rect2(160, 0, 8, s.y - 10), Color("9aa3b5"))


## Loops a short tween that acts out the ability.
func _run_demo(hero_id: String) -> void:
	var ground := _demo_stage.size.y - 10 - 24
	while is_instance_valid(_demo_hero):
		_demo_hero.position = Vector2(24, ground)
		_demo_hero.modulate.a = 1.0
		_demo_hero.flip_h = false
		_demo_hero.speed_scale = 1.0
		# Bound to the demo sprite, so the loop stops by itself when the card is closed.
		var t := _demo_hero.create_tween()
		match hero_id:
			"pink_man":
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 70.0, 0.5)
				t.tween_callback(_demo_hero.play.bind("jump"))
				t.tween_property(_demo_hero, "position", Vector2(95, ground - 26), 0.3).set_ease(Tween.EASE_OUT)
				t.tween_callback(_ghosts.bind(4))
				t.tween_property(_demo_hero, "position:x", 185.0, 0.16)
				t.tween_callback(_demo_hero.play.bind("fall"))
				t.tween_property(_demo_hero, "position", Vector2(210, ground), 0.3).set_ease(Tween.EASE_IN)
				t.tween_callback(_demo_hero.play.bind("idle"))
			"mask_dude":
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 80.0, 0.5)
				t.tween_callback(_demo_hero.play.bind("jump"))
				t.tween_property(_demo_hero, "position", Vector2(115, ground - 26), 0.3).set_ease(Tween.EASE_OUT)
				t.tween_callback(_demo_hero.play.bind("double_jump"))
				t.tween_property(_demo_hero, "position", Vector2(150, ground - 50), 0.3).set_ease(Tween.EASE_OUT)
				t.tween_callback(_demo_hero.play.bind("fall"))
				t.tween_property(_demo_hero, "position", Vector2(200, ground), 0.45).set_ease(Tween.EASE_IN)
				t.tween_callback(_demo_hero.play.bind("idle"))
			"virtual_guy":
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 100.0, 0.7)
				t.tween_callback(func(): _demo_hero.speed_scale = 1.8)
				t.tween_callback(_ghosts.bind(3))
				t.tween_property(_demo_hero, "position:x", 236.0, 0.4)
				t.tween_callback(_demo_hero.play.bind("idle"))
			_:  # ninja_frog: climb between two walls
				t.tween_callback(_demo_hero.play.bind("run"))
				t.tween_property(_demo_hero, "position:x", 100.0, 0.4)
				for i in 3:
					var x := 152.0 if i % 2 == 0 else 126.0
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


## Faded copies of the demo hero left behind, for a sense of speed.
func _ghosts(count: int) -> void:
	if not is_instance_valid(_demo_hero):
		return
	for i in count:
		var g := AnimatedSprite2D.new()
		g.sprite_frames = _demo_hero.sprite_frames
		g.animation = _demo_hero.animation
		g.scale = _demo_hero.scale
		g.position = _demo_hero.position - Vector2(i * 12, 0)
		g.modulate = Color(1, 1, 1, 0.45 - i * 0.1)
		_demo_stage.add_child(g)
		var fade := g.create_tween()
		fade.tween_property(g, "modulate:a", 0.0, 0.35)
		fade.tween_callback(g.queue_free)


func _box(fill: Color, border: Color, width: int, padding: Vector4, bottom := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(3)
	s.corner_detail = 2
	s.anti_aliasing = false
	s.content_margin_left = padding.x
	s.content_margin_top = padding.y
	s.content_margin_right = padding.z
	s.content_margin_bottom = padding.w
	if bottom.a > 0.0:
		s.shadow_color = bottom
		s.shadow_offset = Vector2(0, 2)
	return s
