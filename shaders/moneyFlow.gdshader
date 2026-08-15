shader_type particles;

// Money climbing out of the well and weaving its way up to the counter.
//
// Particle systems can't be pointed at a Control: the counter lives on a CanvasLayer
// and has no world position, and every GPUParticlesAttractor class in the engine is
// 3D-only. moneyFlow.gd bridges that — it takes the label's screen position, pushes it
// back out into the world with Camera3D.project_position(), and feeds the result in as
// `target` every frame, so the flow keeps tracking the counter as the camera moves.
//
// The path is a helix wound around the straight line from the well to the target.
// Every circle draws its own phase, radius, number of turns and winding DIRECTION out
// of its INDEX, so they thread through each other instead of flying in formation. The
// radius is pinched shut at both ends by a sine, so they leave the well in a tight
// bunch, bloom apart across the middle of the trip, and close back onto the counter.
//
// Requires local_coords = OFF on the GPUParticles3D, since `target` is a world point.
// Pairs with shaders/moneyCircle.gdshader on the draw pass.

render_mode disable_velocity;   // this shader drives TRANSFORM itself

uniform vec3 target = vec3(0.0);
uniform float spread = 0.6;      // how far across the well mouth they launch from
// rise and windRadius are FRACTIONS OF THE TRIP LENGTH, not world units. the counter
// sits a fixed distance in front of the camera, so the trip is short when the player is
// stood at the well and long when they're across the square — absolute sizes here spray
// the circles over a quarter of the screen in the first case.
uniform float rise = 0.18;       // upward lob, so they clear the rim instead of cutting through it
uniform float windRadius = 0.14; // how wide the helix opens at its middle
uniform float winds = 2.0;       // full turns around the travel axis over one trip
uniform float windVary = 0.6;    // per-circle variation in that turn count
uniform float arrive = 1.7;      // >1 eases IN: they hang about the well, then whip into the counter
// they start this far below the emitter, down inside the shaft, and rise to it before any
// lateral travel begins — otherwise they simply appear on the rim and leave
uniform float climb = 1.3;       // world units below the mouth that they rise from
uniform float climbTime = 0.3;   // fraction of life spent climbing out
uniform float sizeMin = 0.16;
uniform float sizeMax = 0.30;
uniform float endScale = 0.55;   // circles shrink as they close on the counter
uniform float fadeStart = 0.86;  // age at which they start fading out

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void start() {
	// scatter the launch points across the well mouth (sqrt keeps them even, not clumped
	// in the middle)
	float a = hash11(float(INDEX) * 1.7 + 0.13) * TAU;
	float r = sqrt(hash11(float(INDEX) * 3.1 + 0.71)) * spread;
	vec3 origin = EMISSION_TRANSFORM[3].xyz + vec3(cos(a) * r, 0.0, sin(a) * r);

	CUSTOM = vec4(origin, 0.0);   // xyz = launch point, w = age 0..1

	float s = mix(sizeMin, sizeMax, hash11(float(INDEX) * 11.1 + 0.29));
	TRANSFORM[0] = vec4(s, 0.0, 0.0, 0.0);
	TRANSFORM[1] = vec4(0.0, s, 0.0, 0.0);
	TRANSFORM[2] = vec4(0.0, 0.0, s, 0.0);
	TRANSFORM[3] = vec4(origin, 1.0);

	VELOCITY = vec3(0.0);
	COLOR = vec4(1.0);
}

void process() {
	CUSTOM.w = min(CUSTOM.w + DELTA / LIFETIME, 1.0);
	float t = CUSTOM.w;

	float sPhase = hash11(float(INDEX) * 1.7 + 0.13);
	float sTurns = hash11(float(INDEX) * 5.3 + 0.37);
	float sDir = hash11(float(INDEX) * 7.9 + 0.55);

	vec3 from = CUSTOM.xyz;
	vec3 line = target - from;
	float len = length(line);

	// two phases: rise out of the shaft, then fly. lateral progress is pinned at 0 until
	// they've cleared the mouth, so the climb reads as coming up from the bottom.
	float rising = clamp(t / climbTime, 0.0, 1.0);
	float travel = clamp((t - climbTime) / max(1.0 - climbTime, 0.001), 0.0, 1.0);

	// ease IN, so the weave plays out over the well where the circles are small and
	// readable, then they accelerate into the counter. easing OUT instead parks them on
	// the counter for the back half of the flight, which just looks like they spawned there.
	float e = pow(travel, arrive);

	vec3 straight = from + line * e;
	straight.y -= climb * (1.0 - smoothstep(0.0, 1.0, rising));
	straight.y += rise * len * sin(travel * PI) * (0.6 + sTurns * 0.8);

	// a frame perpendicular to the direction of travel to wind around
	vec3 dir = normalize(line);
	vec3 ref = abs(dir.y) > 0.99 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 side = normalize(cross(dir, ref));
	vec3 up = cross(side, dir);

	// own phase, own turn count, own direction — half of them coil the opposite way,
	// which is what actually makes the paths cross rather than run parallel
	float turns = winds * (1.0 + (sTurns - 0.5) * 2.0 * windVary);
	float spin = sDir < 0.5 ? -1.0 : 1.0;
	float ang = (t * turns * TAU + sPhase * TAU) * spin;
	float radius = windRadius * len * sin(travel * PI) * (0.45 + sTurns);

	TRANSFORM[3].xyz = straight + (side * cos(ang) + up * sin(ang)) * radius;

	// they end up close to the camera, so shrink them on the way in or they arrive as
	// dinner plates
	float s = mix(sizeMin, sizeMax, hash11(float(INDEX) * 11.1 + 0.29)) * mix(1.0, endScale, e);
	TRANSFORM[0] = vec4(s, 0.0, 0.0, 0.0);
	TRANSFORM[1] = vec4(0.0, s, 0.0, 0.0);
	TRANSFORM[2] = vec4(0.0, 0.0, s, 0.0);

	// fade in over the first breath too, so they well up out of the dark rather than pop in
	COLOR.a = smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(fadeStart, 1.0, t));
}
