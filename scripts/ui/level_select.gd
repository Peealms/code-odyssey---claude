extends Control
## Level select: a row of "terminal window" cards you scroll through (arrows / A,D / mouse wheel /
## drag). The centred card is enlarged and shows an animated preview; Enter, Space or a click plays it.
## Locked levels are dimmed with a padlock. Add a level by adding an entry to LEVELS.

const MENU := "res://scenes/ui/main_menu.tscn"

const P1 := "res://assets/level1_pixel_adventure/"
const P2 := "res://assets/level2_treasure_hunters/"
const P3 := "res://assets/level3_kings_and_pigs/"
const P4 := "res://assets/level4_pirate_bomb/"

## Each level's preview is built from that level's own art:
##   sky: a Color or {tex, region, scale, tint, scroll}      clouds: optional scrolling strip
##   ground: {tex, top, fill, scale, rows}                   props: sprites standing on the ground
## A prop is {f: SpriteFrames path, a: animation, x: 0..1 across the preview, dy: lift in px,
##   s: scale, walk: [x0, x1, seconds] to patrol, face: -1 if the art faces left, rep/gap: repeats}.
const LEVELS := [
	{
		"id": "level1", "title": "TUTORIAL", "topic": "HOW TO PLAY",
		"scene": "res://scenes/levels/level1/level1.tscn",
		"accent": Color("5fb8ff"),
		"sky": {"tex": P1 + "backgrounds/bg_blue.png", "scroll": 10.0},
		"ground": {"tex": P1 + "tiles/terrain_16x16.png", "top": Rect2(112, 0, 16, 16),
			"fill": Rect2(112, 16, 16, 16), "scale": 1.0, "rows": 2},
		"props": [
			{"f": P1 + "traps/spikes/spikes_frames.tres", "a": "idle", "x": 0.52, "rep": 3, "gap": 16},
			{"f": P1 + "traps/saw/saw_frames.tres", "a": "on", "x": 0.86, "dy": 0},
			{"f": "res://assets/shared/heroes/chelzy/chelzy_frames.tres", "a": "run",
				"x": 0.2, "walk": [0.2, 0.42, 3.0], "dy": -1},
			{"f": P1 + "collectibles/fruits/fruits_frames.tres", "a": "apple", "x": 0.3, "dy": 46, "bob": 3},
			{"f": P1 + "collectibles/fruits/fruits_frames.tres", "a": "melon", "x": 0.68, "dy": 56, "bob": 3},
			{"f": P1 + "collectibles/fruits/fruits_frames.tres", "a": "cherries", "x": 0.55, "dy": 30, "bob": 3},
		],
	},
	{
		"id": "level2", "title": "CONDITIONALS", "topic": "IF / ELSE",
		"scene": "res://scenes/levels/level2/level2.tscn",
		"accent": Color("ffb347"),
		"sky": {"tex": P2 + "backgrounds/additional_sky.png"},
		"clouds": P2 + "backgrounds/big_clouds.png",
		"ground": {"tex": P2 + "tiles/island_terrain_32x32.png", "top": Rect2(32, 0, 32, 32),
			"fill": Rect2(32, 32, 32, 32), "scale": 0.5, "rows": 2},
		"props": [
			{"f": P2 + "objects/chest/chest_frames.tres", "a": "close", "x": 0.5, "dy": -1, "s": 0.6},
			{"f": P2 + "enemies/crabby/crabby_frames.tres", "a": "run", "x": 0.7,
				"walk": [0.6, 0.76, 3.0], "dy": -1, "s": 0.8},
			{"f": P2 + "characters/captain_clown_nose/captain_clown_nose_frames.tres", "a": "run",
				"x": 0.3, "walk": [0.27, 0.42, 3.0], "dy": -1, "s": 0.9},
			{"f": P2 + "collectibles/gold_coin/gold_coin_frames.tres", "a": "idle", "x": 0.3, "dy": 46, "bob": 3},
			{"f": P2 + "collectibles/gold_coin/gold_coin_frames.tres", "a": "idle", "x": 0.4, "dy": 52, "bob": 3},
		],
	},
	{
		"id": "level3", "title": "LOGIC", "topic": "AND / OR / SWITCH",
		"scene": "",
		"accent": Color("c58bff"),
		"sky": {"color": Color("2d2a40")},
		"ground": {"tex": P3 + "tiles/castle_terrain_32x32.png", "top": Rect2(64, 224, 32, 32),
			"fill": Rect2(64, 256, 32, 32), "scale": 0.5, "rows": 2},
		"props": [
			{"f": P3 + "objects/door/door_frames.tres", "a": "idle", "x": 0.88, "dy": -1, "s": 0.8},
			{"f": P3 + "enemies/pig/pig_frames.tres", "a": "run", "x": 0.6,
				"walk": [0.5, 0.75, 3.0], "dy": -1, "face": -1},
			{"f": P3 + "characters/king_human/king_human_frames.tres", "a": "run", "x": 0.3,
				"walk": [0.25, 0.42, 3.0], "dy": -1, "s": 0.8, "face": -1},
			{"f": P3 + "collectibles/small_diamond/small_diamond_frames.tres", "a": "idle", "x": 0.45, "dy": 46, "bob": 3},
		],
	},
	{
		"id": "level4", "title": "LOOPS", "topic": "REPEAT & ARRAYS",
		"scene": "",
		"accent": Color("6fe08a"),
		"sky": {"tex": P4 + "tiles/ship_tileset_64x64.png", "region": Rect2(128, 192, 64, 64),
			"scale": 0.5, "tint": Color(0.55, 0.5, 0.6)},
		"ground": {"tex": P4 + "tiles/ship_tileset_64x64.png", "top": Rect2(256, 0, 64, 64),
			"fill": Rect2(256, 64, 64, 64), "scale": 0.25, "rows": 2},
		"props": [
			{"f": P4 + "objects/barrel/barrel_frames.tres", "a": "idle", "x": 0.9, "dy": -1, "s": 0.6},
			{"f": P4 + "objects/bomb/bomb_frames.tres", "a": "bomb_on", "x": 0.5, "dy": -1, "s": 0.4},
			{"f": P4 + "enemies/cucumber/cucumber_frames.tres", "a": "run", "x": 0.7,
				"walk": [0.62, 0.74, 3.0], "dy": -1, "s": 0.8, "face": -1},
			{"f": P4 + "characters/bomb_guy/bomb_guy_frames.tres", "a": "run", "x": 0.3,
				"walk": [0.25, 0.42, 3.0], "dy": -1, "s": 0.8},
		],
	},
]

