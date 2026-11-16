extends Node2D
## The scenery of the main menu: an endless side-scroller. The "camera" moves right (the ground
## and obstacles slide left) while ONE runner keeps going and swaps to the hero that suits the
## next obstacle, like in the game:
##   spikes -> Sarah dashes over them           pillar -> Chelzy wall-jumps up it
##   saw    -> April double-jumps it            planks -> Kervin sprints over the falling bars
##   slab   -> Psalm shrinks to crawl under it (it floats one tile above the ground)
## The moves copy the game: Chelzy jumps at the pillar, kicks off it, comes back higher, kicks
## again up onto the top and hops down; April's second jump starts before the first ends, so
## the saw passes under her at the top; Kervin's bars bridge a gap in the ground and drop
## one by one just after he has run over them.
## Fruit lies along the runner's path (on the ground and in arcs over obstacles) and is
## collected as the runner touches it. Everything is scripted - no physics - so it loops forever.

const GROUND_Y := 312.0  ## Top of the ground (the runner's feet line).
const SPEED := 55.0  ## Scroll speed in px/s.
const SPACING := 270.0  ## Distance between obstacles.
const OBSTACLE_COUNT := 4
const RUNNER_X := 130.0
## [obstacle, hero index] - the hero who clears it.
const SEQUENCE := [["spikes", 1], ["pillar", 0], ["saw", 2], ["planks", 3], ["slab", 4]]

const HERO_FRAMES := [
	"res://assets/shared/heroes/chelzy/chelzy_frames.tres",
	"res://assets/shared/heroes/sarah/sarah_frames.tres",
	"res://assets/shared/heroes/april/april_frames.tres",
	"res://assets/shared/heroes/kervin/kervin_frames.tres",
	"res://assets/shared/heroes/psalm/psalm_frames.tres",
]
const PLAYER := preload("res://scripts/player/player.gd")
## [width, height] of each obstacle.
const SIZES := {"spikes": [48.0, 16.0], "saw": [38.0, 38.0], "pillar": [32.0, 48.0], "slab": [64.0, 32.0],
	"planks": [64.0, 0.0]}
const SHRINK_TIME := 0.3  ## Psalm's shrink animation: 6 frames at 20 fps.
const WALL_GAP := 10.0  ## Chelzy's x this far left of the pillar's face touches it (her wall pose reaches 9 px).
const DOUBLE_AT := 0.3  ## April's second jump starts this far into her double jump (0..1).
## The pit under Kervin's bars: the wooden bar row of the terrain sheet (left, middle, right).
const BAR_REGIONS := [Rect2(272, 16, 16, 16), Rect2(288, 16, 16, 16), Rect2(288, 16, 16, 16), Rect2(304, 16, 16, 16)]

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
		"planks":
			# A gap in the ground (the ground tiles over it are hidden, see _cut_pits) with its
			# two edges, bridged by wooden bars that drop once Kervin has run over them.
			for row in 3:
				var edge_y: float = GROUND_Y + row * 16
				var src_y := 0 if row == 0 else 16
				node.add_child(_tile(Rect2(128, src_y, 16, 16), Vector2(-16, edge_y)))
				node.add_child(_tile(Rect2(96, src_y, 16, 16), Vector2(size[0], edge_y)))
			o["bars"] = []
			for i in BAR_REGIONS.size():
				var bar := _tile(BAR_REGIONS[i], Vector2(i * 16, GROUND_Y))
				node.add_child(bar)
				o["bars"].append({"sprite": bar, "falling": false})
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


func _tile(region: Rect2, pos: Vector2) -> Sprite2D:
	var t := Sprite2D.new()
	t.texture = TERRAIN
	t.region_enabled = true
	t.region_rect = region
	t.centered = false
	t.position = pos
	return t


## Hides the ground tiles over every pit, so the gap under Kervin's bars is open.
func _cut_pits() -> void:
	var pits: Array = []
	for o in _obstacles:
		if o.get("type", "") == "planks":
			pits.append(Vector2(o["x"], o["x"] + SIZES["planks"][0]))
	for tile in _ground.get_children():
		var left: float = tile.position.x + _ground.position.x
		var open := false
		for pit in pits:
			if left + 16.0 > pit.x and left < pit.y:
				open = true
				break
		tile.visible = not open


