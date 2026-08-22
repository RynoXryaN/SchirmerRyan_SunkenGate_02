shader_type canvas_item;
render_mode unshaded;

uniform bool use_texture = false;
uniform float speed = 1.0;
uniform vec4 tint : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.55;
uniform float animation_fps : hint_range(1.0, 30.0) = 10.0;
uniform vec2 region_size = vec2(192.0, 8.0);
uniform vec2 tile_size = vec2(64.0, 64.0);

void fragment() {
	float tick = floor(TIME * animation_fps) / animation_fps;
	vec2 tiled_uv = UV * region_size / tile_size;
	vec2 uv = tiled_uv;
	uv.x += tick * speed * 0.08;
	vec4 tex = texture(TEXTURE, uv);
	vec4 counter = texture(TEXTURE, vec2(tiled_uv.x - tick * speed * 0.045 + 0.41, tiled_uv.y + 0.5));
	float wave = step(0.35, sin(tiled_uv.x * 32.0 + tick * speed * 4.0));
	float broken_crest = wave * step(0.58, max(tex.b, counter.b));
	vec3 bright = min(tint.rgb * 1.35, vec3(1.0));
	vec3 authored = mix(tex.rgb * tint.rgb, bright, broken_crest * highlight_strength);
	float simple_crest = step(0.52, sin(tiled_uv.x * 18.0 + tick * speed * 2.0));
	vec3 procedural = mix(tint.rgb * 0.88, bright, simple_crest * 0.22);
	COLOR = use_texture ? vec4(authored, tex.a * tint.a) : vec4(procedural, tint.a);
}
