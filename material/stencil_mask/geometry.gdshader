shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled;
stencil_mode read, compare_equal, 1;
uniform vec3 color:source_color;

void fragment() {
    ALBEDO = color;
	ALPHA = 1.0;
}