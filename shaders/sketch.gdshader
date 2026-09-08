// Sketch line-art shader: draws a hand-drawn, squiggly outline around a mesh and
// leaves everything else see-through, so the scene shows through the shape.
//
// SETUP — this shader goes on the mesh TWICE, as a material and its Next Pass:
//   - outline_pass = true,  render_priority = -101   (the outline)
//   - outline_pass = false, render_priority = -100   (the eraser)
// The outline floods the shape with ink; the eraser then repaints the inside with
// whatever was behind the mesh, wiping that flood back to just the rim.
//
// THE PRIORITIES ARE NOT OPTIONAL. They are what forces the outline to be drawn
// before the eraser. Give both materials the same priority and the order is a
// coin toss that can differ between scenes — when the eraser loses, the mesh
// renders as a solid blob of ink. Which of the two you put in Next Pass does not
// matter; the priorities decide.
//
// Keeping both priorities low also makes sketched objects draw before other
// transparent geometry, which matters because the eraser repaints from a screen
// copy taken before the transparent pass: if a transparent object drew first, the
// eraser would wipe it out inside the silhouette.
//
// Nothing here writes depth, so semi-transparent things behind the mesh stay
// visible through it. The trade-off is that they are painted after the outline,
// so a transparent plane behind will tint the linework it overlaps.
//
// The outline is an inverted hull, so it works on flat-faced meshes (buildings,
// boxes) just as well as round ones — unlike curvature-based outlines, which only
// find edges where a surface bends away.
//
// The line is drawn like a pencil stroke: it wanders off the true silhouette
// (line_squiggle), its weight drifts along the stroke, it skips in places, and it
// presses harder where the form turns away from the light (line_shading).
//
// The squiggle is applied per-vertex, so how finely it waves depends on how dense
// the mesh is. A 24-vertex box gets a wonky-but-straight outline; a proper model
// waves properly. Subdivide if you want more wander out of simple shapes.
//
// Lighting is art-directed through light_direction (it does not read scene
// lights). To make it follow your sun instead, from a script on the mesh:
//     material.set_shader_parameter("light_direction", -$Sun.global_basis.z)
//
// Outline edges are geometry, so they alias without MSAA — 2x or 4x under
// Project Settings > Rendering > Anti Aliasing is worth turning on.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

const int MAX_CONTOUR_PASSES = 3;

// false = the eraser that repaints the inside (goes on the mesh itself).
// true  = the outline hull (goes in Next Pass).
uniform bool outline_pass = false;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

group_uniforms Line;
uniform vec3 line_color : source_color = vec3(0.08, 0.07, 0.10);
uniform float line_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float line_width : hint_range(0.0, 24.0) = 7.0;              // pixels, whatever the object size

group_uniforms Line.Hand;
uniform float line_squiggle : hint_range(0.0, 30.0) = 6.0;           // pixels the line wanders off the true edge
uniform float line_squiggle_scale : hint_range(0.1, 30.0) = 5.0;     // waves per metre of model
uniform float line_pressure : hint_range(0.0, 1.0) = 0.45;           // weight drift along the stroke
uniform float line_breakup : hint_range(0.0, 1.0) = 0.4;             // how much the stroke skips
uniform float line_breakup_scale : hint_range(0.001, 0.3) = 0.045;   // gap frequency, per pixel

group_uniforms Contours;
uniform float contour_edge : hint_range(0.0, 1.0) = 0.5;             // interior lines on round forms, 0 = silhouette only
uniform float contour_softness : hint_range(0.0, 6.0) = 1.2;
uniform int contour_passes : hint_range(1, 3) = 2;                   // times a contour is redrawn
uniform float contour_spread : hint_range(0.0, 8.0) = 1.2;           // pixels between repeated strokes
uniform float contour_wobble : hint_range(0.0, 12.0) = 1.6;          // pixels of waver off the true edge
uniform float contour_wobble_scale : hint_range(0.001, 0.2) = 0.02;  // waver frequency, per pixel

group_uniforms Shading;
uniform vec3 light_direction = vec3(-0.45, -1.0, -0.55);             // direction the light travels
uniform float line_shading : hint_range(0.0, 1.0) = 0.6;             // extra weight on the shadow side
uniform float light_wrap : hint_range(0.0, 1.0) = 0.25;              // softens the lit/shadow falloff

group_uniforms Animation;
uniform float boil_fps : hint_range(0.0, 24.0) = 0.0;                // 0 = still drawing, ~12 = hand-drawn "boil"

group_uniforms;

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Three octaves, remapped to roughly 0..1.
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * value_noise(p);
		p *= 2.07;
		a *= 0.5;
	}
	return v / 0.875;
}

