extends SceneTree
## Animates the five hero-sized teammates as hero sheets that can replace the Pixel Adventure
## heroes. Everyone gets the animations every hero needs (idle, run, jump, fall, hit) plus only
## the ones for their own special ability:
##   Chelzy  Wall Jump    wall_jump    sliding down a wall
##   Sarah   Dash         dash         a low lunge with afterimages and speed lines
##   April   Double Jump  double_jump  a forward flip
##   Kervin  Sprint       sprint       a leaning run with longer strides
##   Psalm   Shrink       shrink       normal -> poof -> tiny (play it backwards to grow), and the
##                                     tiny Psalm's small_idle, small_run, small_jump, small_fall
## Writes, per person:
##   assets/shared/heroes/<name>/<anim>.png          one strip per animation, 40x40 frames
##   assets/shared/heroes/<name>/<name>_frames.tres  SpriteFrames (20 fps like the old heroes)
##
## Frames are 40x40 (the Pixel Adventure heroes use 32x32) so the tallest teammates fit. The
## figure is centred with the feet on the bottom row, so with the player's centred
## AnimatedSprite2D the sprite needs offset (0, -4) to stand on the 16x24 hitbox's floor.
##
## Every frame is stacked from parts, back to front. The head, shirt and hips are cut from the
## person's idle map in make_team_sprites.gd (so the idle frame matches the still). Turned and
## hurt heads are drawn below. Arms and legs are bent from the person's own sleeve and trouser
## pixels (Chelzy's are hand-drawn). A part drawn in front gets a 1 px outline over the parts
## behind it, then the whole figure gets its outer outline. Unflipped frames face right; the
## wall slide has the wall on the right.
## Run:  godot --headless --path . --script res://tools/make_team_heroes.gd [-- <preview_dir>]
## Then: godot --headless --path . --import

const Team := preload("res://tools/make_team_sprites.gd")
const SIZE := 40
const OUT_ROOT := "res://assets/shared/heroes/"
const PREVIEW_SCALE := 4
const PEOPLE := ["chelzy", "sarah", "april", "kervin", "psalm"]

## Animations every hero has: name -> [frame count, fps, loop] (as the Pixel Adventure heroes).
const COMMON := {
	"idle": [11, 20.0, true],
	"run": [12, 20.0, true],
	"jump": [1, 20.0, false],
	"fall": [1, 20.0, false],
	"hit": [7, 20.0, false],
}
## Each person's own ability animations, nobody else's.
const ABILITIES := {
	"chelzy": {"wall_jump": [5, 20.0, true]},
	"sarah": {"dash": [4, 20.0, true]},
	"april": {"double_jump": [6, 20.0, false]},
	"kervin": {"sprint": [8, 20.0, true]},
	"psalm": {"shrink": [6, 20.0, false], "small_idle": [8, 20.0, true], "small_run": [8, 20.0, true],
		"small_jump": [1, 20.0, false], "small_fall": [1, 20.0, false]},
}

## Parts that never get an outline between them: shirt hems sit straight on the trousers, and
## April's hair strands run on from the head over the resting sleeves.
const MERGED := [["body", "leg_l"], ["body", "leg_r"], ["head", "strands"], ["body", "strands"]]

## Where the parts are in each idle map (columns x, rows y of TEAM_SMALL):
##   torso      shirt (or jacket), hem and hips
##   arm_rows   shoulder row to the last hand row
##   shoulders  left arm's outer column, right arm's shoulder column (the arm is the 2 after)
##   legs_row   first trouser row under the hips; leg_cols: left column of each leg
##   join       the top sleeve row runs into the shirt (no outline at the shoulder)
const LAYOUTS := {
	"chelzy": {"torso": Rect2i(3, 13, 6, 10), "arm_rows": Vector2i(13, 21), "shoulders": Vector2i(0, 9),
		"legs_row": 23, "leg_cols": Vector2i(3, 7), "leg_w": 2, "join": true},
	"sarah": {"torso": Rect2i(3, 12, 8, 7), "arm_rows": Vector2i(12, 17), "shoulders": Vector2i(0, 11),
		"legs_row": 19, "leg_cols": Vector2i(3, 8), "leg_w": 3, "join": true, "flare": true},
	# April's hair hangs over the sleeves: the arms use plain sleeves and the strands are drawn on top.
	"april": {"torso": Rect2i(3, 12, 8, 7), "arm_rows": Vector2i(12, 17), "shoulders": Vector2i(0, 11),
		"legs_row": 19, "leg_cols": Vector2i(3, 8), "leg_w": 3, "join": false,
		"sleeves": [["ll", "lu"], ["UU", "uU"]], "strands": Vector2i(11, 13)},
	"kervin": {"torso": Rect2i(3, 12, 8, 8), "arm_rows": Vector2i(12, 18), "shoulders": Vector2i(0, 11),
		"legs_row": 20, "leg_cols": Vector2i(3, 8), "leg_w": 3, "join": true},
	"psalm": {"torso": Rect2i(4, 12, 8, 3), "arm_rows": Vector2i(12, 14), "shoulders": Vector2i(1, 12),
		"legs_row": 15, "leg_cols": Vector2i(4, 9), "leg_w": 3, "join": true},
}

