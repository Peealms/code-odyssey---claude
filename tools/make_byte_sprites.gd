extends SceneTree
## Draws Byte (the helper robot) as 24x24 pixel art and writes:
##   assets/shared/byte/<anim>.png   one horizontal strip per animation
##   assets/shared/byte/byte_frames.tres   SpriteFrames with every animation
## Run:  godot --headless --path . --script res://tools/make_byte_sprites.gd [-- <preview.png>]
## Then: godot --headless --path . --import   (so Godot imports the new PNGs)
## Edit the palette or draw_* functions and re-run to change Byte's look.

const SIZE := 24
const OUT_DIR := "res://assets/shared/byte/"

# Palette (close to Pixel Frog's soft outlines)
const O := Color("2a2238")        # outline
const W := Color("ffffff")        # highlight
const B := Color("d9e4ef")        # body light
const M := Color("a7b8cc")        # body mid
const S := Color("6f819c")        # body shadow
const K := Color("1b2a3a")        # screen
const C := Color("5ef2e0")        # face cyan (normal)
const G := Color("7cf07c")        # face green (happy)
const R := Color("ff5c6c")        # face red (error)
const Y := Color("ffd34d")        # antenna bulb / sparkles

# name -> [frame count, fps, loop]
const ANIMS := {
	"idle": [8, 8.0, true],
	"follow": [6, 10.0, true],
	"talk": [4, 8.0, true],
	"happy": [6, 10.0, false],
	"error": [6, 12.0, false],
}

var img: Image
var ox := 0
var oy := 0


func _init() -> void:
	var preview_path := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		preview_path = args[0]

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var strips := {}
	for anim in ANIMS:
		var count: int = ANIMS[anim][0]
		var strip := Image.create(SIZE * count, SIZE, false, Image.FORMAT_RGBA8)
		for f in count:
			img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
			call("draw_" + anim, f)
			strip.blit_rect(img, Rect2i(0, 0, SIZE, SIZE), Vector2i(f * SIZE, 0))
		var err := strip.save_png(OUT_DIR + anim + ".png")
		print("%s.png: %d frames (%s)" % [anim, count, error_string(err)])
		strips[anim] = strip

	_write_sprite_frames()
	if preview_path != "":
		_write_preview(strips, preview_path)
	quit()


# --- drawing helpers -------------------------------------------------------

func px(x: int, y: int, col: Color) -> void:
	x += ox
	y += oy
	if x >= 0 and x < SIZE and y >= 0 and y < SIZE:
		img.set_pixel(x, y, col)


