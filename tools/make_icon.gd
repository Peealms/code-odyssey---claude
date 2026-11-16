extends SceneTree
## Draws the game's icon, assets/shared/icon.png (256 x 256): Byte, our robot helper, big and
## pixel-sharp on a dark rounded tile with Byte's teal edge. project.godot uses it for the
## window and taskbar (application/config/icon).
## Run:  godot --headless --path . --script res://tools/make_icon.gd
## Then: godot --headless --path . --import

const OUT := "res://assets/shared/icon.png"
const SIZE := 256
const RADIUS := 44  ## Rounded corners.
const EDGE := 10  ## The teal edge's width.
const BG := Color("1b1530")
const BG_TOP := Color("2b2448")
const TEAL := Color("2a9d8f")


func _init() -> void:
	var frames: SpriteFrames = load("res://assets/shared/byte/byte_frames.tres")
	var byte := frames.get_frame_texture(&"idle", 0).get_image()
	if byte.is_compressed():
		byte.decompress()
	byte.convert(Image.FORMAT_RGBA8)
	var used := byte.get_used_rect()
	byte = byte.get_region(used)
	# As big as whole pixels allow, with room for the edge.
	var scale := int(floor((SIZE - 2 * EDGE - 40) / float(maxi(used.size.x, used.size.y))))
	byte.resize(used.size.x * scale, used.size.y * scale, Image.INTERPOLATE_NEAREST)

	var icon := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var d := _outside(x, y)
			if d > 0.0:
				continue  # off the rounded tile: transparent
			var inside_edge := d > -EDGE
			icon.set_pixel(x, y, TEAL if inside_edge else BG.lerp(BG_TOP, 1.0 - y / float(SIZE)))
	var at := Vector2i((SIZE - byte.get_width()) / 2, (SIZE - byte.get_height()) / 2)
	icon.blend_rect(byte, Rect2i(Vector2i.ZERO, byte.get_size()), at)
	print("icon: ", error_string(icon.save_png(ProjectSettings.globalize_path(OUT))), " (Byte x", scale, ")")
	quit()


## How far (px) the point is outside the rounded square: > 0 outside, < 0 inside.
func _outside(x: int, y: int) -> float:
	var cx := clampf(x + 0.5, RADIUS, SIZE - RADIUS)
	var cy := clampf(y + 0.5, RADIUS, SIZE - RADIUS)
	return Vector2(x + 0.5 - cx, y + 0.5 - cy).length() - RADIUS