## Turned (3/4, looking right) and hurt heads, the same size as each idle head.
const HEADS := {
	"sarah": {
		"head_right": [
			"...kkjjjkkk...",
			".kkjjkkkkkkkK.",
			"kjjkkkkkkkkkKK",
			"kjkkkkkkkkkKKK",
			"kkkkkkkkkkKsKK",
			"kKKKKKKKssssSK",
			"kKKssossssosSK",
			"kKKssossssosSK",
			"kKKscsssssscSK",
			"kKKsssSooSsSSw",
			"kKK.SSSSSSSS.K",
		],
		"head_hurt": [
			"...kkjjjkkk...",
			".kkjjkkkkkkkK.",
			"kjjkkkkkkkkkKK",
			"kjkkkkkkkkkKKK",
			"kkkkkkkkkKsKKK",
			"kKKKKKKsssssKK",
			"kKsossssssoSKK",
			"kKssossssosSKK",
			"kKsossssssoSKK",
			"kwssssoossSSwK",
			"kK.SSSSSSSS.KK",
		],
	},
	"april": {
		"head_right": [
			"...kjjKkjjk...",
			".kjjkkKkkjjkK.",
			"kjkkkkkKkkkkKK",
			"kkkkkKshsKkkKK",
			"kkkKsshssssKKK",
			"kKKssossssosSK",
			"kKKsosossosoSK",
			"kKKscsssssscSK",
			"kKKsssowwossSK",
			"kKKssssoossSSK",
			"kKK.SSSSSSSS.K",
		],
		"head_hurt": [
			"...kjjKkjjk...",
			".kjjkkKkkjjkK.",
			"kjkkkkKkkkkkKK",
			"kkkkKshsKkkkKK",
			"kkKsshssssKkKK",
			"kKsossssssoSKK",
			"kKssossssosSKK",
			"kKsossssssoSKK",
			"kKssssoosssSKK",
			"kKssssoossSSKK",
			"kK.SSSSSSSS.KK",
		],
	},
	"kervin": {
		"head_right": [
			".....kjjkkkk..",
			"..kkkjjkkkkkK.",
			".kkjjkkkkkkkKK",
			"kkKshhsssKkkKK",
			"kKssKKssssKKsK",
			"kKsssossssosSS",
			"kKsssossssosSS",
			"..shsssssssssS",
			"..ssssossosssS",
			"..sssssoossssS",
			"...SSSSSSSSSS.",
		],
		"head_hurt": [
			".....kjjkkkk..",
			"..kkkjjkkkkkK.",
			".kkjjkkkkkkkKK",
			"kKshhsssKkkkKK",
			"KssKKssssKKskK",
			"sssossssssosSS",
			"ssssossssossSS",
			".shossssssosS.",
			".sssssoossssS.",
			".sssssoossssS.",
			"..SSSSSSSSSS..",
		],
	},
	"psalm": {
		"head_right": [
			"....kkjjjjkk....",
			"..kkjjkkjjkkkK..",
			".kjjkkjjkkjjkkK.",
			"kjkKkjjKkjjKkjKK",
			"kkKkKKkKKkKKkKKK",
			"kKKSssssssssssSK",
			"kKKssossssssosSK",
			"kKKssossssssosSK",
			"kKKscssossosscSK",
			"..ssssssoosssssS",
			"....SSSSSSSSSS..",
		],
		"head_hurt": [
			"....kkjjjjkk....",
			"..kkjjkkjjkkkK..",
			".kjjkkjjkkjjkkK.",
			"kjkKkjjKkjjKkjKK",
			"kkKkKKkKKkKKkKKK",
			"kKSssssssssssSKK",
			"kKsossssssssoSKK",
			"kKssossssssosSKK",
			"kKsosssoosssoSKK",
			".ssssssoosssssS.",
			"...SSSSSSSSSS...",
		],
	},
}

## Chelzy's hand-drawn poses (the long jacket sleeves and long legs). "a" = the map cell on the
## joint (shoulder pixel for arms, the leg's top-left pixel for legs).
const CHELZY_PARTS := {
	"head_right": {"a": Vector2i(0, 0), "m": [
		"...kkjjkk...",
		".kjjkkkkkkK.",
		"kjjkkkkkkkKK",
		"kjkkkkkkkkKK",
		"kkkKkkkKkkKK",
		"kKKKKKKKKKKK",
		"kKKSssssssSK",
		"kKKsoossooSK",
		"kKKsssssssSK",
		"KKKssossosSK",
		"KKKsssoossSK",
		"....SSSSSS..",
	]},
	"head_hurt": {"a": Vector2i(0, 0), "m": [
		"...kkjjkk...",
		".kjjkkkkkkK.",
		"kjjkkkkkkkKK",
		"kjkkkkkkkkKK",
		"kkkKkkkKkkKK",
		"kKKKKKKKKKKK",
		"kKSossssoSKK",
		"kKssossosSKK",
		"kKsossssoSKK",
		"KKsssoossSKK",
		"KKsssoossSKK",
		"...SSSSSS...",
	]},
	"arm_l_fwd": {"a": Vector2i(0, 0), "m": ["iaa", "ia.", "ia.", "ia.", ".ia", ".ia", ".AA", ".sS", ".sS"]},
	"arm_l_back": {"a": Vector2i(1, 0), "m": [".iaa", ".ia.", ".ia.", ".ia.", "ia..", "ia..", "AA..", "sS..", "sS.."]},
	"arm_r_fwd": {"a": Vector2i(0, 0), "m": ["aAA..", ".aA..", ".aA..", ".aA..", ".AAsS", "...sS"]},
	"arm_r_back": {"a": Vector2i(0, 0), "m": ["aAA", ".aA", ".aA", ".aA", "aA.", "aA.", "AA.", "sS.", "sS."]},
	"arm_l_up": {"a": Vector2i(3, 7), "m": ["sS....", "sS....", ".AA...", ".ia...", ".ia...", "..ia..", "..ia..", "...iaa"]},
	"arm_r_up": {"a": Vector2i(0, 7), "m": ["...sS", "...sS", "..AA.", "..aA.", "..aA.", ".aA..", ".aA..", "aAA.."]},
	"arm_l_out": {"a": Vector2i(3, 0), "m": ["...iaa", "..ia..", "..ia..", ".ia...", "AA....", "sS....", "sS...."]},
	"arm_r_out": {"a": Vector2i(0, 0), "m": ["aAA...", "..aA..", "..aA..", "...aA.", "....AA", "....sS", "....sS"]},
	"arm_r_wall": {"a": Vector2i(0, 6), "m": [".sS", ".sS", ".AA", "aA.", "aA.", "aA.", "aAA"]},
	"leg_bent": {"a": Vector2i(0, 0), "m": ["dD.", "dD.", "dD.", ".dD", ".dD", ".dD", "dD.", "dD.", "ooo"]},
	"leg_squat": {"a": Vector2i(0, 0), "m": ["dD.", ".dD", ".dD", ".dD", ".dD", "dD.", "dD.", "ooo"]},
	"leg_kick": {"a": Vector2i(2, 0), "m": ["..dD", "..dD", "..dD", "..dD", "..dD", ".dD.", ".dD.", "oo.."]},
	"leg_lift": {"a": Vector2i(0, 0), "m": ["dD..", ".dD.", "..dD", "..dD", ".dD.", "dD..", "ooo."]},
	"leg_push": {"a": Vector2i(4, 0), "m": ["....dD", "....dD", "...dD.", "...dD.", "..dD..", "..dD..", ".dD...", ".dD...", "dD....", "oo...."]},
	"leg_reach": {"a": Vector2i(0, 0), "m": ["dD....", ".dD...", ".dD...", "..dD..", "..dD..", "...dD.", "...dD.", "...ooo"]},
	"leg_wall": {"a": Vector2i(0, 0), "m": ["dD...", ".dD..", "..dD.", "...dD", "...dD", "...dD", "...oo"]},
}

