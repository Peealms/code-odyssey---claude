extends Node2D
## The animated scenery of the main menu: the four heroes showing off their special abilities
## on a looping course of spikes, a saw and a fire trap, plus floating fruit and drifting code.
##   Ninja Frog  -> wall jump (climbs the pillar, leaps over the spikes, jumps back)
##   Pink Man    -> dash (hops, dashes through the air over the spikes)
##   Mask Dude   -> double jump (over a saw hovering above the spikes)
##   Virtual Guy -> sprint (the fire trap goes out, he sprints through)
## Everything is driven by small keyframe lists (see `_build_actors`) so no physics is involved.

const GROUND_Y := 312.0  ## Feet line (top of the menu's ground strip).

const FROG := "res://assets/shared/heroes/ninja_frog/ninja_frog_frames.tres"
const PINK := "res://assets/shared/heroes/pink_man/pink_man_frames.tres"
const MASK := "res://assets/shared/heroes/mask_dude/mask_dude_frames.tres"
const VIRTUAL := "res://assets/shared/heroes/virtual_guy/virtual_guy_frames.tres"
const TERRAIN := preload("res://assets/level1_pixel_adventure/tiles/terrain_16x16.png")
const SPIKES := preload("res://assets/level1_pixel_adventure/traps/spikes/idle.png")
const SAW := preload("res://assets/level1_pixel_adventure/traps/saw/saw_frames.tres")
const FIRE := preload("res://assets/level1_pixel_adventure/traps/fire/fire_frames.tres")
const FRUITS := preload("res://assets/level1_pixel_adventure/collectibles/fruits/fruits_frames.tres")
const FONT := preload("res://assets/shared/ui/fonts/pixel_font.fnt")

const SNIPPETS := [
	"int hp = 3;", "var speed = 2.5;", "if (key) {", "}", "// TODO", "bool done = true;",
	"string name;", "float jump = 1.5;", "int coins = 0;", "return x;", "{ }", ";",
]

var _actors: Array = []
var _fire: AnimatedSprite2D
var _backdrop: Node2D
var _floaters: Array = []  ## {node, base_y, speed, phase, kind}
var _time := 0.0


func _ready() -> void:
	# The backdrop sits right above the background but under the logo and buttons.
	_backdrop = Node2D.new()
	get_parent().add_child.call_deferred(_backdrop)
	get_parent().move_child.call_deferred(_backdrop, 1)
	_build_backdrop()
	_build_props()
	_build_actors()


# ---------------- Backdrop: fruit + floating code ----------------

func _build_backdrop() -> void:
	var fruit_names := ["apple", "bananas", "cherries", "kiwi", "melon", "orange", "pineapple", "strawberry"]
	var spots := [Vector2(40, 60), Vector2(96, 150), Vector2(30, 215), Vector2(200, 40),
		Vector2(205, 190), Vector2(600, 62), Vector2(545, 150), Vector2(610, 215),
		Vector2(440, 40), Vector2(430, 190)]
	for i in spots.size():
		var f := AnimatedSprite2D.new()
		f.sprite_frames = FRUITS
		f.animation = fruit_names[i % fruit_names.size()]
		f.play()
		f.position = spots[i]
		_backdrop.add_child(f)
		_floaters.append({"node": f, "base_y": spots[i].y, "speed": 0.0, "phase": i * 1.3, "kind": "fruit"})
	for i in 12:
		var l := Label.new()
		l.text = SNIPPETS[i]
		l.add_theme_font_override("font", FONT)
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", Color(0.18, 0.27, 0.5, 0.55))
		var y := 18.0 + float((i * 47) % 250)
		l.position = Vector2(float(i * 61 % 640), y)
		_backdrop.add_child(l)
		_floaters.append({"node": l, "base_y": y, "speed": 8.0 + float(i % 4) * 3.0, "phase": i, "kind": "code"})


# ---------------- Static props ----------------

