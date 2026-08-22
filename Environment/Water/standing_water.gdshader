shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(0.07, 0.20, 0.30, 1.0);
uniform float base_opacity : hint_range(0.0, 1.0) = 0.40;
uniform float depth_opacity_gain : hint_range(0.0, 0.25) = 0.08;
uniform float shimmer_strength : hint_range(0.0, 0.08) = 0.015;
uniform float shimmer_speed : hint_range(0.0, 4.0) = 0.7;

void fragment() {
	float depth = smoothstep(0.0, 1.0, UV.y);
	float tick = floor(TIME * 8.0) / 8.0;
	float shimmer = sin(UV.y * 42.0 + tick * shimmer_speed * 5.0) * shimmer_strength;
	float alpha = clamp(base_opacity + depth * depth_opacity_gain + shimmer, 0.0, 0.72);
	vec3 depth_color = mix(tint.rgb * 1.08, tint.rgb * 0.82, depth);
	COLOR = vec4(depth_color, alpha * tint.a);
}
