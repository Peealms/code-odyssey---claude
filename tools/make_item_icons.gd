extends SceneTree
## Draws the 16x16 manual book icons (one per cover colour) into
##   assets/shared/items/books.png   (horizontal strip, frame N = cover colour N)
## Run:  godot --headless --path . --script res://tools/make_item_icons.gd
## Then: godot --headless --path . --import
## A manual picks its colour with "book" in scripts/manuals/manual_library.gd.

const SIZE := 16
const OUT := "res://assets/shared/items/books.png"

const O := Color("2a2238")  # outline
const PAGE := Color("f3e6c4")
const PAGE_SHADE := Color("cdb991")

## Cover colours: [main, dark spine/shadow, light highlight]
const COVERS := [
	[Color("c0392b"), Color("7f1f1a"), Color("e5664f")],  # 0 red
	[Color("3b6fd1"), Color("23458a"), Color("6d97e6")],  # 1 blue
	[Color("3e9b4f"), Color("246130"), Color("6cc27a")],  # 2 green
	[Color("8e4fc4"), Color("5a2d84"), Color("b07ddc")],  # 3 purple
	[Color("e08a2e"), Color("9a5615"), Color("f2b061")],  # 4 orange
]

var img: Image


func _init() -> void:
	var strip := Image.create(SIZE * COVERS.size(), SIZE, false, Image.FORMAT_RGBA8)
	for i in COVERS.size():
		img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		_draw_book(COVERS[i])
		strip.blit_rect(img, Rect2i(0, 0, SIZE, SIZE), Vector2i(i * SIZE, 0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	print("books.png: ", error_string(strip.save_png(OUT)))
	quit()


func rect(x: int, y: int, w: int, h: int, col: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), col)


func _draw_book(c: Array) -> void:
	var main: Color = c[0]
	var dark: Color = c[1]
	var light: Color = c[2]
	# outline
	rect(2, 1, 12, 14, O)
	img.set_pixel(2, 1, Color(0, 0, 0, 0))
	img.set_pixel(13, 14, Color(0, 0, 0, 0))
	# cover
	rect(3, 2, 9, 11, main)
	# spine on the left
	rect(3, 2, 2, 12, dark)
	rect(5, 2, 1, 11, light)
	# pages showing on the right and bottom
	rect(12, 3, 1, 11, PAGE)
	rect(6, 13, 7, 1, PAGE)
	img.set_pixel(12, 13, PAGE_SHADE)
	# label plate on the cover
	rect(7, 4, 4, 3, PAGE)
	rect(8, 5, 2, 1, PAGE_SHADE)
	# highlight on the top edge
	rect(6, 2, 5, 1, light)