const CARD := Vector2(168, 196)
const SPACING := 190.0
const NAVY := Color("14112a")
const NAVY_LIGHT := Color("26204a")
const INK := Color("0d0b1e")
const PAPER := Color("f3e6c4")
const STAR := Color("ffd34d")
const STAR_EMPTY := Color(1, 1, 1, 0.15)

var _pos := 0.0  ## Smoothly follows _target (in card indices).
var _target := 0
var _time := 0.0
var _res := {}  ## path -> loaded resource (textures / sprite frames used by the previews)
var _font: Font
var _dragging := false
var _drag_moved := 0.0
var _starting := false


func _ready() -> void:
	for l in LEVELS:
		for path in _preview_paths(l):
			if not _res.has(path):
				_res[path] = load(path)
	_font = get_theme_default_font()
	# Start on the first level that isn't finished yet.
	for i in LEVELS.size():
		_target = i
		if not _is_unlocked(i) or Game.best_stars.get(LEVELS[i]["id"], 0) == 0:
			break
	_target = clampi(_target, 0, LEVELS.size() - 1)
	_pos = _target
	Sound.music("menu")


func _preview_paths(l: Dictionary) -> Array:
	var out := [l["ground"]["tex"]]
	if l["sky"].has("tex"):
		out.append(l["sky"]["tex"])
	if l.has("clouds"):
		out.append(l["clouds"])
	for p in l["props"]:
		out.append(p["f"])
	return out


func _is_unlocked(i: int) -> bool:
	if LEVELS[i]["scene"] == "":
		return false
	if Game.immune: return true  # IMMUNITY: every level open
	return i == 0 or Game.best_stars.get(LEVELS[i - 1]["id"], 0) > 0


func _process(delta: float) -> void:
	_time += delta
	_pos = lerpf(_pos, float(_target), 1.0 - exp(-delta * 12.0))
	queue_redraw()


func _move(step: int) -> void:
	var t := clampi(_target + step, 0, LEVELS.size() - 1)
	if t != _target:
		_target = t
		Sound.play("ui_select")


func _play_selected() -> void:
	if _starting:
		return
	if not _is_unlocked(_target):
		Sound.play("ui_select")
		return
	_starting = true
	Sound.play("ui_select")
	Game.change_scene(LEVELS[_target]["scene"])