## Psalm shrunk (about 11 px tall): the same curly hair, smile and uniform, just tiny.
const TINY := {
	"tiny": [
		"...kjjk...",
		".kkjkkjkK.",
		"kkKjkkjKkK",
		"kKsossosKK",
		"kKcsssscKK",
		".sssoossS.",
		"..SSSSSS..",
		".llyuuyUU.",
		".slubbuUs.",
		"..oo..oo..",
	],
	"tiny_up": [
		"...kjjk...",
		".kkjkkjkK.",
		"kkKjkkjKkK",
		"kKsossosKK",
		"kKcsssscKK",
		".sssoossS.",
		"..SSSSSS..",
		".llyuuyUU.",
		".slubbuUs.",
		"..ee..ee..",
		"..oo..oo..",
	],
	"tiny_step_l": [
		"...kjjk...",
		".kkjkkjkK.",
		"kkKjkkjKkK",
		"kKsossosKK",
		"kKcsssscKK",
		".sssoossS.",
		"..SSSSSS..",
		".llyuuyUU.",
		".slubbuUs.",
		"..ee...oo.",
		"..oo......",
	],
	"tiny_step_r": [
		"...kjjk...",
		".kkjkkjkK.",
		"kkKjkkjKkK",
		"kKsossosKK",
		"kKcsssscKK",
		".sssoossS.",
		"..SSSSSS..",
		".llyuuyUU.",
		".slubbuUs.",
		"...oo.ee..",
		"......oo..",
	],
	"tiny_jump": [
		"...kjjk...",
		".kkjkkjkK.",
		"kkKjkkjKkK",
		"kKsossosKK",
		"kKcsssscKK",
		"ssssoossSs",
		"s.SSSSSS.s",
		".llyuuyUU.",
		".llubbuUU.",
		"...oooo...",
	],
	"tiny_fall": [
		"...kjjk...",
		".kkjkkjkK.",
		"kkKjkkjKkK",
		"kKsossosKK",
		"kKcsssscKK",
		"ssssoossSs",
		"s.SSSSSS.s",
		".llyuuyUU.",
		".llubbuUU.",
		"..ee..ee..",
		".oo....oo.",
	],
}

var person := {}
var layout := {}
var parts := {}  # name -> {"a": Vector2i, "m": Array}
var colors := {}
var arm_rec := {}  # -1 / 1 -> rows of [light, dark] sleeve pixels, shoulder first
var join := {}  # -1 / 1 -> the shoulder pixel that runs into the shirt ("" for none)
var map_at: Vector2i  # frame position of the idle map's row 0, col 0
var torso_at: Vector2i
var shoulder_l: Vector2i
var shoulder_r: Vector2i
var hip_l: Vector2i
var hip_r: Vector2i
var stand := 0  # trouser rows of a straight leg


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var preview_dir: String = args[0] if args.size() > 0 else ""
	var all := {}  # name -> {anim: strip}
	for name: String in PEOPLE:
		if not _setup(name):
			quit(1)
			return
		var anims := _anim_list()
		var dir: String = OUT_ROOT + name + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		_remove_stale(dir, anims)
		var strips := {}
		for anim: String in anims:
			var frames: Array[Image] = _frames(anim)
			if frames.size() != anims[anim][0]:
				push_error("%s %s: %d frames, expected %d" % [name, anim, frames.size(), anims[anim][0]])
				quit(1)
				return
			var strip := Image.create(SIZE * frames.size(), SIZE, false, Image.FORMAT_RGBA8)
			for i in frames.size():
				strip.blit_rect(frames[i], Rect2i(0, 0, SIZE, SIZE), Vector2i(i * SIZE, 0))
			strip.save_png(dir + anim + ".png")
			strips[anim] = strip
		_write_sprite_frames(dir, name, anims)
		all[name] = strips
		print("%s: %s" % [dir, ", ".join(strips.keys())])
	if preview_dir != "":
		for name: String in all:
			_write_sheet(all[name], preview_dir.path_join(name + "_sheet.png"))
		_write_html(all, preview_dir.path_join("team_heroes.html"))
	quit()


func _anim_list() -> Dictionary:
	var anims: Dictionary = COMMON.duplicate()
	anims.merge(ABILITIES[person.name])
	return anims


## Deletes strips this tool made before that the person no longer has (e.g. an old ability).
func _remove_stale(dir: String, anims: Dictionary) -> void:
	var known := COMMON.keys()
	for p: String in ABILITIES:
		known.append_array(ABILITIES[p].keys())
	for anim: String in known:
		if not anims.has(anim):
			for file in [anim + ".png", anim + ".png.import"]:
				if FileAccess.file_exists(dir + file):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + file))
					print("removed old %s%s" % [dir, file])


