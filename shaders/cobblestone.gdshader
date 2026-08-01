// Procedural cobblestone / gravel path for FLAT ground (up = +Y). No textures.
// Voronoi scatters the stones; each stone is a rounded dome clipped by its cell,
// and the gaps between them are discarded so the ground underneath shows through.
// The pattern is driven by WORLD XZ position, so it tiles seamlessly across the
// ground no matter the mesh's UVs or scale. Assign to a PlaneMesh/ground surface.
//
// Stones whose CENTRE falls outside the path area are discarded whole, so the
// path ends on a ragged border of complete stones instead of sliced ones.
// See the EDGE CULLING notes near `path_half_size` for how to set it up.
// Gravel preset values are listed at the bottom.
shader_type spatial;

// --- Layout ------------------------------------------------------------------
// Sizes below are all relative to ONE STONE, so changing stone_scale rescales the
// whole look without having to retune anything.
uniform float stone_scale : hint_range(0.5, 40.0) = 4.0;      // stones per world unit (bigger = smaller stones)
uniform float stone_radius : hint_range(0.2, 0.8) = 0.5;      // dome radius; small = round pebbles, large = tightly packed cobbles
uniform float stone_height : hint_range(0.0, 1.0) = 0.45;     // dome rise, as a fraction of stone width
uniform float dome_power : hint_range(0.3, 3.0) = 1.0;        // 1.0 = true sphere, <1 puffier, >1 flatter with a rounder rim
uniform float stone_gap : hint_range(0.0, 0.3) = 0.06;        // space left between neighbouring stones
uniform float edge_round : hint_range(0.01, 0.4) = 0.14;      // rounds off the flat sides where two stones meet
uniform float irregularity : hint_range(0.0, 1.0) = 0.4;      // 0 = perfect circles, higher = lumpy organic outlines
uniform float irregularity_detail : hint_range(0.5, 6.0) = 2.0; // number of lumps around each stone
uniform float height_variation : hint_range(0.0, 1.0) = 0.2;  // per-stone up/down jitter (uneven cobbles)
uniform float cell_jitter : hint_range(0.0, 1.0) = 0.85;      // 0 = perfect grid, 1 = fully random stone centres

// --- Mortar ------------------------------------------------------------------
// Off by default: the gaps between stones are discarded, so whatever is under
// the path (terrain, dirt, grass) shows through and the stones sit on top of it.
// Turn on to fill the gaps with `mortar_color` instead, for a paved look.
uniform bool show_mortar = false;
uniform vec3 mortar_color : source_color = vec3(0.14, 0.12, 0.10);
uniform float mortar_depth : hint_range(0.0, 0.5) = 0.15;    // how far the mortar sits below the stones

// --- Edge culling -------------------------------------------------------------
// A stone is drawn only if its CENTRE is inside the path area, so stones are
// never cut in half -- they either sit there whole or vanish and show the ground
// underneath.
//
// By default the path area is the WHOLE MESH, worked out from its UVs, so this
// needs no setup and follows the mesh whatever its size or shape. The stones run
// right up to the mesh border and fray out there; use `path_inset` to pull that
// border inwards (in stone widths) if you want them to stop short.
//
// Set `path_from_uv = false` to define the area by hand instead, as a rectangle
// in the mesh's LOCAL space -- useful when the mesh's UVs are tiled or atlassed
// and so don't span 0..1 across the path.
uniform bool cull_outside = true;
uniform bool path_from_uv = true;               // true = use the mesh's own UV bounds
uniform float path_inset : hint_range(-4.0, 8.0) = 0.0;   // pull the border in, in stone widths
uniform vec2 path_half_size = vec2(5.0);        // half extents of the path, local units (path_from_uv = false)
uniform vec2 path_center = vec2(0.0);           // offset of the path area, local units (path_from_uv = false)
uniform float edge_scatter : hint_range(0.0, 4.0) = 0.8;  // stones near the border randomly drop out (in stone widths)
// Optional painted shape: white = path, black = no stones. Sampled in the mesh's
// UV space. Left empty it defaults to white and changes nothing.
uniform sampler2D path_mask : hint_default_white, filter_linear;

// --- Surface detail ----------------------------------------------------------
uniform float grain_scale : hint_range(1.0, 20.0) = 6.0;     // speckle frequency, in stones (6 = detail 1/6 of a stone)
uniform float grain_strength : hint_range(0.0, 0.3) = 0.05;  // fine bumpiness on the stones
uniform float normal_strength : hint_range(0.0, 3.0) = 1.0;  // overall bump intensity (1.0 = true to the height field)

