// Tiled background that slowly scrolls, for a TextureRect in STRETCH_TILE mode.
// The TextureRect needs Texture > Repeat = Enabled.
shader_type canvas_item;

uniform vec2 speed = vec2(0.0, 0.2); // tiles per second

// The node's modulate (used to crossfade rooms). Taken in vertex(): in fragment() COLOR
// already holds the unscrolled texture, which would show a still copy on top.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	COLOR = texture(TEXTURE, UV - speed * TIME) * tint;
}