func _setup(name: String) -> bool:
	person = {}
	for p: Dictionary in Team.TEAM_SMALL:
		if p.name == name:
			person = p
	if person.is_empty():
		push_error("no %s in TEAM_SMALL" % name)
		return false
	layout = LAYOUTS[name]
	colors = Team.PALETTE.duplicate()
	colors.merge(Team.SMALL_OVERRIDES, true)
	colors.merge(Team.SKINS[person.skin], true)

	var m: Array = person.map
	var w: int = (m[0] as String).length()
	var h := m.size()
	var torso: Rect2i = layout.torso
	map_at = Vector2i((SIZE - (w + 2)) / 2 + 1, SIZE - h)
	torso_at = map_at + torso.position
	shoulder_l = map_at + Vector2i(layout.shoulders.x, torso.position.y)
	shoulder_r = map_at + Vector2i(layout.shoulders.y, torso.position.y)
	hip_l = map_at + Vector2i(layout.leg_cols.x, layout.legs_row)
	hip_r = map_at + Vector2i(layout.leg_cols.y, layout.legs_row)
	stand = h - 1 - layout.legs_row

	var cut := func(r0: int, r1: int, c0: int, c1: int) -> Array:
		var rows := []
		for r in range(r0, r1 + 1):
			rows.append((m[r] as String).substr(c0, c1 - c0 + 1))
		return rows
	parts = {
		"head": {"a": Vector2i.ZERO, "m": cut.call(0, torso.position.y - 2, 0, w - 1)},
		"torso": {"a": Vector2i.ZERO, "m": cut.call(torso.position.y, torso.end.y - 1, torso.position.x, torso.end.x - 1)},
	}
	if HEADS.has(name):
		for key: String in HEADS[name]:
			parts[key] = {"a": Vector2i.ZERO, "m": HEADS[name][key]}
	if name == "chelzy":
		parts.merge(CHELZY_PARTS, true)
	if layout.has("strands"):
		var s: Vector2i = layout.strands
		var rows := []
		for r in range(s.x, s.y + 1):
			var row: String = m[r]
			rows.append(row.substr(0, 2) + ".".repeat(w - 4) + row.substr(w - 2, 2))
		parts["strands"] = {"a": Vector2i.ZERO, "m": rows}

	# Sleeve pixels for bending the arms: two columns per arm, shoulder row first.
	var arms: Vector2i = layout.arm_rows
	var sl: int = layout.shoulders.x
	var sr: int = layout.shoulders.y
	arm_rec = {-1: [], 1: []}
	for r in range(arms.x, arms.y + 1):
		var row: String = m[r]
		arm_rec[-1].append(row.substr(sl, 2))
		arm_rec[1].append(row.substr(sr + 1, 2))
	if layout.has("sleeves"):
		for i in 2:
			arm_rec[-1][i] = layout.sleeves[0][i]
			arm_rec[1][i] = layout.sleeves[1][i]
	join = {-1: "", 1: ""}
	if layout.join:
		join[-1] = (m[arms.x] as String)[sl + 2]
		join[1] = (m[arms.x] as String)[sr]

	if name == "psalm":
		for key: String in TINY:
			parts[key] = {"a": Vector2i.ZERO, "m": TINY[key]}
		parts["cloud_big"] = _cloud([[0, 0, 6], [-6, 2, 4], [6, 2, 4], [-3, -5, 4], [3, -5, 4], [0, 4, 5]])
		parts["cloud_mid"] = _cloud([[0, 0, 4], [-4, 1, 3], [4, 1, 3], [0, -3, 3]])
		parts["puff"] = _cloud([[0, 0, 2]])
	return true


# ---------------------------------------------------------------- limbs

## Builds a part from {Vector2i: letter}; `joint` is the cell that goes on the joint.
func _part_from_pixels(px: Dictionary, joint: Vector2i) -> Dictionary:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-(1 << 20), -(1 << 20))
	for p: Vector2i in px:
		lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
		hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
	var rows := []
	for y in range(lo.y, hi.y + 1):
		var row := ""
		for x in range(lo.x, hi.x + 1):
			row += px.get(Vector2i(x, y), ".")
		rows.append(row)
	return {"a": joint - lo, "m": rows}


## An arm bent from the person's sleeve pixels. side -1 = left (far) arm, 1 = right (near).
## The joint is the arm's outer column (left) or the shoulder pixel next to the arm (right).
func _arm(side: int, pose: String) -> Dictionary:
	var rec: Array = arm_rec[side]
	var n := rec.size()
	var idx := range(n)
	var offs := []
	var up := false
	match pose:
		"down":
			for i in n:
				offs.append(0)
		"fwd":  # forearm forward and up (shorter, hand ahead)
			if n >= 4:
				idx.remove_at(n - 2)
			for j in idx.size():
				offs.append(1 if j >= (idx.size() + 1) / 2 else 0)
		"fwd_far":  # pumped harder (sprint)
			if n >= 5:
				idx.remove_at(n - 2)
				idx.remove_at(n - 3)
			elif n >= 4:
				idx.remove_at(n - 2)
			for j in idx.size():
				offs.append(clampi(j - (idx.size() - 3), 0, 2))
		"back":
			for i in n:
				offs.append(-1 if i >= n / 2 else 0)
		"back_far":
			for i in n:
				offs.append(-((i + 1) / 2))
		"up":
			up = true
			for i in n:
				offs.append(side * (i / 2))
		"out":
			for i in n:
				offs.append(side * ((i + 1) / 2))
		_:
			push_error("unknown arm pose " + pose)
	var base := 0 if side < 0 else 1  # arm columns: left 0-1 (shoulder pixel at 2), right 1-2 (at 0)
	var px := {}
	for j in idx.size():
		var row: String = rec[idx[j]]
		var y := -j if up else j
		px[Vector2i(base + offs[j], y)] = row[0]
		px[Vector2i(base + offs[j] + 1, y)] = row[1]
	if join[side] != "":
		px[Vector2i(2 if side < 0 else 0, 0)] = join[side]
	return _part_from_pixels(px, Vector2i.ZERO)


