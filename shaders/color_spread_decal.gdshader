shader_type spatial;
// Projected "decal" version of the vine spread. Put this on a BoxMesh (unit cube)
// MeshInstance3D and scale/position the box over the surface you want it on.
// It reconstructs the underlying surface from the depth buffer, so the vines
// project onto whatever geometry sits inside the box. Forward+ renderer required.
render_mode blend_mix, cull_front, depth_draw_never, depth_test_disabled, unshaded;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform float spread_radius : hint_range(0.0, 2.0) = 0.0;   // 0..~0.9 (in box-local units)
uniform float edge_width : hint_range(0.001, 0.5) = 0.06;

uniform vec4 spread_color : source_color = vec4(0.2, 0.65, 0.3, 1.0);
uniform vec4 edge_color : source_color = vec4(0.6, 1.0, 0.5, 1.0);
uniform float edge_emission : hint_range(0.0, 8.0) = 2.5;

uniform float vine_scale : hint_range(0.2, 40.0) = 12.0;
uniform float vine_reach : hint_range(0.0, 1.0) = 0.35;
uniform float vine_thinness : hint_range(1.0, 8.0) = 3.0;
uniform float warp_amount : hint_range(0.0, 2.0) = 0.6;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash(i + vec3(1.0, 1.0, 1.0));
	vec4 x = mix(vec4(n000, n010, n001, n011), vec4(n100, n110, n101, n111), f.x);
	vec2 y = mix(x.xz, x.yw, f.y);
	return mix(y.x, y.y, f.z);
}

float ridged(vec3 p) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		float n = 1.0 - abs(vnoise(p) * 2.0 - 1.0);
		n *= n;
		sum += n * amp;
		p *= 2.0;
		amp *= 0.5;
	}
	return sum;
}

void fragment() {
	// Reconstruct the underlying surface position from the depth buffer.
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	view.xyz /= view.w;
	vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;

	// Into the box's local space (unit cube spans -0.5..0.5). Clip outside the box.
	vec3 local = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	if (abs(local.x) > 0.5 || abs(local.y) > 0.5 || abs(local.z) > 0.5) {
		discard;
	}

	// Vine field, spreading across the projection plane (ignore the Y/projection
	// axis) so it covers the whole footprint regardless of box height or where
	// the surface sits inside the box.
	float d = length(local.xz);
	vec3 q = local * vine_scale;
	q += warp_amount * vec3(vnoise(q + 11.5), vnoise(q + 47.2), vnoise(q + 83.9));
	float veins = pow(ridged(q), vine_thinness);
	float effective = d - veins * vine_reach;

	float t = smoothstep(spread_radius, spread_radius - edge_width, effective);
	if (t <= 0.001) {
		discard; // nothing here yet -> let the surface show through
	}

	ALBEDO = spread_color.rgb;
	ALPHA = t * spread_color.a;

	float edge = smoothstep(edge_width, 0.0, abs(effective - spread_radius));
	EMISSION = edge_color.rgb * edge * edge_emission * step(0.001, spread_radius);
}
