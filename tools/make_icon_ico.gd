extends SceneTree
## Makes assets/shared/icon.ico (the .exe's icon, set in export_presets.cfg) from icon.png:
## one PNG-compressed entry per size Windows asks for, 16 to 256 px.
## Run:  godot --headless --path . --script res://tools/make_icon_ico.gd

const SOURCE := "res://assets/shared/icon.png"
const OUT := "res://assets/shared/icon.ico"
const SIZES := [16, 24, 32, 48, 64, 128, 256]


func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	var pngs: Array[PackedByteArray] = []
	for s in SIZES:
		var img := source.duplicate() as Image
		img.resize(s, s, Image.INTERPOLATE_LANCZOS)
		pngs.append(img.save_png_to_buffer())
	var ico := StreamPeerBuffer.new()  # little-endian
	ico.put_u16(0)
	ico.put_u16(1)  # type: icon
	ico.put_u16(SIZES.size())
	var offset := 6 + 16 * SIZES.size()
	for i in SIZES.size():
		var s: int = SIZES[i]
		ico.put_u8(0 if s == 256 else s)  # 0 means 256
		ico.put_u8(0 if s == 256 else s)
		ico.put_u8(0)  # no palette
		ico.put_u8(0)
		ico.put_u16(1)  # planes
		ico.put_u16(32)  # bits per pixel
		ico.put_u32(pngs[i].size())
		ico.put_u32(offset)
		offset += pngs[i].size()
	for png in pngs:
		ico.put_data(png)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_buffer(ico.data_array)
	f.close()
	print("wrote %s (%d bytes, sizes %s)" % [OUT, ico.data_array.size(), SIZES])
	quit()
