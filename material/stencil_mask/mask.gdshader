shader_type spatial;
stencil_mode write, compare_always, 1;
uniform float visibility: hint_range(0.0, 1.0, 0.1);

void fragment() {
	ALPHA = visibility;
}