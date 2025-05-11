// 11/05/25 :: render tampilan portal menyesuaikan ukuran layar
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D subviewport_tampilan : source_color;

void fragment() {
	vec2 base_uv = SCREEN_UV;
	vec4 albedo_tex = texture(subviewport_tampilan, base_uv);
	ALBEDO = albedo_tex.rgb;
}
