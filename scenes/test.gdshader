shader_type canvas_item;

// Screen-space pixelation, the canvas_item equivalent of shaders/pixel.gdshader.
// Applied to a full-screen ColorRect on a CanvasLayer it pixelates everything
// rendered behind it, with the same grid and block size as the 3D post-process.
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;

void fragment() {
	vec2 size = vec2(textureSize(screen_texture, 0));

	// Snap to the block center, same formula as the 3D shader:
	// center = floor(p / size) * size + floor(size / 2).
	vec2 snapped = floor(FRAGCOORD.xy / pixel_size) * pixel_size + floor(pixel_size / 2.0);

	COLOR = texture(screen_texture, snapped / size);
}
