shader_type spatial;

// Per-mesh vine spread along a straight TRAIL from `trail_start` to `trail_end`
// (both in mesh LOCAL space). Animate `progress` upward: the tip travels from
// start to end (reaching it at progress = 1), and every point keeps spreading
// the longer it's been reached -- so it grows like a triangle and keeps
// expanding even after the tip arrives. Animate `progress` 0 -> ~2+.

uniform vec3 trail_start = vec3(0.0);
uniform vec3 trail_end = vec3(0.0, 0.0, 1.0);
uniform float progress : hint_range(0.0, 4.0) = 0.0;        // main driver (tip reaches end at 1.0)
uniform float spread_rate : hint_range(0.0, 500.0) = 1.0;     // how fast thickness grows behind the tip
uniform float max_radius : hint_range(0.0, 500.0) = 2.0;      // cap on thickness
uniform float edge_width : hint_range(0.001, 2.0) = 0.2;

uniform vec4 base_color : source_color = vec4(0.35, 0.35, 0.35, 1.0);
uniform vec4 spread_color : source_color = vec4(0.2, 0.65, 0.3, 1.0);
uniform vec4 edge_color : source_color = vec4(0.6, 1.0, 0.5, 1.0);
uniform float edge_emission : hint_range(0.0, 8.0) = 2.5;

uniform float vine_scale : hint_range(0.2, 40.0) = 4.0;
uniform float vine_reach : hint_range(0.0, 4.0) = 1.6;
uniform float vine_thinness : hint_range(1.0, 8.0) = 3.0;
uniform float warp_amount : hint_range(0.0, 2.0) = 0.6;

varying vec3 local_pos;

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

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// vine filament field
	vec3 q = local_pos * vine_scale;
	q += warp_amount * vec3(vnoise(q + 11.5), vnoise(q + 47.2), vnoise(q + 83.9));
	float veins = pow(ridged(q), vine_thinness);

	// position along the full start->end line (clamped to the segment)
	vec3 ab = trail_end - trail_start;
	float f = clamp(dot(local_pos - trail_start, ab) / max(dot(ab, ab), 1e-6), 0.0, 1.0);
	float d = distance(local_pos, trail_start + ab * f);

	// "age" = how long ago the tip passed this point (tip is at fraction = progress,
	// so a point at fraction f was reached at progress = f). Older points (closer to
	// the start) have spread further, so the radius grows toward the start -> a
	// triangle that keeps expanding as progress increases.
	float age = progress - f;
	float radius = clamp(age * spread_rate, 0.0, max_radius);

	float effective = d - veins * vine_reach;
	float t = smoothstep(radius, radius - edge_width, effective);
	ALBEDO = mix(base_color.rgb, spread_color.rgb, t);

	float edge = smoothstep(edge_width, 0.0, abs(effective - radius));
	EMISSION = edge_color.rgb * edge * edge_emission * step(0.001, t);
}