func _build_props() -> void:
	# Pillar for the wall jump: 2 tiles wide, 5 tall, from the grass block of the terrain sheet.
	_add_tile(Rect2(96, 0, 16, 16), Vector2(0, GROUND_Y - 80))
	_add_tile(Rect2(128, 0, 16, 16), Vector2(16, GROUND_Y - 80))
	for row in range(1, 5):
		_add_tile(Rect2(96, 16, 16, 16), Vector2(0, GROUND_Y - 80 + row * 16))
		_add_tile(Rect2(128, 16, 16, 16), Vector2(16, GROUND_Y - 80 + row * 16))
	# Spike patches: under the frog's leap, the pink dash, the double jump.
	_add_spikes(72, 3)
	_add_spikes(176, 3)
	_add_spikes(444, 4)
	# Saw hovering over the double-jump spikes.
	var saw := AnimatedSprite2D.new()
	saw.sprite_frames = SAW
	saw.animation = &"on"
	saw.play()
	saw.position = Vector2(476, GROUND_Y - 27)
	add_child(saw)
	# Fire trap for the sprint.
	_fire = AnimatedSprite2D.new()
	_fire.sprite_frames = FIRE
	_fire.animation = &"on"
	_fire.play()
	_fire.position = Vector2(596, GROUND_Y - 16)
	add_child(_fire)


func _add_tile(region: Rect2, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = TERRAIN
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.position = pos
	add_child(s)


func _add_spikes(x: float, count: int) -> void:
	for i in count:
		var s := Sprite2D.new()
		s.texture = SPIKES
		s.centered = false
		s.position = Vector2(x + i * 16, GROUND_Y - 16)
		add_child(s)


# ---------------- Heroes ----------------

## Keyframes: d = seconds, to = feet position, arc = extra lift in px (a hop), anim = name or
## [first half, second half], flip = faces left, ease = "in" / "out", tag = ability label,
## trail = leave afterimages, fire_off = the fire trap is out during this step.
func _build_actors() -> void:
	_add_actor(FROG, Vector2(46, GROUND_Y), [
		{"d": 1.3, "to": Vector2(46, 262), "anim": "wall_jump", "tag": "WALL JUMP"},
		{"d": 1.0, "to": Vector2(124, GROUND_Y), "arc": 70, "anim": ["jump", "fall"]},
		{"d": 0.7, "to": Vector2(124, GROUND_Y), "anim": "idle", "flip": true},
		{"d": 0.9, "to": Vector2(46, 268), "arc": 50, "anim": ["jump", "fall"], "flip": true},
		{"d": 0.7, "to": Vector2(46, GROUND_Y), "anim": "wall_jump", "tag": "WALL JUMP"},
	])
	_add_actor(PINK, Vector2(152, GROUND_Y), [
		{"d": 0.9, "to": Vector2(152, GROUND_Y), "anim": "idle"},
		{"d": 0.28, "to": Vector2(168, 268), "anim": "jump", "ease": "out"},
		{"d": 0.34, "to": Vector2(236, 268), "anim": "fall", "tag": "DASH", "trail": true},
		{"d": 0.3, "to": Vector2(246, GROUND_Y), "anim": "fall", "ease": "in"},
		{"d": 0.9, "to": Vector2(246, GROUND_Y), "anim": "idle", "flip": true},
		{"d": 0.28, "to": Vector2(232, 268), "anim": "jump", "ease": "out", "flip": true},
		{"d": 0.34, "to": Vector2(162, 268), "anim": "fall", "tag": "DASH", "trail": true, "flip": true},
		{"d": 0.3, "to": Vector2(152, GROUND_Y), "anim": "fall", "ease": "in", "flip": true},
	])
	_add_actor(MASK, Vector2(424, GROUND_Y), [
		{"d": 0.9, "to": Vector2(424, GROUND_Y), "anim": "idle"},
		{"d": 0.35, "to": Vector2(448, 252), "anim": "jump", "ease": "out"},
		{"d": 0.3, "to": Vector2(478, 212), "anim": "double_jump", "tag": "DOUBLE JUMP", "ease": "out"},
		{"d": 0.5, "to": Vector2(530, GROUND_Y), "anim": "fall", "ease": "in"},
		{"d": 0.9, "to": Vector2(530, GROUND_Y), "anim": "idle", "flip": true},
		{"d": 0.35, "to": Vector2(506, 252), "anim": "jump", "ease": "out", "flip": true},
		{"d": 0.3, "to": Vector2(478, 212), "anim": "double_jump", "tag": "DOUBLE JUMP", "ease": "out", "flip": true},
		{"d": 0.5, "to": Vector2(424, GROUND_Y), "anim": "fall", "ease": "in", "flip": true},
	])
	_add_actor(VIRTUAL, Vector2(570, GROUND_Y), [
		{"d": 0.7, "to": Vector2(570, GROUND_Y), "anim": "idle"},
		{"d": 0.4, "to": Vector2(570, GROUND_Y), "anim": "idle", "fire_off": true},
		{"d": 0.45, "to": Vector2(622, GROUND_Y), "anim": "run", "tag": "SPRINT", "trail": true, "fire_off": true},
		{"d": 0.7, "to": Vector2(622, GROUND_Y), "anim": "idle", "flip": true},
		{"d": 0.4, "to": Vector2(622, GROUND_Y), "anim": "idle", "flip": true, "fire_off": true},
		{"d": 0.45, "to": Vector2(570, GROUND_Y), "anim": "run", "tag": "SPRINT", "trail": true,
			"flip": true, "fire_off": true},
	])


func _add_actor(frames_path: String, start: Vector2, steps: Array) -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load(frames_path)
	add_child(sprite)
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("ffe477"))
	label.add_theme_color_override("font_outline_color", Color("1b1530"))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(90, 12)
	label.visible = false
	add_child(label)
	_actors.append({
		"sprite": sprite, "label": label, "steps": steps,
		"index": 0, "t": 0.0, "from": start, "ghost_t": 0.0,
	})
	sprite.position = start + Vector2(0, -16)


