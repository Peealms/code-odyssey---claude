extends Node2D
## The scenery of the main menu: an endless side-scroller. The "camera" moves right (the ground
## and obstacles slide left) while ONE runner keeps going and swaps to the hero that suits the
## next obstacle, like in the game:
##   spikes -> Sarah dashes over them           pillar -> Chelzy wall-jumps it
##   saw    -> April double-jumps it            spikes -> Kervin sprints through them
##   slab   -> Psalm shrinks to crawl under it (it floats one tile above the ground)
## Fruit lies along the runner's path (on the ground and in arcs over obstacles) and is
## collected as the runner touches it. Everything is scripted - no physics - so it loops forever.

const GROUND_Y := 312.0  ## Top of the ground (the runner's feet line).
const SPEED := 55.0  ## Scroll speed in px/s.
const SPACING := 270.0  ## Distance between obstacles.
const OBSTACLE_COUNT := 4
const RUNNER_X := 130.0
## [obstacle, hero index] - the hero who clears it.
const SEQUENCE := [["spikes", 1], ["pillar", 0], ["saw", 2], ["spikes", 3], ["slab", 4]]

const HERO_FRAMES := [
	"res://assets/shared/heroes/chelzy/chelzy_frames.tres",
	"res://assets/shared/heroes/sarah/sarah_frames.tres",
	"res://assets/shared/heroes/april/april_frames.tres",
	"res://assets/shared/heroes/kervin/kervin_frames.tres",
	"res://assets/shared/heroes/psalm/psalm_frames.tres",
]
const PLAYER := preload("res://scripts/player/player.gd")
## [width, height] of each obstacle.
const SIZES := {"spikes": [48.0, 16.0], "saw": [38.0, 38.0], "pillar": [32.0, 48.0], "slab": [64.0, 32.0]}
const SHRINK_TIME := 0.3  ## Psalm's shrink animation: 6 frames at 20 fps.

const TERRAIN := preload("res://assets/level1_pixel_adventure/tiles/terrain_16x16.png")
const SPIKES := preload("res://assets/level1_pixel_adventure/traps/spikes/idle.png")
const SAW := preload("res://assets/level1_pixel_adventure/traps/saw/saw_frames.tres")
const FRUITS := preload("res://assets/level1_pixel_adventure/collectibles/fruits/fruits_frames.tres")
const SWAP_FX := preload("res://assets/shared/heroes/swap_fx/swap_fx_frames.tres")
const FONT := preload("res://assets/shared/ui/fonts/pixel_font.fnt")
const FRUIT_NAMES := ["apple", "bananas", "cherries", "kiwi", "melon", "orange", "pineapple", "strawberry"]
const FRUIT_SPACING := 28.0

var _ground: Node2D
var _obstacles: Array = []  ## {node, type, hero, x, done, fruits: [{sprite, rel, lift, alive}]}
var _hero_frames: Array[SpriteFrames] = []
var _runner: AnimatedSprite2D
var _swap_fx: AnimatedSprite2D
var _label: Label
var _hero := 1
var _act := {}
var _ghost_t := 0.0
var _next_index := 0
var _fruit_pick := 0
var _distance := 0.0


func _ready() -> void:
	for path in HERO_FRAMES:
		_hero_frames.append(load(path))
	_build_ground()
	for i in OBSTACLE_COUNT:
		var o := {"node": Node2D.new(), "x": 420.0 + i * SPACING, "fruits": []}
		add_child(o["node"])
		_obstacles.append(o)
		_assign_type(o)
	_runner = AnimatedSprite2D.new()
	_runner.sprite_frames = _hero_frames[_hero]
	_runner.offset = PLAYER.SPRITE_OFFSET  # feet on the ground line (40x40 frames)
	_runner.play(&"run")
	add_child(_runner)
	_swap_fx = AnimatedSprite2D.new()
	_swap_fx.sprite_frames = SWAP_FX
	_swap_fx.visible = false
	_swap_fx.animation_finished.connect(func(): _swap_fx.visible = false)
	add_child(_swap_fx)
	_label = Label.new()
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color("ffe477"))
	_label.add_theme_color_override("font_outline_color", Color("1b1530"))
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(100, 12)
	_label.visible = false
	add_child(_label)
	_runner.position = Vector2(RUNNER_X, GROUND_Y - 16.0)