## Kervin's bars: each one shakes and drops just after he has run over it.
func _drop_bars(o: Dictionary) -> void:
	for b in o.get("bars", []):
		var bar: Sprite2D = b["sprite"]
		if b["falling"] or not is_instance_valid(bar):
			continue
		if _runner.position.x < bar.global_position.x + 12.0:
			continue
		b["falling"] = true
		var t := bar.create_tween()
		t.tween_property(bar, "position:x", bar.position.x + 1.0, 0.04)
		t.tween_property(bar, "position:x", bar.position.x - 1.0, 0.04)
		t.tween_property(bar, "position:x", bar.position.x, 0.04)
		t.tween_property(bar, "position:y", bar.position.y + 120.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(bar, "modulate:a", 0.0, 0.6)


## Fruit along the runner's path: in an arc that matches the jump over the obstacle, then evenly
## spaced on the ground until the next one. `rel` is the offset from the obstacle's left edge.
func _place_fruit(o: Dictionary, width: float, hero: int, type: String) -> void:
	var plan := _plan(hero, type)
	var span: float = SPEED * plan["d"]
	var mid := width * 0.5
	var spots: Array = []  # [rel x, lift of the fruit above the ground]
	if plan["kind"] == "wall":
		# Where Chelzy touches the pillar's face (twice), the top of her last kick, and on top.
		spots.append([-WALL_GAP, 38.0])
		spots.append([-WALL_GAP, 56.0])
		spots.append([3.0, 80.0])
		spots.append([24.0, 62.0])
	elif plan["kind"] == "shrink":
		# Under the slab, low enough for tiny Psalm.
		for k in 3:
			spots.append([12.0 + k * 20.0, 8.0])
	else:
		var cross: float = plan.get("cross", 0.5)  # the obstacle's middle passes the runner here
		for k in 3:
			var u := 0.25 + k * 0.25
			spots.append([mid + (u - cross) * span, _lift(plan, u) + 14.0])
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
			return {"kind": "wall", "d": 1.7, "tag": "WALL JUMP"}
		[1, "spikes"]:
			return {"kind": "dash", "d": d * 0.9, "tag": "DASH", "apex": 20.0}
		[2, "saw"]:
			# The saw's middle passes under her at the top of the second jump (u = cross).
			return {"kind": "double", "d": d + 0.3, "tag": "DOUBLE JUMP", "apex": size[1] + 32.0, "cross": 0.57}
		[3, "planks"]:
			# Flat out over the bars, no jump: they only drop behind him.
			return {"kind": "sprint", "d": (size[0] + 40.0) / SPEED * 0.85, "tag": "SPRINT", "apex": 0.0}
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
			# Jump 1 rises to h1; jump 2 starts there (still going up) and peaks at about `apex`.
			var h1 := apex * 0.62
			if u < DOUBLE_AT:
				var a := u / DOUBLE_AT
				return h1 * (1.0 - (1.0 - a) * (1.0 - a))
			var v := (u - DOUBLE_AT) / (1.0 - DOUBLE_AT)
			return h1 * (1.0 - v) + apex * 0.667 * 4.0 * v * (1.0 - v)
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
	_cut_pits()
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
			var lead: float = SPEED * plan["d"] * plan.get("cross", 0.5)
			# Swap to the right hero a little before the obstacle needs them.
			if o["hero"] != _hero and centre - RUNNER_X <= lead + 75.0:
				_swap_to(o["hero"])
			if o["hero"] == _hero:
				var ready: bool = (o["x"] - RUNNER_X <= 30.0) if plan["kind"] == "wall" \
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
	var flip := false
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
				# Kervin's sprint (it has its own speed lines) with a trail, out ahead and back.
				anim = &"sprint"
				trail = true
				x += 24.0 * sin(u * PI)
				_drop_bars(_act["obs"])
			"double":
				lift = _lift(_act, u)
				if u < DOUBLE_AT:
					anim = &"jump"
				else:
					anim = &"double_jump" if (u - DOUBLE_AT) / (1.0 - DOUBLE_AT) < 0.45 else &"fall"
			"wall":
				var pose := _wall_pose(_act["t"], _act)
				x = pose["x"]
				lift = pose["lift"]
				anim = pose["anim"]
				flip = pose["flip"]
		if _act["t"] >= float(_act["d"]):
			_act = {}

	_runner.position = Vector2(x, GROUND_Y - 16.0 - lift)
	_runner.flip_h = flip
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


## Chelzy over the pillar, as in the game, `t` seconds into the move. The pillar's near face is
## at o.x and slides left; the wall pose is her wall slide (the wall on her right).
func _wall_pose(t: float, act: Dictionary) -> Dictionary:
	var o: Dictionary = act["obs"]
	var top_y: float = SIZES["pillar"][1]
	var wall: float = o["x"] - WALL_GAP  # touching the near face
	var top: float = o["x"] + 16.0  # the middle of the pillar's top
	if t < 0.22:  # 1. jump at the pillar
		var s := t / 0.22
		return {"x": lerpf(RUNNER_X, wall, s), "lift": 26.0 * sin(s * PI / 2.0), "anim": &"jump", "flip": false}
	if t < 0.34:  # 2. touch its face
		var s := (t - 0.22) / 0.12
		return {"x": wall, "lift": 26.0 - 4.0 * s, "anim": &"wall_jump", "flip": false}
	if t < 0.62:  # 3. wall jump: kick away, up, and swing back to it
		var s := (t - 0.34) / 0.28
		return {"x": wall - 20.0 * sin(s * PI), "lift": 22.0 + 22.0 * sin(s * PI / 2.0), "anim": &"jump", "flip": s < 0.5}
	if t < 0.74:  # 4. touch it again, higher
		var s := (t - 0.62) / 0.12
		return {"x": wall, "lift": 44.0 - 4.0 * s, "anim": &"wall_jump", "flip": false}
	if t < 1.08:  # 5. kick off again, up and over onto the top
		var s := (t - 0.74) / 0.34
		return {"x": lerpf(wall, top, smoothstep(0.0, 1.0, s)), "lift": lerpf(40.0, top_y, s) + 22.0 * 4.0 * s * (1.0 - s),
			"anim": &"jump" if s < 0.5 else &"fall", "flip": s < 0.2}
	if t < 1.22:  # 6. a step along the top
		var s := (t - 1.08) / 0.14
		return {"x": top + 8.0 * s, "lift": top_y, "anim": &"run", "flip": false}
	# 7. hop down the far side, back to the running spot
	if not act.has("from_x"):
		act["from_x"] = top + 8.0
	var s := clampf((t - 1.22) / 0.48, 0.0, 1.0)
	return {"x": lerpf(act["from_x"], RUNNER_X, smoothstep(0.0, 1.0, s)), "lift": lerpf(top_y, 0.0, s) + 20.0 * 4.0 * s * (1.0 - s),
		"anim": &"jump" if s < 0.4 else &"fall", "flip": false}


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