func rect(x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(xx, yy, col)


## The robot body without a face. bulb = antenna colour, glow = thruster strength 0..2.
func draw_body(bulb: Color, glow: int) -> void:
	# antenna bulb (sits on top of the head)
	rect(11, 2, 2, 1, O)
	rect(10, 3, 4, 2, O)
	rect(11, 3, 2, 2, bulb)
	px(11, 3, W)
	# head / body outline with rounded corners
	rect(5, 5, 14, 1, O)
	rect(4, 6, 16, 12, O)
	rect(5, 18, 14, 1, O)
	# body fill and shading
	rect(5, 6, 14, 12, B)
	rect(18, 7, 1, 10, M)
	rect(5, 16, 14, 1, M)
	rect(5, 17, 14, 1, S)
	rect(5, 6, 1, 3, W)
	px(6, 6, W)
	# screen with rounded corners
	rect(6, 7, 12, 8, K)
	px(6, 7, M)
	px(17, 7, M)
	px(6, 14, M)
	px(17, 14, M)
	# side bolts
	rect(2, 10, 2, 3, O)
	px(3, 11, M)
	rect(20, 10, 2, 3, O)
	px(20, 11, M)
	# thruster
	px(9, 19, O)
	rect(10, 19, 4, 1, S)
	px(14, 19, O)
	rect(10, 20, 4, 1, O)
	# thruster glow
	var g := C
	g.a = 0.75
	var g2 := C
	g2.a = 0.4
	if glow >= 1:
		rect(10, 21, 4, 1, g)
		rect(11, 22, 2, 1, g2)
	if glow >= 2:
		rect(11, 22, 2, 1, g)
		px(11, 23, g2)
		px(12, 23, g2)


func eyes(col: Color, look := 0, blink := false) -> void:
	for ex in [8, 14]:
		if blink:
			rect(ex + look, 10, 2, 1, col)
		else:
			rect(ex + look, 9, 2, 2, col)


func smile(col: Color) -> void:
	px(9, 12, col)
	rect(10, 13, 4, 1, col)
	px(14, 12, col)


func sparkle(x: int, y: int) -> void:
	px(x, y, Y)
	px(x - 1, y, Y)
	px(x + 1, y, Y)
	px(x, y - 1, Y)
	px(x, y + 1, Y)


# --- animations ------------------------------------------------------------

func draw_idle(f: int) -> void:
	ox = 0
	oy = [0, 0, 0, 1, 1, 1, 0, 0][f]
	draw_body(Y, 1 + f % 2)
	eyes(C, 0, f == 6)
	smile(C)


func draw_follow(f: int) -> void:
	# faster bob, bigger flame, eyes looking ahead (right; use flip_h for left)
	ox = 0
	oy = [0, 1, 1, 0, 0, 1][f]
	draw_body(Y, 2)
	eyes(C, 1)
	smile(C)


func draw_talk(f: int) -> void:
	ox = 0
	oy = [0, 0, 1, 1][f]
	draw_body(Y, 1 + f % 2)
	eyes(C)
	if f % 2 == 0:
		# open mouth
		rect(10, 11, 4, 1, C)
		px(10, 12, C)
		px(13, 12, C)
		rect(10, 13, 4, 1, C)
	else:
		rect(10, 12, 4, 1, C)


func draw_happy(f: int) -> void:
	ox = 0
	oy = [0, -1, -2, -1, 0, 0][f]
	draw_body(Y, 2 if f < 3 else 1)
	# ^ ^ eyes
	for ex in [8, 14]:
		px(ex - 1, 9, G)
		rect(ex, 8, 2, 1, G)
		px(ex + 2, 9, G)
	# wide open grin
	rect(9, 11, 6, 1, G)
	px(9, 12, G)
	px(14, 12, G)
	rect(10, 13, 4, 1, G)
	if f in [1, 2, 3]:
		sparkle(2, 6)
		sparkle(21, 7)
	if f in [2, 3, 4]:
		sparkle(19, 4)


func draw_error(f: int) -> void:
	ox = [0, -1, 1, -1, 1, 0][f]
	oy = 0
	draw_body(R, 1)
	# X X eyes
	for ex in [7, 14]:
		px(ex, 8, R)
		px(ex + 2, 8, R)
		px(ex + 1, 9, R)
		px(ex, 10, R)
		px(ex + 2, 10, R)
	# wavy mouth
	for i in 6:
		px(9 + i, 13 if i % 2 == 0 else 12, R)


# --- output ----------------------------------------------------------------

func _write_sprite_frames() -> void:
	var ext := ""
	var subs := ""
	var anims := []
	var tex_id := 0
	var sub_id := 0
	for anim in ANIMS:
		tex_id += 1
		ext += '[ext_resource type="Texture2D" path="%s%s.png" id="%d_tex"]\n' % [OUT_DIR, anim, tex_id]
		var frames := []
		for f in ANIMS[anim][0]:
			sub_id += 1
			subs += '[sub_resource type="AtlasTexture" id="AtlasTexture_%d"]\natlas = ExtResource("%d_tex")\nregion = Rect2(%d, 0, %d, %d)\n\n' % [sub_id, tex_id, f * SIZE, SIZE, SIZE]
			frames.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % sub_id)
		anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}' % [", ".join(frames), str(ANIMS[anim][2]).to_lower(), anim, ANIMS[anim][1]])

	var text := '[gd_resource type="SpriteFrames" format=3]\n\n' + ext + "\n" + subs
	text += "[resource]\nanimations = [%s]\n" % ", ".join(anims)
	var file := FileAccess.open(OUT_DIR + "byte_frames.tres", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("byte_frames.tres written")


## A scaled-up contact sheet (one row per animation) for checking the art.
func _write_preview(strips: Dictionary, path: String) -> void:
	var scale := 6
	var max_w := 0
	for anim in strips:
		max_w = max(max_w, strips[anim].get_width())
	var sheet := Image.create(max_w * scale, SIZE * scale * strips.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3c4a5c"))
	var row := 0
	for anim in strips:
		var big: Image = strips[anim].duplicate()
		big.resize(big.get_width() * scale, SIZE * scale, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(0, row * SIZE * scale))
		row += 1
	sheet.save_png(path)
	print("preview: " + path)