func _back() -> void:
	if _starting:
		return
	_starting = true
	Game.change_scene(MENU)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_move(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_move(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_play_selected()
	elif event.is_action_pressed("ui_cancel"):
		_back()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			if mb.pressed:
				_move(1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			if mb.pressed:
				_move(-1)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_moved = 0.0
			else:
				_dragging = false
				if _drag_moved < 6.0:
					_click(mb.position)
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_drag_moved += absf(mm.relative.x)
		_pos = clampf(_pos - mm.relative.x / SPACING, 0.0, LEVELS.size() - 1.0)
		_target = clampi(roundi(_pos), 0, LEVELS.size() - 1)


func _click(p: Vector2) -> void:
	# Back button area (top-left).
	if Rect2(8, 8, 52, 18).has_point(p):
		_back()
		return
	for i in LEVELS.size():
		if _card_rect(i).has_point(p):
			if i == _target:
				_play_selected()
			else:
				_target = i
				Sound.play("ui_select")
			return


func _card_scale(i: int) -> float:
	return lerpf(1.0, 0.72, clampf(absf(i - _pos), 0.0, 1.0))


func _card_center(i: int) -> Vector2:
	var d := i - _pos
	# Slightly compress spacing for side cards so they tuck behind the centre one.
	return Vector2(size.x * 0.5 + d * SPACING, size.y * 0.5 + 6.0)


func _card_rect(i: int) -> Rect2:
	var s := CARD * _card_scale(i)
	return Rect2(_card_center(i) - s * 0.5, s)


func _draw() -> void:
	_draw_backdrop()
	_draw_header()
	# Draw far cards first, the centred one last (on top).
	var order := range(LEVELS.size())
	order.sort_custom(func(a, b): return absf(a - _pos) > absf(b - _pos))
	for i in order:
		_draw_card(i)
	_draw_footer()


func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	# Faint grid that drifts like a terminal screen.
	var off := fmod(_time * 10.0, 32.0)
	for x in range(-1, int(size.x / 32.0) + 2):
		draw_line(Vector2(x * 32.0 - off, 0), Vector2(x * 32.0 - off, size.y), Color(1, 1, 1, 0.035))
	for y in range(0, int(size.y / 32.0) + 1):
		draw_line(Vector2(0, y * 32.0), Vector2(size.x, y * 32.0), Color(1, 1, 1, 0.035))
	# Falling binary digits in the accent colour of the selected level.
	var accent: Color = LEVELS[clampi(roundi(_pos), 0, LEVELS.size() - 1)]["accent"]
	for c in 22:
		var x := c * 30.0 + 6.0
		var speed := 14.0 + float((c * 37) % 23)
		var y := fmod(_time * speed + c * 53.0, size.y + 40.0) - 20.0
		for k in 4:
			var a := (1.0 - k * 0.25) * 0.22
			var ch := "1" if ((c + k + int(_time * 2.0 + c)) % 3) == 0 else "0"
			draw_string(_font, Vector2(x, y - k * 11.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
				Color(accent.r, accent.g, accent.b, a))


func _draw_header() -> void:
	# Back button.
	draw_rect(Rect2(8, 8, 52, 18), NAVY_LIGHT)
	draw_rect(Rect2(8, 8, 52, 18), Color(1, 1, 1, 0.35), false, 1.0)
	draw_string(_font, Vector2(14, 21), "< BACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	var title := "SELECT LEVEL"
	var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var cursor := "_" if fmod(_time, 1.0) < 0.5 else " "
	draw_string(_font, Vector2((size.x - tw) * 0.5 - 6, 21), "> " + title + cursor,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8ee89c"))
	# Progress dots.
	for i in LEVELS.size():
		var dot := Vector2(size.x * 0.5 + (i - (LEVELS.size() - 1) * 0.5) * 12.0, 38.0)
		var on := i == _target
		draw_rect(Rect2(dot - Vector2(3, 3), Vector2(6, 6)), LEVELS[i]["accent"] if on else Color(1, 1, 1, 0.25))


func _draw_footer() -> void:
	var unlocked := _is_unlocked(_target)
	var text := "ENTER: PLAY      < > : SCROLL      ESC: BACK"
	if not unlocked:
		text = "FINISH THE PREVIOUS LEVEL TO UNLOCK" if LEVELS[_target]["scene"] != "" else "COMING SOON"
	var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(_font, Vector2((size.x - tw) * 0.5, size.y - 12), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.75))
	# Arrows hinting there is more to scroll to.
	var bob := roundf(sin(_time * 5.0) * 2.0)
	if _target > 0:
		_draw_arrow(Vector2(18 + bob * -1.0, size.y * 0.5), -1)
	if _target < LEVELS.size() - 1:
		_draw_arrow(Vector2(size.x - 18 + bob, size.y * 0.5), 1)


func _draw_arrow(p: Vector2, dir: int) -> void:
	var pts := PackedVector2Array([p + Vector2(-5 * dir, -9), p + Vector2(5 * dir, 0), p + Vector2(-5 * dir, 9)])
	draw_colored_polygon(pts, Color(1, 1, 1, 0.8))


func _draw_card(i: int) -> void:
	var data: Dictionary = LEVELS[i]
	var unlocked := _is_unlocked(i)
	var focus := 1.0 - clampf(absf(i - _pos), 0.0, 1.0)
	var sc := _card_scale(i)
	var accent: Color = data["accent"]
	var center := _card_center(i)
	draw_set_transform(center, 0.0, Vector2(sc, sc))
	var half := CARD * 0.5
	var origin := -half

	# Glow behind the focused card.
	if focus > 0.01:
		var g := accent
		g.a = 0.28 * focus
		draw_rect(Rect2(origin - Vector2(4, 4), CARD + Vector2(8, 8)), g)
	# Window body + drop shadow.
	draw_rect(Rect2(origin + Vector2(4, 4), CARD), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(origin, CARD), NAVY)
	draw_rect(Rect2(origin, CARD), accent if unlocked else Color(1, 1, 1, 0.25), false, 2.0)
	# Title bar with three dots.
	draw_rect(Rect2(origin + Vector2(2, 2), Vector2(CARD.x - 4, 14)), accent.darkened(0.45) if unlocked else Color("3a3550"))
	for d in 3:
		draw_rect(Rect2(origin + Vector2(7 + d * 9, 6), Vector2(5, 5)), [Color("ff6b6b"), Color("ffd34d"), Color("6fe08a")][d])
	var num := "LEVEL %d" % (i + 1)
	var nw := _font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(_font, origin + Vector2(CARD.x - nw - 8, 14), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)

	# Preview window.
	var pv := Rect2(origin + Vector2(8, 22), Vector2(CARD.x - 16, 112))
	_draw_preview(i, pv, unlocked, focus)

	# Info.
	draw_string(_font, origin + Vector2(10, 150), data["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color.WHITE if unlocked else Color(1, 1, 1, 0.45))
	draw_string(_font, origin + Vector2(10, 163), "> " + data["topic"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color("8ee89c") if unlocked else Color(1, 1, 1, 0.3))
	# Stars.
	var best: int = Game.best_stars.get(data["id"], 0)
	for s in 3:
		_draw_star(origin + Vector2(18 + s * 22, 180), 7.0, s < best, unlocked)
	if unlocked and best == 0:
		draw_string(_font, origin + Vector2(CARD.x - 56, 184), "NEW!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			accent.lightened(0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_preview(i: int, r: Rect2, unlocked: bool, focus: float) -> void:
	var l: Dictionary = LEVELS[i]
	var t := _time if focus > 0.5 else 0.0
	# Sky / wall.
	var sky: Dictionary = l["sky"]
	if sky.has("color"):
		draw_rect(r, sky["color"])
	else:
		var tex: Texture2D = _res[sky["tex"]]
		var region := Rect2(Vector2.ZERO, tex.get_size())
		if sky.has("region"):
			region = sky["region"]
		var k: float = sky.get("scale", 1.0)
		var tint: Color = sky.get("tint", Color.WHITE)
		var tile := region.size * k
		var off := fmod(t * sky.get("scroll", 0.0), tile.x)
		var y := r.position.y
		while y < r.end.y:
			var x := r.position.x - off
			while x < r.end.x:
				_draw_clipped(tex, Rect2(Vector2(x, y), tile), r, region, tint)
				x += tile.x
			y += tile.y
	# Drifting clouds.
	if l.has("clouds"):
		var ctex: Texture2D = _res[l["clouds"]]
		var cs := ctex.get_size() * 0.5
		var cx := r.position.x - fmod(t * 6.0, cs.x)
		while cx < r.end.x:
			_draw_clipped(ctex, Rect2(Vector2(cx, r.position.y + 6), cs), r, Rect2(Vector2.ZERO, ctex.get_size()))
			cx += cs.x
	# Ground.
	var g: Dictionary = l["ground"]
	var gtex: Texture2D = _res[g["tex"]]
	var gs: float = g["scale"]
	var tsz: Vector2 = (g["top"] as Rect2).size * gs
	var rows: int = g["rows"]
	var ground_y := r.end.y - tsz.y * rows
	for row in rows:
		var src: Rect2 = g["top"] if row == 0 else g["fill"]
		var gx := r.position.x
		while gx < r.end.x:
			_draw_clipped(gtex, Rect2(gx, ground_y + row * tsz.y, tsz.x, tsz.y), r, src)
			gx += tsz.x
	# Props standing on the ground.
	for p in l["props"]:
		_draw_prop(p, r, ground_y, t)
	# Frame + scanlines.
	draw_rect(r, Color.BLACK, false, 1.0)
	for sy in range(int(r.position.y), int(r.end.y), 3):
		draw_line(Vector2(r.position.x, sy), Vector2(r.end.x, sy), Color(0, 0, 0, 0.12))
	if not unlocked:
		draw_rect(r, Color(0.05, 0.04, 0.12, 0.72))
		_draw_lock(r.get_center())


func _draw_prop(p: Dictionary, r: Rect2, ground_y: float, t: float) -> void:
	var frames: SpriteFrames = _res[p["f"]]
	var anim := StringName(p["a"])
	if not frames.has_animation(anim):
		anim = frames.get_animation_names()[0]
	var n := frames.get_frame_count(anim)
	var frame := int(t * frames.get_animation_speed(anim)) % n
	var tex := frames.get_frame_texture(anim, frame)
	if tex == null:
		return
	var s: float = p.get("s", 1.0)
	var size_px := tex.get_size() * s
	var body := SpriteMetrics.body_rect(frames, anim)  # where the character really is in the frame
	var fx: float = p["x"]
	var flip := false
	if p.has("walk"):
		var w: Array = p["walk"]
		# Ping-pong between w[0] and w[1] with a short pause at each end.
		var ph := fmod(t / float(w[2]), 2.0)
		var u := ph if ph < 1.0 else 2.0 - ph
		u = smoothstep(0.0, 1.0, clampf(u * 1.2 - 0.1, 0.0, 1.0))
		fx = lerpf(w[0], w[1], u)
		flip = ph >= 1.0
	if p.get("face", 1) == -1:
		flip = not flip
	var base_y := ground_y - float(p.get("dy", 0))
	base_y -= sin(t * 2.5 + fx * 9.0) * float(p.get("bob", 0))
	# Line the body's feet (bottom edge) and middle up with the spot, whichever way it faces.
	var body_mid_x := body.get_center().x * s
	if flip:
		body_mid_x = size_px.x - body_mid_x
	var reps: int = p.get("rep", 1)
	for k in reps:
		var pos := Vector2(r.position.x + fx * r.size.x - body_mid_x + k * float(p.get("gap", 0)),
			base_y - body.end.y * s)
		_draw_sprite_clipped(tex, Rect2(pos, size_px), r, flip)


## Draws a whole texture into `dst` (mirrored if `flip`), cropped to `clip`.
func _draw_sprite_clipped(tex: Texture2D, dst: Rect2, clip: Rect2, flip: bool) -> void:
	var inter := dst.intersection(clip)
	if inter.size.x <= 0.0 or inter.size.y <= 0.0:
		return
	var k := tex.get_size() / dst.size
	var src := Rect2((inter.position - dst.position) * k, inter.size * k)
	if flip:
		src.position.x = (dst.end.x - inter.end.x) * k.x
		draw_texture_rect_region(tex, Rect2(inter.position.x, inter.position.y, -inter.size.x, inter.size.y), src)
	else:
		draw_texture_rect_region(tex, inter, src)


## Draws `src` (a region of `tex`) scaled into `dst`, cropped so nothing leaves `clip`.
func _draw_clipped(tex: Texture2D, dst: Rect2, clip: Rect2, src: Rect2, tint := Color.WHITE) -> void:
	var inter := dst.intersection(clip)
	if inter.size.x <= 0.0 or inter.size.y <= 0.0:
		return
	var k := Vector2(src.size.x / dst.size.x, src.size.y / dst.size.y)
	var cropped := Rect2(src.position + (inter.position - dst.position) * k, inter.size * k)
	draw_texture_rect_region(tex, inter, cropped, tint)


func _draw_lock(c: Vector2) -> void:
	draw_rect(Rect2(c + Vector2(-12, -2), Vector2(24, 18)), Color("c8c2e0"))
	draw_rect(Rect2(c + Vector2(-12, -2), Vector2(24, 18)), INK, false, 2.0)
	draw_arc(c + Vector2(0, -2), 8, PI, TAU, 12, Color("c8c2e0"), 3.0)
	draw_rect(Rect2(c + Vector2(-2, 4), Vector2(4, 7)), INK)


func _draw_star(c: Vector2, r: float, filled: bool, unlocked: bool) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var ang := -PI / 2.0 + k * PI / 5.0
		var rad := r if k % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	var col := STAR if filled else STAR_EMPTY
	if not unlocked:
		col = STAR_EMPTY
	draw_colored_polygon(pts, col)
