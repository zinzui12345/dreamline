shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

group_uniforms Textures;
uniform sampler2D lamp_texture : source_color, filter_linear;
uniform sampler2D normal_map : hint_normal, filter_linear;

group_uniforms Glass;
uniform float glass_distort : hint_range(0.0, 1.0) = 0.5;

group_uniforms Projection;
uniform float parallax_depth : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float projection_scale_x : hint_range(1.0, 10.0, 0.1) = 1.0;
uniform float projection_scale_y : hint_range(1.0, 10.0, 0.1) = 1.1;
uniform float dimension_inherit : hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float projection_tiling : hint_range(0.0, 1.0, 1.0) = 0.0;
uniform vec2 mesh_dimensions = vec2(0.5, 2.0);

group_uniforms Emission;
uniform vec3 emission_color : source_color = vec3(1.0, 0.85, 0.55);
uniform float emission_strength : hint_range(0.0, 20.0) = 2.0;
uniform float emission_mask_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float emission_mask_softness : hint_range(0.001, 1.0) = 0.15;

group_uniforms Glass_Catch;
uniform float glass_catch_opacity : hint_range(0.0, 1.0) = 0.045;
uniform float glass_catch_blur : hint_range(0.0, 10.0) = 10.0;
uniform float glass_catch_scale : hint_range(0.5, 2.0) = 1.0;
uniform float glass_catch_glow_strength : hint_range(0.0, 10.0) = 0.0;

group_uniforms Pane;
uniform vec3 pane_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float pane_thickness : hint_range(0.0, 2.0, 0.001) = 0.05;
uniform float pane_corner_radius : hint_range(0.0, 2.0, 0.001) = 0.0;
uniform float pane_edge_softness : hint_range(0.0001, 0.05, 0.0001) = 0.0001;
uniform float pane_outer_bias : hint_range(0.0, 0.02, 0.0001) = 0.02;
uniform float pane_roughness : hint_range(0.0, 1.0) = 0.4;
uniform float pane_metallic : hint_range(0.0, 1.0) = 0.8;
uniform float pane_normal_flatten : hint_range(0.0, 1.0) = 1.0;

group_uniforms Pane_Noise;
uniform sampler2D pane_noise_texture : hint_default_white, filter_linear, repeat_enable;
uniform float pane_noise_scale : hint_range(0.1, 50.0) = 0.25;
uniform float pane_noise_roughness_strength : hint_range(0.0, 1.0) = 0.3;
uniform float pane_noise_normal_strength : hint_range(0.0, 1.0) = 1.0;
uniform float pane_noise_albedo_strength : hint_range(0.0, 0.5) = 0.05;

vec2 parallax(float depth, vec3 n, vec3 t, vec3 v) {
	vec3 normal = normalize(n);
	vec3 tangent = normalize(t);
	vec3 bitangent = cross(normal, tangent);
	vec3 view = normalize(v);
	vec3 view_tangent = vec3(dot(view, tangent), dot(view, bitangent), dot(view, normal));
	vec2 offset = (view_tangent.xy / max(view_tangent.z, 0.001)) * (depth / mesh_dimensions);
	offset = vec2(-offset.x, offset.y);
	return offset;
}

const float blur_weights[5] = float[](1.0, 4.0, 6.0, 4.0, 1.0);

vec3 gaussian_blur(sampler2D tex, vec2 uv, vec2 texel, float radius) {
	vec3 color = vec3(0.0);
	float total_weight = 0.0;
	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			float weight = blur_weights[x + 2] * blur_weights[y + 2];
			vec2 offset = vec2(float(x), float(y)) * texel * radius;
			color += texture(tex, clamp(uv + offset, 0.0, 1.0)).rgb * weight;
			total_weight += weight;
		}
	}
	return color / total_weight;
}