func _zeros(k: int) -> Array:
	var a := []
	for i in k:
		a.append(0)
	return a


func _bent(k: int) -> Array:
	if k <= 0:
		return []
	if k == 1:
		return [0]
	if k == 2:
		return [0, 1]
	var a := [0]
	for i in k - 2:
		a.append(1)
	a.append(0)
	return a


## A leg from the person's trouser pattern: `offs` = x offset of each trouser row (+ = right),
## then the shoe under it at `shoe_off`: toes -1/1 = pointing left/right, 0 = only the toe.
func _make_leg(offs: Array, shoe_off: int, toes: int, flare := 0) -> Dictionary:
	var w: int = layout.leg_w
	var pattern := "dD" if w == 2 else "epe"
	var px := {}
	for i in offs.size():
		for c in w:
			px[Vector2i(offs[i] + c, i)] = pattern[c]
	if flare != 0 and offs.size() > 0:
		var li := offs.size() - 1
		px[Vector2i(offs[li] - 1 if flare < 0 else offs[li] + w, li)] = pattern[0]
	var sy := offs.size()
	if toes == 0:
		px[Vector2i(shoe_off - 1, sy)] = "o"
		px[Vector2i(shoe_off, sy)] = "o"
	else:
		var x0 := shoe_off - 1 if toes < 0 else shoe_off
		for c in w + 1:
			px[Vector2i(x0 + c, sy)] = "o"
	return _part_from_pixels(px, Vector2i.ZERO)


## A leg pose for the person's leg length (`stand` rows when straight). Run poses point right.
func _leg(side: int, pose: String) -> Dictionary:
	var n := stand
	if pose.begins_with("stand"):  # toes outward, wide-leg flare
		var k := n if pose == "stand" else int(pose.substr(5))
		return _make_leg(_zeros(k), 0, side, side if layout.get("flare", false) else 0)
	if pose.begins_with("run"):
		return _make_leg(_zeros(int(pose.substr(3))), 0, 1)
	var o := []
	match pose:
		"bent":  # body 1 px down, knee forward
			o = _bent(n - 1)
			return _make_leg(o, o[-1] if o.size() > 0 else 0, 1)
		"squat":  # body 2 px down
			o = _bent(n - 2)
			return _make_leg(o, o[-1] if o.size() > 0 else 0, 1)
		"lift":  # knee forward, foot up
			var k := maxi(n - 2, 0)
			for i in k:
				o.append(1 if i > 0 or k == 1 else 0)
			return _make_leg(o, 1, 1)
		"kick":  # foot raised behind
			var k := maxi(n - 2, 0)
			for i in k:
				o.append(-1 if i == k - 1 else 0)
			return _make_leg(o, (o[-1] if o.size() > 0 else 0) - 1, 1)
		"push", "push_far":  # stretched back, toe pointed
			var step := 3 if pose == "push_far" else 2
			for i in n:
				o.append(-((i + 1) * step / (n + 1)))
			return _make_leg(o, o[-1] - 1, 0)
		"reach", "reach_far":  # reaching forward
			var k := maxi(n - 1, 1)
			var step := 3 if pose == "reach_far" else 2
			for i in k:
				o.append((i + 1) * step / (k + 1))
			return _make_leg(o, o[-1] + 1, 1)
	push_error("unknown leg pose " + pose)
	return {"a": Vector2i.ZERO, "m": []}


## A puff of smoke from circles [x, y, radius] around its middle (white top-left, grey rest).
func _cloud(circles: Array) -> Dictionary:
	var px := {}
	for c: Array in circles:
		var r: int = c[2]
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				if x * x + y * y <= r * r + r / 2:
					var p := Vector2i(c[0] + x, c[1] + y)
					px[p] = "w" if x + y < -r / 2 else px.get(p, "x")
	return _part_from_pixels(px, Vector2i.ZERO)


# ---------------------------------------------------------------- poses

## The parts of one pose, back to front. `dy` moves the upper body (and hips); legs hang from
## the hips. `hdx` leans the head. Arms/legs are pose names; an arm in "front" is drawn over
## the shirt (the near arm is in front whenever it is not hanging down).
func _stack(o: Dictionary) -> Array:
	var d := Vector2i(o.get("dx", 0), o.get("dy", 0))
	var hd := d + Vector2i(o.get("hdx", 0), 0)
	var arm_l: String = o.get("arm_l", "down")
	var arm_r: String = o.get("arm_r", "down")
	var l_front: bool = o.get("l_front", false)
	var r_front: bool = o.get("r_front", arm_r != "down")
	var stack := []
	if not l_front:
		stack.append(["arm_l_" + arm_l, shoulder_l + d, "body" if arm_l == "down" else "arm_l"])
	if not r_front:
		stack.append(["arm_r_" + arm_r, shoulder_r + d, "body" if arm_r == "down" else "arm_r"])
	stack.append(["leg_l_" + o.get("leg_l", "stand"), hip_l + d, "leg_l"])
	stack.append(["leg_r_" + o.get("leg_r", "stand"), hip_r + d, "leg_r"])
	stack.append(["torso", torso_at + d, "body"])
	stack.append([o.get("head", "head"), map_at + hd, "head"])
	if layout.has("strands"):
		stack.append(["strands", map_at + hd + Vector2i(0, layout.strands.x), "strands"])
	if l_front:
		stack.append(["arm_l_" + arm_l, shoulder_l + d, "arm_l"])
	if r_front:
		stack.append(["arm_r_" + arm_r, shoulder_r + d, "arm_r"])
	return stack


func _pose(o: Dictionary) -> Image:
	return _compose(_stack(o))


