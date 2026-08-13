shader_type spatial;

// The circles carried by shaders/moneyFlow.gdshader. Draws images/moneyParticle.png on
// a QuadMesh billboarded at the camera.
//
// Unshaded on purpose — these want to read the same against grass, cobbles and the dark
// inside of the well, rather than picking up scene lighting.

render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brightness : hint_range(0.2, 4.0) = 1.0;
uniform float alphaCut : hint_range(0.0, 0.5) = 0.01;

void vertex() {
	// billboard: swap the model-view basis for the camera's, keeping position and the
	// per-particle scale the process shader wrote into TRANSFORM
	float s = length(MODEL_MATRIX[0].xyz);
	mat4 mv = VIEW_MATRIX * MODEL_MATRIX;
	MODELVIEW_MATRIX = mat4(
		vec4(s, 0.0, 0.0, 0.0),
		vec4(0.0, s, 0.0, 0.0),
		vec4(0.0, 0.0, s, 0.0),
		mv[3]);
}

void fragment() {
	vec4 t = texture(tex, UV) * tint;

	// COLOR.a is the fade the process shader applies as they close on the counter
	float a = t.a * COLOR.a;
	if (a < alphaCut) {
		discard;
	}

	ALBEDO = t.rgb * brightness;
	ALPHA = a;
}