# ---------------- Ground & obstacles ----------------

func _build_ground() -> void:
	_ground = Node2D.new()
	add_child(_ground)
	for col in 42:
		_ground_tile(Rect2(112, 0, 16, 16), Vector2(col * 16, GROUND_Y))
		_ground_tile(Rect2(112, 16, 16, 16), Vector2(col * 16, GROUND_Y + 16))
		_ground_tile(Rect2(112, 16, 16, 16), Vector2(col * 16, GROUND_Y + 32))


func _ground_tile(region: Rect2, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = TERRAIN
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.position = pos
	_ground.add_child(s)


## Rebuilds an obstacle (and its fruit) for the next entry in the sequence.
func _assign_type(o: Dictionary) -> void:
	var node: Node2D = o["node"]
	for c in node.get_children():
		c.queue_free()
	var entry: Array = SEQUENCE[_next_index % SEQUENCE.size()]
	_next_index += 1
	var type: String = entry[0]
	o["type"] = type
	o["hero"] = entry[1]
	o["done"] = false
	o["fruits"] = []
	var size: Array = SIZES[type]
	match type:
		"spikes":
			for i in 3:
				var s := Sprite2D.new()
				s.texture = SPIKES
				s.centered = false
				s.position = Vector2(i * 16, GROUND_Y - 16)
				node.add_child(s)
		"saw":
			var saw := AnimatedSprite2D.new()
			saw.sprite_frames = SAW
			saw.animation = &"on"
			saw.play()
			saw.position = Vector2(19, GROUND_Y - 19)
			node.add_child(saw)
		"pillar":
			for row in 3:
				for col in 2:
					var s := Sprite2D.new()
					s.texture = TERRAIN
					s.region_enabled = true
					s.region_rect = Rect2(96 + col * 32, 0 if row == 0 else 16, 16, 16)
					s.centered = false
					s.position = Vector2(col * 16, GROUND_Y - 48 + row * 16)
					node.add_child(s)
		"slab":
			# The ground's 3x3 tiles (grass top, edges, underside), floating a tile above the ground.
			for row in 2:
				for col in 4:
					var s := Sprite2D.new()
					s.texture = TERRAIN
					s.region_enabled = true
					var edge := 0 if col == 0 else (2 if col == 3 else 1)
					s.region_rect = Rect2(96 + edge * 16, 0 if row == 0 else 32, 16, 16)
					s.centered = false
					s.position = Vector2(col * 16, GROUND_Y - 48 + row * 16)
					node.add_child(s)
	_place_fruit(o, size[0], entry[1], type)


## Fruit along the runner's path: in an arc that matches the jump over the obstacle, then evenly
## spaced on the ground until the next one. `rel` is the offset from the obstacle's left edge.
func _place_fruit(o: Dictionary, width: float, hero: int, type: String) -> void:
	var plan := _plan(hero, type)
	var span: float = SPEED * plan["d"]
	var mid := width * 0.5
	var spots: Array = []  # [rel x, lift of the fruit above the ground]
	if plan["kind"] == "wall":
		# Up the pillar's near face, where Chelzy climbs.
		spots.append([-12.0, 14.0])
		spots.append([-12.0, 32.0])
		spots.append([-12.0, 50.0])
	elif plan["kind"] == "shrink":
		# Under the slab, low enough for tiny Psalm.
		for k in 3:
			spots.append([12.0 + k * 20.0, 8.0])
	else:
		for k in 3:
			var u := 0.25 + k * 0.25
			spots.append([mid + (u - 0.5) * span, _lift(plan, u) + 14.0])
	var after := width + 55.0
	var limit := SPACING - 130.0
	while after < limit:
		spots.append([after, 14.0])
		after += FRUIT_SPACING
	for sp in spots:
		var f := AnimatedSprite2D.new()
		f.sprite_frames = FRUITS
		f.animation = FRUIT_NAMES[_fruit_pick % FRUIT_NAMES.size()]
		_fruit_pick += 1
		f.play()
		f.position = Vector2(sp[0], GROUND_Y - sp[1])
		(o["node"] as Node2D).add_child(f)
		o["fruits"].append({"sprite": f, "rel": sp[0], "lift": sp[1], "alive": true})


# ---------------- The runner ----------------

## What a hero does about an obstacle: the ability used, and how long clearing it takes.
func _plan(hero: int, type: String) -> Dictionary:
	var size: Array = SIZES[type]
	var d: float = (size[0] + 30.0) / SPEED
	match [hero, type]:
		[0, "pillar"]:
			return {"kind": "wall", "d": 1.45, "tag": "WALL JUMP"}
		[1, "spikes"]:
			return {"kind": "dash", "d": d * 0.9, "tag": "DASH", "apex": 20.0}
		[2, "saw"]:
			return {"kind": "double", "d": d + 0.3, "tag": "DOUBLE JUMP", "apex": size[1] + 30.0}
		[3, "spikes"]:
			return {"kind": "sprint", "d": d * 0.9, "tag": "SPRINT", "apex": 34.0}
		[4, "slab"]:
			# Long enough to be tiny before the slab arrives and to grow back once it's past.
			return {"kind": "shrink", "d": (size[0] + 60.0) / SPEED, "tag": "SHRINK"}
	return {"kind": "jump", "d": d + 0.15, "tag": "", "apex": size[1] + 22.0}


## Lift above the ground at progress `u` (0..1) of a jump-type plan.
func _lift(plan: Dictionary, u: float) -> float:
	var apex: float = plan["apex"]
	match plan["kind"]:
		"dash":
			return apex * minf(1.0, 4.0 * u * (1.0 - u) * 1.6)
		"double":
			if u < 0.45:
				var a := u / 0.45
				return apex * 0.55 * 4.0 * a * (1.0 - a) + apex * 0.25 * a
			var b := (u - 0.45) / 0.55
			var start := apex * 0.25
			return lerpf(start, 0.0, b * b) + (apex - start) * 4.0 * b * (1.0 - b)
	return apex * 4.0 * u * (1.0 - u)


func _process(delta: float) -> void:
	_distance += SPEED * delta
	_ground.position.x = -fmod(_distance, 16.0)
	for o in _obstacles:
		o["x"] -= SPEED * delta
		(o["node"] as Node2D).position.x = o["x"]
		if o["x"] < -110.0:
			o["x"] += SPACING * OBSTACLE_COUNT
			_assign_type(o)
	_update_runner(delta)
	_collect_fruit()


## The next obstacle the runner has not dealt with yet, or an empty dictionary.
func _next_obstacle() -> Dictionary:
	var best := {}
	for o in _obstacles:
		if o["done"]:
			continue
		var size: Array = SIZES[o["type"]]
		if o["x"] + size[0] < RUNNER_X - 40.0:
			continue
		if best.is_empty() or o["x"] < best["x"]:
			best = o
	return best


func _update_runner(delta: float) -> void:
	if _act.is_empty():
		var o := _next_obstacle()
		if not o.is_empty():
			var size: Array = SIZES[o["type"]]
			var plan := _plan(o["hero"], o["type"])
			var centre: float = o["x"] + size[0] * 0.5
			var lead: float = SPEED * plan["d"] * 0.5
			# Swap to the right hero a little before the obstacle needs them.
			if o["hero"] != _hero and centre - RUNNER_X <= lead + 75.0:
				_swap_to(o["hero"])
			if o["hero"] == _hero:
				var ready: bool = (o["x"] - RUNNER_X <= 12.0) if plan["kind"] == "wall" \
					else (centre - RUNNER_X <= lead)
				if ready:
					o["done"] = true
					_act = plan
					_act["t"] = 0.0
					_act["obs"] = o

	var x := RUNNER_X
	var lift := 0.0
	var anim := &"run"
	var tag := ""
	var trail := false
	var growing := false
	if not _act.is_empty():
		_act["t"] += delta
		var u := clampf(_act["t"] / float(_act["d"]), 0.0, 1.0)
		tag = _act["tag"]
		match _act["kind"]:
			"shrink":
				# Psalm shrinks, runs tiny under the slab, then grows (shrink played backwards).
				if _act["t"] < SHRINK_TIME:
					anim = &"shrink"
				elif _act["t"] < float(_act["d"]) - SHRINK_TIME:
					anim = &"small_run"
				else:
					growing = true
					if not _act.has("grown"):
						_act["grown"] = true
						_runner.play_backwards(&"shrink")
			"jump":
				lift = _lift(_act, u)
				anim = &"jump" if u < 0.5 else &"fall"
			"dash":
				# Sarah's dash animation brings its own afterimages, so no trail here.
				lift = _lift(_act, u)
				if u > 0.12 and u < 0.9:
					anim = &"dash"
				else:
					anim = &"jump" if u < 0.2 else &"fall"
				x += 14.0 * sin(u * PI)
			"sprint":
				# Kervin's sprint animation has speed lines; in the air the trail shows the speed.
				lift = _lift(_act, u)
				var on_ground := u < 0.25 or u > 0.75
				anim = &"sprint" if on_ground else (&"jump" if u < 0.5 else &"fall")
				trail = not on_ground
				x += 24.0 * sin(u * PI)
			"double":
				lift = _lift(_act, u)
				if u < 0.45:
					anim = &"jump"
				else:
					anim = &"double_jump" if (u - 0.45) / 0.55 < 0.55 else &"fall"
			"wall":
				var o: Dictionary = _act["obs"]
				var climb := 0.48
				if u < climb:
					# Cling to the pillar's near face (facing it) and climb while it slides past.
					# Chelzy's wall pose reaches 9 px right of the sprite's centre, so 10 px leaves no gap.
					x = o["x"] - 10.0
					lift = 52.0 * (u / climb)
					anim = &"wall_jump"
				else:
					var b := (u - climb) / (1.0 - climb)
					if not _act.has("from_x"):
						_act["from_x"] = o["x"] - 10.0
					x = lerpf(_act["from_x"], RUNNER_X, smoothstep(0.0, 1.0, b))
					lift = lerpf(52.0, 0.0, b) + 16.0 * 4.0 * b * (1.0 - b)
					anim = &"jump" if b < 0.45 else &"fall"
		if _act["t"] >= float(_act["d"]):
			_act = {}

	_runner.position = Vector2(x, GROUND_Y - 16.0 - lift)
	_runner.flip_h = false
	if growing:
		pass  # growing back: started above, left to play out
	elif anim == &"shrink":
		if _runner.animation != anim:
			_runner.play(anim)  # once: it must not restart when it ends
	elif _runner.animation != anim or not _runner.is_playing():
		_runner.play(anim)
	_label.visible = tag != ""
	if tag != "":
		_label.text = tag
		_label.position = Vector2(maxf(_runner.position.x - 50.0, 4.0), _runner.position.y - 40.0)
	if trail:
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = 0.05
			_spawn_ghost()


func _swap_to(hero: int) -> void:
	_hero = hero
	_runner.sprite_frames = _hero_frames[hero]
	_runner.play(&"run")
	_swap_fx.position = _runner.position
	_swap_fx.visible = true
	_swap_fx.play(&"appearing")


## Picks up any fruit the runner is touching.
func _collect_fruit() -> void:
	for o in _obstacles:
		for f in o["fruits"]:
			if not f["alive"]:
				continue
			var sprite: AnimatedSprite2D = f["sprite"]
			if not is_instance_valid(sprite):
				continue
			if sprite.global_position.distance_to(_runner.global_position) < 20.0:
				f["alive"] = false
				sprite.play(&"collected")
				sprite.animation_finished.connect(sprite.queue_free)


func _spawn_ghost() -> void:
	var tex := _runner.sprite_frames.get_frame_texture(_runner.animation, _runner.frame)
	if tex == null:
		return
	var g := Sprite2D.new()
	g.texture = tex
	g.offset = _runner.offset
	g.flip_h = _runner.flip_h
	g.position = _runner.position
	g.modulate = Color(1, 1, 1, 0.5)
	add_child(g)
	move_child(g, _runner.get_index())
	var tw := create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)
