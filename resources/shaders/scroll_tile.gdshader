// Tiled background that slowly scrolls, for a TextureRect in STRETCH_TILE mode.
// The TextureRect needs Texture > Repeat = Enabled.
shader_type canvas_item;

uniform vec2 speed = vec2(0.0, 0.2); // tiles per second

void fragment() {
	COLOR = texture(TEXTURE, UV - speed * TIME);
}