float rounded_box_sdf(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - (half_size - vec2(radius));
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

float pane_noise_height(vec2 uv) {
	return texture(pane_noise_texture, uv).r;
}

vec2 pane_noise_gradient(vec2 uv, vec2 texel) {
	float h_x1 = pane_noise_height(uv + vec2(texel.x, 0.0));
	float h_x0 = pane_noise_height(uv - vec2(texel.x, 0.0));
	float h_y1 = pane_noise_height(uv + vec2(0.0, texel.y));
	float h_y0 = pane_noise_height(uv - vec2(0.0, texel.y));
	return vec2(h_x1 - h_x0, h_y1 - h_y0);
}

void fragment() {
	vec2 half_size = mesh_dimensions * 0.5;
	float corner_radius = min(pane_corner_radius, min(half_size.x, half_size.y));
	vec2 world_pos = (UV - 0.5) * mesh_dimensions;

	float sdf_outer = rounded_box_sdf(world_pos, half_size, corner_radius) - pane_outer_bias;
	vec2 inner_half_size = max(half_size - vec2(pane_thickness), vec2(0.0));
	float inner_radius = max(corner_radius - pane_thickness, 0.0);
	float sdf_inner = rounded_box_sdf(world_pos, inner_half_size, inner_radius);

	float outer_mask = 1.0 - smoothstep(0.0, pane_edge_softness, sdf_outer);
	float inner_mask = smoothstep(0.0, pane_edge_softness, sdf_inner);
	float pane_mask = outer_mask * inner_mask;

	vec2 pane_noise_uv = world_pos * pane_noise_scale;
	vec2 pane_noise_texel = 1.0 / vec2(textureSize(pane_noise_texture, 0));
	float pane_noise_h = pane_noise_height(pane_noise_uv);
	vec2 pane_noise_grad = pane_noise_gradient(pane_noise_uv, pane_noise_texel);
	float pane_noise_signed = pane_noise_h * 2.0 - 1.0;

	NORMAL = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 nmpd = texture(normal_map, UV).rgb * 2.0 - 1.0;
	vec3 blended_normal = normalize(TANGENT * nmpd.x + BINORMAL * nmpd.y + NORMAL * nmpd.z);
	NORMAL = mix(NORMAL, blended_normal, glass_distort * (1.0 - pane_mask));

	vec3 pane_bump_local = normalize(vec3(pane_noise_grad * pane_noise_normal_strength, 1.0));
	vec3 pane_bump_normal = normalize(TANGENT * pane_bump_local.x + BINORMAL * pane_bump_local.y + NORMAL * pane_bump_local.z);
	NORMAL = normalize(mix(NORMAL, pane_bump_normal, pane_mask * pane_normal_flatten));

	NORMAL = normalize((VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	vec2 projection_scale = vec2(projection_scale_x, projection_scale_y);
	projection_scale = (projection_scale * dimension_inherit) + (projection_scale / mesh_dimensions) * (1.0 - dimension_inherit);

	vec2 parallax_uv = (UV - 0.5) / projection_scale + 0.5;
	parallax_uv += parallax(parallax_depth, NORMAL, TANGENT, VIEW) / projection_scale;
	parallax_uv = (clamp(parallax_uv, 0.0, 1.0) * (1.0 - projection_tiling)) + (parallax_uv * projection_tiling);

	vec3 lamp_color = texture(lamp_texture, parallax_uv).rgb;

	float luminance = dot(lamp_color, vec3(0.299, 0.587, 0.114));
	float emission_mask = smoothstep(emission_mask_threshold - emission_mask_softness, emission_mask_threshold + emission_mask_softness, luminance);

	vec2 catch_uv = (UV - 0.5) / (projection_scale * glass_catch_scale) + 0.5;
	catch_uv = clamp(catch_uv, 0.0, 1.0);
	vec2 texel = 1.0 / vec2(textureSize(lamp_texture, 0));
	vec3 glass_catch = gaussian_blur(lamp_texture, catch_uv, texel, glass_catch_blur);

	float catch_mask = 1.0 - emission_mask;
	vec3 final_albedo = mix(lamp_color, glass_catch, glass_catch_opacity * catch_mask);

	vec3 pane_color_varied = clamp(pane_color * (1.0 + pane_noise_signed * pane_noise_albedo_strength), 0.0, 1.0);
	float pane_roughness_varied = clamp(pane_roughness + pane_noise_signed * pane_noise_roughness_strength, 0.0, 1.0);

	ALBEDO = mix(final_albedo, pane_color_varied, pane_mask);
	ROUGHNESS = mix(0.04, pane_roughness_varied, pane_mask);
	METALLIC = mix(0.0, pane_metallic, pane_mask);

	vec3 emission_primary = emission_color * emission_strength * emission_mask;
	float catch_luminance = dot(glass_catch, vec3(0.299, 0.587, 0.114));
	vec3 emission_halo = emission_color * glass_catch_glow_strength * catch_luminance * catch_mask;

	EMISSION = (emission_primary + emission_halo) * (1.0 - pane_mask);
}