func _frames(anim: String) -> Array[Image]:
	var out: Array[Image] = []
	var straight := "run%d" % stand
	match anim:
		"idle":
			# Breathing: the upper body rises 1 px for five frames, like the heroes' bounce.
			for f in 11:
				var up := -1 if f >= 4 and f <= 8 else 0
				out.append(_pose({"dy": up, "leg_l": "stand%d" % (stand - up), "leg_r": "stand%d" % (stand - up)}))
		"run":
			# Two steps of six frames (contact, down x2, passing, up x2), arms against the legs.
			var a := {"head": "head_right", "arm_l": "fwd", "arm_r": "back"}
			var b := {"head": "head_right", "arm_l": "back", "arm_r": "fwd"}
			var mid := {"head": "head_right"}
			var steps := [
				[a, 0, "kick", straight], [a, 1, "kick", "bent"], [a, 1, "kick", "bent"],
				[mid, 0, "lift", straight], [b, -1, "reach", "push"], [b, -1, "reach", "push"],
				[b, 0, straight, "kick"], [b, 1, "bent", "kick"], [b, 1, "bent", "kick"],
				[mid, 0, straight, "lift"], [a, -1, "push", "reach"], [a, -1, "push", "reach"],
			]
			for s: Array in steps:
				out.append(_pose(_with(s[0], {"dy": s[1], "leg_l": s[2], "leg_r": s[3]})))
		"jump":
			out.append(_pose({"dy": -1, "head": "head_right", "arm_l": "back", "arm_r": "up",
				"leg_l": "run%d" % (stand + 1), "leg_r": "lift"}))
		"fall":
			out.append(_pose({"head": "head_right", "arm_l": "up", "arm_r": "up", "l_front": true,
				"leg_l": "lift", "leg_r": straight}))
		"hit":
			var stretch := _pose({"dy": -1, "arm_l": "up", "arm_r": "up", "l_front": true,
				"leg_l": "stand%d" % (stand + 1), "leg_r": "stand%d" % (stand + 1)})
			var squash := _pose({"dy": 1, "head": "head_hurt", "arm_l": "out", "arm_r": "out",
				"leg_l": "bent", "leg_r": "bent"})
			var squash2 := _pose({"dy": mini(2, stand), "head": "head_hurt", "arm_l": "out", "arm_r": "out",
				"leg_l": "squat" if stand >= 2 else "bent", "leg_r": "squat" if stand >= 2 else "bent"})
			out.append(_white(stretch))
			out.append(_white(stretch))
			out.append(stretch)
			out.append(squash)
			out.append(squash2)
			out.append(squash)
			out.append(_pose({}))

		# ---- abilities (each person has only their own) ----
		"wall_jump":
			# Back to the wall on the right, looking away from it, sliding down.
			var wall := _pose({"dx": 2, "head": "head_left", "arm_l": "out", "arm_r": "wall",
				"leg_l": "stand", "leg_r": "wall"})
			for f in 5:
				out.append(wall)
		"dash":
			out = _dash_frames()
		"double_jump":
			# A forward flip: the tucked pose turned a quarter at a time, two frames each.
			var tuck := _centred(_pose({"dy": -1, "head": "head_right", "arm_l": "fwd", "arm_r": "fwd",
				"leg_l": "lift", "leg_r": "lift"}))
			for turn in [1, 1, 2, 2, 3, 3]:
				var img: Image = tuck.duplicate()
				for t in turn:
					img.rotate_90(CLOCKWISE)
				out.append(img)
		"sprint":
			# Leaning forward, longer strides, arms pumping; faint speed lines behind.
			var a := {"hdx": 1, "head": "head_right", "arm_l": "fwd", "arm_r": "back_far"}
			var b := {"hdx": 1, "head": "head_right", "arm_l": "back_far", "arm_r": "fwd_far"}
			var steps := [
				[a, 0, "kick", straight], [a, 1, "kick", "bent"], [a, 0, "lift", straight], [b, -1, "reach_far", "push_far"],
				[b, 0, straight, "kick"], [b, 1, "bent", "kick"], [b, 0, straight, "lift"], [a, -1, "push_far", "reach_far"],
			]
			for i in steps.size():
				var s: Array = steps[i]
				var img := _pose(_with(s[0], {"dy": s[1], "leg_l": s[2], "leg_r": s[3]}))
				_speed_lines(img, i, 2, 0.55)
				out.append(img)
		"shrink":
			# Normal Psalm squashes, vanishes in a puff, and tiny Psalm is left. Backwards = grow.
			var squash := _stack({"dy": 1, "arm_l": "out", "arm_r": "out", "leg_l": "bent", "leg_r": "bent"})
			var middle := map_at + Vector2i(8, 7)
			var tiny := [["tiny", _tiny_at("tiny"), "body"]]
			out.append(_pose({}))
			out.append(_compose(squash))
			out.append(_compose(squash + [["cloud_big", middle, "fx"]]))
			out.append(_compose(tiny + [["cloud_mid", Vector2i(20, 34), "fx"]]))
			out.append(_compose(tiny + [["puff", Vector2i(13, 32), "fx"], ["puff", Vector2i(27, 30), "fx"],
				["puff", Vector2i(21, 26), "fx"]]))
			out.append(_compose(tiny))
		"small_idle":
			for key in ["tiny", "tiny", "tiny", "tiny_up", "tiny_up", "tiny_up", "tiny_up", "tiny"]:
				out.append(_compose([[key, _tiny_at(key), "body"]]))
		"small_run":
			for key in ["tiny_step_l", "tiny_step_l", "tiny", "tiny", "tiny_step_r", "tiny_step_r", "tiny", "tiny"]:
				out.append(_compose([[key, _tiny_at(key), "body"]]))
		"small_jump":
			out.append(_compose([["tiny_jump", _tiny_at("tiny_jump"), "body"]]))
		"small_fall":
			out.append(_compose([["tiny_fall", _tiny_at("tiny_fall"), "body"]]))
	return out


func _with(base: Dictionary, extra: Dictionary) -> Dictionary:
	var o := base.duplicate()
	o.merge(extra, true)
	return o


## Where a tiny-Psalm map goes: centred, feet on the bottom row.
func _tiny_at(key: String) -> Vector2i:
	var m: Array = TINY[key]
	return Vector2i((SIZE - ((m[0] as String).length() + 2)) / 2 + 1, SIZE - m.size())


