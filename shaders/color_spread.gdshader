shader_type spatial;

// Color spreads from `spread_origin` (mesh LOCAL space) like VINES: thin tendrils
// race outward along noise ridges, then the gaps fill in.
// Animate `spread_radius` 0 -> max to play it.

uniform vec3 spread_origin = vec3(0.0);
uniform float spread_radius : hint_range(0.0, 12.0) = 0.0;
uniform float edge_width : hint_range(0.001, 2.0) = 0.2;

uniform vec4 base_color : source_color = vec4(0.35, 0.35, 0.35, 1.0);   // before
uniform vec4 spread_color : source_color = vec4(0.2, 0.65, 0.3, 1.0);   // the vines/after
uniform vec4 edge_color : source_color = vec4(0.6, 1.0, 0.5, 1.0);      // glowing tips
uniform float edge_emission : hint_range(0.0, 8.0) = 2.5;

uniform float vine_scale : hint_range(0.2, 20.0) = 4.0;     // tendril frequency (bigger = finer)
uniform float vine_reach : hint_range(0.0, 4.0) = 1.6;      // how far tendrils shoot ahead
uniform float vine_thinness : hint_range(1.0, 8.0) = 3.0;   // bigger = thinner, wispier vines
uniform float warp_amount : hint_range(0.0, 2.0) = 0.6;     // curl/meander of the tendrils

varying vec3 local_pos;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

// trilinear value noise
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

// ridged fractal noise -> bright thin filaments (the "veins")
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
	return sum; // ~0..1
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float d = distance(local_pos, spread_origin);

	// domain-warp the sample point so tendrils curl instead of going straight
	vec3 q = local_pos * vine_scale;
	q += warp_amount * vec3(
		vnoise(q + 11.5),
		vnoise(q + 47.2),
		vnoise(q + 83.9));

	float veins = pow(ridged(q), vine_thinness); // thin filaments, high on the vine lines

	// along the veins the effective distance shrinks, so they reveal first
	float effective = d - veins * vine_reach;

	float t = smoothstep(spread_radius, spread_radius - edge_width, effective);
	ALBEDO = mix(base_color.rgb, spread_color.rgb, t);

	// glow on the growing tips
	float edge = smoothstep(edge_width, 0.0, abs(effective - spread_radius));
	EMISSION = edge_color.rgb * edge * edge_emission * step(0.001, spread_radius);
}
