// Particle-process shader: swirls each particle (leaf) into a tornado funnel.
// Assign this to a GPUParticles3D's "Process Material" (as a ShaderMaterial).
// The number of leaves = the GPUParticles3D "Amount" field.
shader_type particles;

// ---- tornado shape ----
uniform float radius = 1.5;          // circle radius at the TOP of the funnel
uniform float bottom_radius = 0.15;  // 0..1 : how pinched the base is (0 = point)
uniform float tornado_height = 3.0;  // vertical length of the column

// ---- motion ----
uniform float spin_speed = 2.0;      // how fast leaves orbit the center
uniform float rise_speed = 0.5;      // how fast they climb the column
uniform float tumble_speed = 4.0;    // how fast each leaf spins on its own axis
uniform float wobble = 0.15;         // radial jitter so it isn't a perfect ring

// ---- look ----
uniform float leaf_size = 0.25;      // size of each leaf

// Per-value hash (Dave Hoskins) -> stable random per leaf from its INDEX.
float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}
vec3 hash31(float p) {
	return vec3(hash11(p), hash11(p + 19.19), hash11(p + 43.21));
}

// Axis-angle rotation matrix.
mat3 rot_axis(vec3 a, float ang) {
	a = normalize(a);
	float c = cos(ang);
	float s = sin(ang);
	float t = 1.0 - c;
	return mat3(
		vec3(t*a.x*a.x + c,     t*a.x*a.y + s*a.z, t*a.x*a.z - s*a.y),
		vec3(t*a.x*a.y - s*a.z, t*a.y*a.y + c,     t*a.y*a.z + s*a.x),
		vec3(t*a.x*a.z + s*a.y, t*a.y*a.z - s*a.x, t*a.z*a.z + c)
	);
}

void start() {
	// Everything is computed analytically in process(), so nothing to seed here.
}

void process() {
	float id = float(INDEX);
	vec3 rnd = hash31(id + 1.0);

	float ang0    = rnd.x * 6.2831853;     // starting angle around the column
	float phase   = rnd.y;                 // starting height offset
	float spinVar = 0.6 + rnd.z * 0.8;     // per-leaf speed variance

	// Height loops 0..1 up the column, offset per leaf.
	float h = fract(phase + TIME * (rise_speed / max(tornado_height, 0.001)));
	float y = (h - 0.5) * tornado_height;  // center the column on the node

	// Funnel: narrow at the bottom, full radius at the top.
	float rad = radius * mix(bottom_radius, 1.0, h);
	rad += sin(TIME * 3.0 + id * 2.399) * wobble;

	// Orbit around the vertical axis.
	float ang = ang0 + TIME * spin_speed * spinVar;
	vec3 pos = vec3(cos(ang) * rad, y, sin(ang) * rad);

	// Tumble each leaf about a random axis.
	vec3 axis = normalize(hash31(id + 7.0) - 0.5);
	mat3 rot = rot_axis(axis, TIME * tumble_speed * spinVar + id);

	// Build this particle's transform: (rotation * scale), then translate.
	mat4 xform = mat4(
		vec4(rot[0] * leaf_size, 0.0),
		vec4(rot[1] * leaf_size, 0.0),
		vec4(rot[2] * leaf_size, 0.0),
		vec4(pos, 1.0)
	);
	TRANSFORM = EMISSION_TRANSFORM * xform;
	VELOCITY = vec3(0.0);

	// Slight per-leaf green tint variation, passed to the leaf material via COLOR.
	COLOR = vec4(mix(vec3(0.8, 0.9, 0.7), vec3(1.15, 1.2, 0.9), rnd.x), 1.0);
}
