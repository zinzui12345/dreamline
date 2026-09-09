shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled; 

uniform vec3 grid_color : source_color = vec3(1.0, 0.0, 0.0);
uniform float grid_size = 2.0;
uniform float line_thickness = 0.02; 
uniform float fade_distance = 30.0; 
uniform float glow_intensity = 2.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// 1. Ambil arah permukaan (Normal) berdasarkan kordinat dunia nyata.
	// Kita gunakan 'abs' karena dinding bisa menghadap arah positif atau negatif.
	vec3 world_normal = abs((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// 2. Buat "Topeng" (Mask) untuk sumbu. 
	// Jika dinding menghadap sumbu X (normal.x mendekati 1.0), maka mask.x = 0.0
	// Ini akan mencegah sumbu X dieksekusi secara solid pada dinding yang sejajar dengannya.
	vec3 mask = 1.0 - step(0.9, world_normal);

	// Hitung posisi grid
	vec3 grid = fract(world_pos / grid_size);
	vec3 dist = abs(grid - 0.5);
	float line_w = 0.5 - (line_thickness / 2.0);
	
	// 3. Kalikan perhitungan garis dengan topeng (mask) permukaannya
	float line_x = step(line_w, dist.x) * mask.x;
	float line_y = step(line_w, dist.y) * mask.y;
	float line_z = step(line_w, dist.z) * mask.z;
	
	float is_line = clamp(line_x + line_y + line_z, 0.0, 1.0);

	// Efek kabut/fade
	float dist_to_cam = length(world_pos - CAMERA_POSITION_WORLD);
	float fade = 1.0 - smoothstep(0.0, fade_distance, dist_to_cam);

	ALBEDO = grid_color;
	EMISSION = grid_color * glow_intensity;
	ALPHA = is_line * fade;
}