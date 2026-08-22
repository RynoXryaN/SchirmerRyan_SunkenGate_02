shader_type canvas_item;
render_mode unshaded;

uniform bool use_texture = false;
uniform vec2 speed = vec2(0.0, 0.6);
uniform vec4 tint : source_color = vec4(0.55, 0.85, 1.0, 1.0);
uniform float detail_strength : hint_range(0.0, 1.0) = 0.38;
uniform float animation_fps : hint_range(1.0, 30.0) = 12.0;
uniform vec2 region_size = vec2(64.0, 96.0);
uniform vec2 tile_size = vec2(64.0, 64.0);
uniform int origin_shape = 1;
uniform float origin_depth = 12.0;
uniform float origin_corner_radius = 5.0;

void fragment() {
	float tick = floor(TIME * animation_fps) / animation_fps;
	vec2 tiled_uv = UV * region_size / tile_size;
	vec2 primary_uv = tiled_uv - tick * speed;
	vec2 detail_uv = vec2(1.0 - tiled_uv.x, tiled_uv.y) - tick * speed * vec2(0.35, 1.65) + vec2(0.17, 0.31);
	vec4 primary = texture(TEXTURE, primary_uv);
	vec4 detail = texture(TEXTURE, detail_uv);
	vec3 layered = mix(primary.rgb, max(primary.rgb, detail.rgb * 0.9), detail_strength);
	float flash = step(0.82, detail.b) * step(0.68, detail.g);
	layered += vec3(0.08, 0.16, 0.2) * flash * detail_strength;
	vec3 procedural = mix(tint.rgb * 0.65, tint.rgb, step(0.62, fract(tiled_uv.x * 9.0 + tiled_uv.y * 3.0 + tick * 5.0)) * 0.35);
	float mask = 1.0;
	vec2 pixel = UV * region_size;
	float cap_depth = min(origin_depth, region_size.y);
	if (pixel.y < cap_depth) {
		if (origin_shape == 0) {
			float radius = min(region_size.x * 0.5, cap_depth);
			if (pixel.y < radius) {
				mask = step(distance(pixel, vec2(region_size.x * 0.5, radius)), radius);
			}
		} else {
			float radius = min(origin_corner_radius, min(region_size.x * 0.5, cap_depth));
			if (pixel.y < radius && pixel.x < radius) {
				mask = step(distance(pixel, vec2(radius)), radius);
			} else if (pixel.y < radius && pixel.x > region_size.x - radius) {
				mask = step(distance(pixel, vec2(region_size.x - radius, radius)), radius);
			}
		}
	}
	vec4 water = use_texture ? vec4(layered * tint.rgb, primary.a * tint.a) : vec4(procedural, tint.a);
	COLOR = vec4(water.rgb, water.a * mask);
}
