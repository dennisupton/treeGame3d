// Slices the top off a mesh: everything above cut_height stops being drawn, and
// nothing is drawn in its place. Back faces cull as usual, so the opening is a
// clean see-through hole rather than a view of the mesh's inside.
shader_type spatial;

uniform bool cut_in_world = false;                         // measure the model's own Y, or world Y
uniform float cut_height = 0.0;
render_mode cull_disabled;
group_uniforms Surface;
uniform vec3 albedo : source_color = vec3(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

group_uniforms;

varying float height;

void vertex() {
	height = cut_in_world ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).y : VERTEX.y;
}

void fragment() {
	if (height > cut_height) {
		discard;
	}
	ALBEDO = albedo * texture(albedo_texture, UV).rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