## Sarah's dash: a low lunge with the arms swept back, two fading copies behind and speed
## lines that slide back every frame.
func _dash_frames() -> Array[Image]:
	var out: Array[Image] = []
	var lunge := _pose({"hdx": 1, "head": "head_right", "arm_l": "back_far", "arm_r": "back_far",
		"leg_l": "push_far", "leg_r": "reach"})
	for f in 4:
		var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		_ghost(img, lunge, -9, 0.16)
		_ghost(img, lunge, -5, 0.33)
		img.blend_rect(lunge, Rect2i(0, 0, SIZE, SIZE), Vector2i.ZERO)
		_speed_lines(img, f, 3, 0.85, lunge.get_used_rect())
		out.append(img)
	return out


func _ghost(dst: Image, src: Image, dx: int, alpha: float) -> void:
	for y in SIZE:
		for x in SIZE:
			var c := src.get_pixel(x, y)
			if c.a > 0.0 and x + dx >= 0 and x + dx < SIZE:
				c.a = alpha
				dst.set_pixel(x + dx, y, dst.get_pixel(x + dx, y).blend(c))


## White streaks behind (left of) the figure; frame `f` slides them back.
func _speed_lines(img: Image, f: int, count: int, alpha: float, around := Rect2i()) -> void:
	var used := around if around.size != Vector2i.ZERO else img.get_used_rect()
	var lines := [[9, 5], [15, 7], [21, 4]]
	for i in count:
		var y: int = used.position.y + lines[i][0]
		var length: int = lines[i][1]
		var end := used.position.x - 1 - ((f * 3 + i * 2) % 6)
		for x in range(end - length, end):
			if x >= 0 and y < SIZE and img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, alpha))


# ---------------------------------------------------------------- drawing

## Looks up a part: drawn or cut parts first, then bent arms/legs, then the mirrored head.
func _part(name: String) -> Dictionary:
	if parts.has(name):
		return parts[name]
	if name.begins_with("arm_l_"):
		return _arm(-1, name.substr(6))
	if name.begins_with("arm_r_"):
		return _arm(1, name.substr(6))
	if name.begins_with("leg_l_") or name.begins_with("leg_r_"):
		var pose := name.substr(6)
		if parts.has("leg_" + pose):  # Chelzy's hand-drawn legs work for either side
			return parts["leg_" + pose]
		return _leg(-1 if name.begins_with("leg_l_") else 1, pose)
	if name == "head_left":
		var m := []
		for row: String in _part("head_right").m:
			m.append(row.reverse())
		return {"a": Vector2i.ZERO, "m": m}
	push_error("unknown part " + name)
	return {"a": Vector2i.ZERO, "m": []}


## Stacks parts back to front, adds the outlines between parts and around the figure.
func _compose(stack: Array) -> Image:
	var keys := PackedStringArray()
	keys.resize(SIZE * SIZE)
	var owner := PackedInt32Array()
	owner.resize(SIZE * SIZE)
	owner.fill(-1)
	var groups: Array[String] = []
	for i in stack.size():
		var part := _part(stack[i][0])
		var joint: Vector2i = stack[i][1]
		groups.append(stack[i][2])
		var rows: Array = part.m
		for r in rows.size():
			var row: String = rows[r]
			for c in row.length():
				var ch := row[c]
				if ch == "." or ch == ":":
					continue
				var p := joint - (part.a as Vector2i) + Vector2i(c, r)
				if p.x < 1 or p.y < 1 or p.x >= SIZE - 1 or p.y >= SIZE:
					push_error("%s %s goes outside the frame at %s" % [person.name, stack[i][0], p])
					continue
				keys[p.y * SIZE + p.x] = ch
				owner[p.y * SIZE + p.x] = i

	# A pixel next to a part drawn in front of it becomes outline.
	var dark := []
	for idx in SIZE * SIZE:
		var me := owner[idx]
		if me < 0 or keys[idx] == "o":
			continue
		for n in _neighbours(idx):
			var them := owner[n]
			if them > me and keys[n] != "o" and not _merged(groups[me], groups[them]):
				dark.append(idx)
				break
	for idx: int in dark:
		keys[idx] = "o"

	# Outer outline around everything that is not already dark.
	var rim := []
	for idx in SIZE * SIZE:
		if owner[idx] >= 0:
			continue
		for n in _neighbours(idx):
			if owner[n] >= 0 and keys[n] != "o":
				rim.append(idx)
				break
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for idx: int in rim:
		img.set_pixel(idx % SIZE, idx / SIZE, colors["o"])
	for idx in SIZE * SIZE:
		if owner[idx] >= 0:
			img.set_pixel(idx % SIZE, idx / SIZE, colors[keys[idx]])
	return img


func _neighbours(idx: int) -> Array[int]:
	var x := idx % SIZE
	var y := idx / SIZE
	var out: Array[int] = []
	if x > 0:
		out.append(idx - 1)
	if x < SIZE - 1:
		out.append(idx + 1)
	if y > 0:
		out.append(idx - SIZE)
	if y < SIZE - 1:
		out.append(idx + SIZE)
	return out


func _merged(a: String, b: String) -> bool:
	return a == b or [a, b] in MERGED or [b, a] in MERGED


## The figure moved so its bounding box sits in the middle of the frame (for the flip).
func _centred(img: Image) -> Image:
	var used := img.get_used_rect()
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, used, Vector2i((SIZE - used.size.x) / 2, (SIZE - used.size.y) / 2))
	return out


## The hit flash: the same shape in plain white.
func _white(img: Image) -> Image:
	var out := img.duplicate() as Image
	for y in SIZE:
		for x in SIZE:
			if out.get_pixel(x, y).a > 0.0:
				out.set_pixel(x, y, Color.WHITE)
	return out


# ---------------------------------------------------------------- output

