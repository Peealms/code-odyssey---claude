class_name GameFonts
extends RefCounted
## The game's two reading fonts, in one place so the books, chest window, signs and Byte's
## terminal all match:
##   TEXT  Pixel Operator by Jayvee Enaguas (CC0): words. It's drawn on a 16 px grid, so it's
##         sharpest at 16 (or 8) - at the game's 2x and 3x window sizes every pixel stays square.
##   CODE  JetBrains Mono (SIL Open Font License): Java code, like in a real code editor.
## Licences: assets/shared/ui/fonts/pixel_operator/LICENSE.txt and jetbrains_mono/OFL.txt.

const TEXT := preload("res://assets/shared/ui/fonts/pixel_operator/PixelOperator.ttf")
const TEXT_BOLD := preload("res://assets/shared/ui/fonts/pixel_operator/PixelOperator-Bold.ttf")
const CODE := preload("res://assets/shared/ui/fonts/jetbrains_mono/JetBrainsMono-Regular.ttf")
const CODE_BOLD := preload("res://assets/shared/ui/fonts/jetbrains_mono/JetBrainsMono-Bold.ttf")

const TEXT_SIZE := 16
const SMALL_TEXT_SIZE := 8  ## Still sharp: half the font's grid.
const CODE_SIZE := 11


## Pixel Operator slanted for italics (it has no italic of its own).
static func italic() -> FontVariation:
	var v := FontVariation.new()
	v.base_font = TEXT
	v.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	return v