// The low frame rate the linework is redrawn at, so it can boil like hand-drawn
// animation. Godot does not expose built-ins inside functions, hence the argument.
vec2 draw_seed(float time) {
	float frame = boil_fps > 0.0 ? floor(time * boil_fps) : 0.0;
	return vec2(frame * 3.71, frame * 11.13);
}

// Press harder where the form turns away from the light: this is what gives the
// outline its weight and lets it carry the volume on its own.
float shade_weight(vec3 view_normal, mat4 view_matrix) {
	vec3 l = normalize((view_matrix * vec4(-normalize(light_direction), 0.0)).xyz);
	float lit = clamp((dot(view_normal, l) + light_wrap) / (1.0 + light_wrap), 0.0, 1.0);
	return 1.0 + line_shading * (1.0 - lit) * 1.6;
}

// How far the line wanders off the true silhouette here, in -1..1. Keyed to model
// space so the wander sits on the object instead of swimming across it.
float squiggle(vec3 obj_pos, vec2 seed) {
	float n = value_noise(obj_pos.xy * line_squiggle_scale + seed) * 0.6
			+ value_noise(obj_pos.yz * line_squiggle_scale * 1.7 + seed + 19.0) * 0.4;
	return (n - 0.5) * 2.0;
}

// Where the pencil lifted off the paper.
float skip_gate(vec2 sp, vec2 seed) {
	return mix(1.0, smoothstep(0.12, 0.62, fbm(sp * line_breakup_scale + seed)), line_breakup);
}

void vertex() {
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * view_pos;

	vec3 view_n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 seed = draw_seed(TIME);

	// Both passes wander by the SAME amount, so the band between them keeps its
	// width and the whole line snakes in and out together.
	float push = line_squiggle * squiggle(VERTEX, seed);

	if (outline_pass) {
		// Weight drifts slowly over the surface so the line is not an even ribbon.
		float press = 1.0 - line_pressure * value_noise(VERTEX.xy * 2.7 + vec2(VERTEX.z * 1.9) + seed);
		push += line_width * shade_weight(view_n, VIEW_MATRIX) * press;
	}

	// Which way the surface faces once flattened onto the screen.
	vec2 n_px = (PROJECTION_MATRIX * vec4(view_n, 0.0)).xy * VIEWPORT_SIZE;
	n_px = length(n_px) > 1e-6 ? normalize(n_px) : vec2(0.0);

	// Offset in clip space; the clip.w factor survives the perspective divide, so
	// the outline stays the same pixel weight near or far, big mesh or small.
	clip.xy += n_px * (2.0 * push / VIEWPORT_SIZE) * clip.w;

	POSITION = clip;
}

void fragment() {
	// Derivatives first: they read neighbouring pixels, so they have to happen
	// before anything gets discarded below.
	vec3 n = normalize(NORMAL);
	float rim = 1.0 - abs(dot(n, normalize(VIEW)));
	float rim_px = (1.0 - rim) / (fwidth(rim) + 1e-4);   // pixels from where the surface turns away

	vec2 sp = FRAGCOORD.xy;
	vec2 seed = draw_seed(TIME);
	float weight = shade_weight(n, VIEW_MATRIX);

	// The hull keeps its back faces, which is what pokes out past the silhouette
	// and becomes the line. The eraser keeps the front faces.
	if (outline_pass == FRONT_FACING) {
		discard;
	}

	if (outline_pass) {
		ALBEDO = line_color;
		ALPHA = clamp(skip_gate(sp, seed), 0.0, 1.0) * line_opacity;
	} else {
		// Interior contours: soft lines where a round form turns away from us.
		// Flat faces have no curvature here, so they stay clean.
		float ink = 0.0;
		for (int i = 0; i < MAX_CONTOUR_PASSES; i++) {
			if (i >= contour_passes) {
				break;   // uniform for the whole draw, so the derivatives above stay valid
			}
			float fi = float(i);
			vec2 s = seed + vec2(fi * 37.0, fi * 61.0);

			float wob = (fbm(sp * contour_wobble_scale + s) - 0.5) * 2.0 * contour_wobble;
			float press = 1.0 - line_pressure * value_noise(sp * contour_wobble_scale * 0.6 + s * 1.3);
			float w = max(line_width * weight * press + fi * contour_spread + wob, 0.35);

			float cov = 1.0 - smoothstep(w, w + contour_softness, rim_px);
			ink = max(ink, cov * skip_gate(sp, s * 1.7));
		}
		ink = clamp(ink * contour_edge, 0.0, 1.0);

		// Repaint whatever was behind the mesh, erasing the hull's flood back to
		// just the rim. Contour lines go on top of that.
		vec3 behind = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
		ALBEDO = mix(behind, line_color, ink * line_opacity);
		ALPHA = 1.0;
	}
}
