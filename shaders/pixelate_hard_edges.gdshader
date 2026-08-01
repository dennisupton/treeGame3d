shader_type canvas_item;

// Screen-space pixelation like shaders/2Dpixel.gdshader, but instead of
// trusting a single sample per block (which can land on a renderer-
// antialiased edge pixel and bake a blended color into the block), it takes
// a small grid of samples across the block and outputs whichever color is
// most common -- never a blend/average of the two.
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;
uniform float match_tolerance : hint_range(0.0, 0.2) = 0.02; // how close 2 samples must be to count as "the same" color

const int GRID = 3; // samples per block edge (3 -> 3x3 = 9 samples)
const int SAMPLE_COUNT = GRID * GRID;

void fragment() {
	vec2 size = vec2(textureSize(screen_texture, 0));
	vec2 block_origin = floor(FRAGCOORD.xy / pixel_size) * pixel_size;

	vec3 samples[SAMPLE_COUNT];
	int idx = 0;
	for (int y = 0; y < GRID; y++) {
		for (int x = 0; x < GRID; x++) {
			// Spread samples evenly across the block (not clumped at the
			// center) so a thin sliver of the "other" color still gets a vote.
			vec2 offset = (vec2(float(x), float(y)) + 0.5) / float(GRID) * pixel_size;
			samples[idx] = texture(screen_texture, (block_origin + offset) / size).rgb;
			idx += 1;
		}
	}

	// Majority vote: whichever sampled color has the most near-matches in
	// the block wins outright. No mix()/average anywhere, so a block that
	// straddles two colors always resolves to one of them, not a blend.
	int best_index = 0;
	int best_score = 0;
	for (int i = 0; i < SAMPLE_COUNT; i++) {
		int score = 0;
		for (int j = 0; j < SAMPLE_COUNT; j++) {
			if (distance(samples[i], samples[j]) <= match_tolerance) {
				score += 1;
			}
		}
		if (score > best_score) {
			best_score = score;
			best_index = i;
		}
	}

	COLOR = vec4(samples[best_index], 1.0);
}
