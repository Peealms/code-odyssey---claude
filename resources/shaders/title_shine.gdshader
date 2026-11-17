// A band of light that sweeps across the title letters (scripts/ui/title_logo.gd).
// Every letter has its own material; the script moves `shine` along the whole logo, and
// `letter_pos` says where this letter sits in it, so the band runs across all of them as one.
// The band is slanted and snapped to whole pixels, so it stays pixel art. It only lights the
// letters' faces, not their dark outline or 3D side.
shader_type canvas_item;

uniform float shine = -1000.0; // where the band is: x + y / 2, in logo pixels
uniform vec2 letter_pos = vec2(0.0); // this letter's origin, in logo pixels
uniform float half_width = 3.0;

varying vec2 logo_pos;

void vertex() {
	logo_pos = VERTEX + letter_pos;
}

void fragment() {
	vec4 c = COLOR; // the texture, with the node's modulate
	vec2 p = floor(logo_pos);
	float on_band = step(abs(p.x + p.y * 0.5 - shine), half_width);
	float face = step(0.35, dot(c.rgb, vec3(0.299, 0.587, 0.114)));
	c.rgb = mix(c.rgb, vec3(1.0), on_band * face * 0.65);
	COLOR = c;
}