// --- Color -------------------------------------------------------------------
uniform vec3 stone_color_a : source_color = vec3(0.48, 0.46, 0.44); // light grey stone
uniform vec3 stone_color_b : source_color = vec3(0.28, 0.27, 0.26); // dark grey stone
uniform float color_variation : hint_range(0.0, 1.0) = 0.35;        // brightness spread between stones
uniform float ao_strength : hint_range(0.0, 1.0) = 0.35;            // shading toward the base of each stone

uniform float stone_roughness : hint_range(0.0, 1.0) = 0.85;
uniform float mortar_roughness : hint_range(0.0, 1.0) = 1.0;

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

float fbm(vec2 p) {
	float s = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		s += amp * vnoise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return s;
}

// Voronoi: F1 = distance to the nearest stone centre, F2 = to the second nearest,
// cell = id of the nearest. (F2 - F1) is the distance to the border between two
// stones. `center` is the nearest feature point itself.
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
			vec2 o = mix(vec2(0.5), hash2(n + g), cell_jitter); // jitter each stone centre
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

// Height field at a world XZ point, in world units.
// `top` is the stone's dome profile: 1 at the peak, falling to 0 exactly at the
// silhouette, so `top <= 0` means "this fragment is in the gap, not on a stone".
float pattern(vec2 p, out float top, out vec2 cell, out vec2 center) {
	vec2 fp = p * stone_scale;                        // into cell units (1 = one stone spacing)

	// Domain warp: nudge the sample point by smooth noise before the Voronoi
	// lookup. Circular contours get pushed around into lumpy, non-circular stone
	// outlines, while the dome underneath stays smooth. `irregularity` is the
	// strength (in stone widths), `irregularity_detail` how many lumps per stone.
	vec2 w = vec2(fbm(fp * irregularity_detail + 19.3),
			fbm(fp * irregularity_detail + 47.1)) - 0.5;
	fp += w * irregularity;

	float f1, f2;
	voronoi(fp, f1, f2, cell, center);
	center /= stone_scale;                            // back into world XZ units

	// A true hemisphere around the stone's centre. Distance from the CENTRE (not
	// from the cell border) is what makes the contours circular, so the stone
	// actually reads as round instead of as a faceted polygon.
	float r = f1 / stone_radius;                      // 0 at the centre, 1 at the rim
	float dome = pow(sqrt(max(0.0, 1.0 - r * r)), dome_power);

	// Clip the dome against the Voronoi cell so neighbours never overlap: where
	// two stones crowd each other the sphere gets a flat side, rounded off by
	// `edge_round` so it still meets the ground smoothly.
	float cell_edge = (f2 - f1) - stone_gap;
	float taper = smoothstep(0.0, edge_round, cell_edge);

	top = dome * taper;

	float ch = hash1(cell);                           // per-stone random 0..1
	// Some stones sit higher/lower (faded out at the rim so domes still meet the ground).
	float h = top * (stone_height + (ch - 0.5) * height_variation);

	// Fine surface grain.
	h += (fbm(p * stone_scale * grain_scale) - 0.5) * grain_strength;

	// Sink the mortar below the stones (only matters when mortar is shown).
	if (show_mortar) {
		h -= (1.0 - taper) * mortar_depth;
	}

	// Everything above is in STONE widths -- convert to world units so the slopes
	// (and therefore the lighting) stay correct at any stone_scale.
	return h / stone_scale;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;

	// Screen-space derivatives have to be taken up here, BEFORE any discard,
	// while every lane in the 2x2 quad is still alive. They give us how UV
	// changes per world unit, which is what lets us ask "where in the mesh's UV
	// space does this stone's CENTRE sit?" further down.
	vec2 dw_x = dFdx(p);
	vec2 dw_y = dFdy(p);
	vec2 duv_x = dFdx(UV);
	vec2 duv_y = dFdy(UV);

	// Primary sample -- the normal below takes its own samples.
	float top;
	vec2 cell, center;
	pattern(p, top, cell, center);

	// --- Drop the gaps between stones -----------------------------------------
	// `top` hits 0 exactly where the dome meets the ground, so the silhouette
	// lands on the steepest part of the curve and stones look round, not sliced.
	if (!show_mortar && top <= 0.0) {
		discard;
	}

	// --- Cull stones that hang off the edge -----------------------------------
	// The test uses the stone's centre, not this fragment, so the whole stone is
	// kept or dropped together. Any mortar around it goes with it.
	if (cull_outside) {
		float inside;                                 // stone widths inside the path, <0 = outside
		vec2 mask_uv;

		if (path_from_uv) {
			// Rebuild the world -> UV mapping from the derivatives. It is affine
			// across a flat mesh, so extrapolating from this fragment to the
			// stone's centre is exact, not an approximation.
			mat2 world_to_screen = mat2(dw_x, dw_y);
			float det = determinant(world_to_screen);
			if (abs(det) < 1e-9) {
				inside = 1e6;                         // degenerate quad -- don't cull
				mask_uv = UV;
			} else {
				mat2 j = mat2(duv_x, duv_y) * inverse(world_to_screen);
				mask_uv = UV + j * (center - p);      // UV at the stone's centre
				// Rows of j are how fast u and v change per world unit, so they
				// convert a UV border distance back into world units.
				float su = length(vec2(j[0][0], j[1][0]));
				float sv = length(vec2(j[0][1], j[1][1]));
				float du = su > 1e-9 ? min(mask_uv.x, 1.0 - mask_uv.x) / su : 1e6;
				float dv = sv > 1e-9 ? min(mask_uv.y, 1.0 - mask_uv.y) / sv : 1e6;
				inside = min(du, dv) * stone_scale;
			}
		} else {
			// Hand-placed rectangle: stone centre from world into mesh local space.
			vec3 center_local = (inverse(MODEL_MATRIX) * vec4(center.x, world_pos.y, center.y, 1.0)).xyz;
			vec2 d = path_half_size - abs(center_local.xz - path_center);
			inside = min(d.x, d.y) * stone_scale;
			mask_uv = (center_local.xz - path_center) / (path_half_size * 2.0) + 0.5;
		}

		inside -= path_inset;
		inside = min(inside, (texture(path_mask, mask_uv).r - 0.5) * 20.0);
		// Randomly drop stones near the border so the path frays out instead of
		// ending on a straight line.
		inside += (hash1(cell + 9.1) - 0.5) * 2.0 * edge_scatter;
		if (inside < 0.0) {
			discard;
		}
	}

	// Surface normal from the height field, assuming the ground faces +Y.
	// (Central differences -> world-space normal -> view space. Independent of
	//  mesh tangents, so it works on any ground mesh.)
	float eps = 1.0 / (stone_scale * 48.0);
	float t_t;
	vec2 c_t, n_t;
	float hx1 = pattern(p - vec2(eps, 0.0), t_t, c_t, n_t);
	float hx2 = pattern(p + vec2(eps, 0.0), t_t, c_t, n_t);
	float hz1 = pattern(p - vec2(0.0, eps), t_t, c_t, n_t);
	float hz2 = pattern(p + vec2(0.0, eps), t_t, c_t, n_t);
	vec2 grad = vec2(hx2 - hx1, hz2 - hz1) / (2.0 * eps);
	vec3 n_world = normalize(vec3(-grad.x * normal_strength, 1.0, -grad.y * normal_strength));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	// Per-stone color: pick a tint on the a<->b range, then vary brightness.
	float tint = hash1(cell + 1.7);
	vec3 stone = mix(stone_color_a, stone_color_b, tint);
	stone *= 1.0 - color_variation * 0.5 + color_variation * hash1(cell + 5.3);
	stone *= 0.94 + 0.12 * fbm(p * stone_scale * grain_scale);   // speckle

	float mortar_mask = 1.0 - smoothstep(0.0, 0.15, top);        // 1 in the gaps
	vec3 col = show_mortar ? mix(stone, mortar_color, mortar_mask) : stone;

	// Contact shading where each stone meets the ground (and depth in the mortar).
	float shade = 1.0 - smoothstep(0.0, 0.5, top);
	col *= mix(1.0, 1.0 - ao_strength, shade);

	ALBEDO = col;
	ROUGHNESS = mix(stone_roughness, mortar_roughness, show_mortar ? mortar_mask : 0.0);
	SPECULAR = 0.3;
}

// --- GRAVEL PRESET -----------------------------------------------------------
// Same shader, just push it toward many small chaotic stones:
//   stone_scale      = 18.0     stone_radius     = 0.42   (rounder, looser pebbles)
//   stone_height     = 0.55     dome_power       = 0.8
//   stone_gap        = 0.1      edge_round       = 0.2
//   irregularity     = 0.6      irregularity_detail = 3.0  (chunky broken gravel)
//   height_variation = 0.6      cell_jitter      = 1.0
//   grain_scale      = 8.0      grain_strength   = 0.12
//   color_variation  = 0.6      edge_scatter     = 2.0  (frays out over a wider band)
//   stone_color_a    = warm tan (0.55, 0.5, 0.42), stone_color_b = brown (0.32, 0.27, 0.2)