func _process(delta: float) -> void:
	_time += delta
	_update_floaters()
	var fire_off := false
	for a in _actors:
		if _step_actor(a, delta):
			fire_off = true
	var want: StringName = &"off" if fire_off else &"on"
	if _fire.animation != want:
		_fire.play(want)


## Advances one hero along its keyframes; returns true if the fire trap should be out.
func _step_actor(a: Dictionary, delta: float) -> bool:
	var steps: Array = a["steps"]
	var step: Dictionary = steps[a["index"]]
	a["t"] += delta
	var u := clampf(a["t"] / float(step["d"]), 0.0, 1.0)
	var e := u
	match step.get("ease", ""):
		"in":
			e = u * u
		"out":
			e = 1.0 - (1.0 - u) * (1.0 - u)
	var from: Vector2 = a["from"]
	var feet := from.lerp(step["to"], e)
	feet.y -= float(step.get("arc", 0)) * 4.0 * u * (1.0 - u)
	var sprite: AnimatedSprite2D = a["sprite"]
	sprite.position = feet + Vector2(0, -16)
	sprite.flip_h = step.get("flip", false)
	var anim: Variant = step["anim"]
	var name_now: StringName = StringName(anim[0] if u < 0.5 else anim[1]) if anim is Array else StringName(anim)
	if sprite.animation != name_now or not sprite.is_playing():
		sprite.play(name_now)
	# Ability label above the hero.
	var label: Label = a["label"]
	var tag: String = step.get("tag", "")
	label.visible = tag != ""
	if tag != "":
		label.text = tag
		label.position = feet + Vector2(-45, -52)
	# Afterimages for dash / sprint.
	if step.get("trail", false):
		a["ghost_t"] -= delta
		if a["ghost_t"] <= 0.0:
			a["ghost_t"] = 0.05
			_spawn_ghost(sprite)
	if a["t"] >= float(step["d"]):
		a["from"] = step["to"]
		a["t"] = 0.0
		a["index"] = (a["index"] + 1) % steps.size()
	return step.get("fire_off", false)


func _spawn_ghost(sprite: AnimatedSprite2D) -> void:
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return
	var g := Sprite2D.new()
	g.texture = tex
	g.position = sprite.position
	g.flip_h = sprite.flip_h
	g.modulate = Color(1, 1, 1, 0.5)
	add_child(g)
	move_child(g, sprite.get_index())
	var tw := create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)


func _update_floaters() -> void:
	for f in _floaters:
		var n: Node2D = f["node"] if f["node"] is Node2D else null
		if f["kind"] == "fruit":
			n.position.y = f["base_y"] + roundf(sin(_time * 2.0 + f["phase"]) * 4.0)
		else:
			var l: Label = f["node"]
			l.position.x += get_process_delta_time() * f["speed"]
			if l.position.x > 650.0:
				l.position.x = -90.0
			# Fade out behind the logo and buttons so the code never clutters them.
			var mid := l.position.x + 40.0
			l.modulate.a = clampf((absf(mid - 320.0) - 110.0) / 60.0, 0.0, 1.0)
