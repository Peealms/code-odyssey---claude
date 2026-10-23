// Tiled background that slowly scrolls, for a TextureRect in STRETCH_TILE mode.
// The TextureRect needs Texture > Repeat = Enabled.
shader_type canvas_item;

uniform vec2 speed = vec2(0.0, 0.2); // tiles per second

void fragment() {
	// Multiply by COLOR so the node's modulate (used to crossfade rooms) still applies.
	COLOR = texture(TEXTURE, UV - speed * TIME) * COLOR;
}
