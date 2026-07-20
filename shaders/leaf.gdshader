// Spatial shader that turns a flat quad into a green leaf silhouette (no texture
// needed). Assign this to the QuadMesh used in the particle system's Draw Pass.
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform vec3 leaf_color : source_color = vec3(0.16, 0.55, 0.13);   // base green
uniform vec3 leaf_tip   : source_color = vec3(0.42, 0.78, 0.22);   // lighter edge/tip
uniform float vein_strength : hint_range(0.0, 1.0) = 0.3;
uniform float emission_amount : hint_range(0.0, 1.0) = 0.05;       // subtle glow so it pops

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;                 // -1..1 across the quad

	// Pointed-oval leaf silhouette: width tapers to a point at top and bottom.
	float half_w = (1.0 - uv.y * uv.y) * 0.8;
	if (abs(uv.x) - half_w > 0.0)
		discard;                              // outside the leaf -> transparent

	// Green gradient from base to tip, times the per-leaf tint from the particle.
	vec3 col = mix(leaf_color, leaf_tip, UV.y) * COLOR.rgb;

	// Darken a thin midrib vein down the center.
	float vein = smoothstep(0.05, 0.0, abs(uv.x)) * vein_strength;
	col = mix(col, col * 0.55, vein);

	ALBEDO = col;
	ROUGHNESS = 0.7;
	EMISSION = col * emission_amount;
}