func _write_sprite_frames(dir: String, name: String, anims: Dictionary) -> void:
	var ext := ""
	var subs := ""
	var list := []
	var tex_id := 0
	var sub_id := 0
	for anim: String in anims:
		tex_id += 1
		ext += '[ext_resource type="Texture2D" path="%s%s.png" id="%d_tex"]\n' % [dir, anim, tex_id]
		var frames := []
		for f in anims[anim][0]:
			sub_id += 1
			subs += '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]\natlas = ExtResource("%d_tex")\nregion = Rect2(%d, 0, %d, %d)\n\n' % [sub_id, tex_id, f * SIZE, SIZE, SIZE]
			frames.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % sub_id)
		list.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}' % [", ".join(frames), str(anims[anim][2]).to_lower(), anim, anims[anim][1]])
	var text := '[gd_resource type="SpriteFrames" format=3]\n\n' + ext + "\n" + subs
	text += "[resource]\nanimations = [%s]\n" % ", ".join(list)
	var file := FileAccess.open(dir + name + "_frames.tres", FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Contact sheet: one row per animation, frames on light boxes, zoomed.
func _write_sheet(strips: Dictionary, path: String) -> void:
	var cols := 12
	var cell := SIZE + 2
	var sheet := Image.create((cols * cell + 2) * PREVIEW_SCALE, (strips.size() * cell + 2) * PREVIEW_SCALE, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("6d727c"))
	var r := 0
	for anim: String in strips:
		var strip: Image = strips[anim]
		for f in strip.get_width() / SIZE:
			var box := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
			box.fill(Color("a9d6a3"))
			box.blend_rect(strip, Rect2i(f * SIZE, 0, SIZE, SIZE), Vector2i.ZERO)
			box.resize(SIZE * PREVIEW_SCALE, SIZE * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(box, Rect2i(0, 0, SIZE * PREVIEW_SCALE, SIZE * PREVIEW_SCALE),
				Vector2i((2 + f * cell) * PREVIEW_SCALE, (2 + r * cell) * PREVIEW_SCALE))
		r += 1
	sheet.save_png(path)
	print("sheet: " + path)


## A page that loops every person's animations (for checking them in motion).
func _write_html(all: Dictionary, path: String) -> void:
	var people := []
	var titles := {"chelzy": "Chelzy · Wall Jump", "sarah": "Sarah · Dash", "april": "April · Double Jump",
		"kervin": "Kervin · Sprint", "psalm": "Psalm · Shrink"}
	for name: String in all:
		var anims := []
		for anim: String in all[name]:
			var strip: Image = all[name][anim]
			anims.append('{"name":"%s","n":%d,"src":"data:image/png;base64,%s"}' % [anim, strip.get_width() / SIZE,
				Marshalls.raw_to_base64(strip.save_png_to_buffer())])
		people.append('{"title":"%s","anims":[%s]}' % [titles[name], ",".join(anims)])
	var html := HTML.replace("__PEOPLE__", "[" + ",".join(people) + "]")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(html)
	f.close()
	print("html: " + path)


const HTML := """<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Team Hero Animations</title>
<style>
:root{--bg:#f4f5f2;--fg:#23242c;--muted:#5d6170;--card:#ffffff;--line:#d9dbe0;--accent:#3d6b4a}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#17181d;--fg:#e9eaee;--muted:#a3a7b3;--card:#22232a;--line:#33353e;--accent:#8fc59c}}
:root[data-theme="dark"]{--bg:#17181d;--fg:#e9eaee;--muted:#a3a7b3;--card:#22232a;--line:#33353e;--accent:#8fc59c}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:1000px;margin:0 auto;padding:24px 16px 48px}h1{font-size:22px;margin:0 0 4px}
h2{font-size:16px;margin:26px 0 10px;color:var(--accent)}p{margin:0 0 12px;color:var(--muted)}
.row{display:flex;flex-wrap:wrap;gap:10px}
.card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:8px;text-align:center;width:132px}
.card canvas{width:120px;height:120px;image-rendering:pixelated;background:#a9d6a3;border-radius:6px;display:block}
.name{font-weight:600;font-size:13px;margin-top:4px}.sub{font-size:12px;color:var(--muted)}
.ability{border-color:var(--accent)}
</style></head><body><main>
<h1>The team as heroes</h1>
<p>Every animation loops at the game's speed (20 fps). Each teammate has the basic set plus only their own ability (outlined in green).</p>
<div id="list"></div>
</main><script>
const PEOPLE=__PEOPLE__;
const BASIC=['idle','run','jump','fall','hit'];
const LABEL={idle:'Idle',run:'Run',jump:'Jump',fall:'Fall',hit:'Hit',wall_jump:'Wall slide',dash:'Dash',double_jump:'Double jump (flip)',sprint:'Sprint',shrink:'Shrink',small_idle:'Tiny idle',small_run:'Tiny run',small_jump:'Tiny jump',small_fall:'Tiny fall'};
const list=document.getElementById('list'),loops=[];
for(const p of PEOPLE){const h=document.createElement('h2');h.textContent=p.title;list.appendChild(h);const row=document.createElement('div');row.className='row';
for(const a of p.anims){const card=document.createElement('div');card.className='card'+(BASIC.includes(a.name)?'':' ability');const c=document.createElement('canvas');c.width=40;c.height=40;card.appendChild(c);
const nm=document.createElement('div');nm.className='name';nm.textContent=LABEL[a.name]||a.name;card.appendChild(nm);const sub=document.createElement('div');sub.className='sub';sub.textContent=a.n+(a.n===1?' frame':' frames');card.appendChild(sub);row.appendChild(card);
const im=new Image();im.src=a.src;loops.push({ctx:c.getContext('2d'),im,n:a.n})}list.appendChild(row)}
let tick=0,last=0;function loop(t){if(t-last>=50){last=t;tick++;for(const l of loops){if(!l.im.complete)continue;const f=tick%(l.n+(l.n<8?6:0));const k=Math.min(f,l.n-1);l.ctx.clearRect(0,0,40,40);l.ctx.drawImage(l.im,k*40,0,40,40,0,0,40,40)}}requestAnimationFrame(loop)}
requestAnimationFrame(loop);
</script></body></html>
"""
