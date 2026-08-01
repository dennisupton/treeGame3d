// Stylized flat pebble path -- solid-color stones on a TRANSPARENT background.
// Voronoi packs rounded stones of varied sizes; each is filled with a single flat
// color and ringed by a dark outline. The gaps are discarded (fully transparent),
// so whatever is under the path -- terrain, grass, dirt -- shows straight through.
//
// Driven by WORLD XZ position, so it tiles seamlessly across the ground whatever
// the mesh's UVs or scale. Meant for flat ground (up = +Y). Put it on a plane that
// sits just above the ground you want to show through the gaps.
shader_type spatial;
render_mode cull_disabled;

// --- Layout ------------------------------------------------------------------
uniform float pattern_scale : hint_range(0.3, 20.0) = 2.2;   // stones per world unit (bigger = smaller stones)
uniform float cell_jitter : hint_range(0.0, 0.9) = 0.7;      // 0 = grid, high = scattered stone centres
uniform float stone_fill : hint_range(0.3, 1.0) = 0.8;       // how much of each cell a stone fills (rounds the corners)
uniform float size_variation : hint_range(0.0, 0.6) = 0.3;   // spread of big vs small stones
uniform float gap : hint_range(0.0, 0.25) = 0.06;            // transparent gap left between stones
// Low-frequency warp so patches of big and small stones cluster like the reference.
uniform float clump : hint_range(0.0, 1.0) = 0.25;
uniform float clump_scale : hint_range(0.1, 2.0) = 0.5;

// --- Color -------------------------------------------------------------------
uniform vec3 stone_color : source_color = vec3(0.56, 0.57, 0.58);  // one flat colour for every stone
uniform float value_variation : hint_range(0.0, 0.5) = 0.0;        // 0 = every stone identical; raise for subtle per-stone shade
uniform bool draw_outline = true;
uniform vec3 outline_color : source_color = vec3(0.10, 0.11, 0.10);
uniform float outline_width : hint_range(0.0, 0.15) = 0.05;        // thickness of the dark ring, in stone widths

// --- Edge culling ------------------------------------------------------------
// A stone is drawn only if its CENTRE is inside the path, so stones are never cut
// in half. By default the path area is the whole mesh, taken from its UVs, so no
// setup is needed. `path_inset` pulls that border in (in stone widths).
uniform bool cull_outside = true;
uniform float path_inset : hint_range(-4.0, 8.0) = 0.0;
uniform float edge_scatter : hint_range(0.0, 4.0) = 0.8;    // random drop-out near the border so it frays

varying vec3 world_pos;

// --- Noise helpers ------------------------------------------------------------
float hash1(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
	vec2 q = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(q) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash1(i);
	float b = hash1(i + vec2(1.0, 0.0));
	float c = hash1(i + vec2(0.0, 1.0));
	float d = hash1(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Voronoi: f1 = distance to nearest stone centre, f2 = to second nearest,
// cell = id of the nearest, center = the nearest feature point (in cell units).
void voronoi(vec2 x, out float f1, out float f2, out vec2 cell, out vec2 center) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	f1 = 8.0;
	f2 = 8.0;
	cell = n;
	center = n;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = mix(vec2(0.5), hash2(n + g), cell_jitter);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				cell = n + g;
				center = n + g + o;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	f1 = sqrt(f1);
	f2 = sqrt(f2);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Derivatives must be read before any discard, while the whole 2x2 quad is live.
	vec2 duv_x = dFdx(UV);
	vec2 duv_y = dFdy(UV);

	vec2 p = world_pos.xz;
	vec2 fp = p * pattern_scale;                       // cell units

	// Cluster big/small stones together with a low-frequency warp.
	fp += (vec2(vnoise(fp * clump_scale + 3.1), vnoise(fp * clump_scale + 8.6)) - 0.5) * clump;
	vec2 dw_x = dFdx(fp);
	vec2 dw_y = dFdy(fp);

	float f1, f2;
	vec2 cell, center;
	voronoi(fp, f1, f2, cell, center);

	float edge = f2 - f1;                              // distance to the cell border
	// Per-stone radius. Clamped so no cell collapses into a speck -- that collapse
	// is what produced the dark star-shaped artifacts.
	float R = max(0.42, stone_fill + (hash1(cell + 3.3) - 0.5) * 2.0 * size_variation);
	// Rounded pebble: the cell (minus the gap) intersected with a circle of radius
	// R. The circle rounds the cell's corners; a small R makes a small pebble.
	float d = min(edge - gap, R - f1);                 // >0 inside the stone
	float aa = fwidth(d) + 1e-5;

	// Everything outside the stone (and its outline) is transparent background.
	float outline = draw_outline ? outline_width : 0.0;
	if (d < -outline - aa) { discard; }

	// --- Cull whole stones that hang off the edge (centre-based, so never sliced).
	if (cull_outside) {
		mat2 w2s = mat2(dw_x, dw_y);
		float det = determinant(w2s);
		float inside = 1e6;
		if (abs(det) > 1e-9) {
			mat2 j = mat2(duv_x, duv_y) * inverse(w2s);
			vec2 muv = UV + j * (center - fp);         // UV at the stone's centre
			float su = length(vec2(j[0][0], j[1][0]));
			float sv = length(vec2(j[0][1], j[1][1]));
			float du = su > 1e-9 ? min(muv.x, 1.0 - muv.x) / su : 1e6;
			float dv = sv > 1e-9 ? min(muv.y, 1.0 - muv.y) / sv : 1e6;
			inside = min(du, dv) * pattern_scale;
		}
		inside -= path_inset;
		inside += (hash1(cell + 9.1) - 0.5) * 2.0 * edge_scatter;
		if (inside < 0.0) { discard; }
	}

	// Solid stone colour (optionally a touch of flat per-stone variation), with a
	// dark outline ring on the border. No gradients -> nothing to stripe.
	vec3 stone = stone_color * (1.0 + (hash1(cell + 5.3) - 0.5) * 2.0 * value_variation);
	vec3 col = mix(outline_color, stone, smoothstep(outline - aa, outline + aa, d));

	ALBEDO = col;
	ROUGHNESS = 1.0;
}
