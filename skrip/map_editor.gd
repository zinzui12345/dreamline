# 21/08/26
extends Control

var _cek_ukuran_kanvas : Vector2
var jalur_file_desain : String

# TODO :
# Shortcut ubah ukuran grid (x^2) : [1, 2, 4, 8, 16, 32, 64, 128]
# fix skala desimal objek ketika mengatur skala setelah memperbesar ukuran grid
# Fungsikan tool Knife

# Seleksi dan transformasi
var objek_terpilih : Node3D = null :
	set(pilih_objek):
		if select_boundary != null:
			if pilih_objek != null:
				select_boundary.global_position = pilih_objek.global_position
				if pilih_objek.get("ukuran") != null:
					select_boundary.mesh.size = pilih_objek.ukuran + Vector3(0.001, 0.001, 0.001)
				select_boundary.visible = true
			elif pilih_objek == null:
				select_boundary.visible = false
		objek_terpilih = pilih_objek
var mode_transformasi : String = "gerak"  # gerak, putar, skala
var tool_aktif : String = "select" # select, face_select, knife
var viewport_aktif : SubViewportContainer
var viewport_fokus : bool = false
var jumlah_kisi_kisi : int = 4
var sedang_meni_transformasi : bool = false
var handle_yang_digunakan : Node3D = null
var axis_yang_digunakan : Vector3 = Vector3.ZERO
var posisi_kursor_di_dunia : Vector3 = Vector3.ZERO
var posisi_kursor_di_viewport : Vector2 = Vector2.ZERO
var nilai_transformasi : Vector2 = Vector2.ZERO
var indeks_face_terpilih : int = -1  # Indeks face yang dipilih (untuk mesh)

# Handles
var handles : Node3D
var handle_x : MeshInstance3D
var handle_y : MeshInstance3D
var handle_z : MeshInstance3D
var select_boundary : MeshInstance3D

# Warna handles
var warna_x = Color(1, 0, 0)
var warna_y = Color(0, 1, 0)
var warna_z = Color(0, 0, 1)

# Material selector
var material_terpilih : Material = null
var button_material : Button = null
var face_highlight_marker : MeshInstance3D = null
var posisi_face_terpilih : Vector3 = Vector3.ZERO

# Properti Bawaan Resource Material
const PROP_WARNA_MATERIAL = [
	"albedo_color", "backlight", "emission", "subsurf_scatter_transmittance_color"
]
const PROP_VEKTOR_MATERIAL = [
	"uv1_offset", "uv1_scale", "uv2_offset", "uv2_scale"
]
const PROP_TEKSTUR_MATERIAL = [
	"albedo_texture", "anisotropy_flowmap", "ao_texture", "backlight_texture", 
	"bent_normal_texture", "clearcoat_texture", "detail_albedo", "detail_mask", 
	"detail_normal", "emission_texture", "heightmap_texture", "metallic_texture", 
	"normal_texture", "orm_texture", "refraction_texture", "rim_texture", 
	"roughness_texture", "subsurf_scatter_texture", "subsurf_scatter_transmittance_texture"
]
const PROP_STANDAR_MATERIAL = [
	"albedo_texture_force_srgb", "albedo_texture_msdf", "alpha_antialiasing_edge", 
	"alpha_antialiasing_mode", "alpha_hash_scale", "alpha_scissor_threshold", "anisotropy", 
	"anisotropy_enabled", "ao_enabled", "ao_light_affect", "ao_on_uv2", "ao_texture_channel", 
	"backlight_enabled", "bent_normal_enabled", "billboard_keep_scale", "billboard_mode", 
	"blend_mode", "clearcoat", "clearcoat_enabled", "clearcoat_roughness", "cull_mode", 
	"depth_draw_mode", "detail_blend_mode", "detail_enabled", "detail_uv_layer", "diffuse_mode", 
	"disable_ambient_light", "disable_fog", "disable_receive_shadows", "disable_specular_occlusion", 
	"distance_fade_max_distance", "distance_fade_min_distance", "distance_fade_mode", 
	"emission_enabled", "emission_energy_multiplier", "emission_intensity", "emission_on_uv2", 
	"emission_operator", "fixed_size", "fov_override", "grow", "grow_amount", 
	"heightmap_deep_parallax", "heightmap_enabled", "heightmap_flip_binormal", "heightmap_flip_tangent", 
	"heightmap_flip_texture", "heightmap_max_layers", "heightmap_min_layers", "heightmap_scale", 
	"metallic", "metallic_specular", "metallic_texture_channel", "msdf_outline_size", 
	"msdf_pixel_range", "no_depth_test", "normal_enabled", "normal_scale", 
	"particles_anim_h_frames", "particles_anim_loop", "particles_anim_v_frames", "point_size", 
	"proximity_fade_distance", "proximity_fade_enabled", "refraction_enabled", "refraction_scale", 
	"refraction_texture_channel", "rim", "rim_enabled", "rim_tint", "roughness", 
	"roughness_texture_channel", "shading_mode", "shadow_to_opacity", "specular_mode", 
	"subsurf_scatter_enabled", "subsurf_scatter_skin_mode", "subsurf_scatter_strength", 
	"subsurf_scatter_transmittance_boost", "subsurf_scatter_transmittance_depth", 
	"subsurf_scatter_transmittance_enabled", "texture_filter", "texture_repeat", "transparency", 
	"use_fov_override", "use_particle_trails", "use_point_size", "use_z_clip_scale", 
	"uv1_triplanar", "uv1_triplanar_sharpness", "uv1_world_triplanar", "uv2_triplanar", 
	"uv2_triplanar_sharpness", "uv2_world_triplanar", "vertex_color_is_srgb", 
	"vertex_color_use_as_albedo", "z_clip_scale"
]

func _ready() -> void:
	# Buat node untuk handles
	handles = Node3D.new()
	handles.name = "handles"
	add_child(handles)
	
	# Buat handles (bola sederhana untuk masing-masing sumbu)
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radial_segments = 16
	sphere_mesh.radius = 0.08
	sphere_mesh.height = 0.16
	sphere_mesh.rings = 8
	
	# Buat fisik handles (agar bisa di raycast)
	var badan_handle = StaticBody3D.new()
	badan_handle.name = "badan_handle"
	var bentuk_tabrakan = CollisionShape3D.new()
	bentuk_tabrakan.name = "bentuk_tabrakan"
	var bulat = SphereShape3D.new()
	bulat.radius = 0.15
	bentuk_tabrakan.shape = bulat
	badan_handle.add_child(bentuk_tabrakan)
	badan_handle.set_collision_layer_value(1, false)
	badan_handle.set_collision_layer_value(6, true)
	
	handle_x = MeshInstance3D.new()
	handle_x.mesh = sphere_mesh
	handle_x.name = "handle_x"
	handle_x.material_override = StandardMaterial3D.new()
	handle_x.material_override.albedo_color = warna_x
	handle_x.material_override.no_depth_test = true
	handle_x.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	handle_x.add_to_group("handle_transformasi")
	handle_x.add_child(badan_handle)
	handle_x.set_layer_mask_value(1, false)
	handle_x.set_layer_mask_value(16, true)
	handles.add_child(handle_x)
	
	handle_y = MeshInstance3D.new()
	handle_y.mesh = sphere_mesh
	handle_y.name = "handle_y"
	handle_y.material_override = StandardMaterial3D.new()
	handle_y.material_override.albedo_color = warna_y
	handle_y.material_override.no_depth_test = true
	handle_y.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	handle_y.add_to_group("handle_transformasi")
	handle_y.add_child(badan_handle.duplicate())
	handle_y.set_layer_mask_value(1, false)
	handle_y.set_layer_mask_value(17, true)
	handles.add_child(handle_y)
	
	handle_z = MeshInstance3D.new()
	handle_z.mesh = sphere_mesh
	handle_z.name = "handle_z"
	handle_z.material_override = StandardMaterial3D.new()
	handle_z.material_override.albedo_color = warna_z
	handle_z.material_override.no_depth_test = true
	handle_z.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	handle_z.add_to_group("handle_transformasi")
	handle_z.add_child(badan_handle.duplicate())
	handle_z.set_layer_mask_value(1, false)
	handle_z.set_layer_mask_value(18, true)
	handles.add_child(handle_z)
	
	# Sembunyikan handles awalnya
	handles.visible = false
	
	# Buat marker highlight face
	face_highlight_marker = MeshInstance3D.new()
	face_highlight_marker.name = "face_highlight_marker"
	var highlight_box = PlaneMesh.new()
	highlight_box.size = Vector2(1, 1)
	face_highlight_marker.mesh = highlight_box
	var highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1, 1, 0, 0.7)
	highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	highlight_material.disable_receive_shadows = true
	face_highlight_marker.material_override = highlight_material
	face_highlight_marker.visible = false
	add_child(face_highlight_marker)
	
	# buat marker highlight objek
	select_boundary = MeshInstance3D.new()
	select_boundary.name = "object_highlight_marker"
	select_boundary.mesh = BoxMesh.new()
	select_boundary.material_override = highlight_material
	select_boundary.visible = false
	add_child(select_boundary)
	
	# Hubungkan tombol menu
	$tata_letak_vertikal/menu/HBoxContainer/buka_desain.connect("pressed", buka_desain)
	$tata_letak_vertikal/menu/HBoxContainer/simpan_desain.connect("pressed", simpan_desain)
	$tata_letak_vertikal/menu/HBoxContainer/perbesar_kisi.connect("pressed", _ketika_perbesar_ukuran_kisi)
	$tata_letak_vertikal/menu/HBoxContainer/perkecil_kisi.connect("pressed", _ketika_perkecil_ukuran_kisi)
	
	# Hubungkan tombol alat
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/select_tool_button.connect("pressed", self._on_select_tool_pressed)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/move_selected_button.connect("pressed", self._pilih_mode_transformasi_gerak)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/scale_selected_button.connect("pressed", self._pilih_mode_transformasi_skala)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/face_select_tool_button.connect("pressed", self._on_face_select_tool_pressed)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/knife_tool_button.connect("pressed", self._on_knife_tool_pressed)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/material_tool_button.connect("pressed", self._terapkan_material_terpilih)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/material_picker_button.connect("pressed", self._ambil_material_terpilih)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/add_cube_button.connect("pressed", self._ketika_menambah_kubus)
	
	# Sesuaikan posisi batas raycast
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/grid_depan.position.z = -9000.0
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/grid_atas.position.y = -9000.0
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/grid_kanan.position.x = -9000.0

func _ketika_ukuran_tampilan_diubah() -> void:
	$tata_letak_vertikal/tata_letak/kanvas.split_offset = $tata_letak_vertikal/tata_letak/kanvas.size.x / 2
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a.split_offset = $tata_letak_vertikal/tata_letak/kanvas.size.y / 2
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b.split_offset = $tata_letak_vertikal/tata_letak/kanvas.size.y / 2
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport2/CanvasLayer/grid_atas.material.set_shader_parameter("resolution", $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas.size)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport2/CanvasLayer/grid_depan.material.set_shader_parameter("resolution", $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan.size)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport2/CanvasLayer/grid_kanan.material.set_shader_parameter("resolution", $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan.size)
	_cek_ukuran_kanvas = $tata_letak_vertikal/tata_letak/kanvas.size

func _ketika_viewport_ditransformasi() -> void:
	var zoom_atas : float = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat.size
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat.position.y = zoom_atas
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport2/CanvasLayer/grid_atas.material.set_shader_parameter("transform", Vector2($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus.global_position.x / zoom_atas, $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus.global_position.z / zoom_atas))
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport2/CanvasLayer/grid_atas.material.set_shader_parameter("zoom", jumlah_kisi_kisi * $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat.position.y)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/CanvasLayer/nilai_zoom.text = str(zoom_atas / 2)
	
	var zoom_depan : float = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat.size
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat.position.z = zoom_depan
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport2/CanvasLayer/grid_depan.material.set_shader_parameter("transform", Vector2($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus.global_position.x / zoom_depan, -($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus.global_position.y / zoom_depan)))
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport2/CanvasLayer/grid_depan.material.set_shader_parameter("zoom", jumlah_kisi_kisi * $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat.position.z)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/CanvasLayer/nilai_zoom.text = str(zoom_depan / 2)
	
	var zoom_kanan : float = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat.size
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat.position.x = zoom_kanan
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport2/CanvasLayer/grid_kanan.material.set_shader_parameter("transform", Vector2(-($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus.global_position.z / zoom_kanan), -($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus.global_position.y / zoom_kanan)))
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport2/CanvasLayer/grid_kanan.material.set_shader_parameter("zoom", jumlah_kisi_kisi * $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat.position.x)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/CanvasLayer/nilai_zoom.text = str(zoom_kanan / 2)

func _input(event: InputEvent) -> void:
	# Sinkronisasi kamera
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		atur_posisi_fokus_viewport($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat/titik_fokus.global_position)
		_ketika_viewport_ditransformasi()

	# Handle pemilihan objek dan transformasi
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if tool_aktif == "select" or tool_aktif == "face_select":
				var objek_yang_diketahui = _deteksi_objek_dari_klik(event.position)
				if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d:
					if objek_yang_diketahui:
						if objek_terpilih != null:
							objek_terpilih.tampilkan_di_viewport(false)
						if tool_aktif == "select" and objek_terpilih != objek_yang_diketahui:
							atur_posisi_fokus_viewport(objek_yang_diketahui.global_position)
							_ketika_viewport_ditransformasi()
						objek_terpilih = objek_yang_diketahui
						objek_terpilih.tampilkan_di_viewport(true)
						if tool_aktif == "select":
							# Indeks face sudah diatur di _pilih_objek_dari_viewport jika tool_aktif == "face_select"
							indeks_face_terpilih = -1 # Reset face selection saat tool select
						_perbarui_handles()
						handles.visible = true
						_highlight_face_seleksi()
					elif _cek_viewport_dari_klik(event.position):
						_clear_face_highlight()
						_clear_selection()
			elif tool_aktif == "knife":
				# TODO: Logika untuk knife tool (misalnya memulai gambar garis)
				print("Knife tool diklik.")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cek_viewport_dari_klik(event.position)

	# Handle drag untuk transformasi
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and sedang_meni_transformasi:
			sedang_meni_transformasi = false
			handle_yang_digunakan = null
			nilai_transformasi = Vector2.ZERO
			axis_yang_digunakan = Vector3.ZERO
			posisi_kursor_di_dunia = Vector3.ZERO
			posisi_kursor_di_viewport = Vector2.ZERO
	
	# auto-fokus viewport
	if event is InputEventMouseMotion and not viewport_fokus and not sedang_meni_transformasi:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			_cek_viewport_dari_klik(event.position)
	
	# Handle tombol pintasan
	if Input.is_action_just_pressed("daftar_pemain"):
		if not viewport_fokus:
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d.visible = false
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan.visible = false
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas.visible = false
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan.visible = false
			if viewport_aktif.name == "tampilan_3d" or viewport_aktif.name == "tampilan_depan":
				$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b.visible = false
			elif viewport_aktif.name == "tampilan_atas" or viewport_aktif.name == "tampilan_kanan":
				$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a.visible = false
			viewport_aktif.visible = true
			viewport_fokus = true
		else:
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a.visible = true
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b.visible = true
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d.visible = true
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan.visible = true
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas.visible = true
			$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan.visible = true
			viewport_fokus = false
		_ketika_ukuran_tampilan_diubah()

func _deteksi_objek_dari_klik(posisi_layar: Vector2) -> Node3D:
	# Periksa setiap viewport untuk melihat klik terjadi di mana
	var viewports = [
		{ "nama": "tampilan_3d", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat, "is_3d": true },
		{ "nama": "tampilan_depan", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat, "is_3d": false },
		{ "nama": "tampilan_atas", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat, "is_3d": false },
		{ "nama": "tampilan_kanan", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat, "is_3d": false }
	]
	
	for viewport in viewports:
		var container = viewport["node"]
		var kamera = viewport["kamera"]
		# Periksa apakah klik berada dalam area viewport
		var rect = container.get_global_rect()
		if rect.has_point(posisi_layar) and container.visible:
			# Konversi posisi layar global ke posisi relatif viewport
			var posisi_relatif = posisi_layar - container.get_global_position()
			var objek_ = _pilih_objek_dari_viewport(kamera, posisi_relatif)
			if viewport_aktif != null:
				if viewport_aktif.name == "tampilan_3d":
					viewport_aktif.get_node("SubViewport/pengamat").process_mode = Node.PROCESS_MODE_DISABLED
				elif viewport_aktif.get_node("SubViewport/titik_fokus/pengamat").get("fungsikan") != null:
					viewport_aktif.get_node("SubViewport/titik_fokus/pengamat").set("fungsikan", false)
			if not viewport["is_3d"] and container.get_node("SubViewport/titik_fokus/pengamat").get("fungsikan") != null:
				container.get_node("SubViewport/titik_fokus/pengamat").set("fungsikan", true)
			elif viewport["is_3d"]:
				container.get_node("SubViewport/pengamat").process_mode = Node.PROCESS_MODE_ALWAYS
			viewport_aktif = container
			if objek_:
				return objek_
	return null

func _cek_viewport_dari_klik(posisi_layar: Vector2) -> bool:
	# Periksa setiap viewport untuk melihat klik terjadi di mana
	var viewports = [
		{ "nama": "tampilan_3d", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat, "is_3d": true },
		{ "nama": "tampilan_depan", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat, "is_3d": false },
		{ "nama": "tampilan_atas", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat, "is_3d": false },
		{ "nama": "tampilan_kanan", "node": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan, "kamera": $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat, "is_3d": false }
	]
	
	for viewport in viewports:
		var container = viewport["node"]
		var rect = container.get_global_rect()
		if rect.has_point(posisi_layar) and container.visible:
			if viewport_aktif != null:
				if viewport_aktif.name == "tampilan_3d":
					viewport_aktif.get_node("SubViewport/pengamat").process_mode = Node.PROCESS_MODE_DISABLED
				elif viewport_aktif.get_node("SubViewport/titik_fokus/pengamat").get("fungsikan") != null:
					viewport_aktif.get_node("SubViewport/titik_fokus/pengamat").set("fungsikan", false)
			if not viewport["is_3d"] and container.get_node("SubViewport/titik_fokus/pengamat").get("fungsikan") != null:
				container.get_node("SubViewport/titik_fokus/pengamat").set("fungsikan", true)
			elif viewport["is_3d"]:
				container.get_node("SubViewport/pengamat").process_mode = Node.PROCESS_MODE_ALWAYS
			viewport_aktif = container
			return true
	return false

func _pilih_objek_dari_viewport(kamera: Camera3D, posisi_viewport: Vector2) -> Node3D:
	# Gunakan world dari kamera (SubViewport), bukan world dari viewport utama
	var physics_state = kamera.get_world_3d().direct_space_state
	var dari = kamera.project_ray_origin(posisi_viewport)
	var arah = kamera.project_ray_normal(posisi_viewport)
	var deteksi : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(dari, dari + arah * 10000)
	if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d:
		# benda_statis(1)
		deteksi.set_collision_mask(0b00000000_00000000_00000000_00000001)
	else:
		# hanya_raycast(6)
		deteksi.set_collision_mask(0b00000000_00000000_00000000_00100000)
	var hasil = physics_state.intersect_ray(deteksi)
	if hasil:
		var objek_ = hasil["collider"] as Node3D
		# Jika collider adalah StaticBody3D, ambil parentnya (MeshInstance3D)
		if objek_ is StaticBody3D:
			objek_ = objek_.get_parent()
		# Periksa apakah objek dapat dipilih (ada grup "seleksi_aktif")
		if objek_:
			if objek_.is_in_group("seleksi_aktif"):
				return objek_
			if objek_.is_in_group("wajah") and tool_aktif == "face_select" and objek_.get("indeks_wajah") != null:
				indeks_face_terpilih = _dapatkan_indeks_face(objek_, hasil)
				#Panku.notify(objek_.objek_bentuk.name + " : " + objek_.name + " -> " + str(indeks_face_terpilih))
				return objek_.objek_bentuk
			elif objek_.is_in_group("handle_transformasi"):
				if objek_ == handle_x:
					axis_yang_digunakan = Vector3(1, 0, 0)
				elif objek_ == handle_y:
					axis_yang_digunakan = Vector3(0, 1, 0)
				elif objek_ == handle_z:
					axis_yang_digunakan = Vector3(0, 0, 1)
				sedang_meni_transformasi = true
				handle_yang_digunakan = objek_
				return objek_terpilih
			else:
				if tool_aktif == "face_select":
					indeks_face_terpilih = -1
				print_debug(objek_.name)
	indeks_face_terpilih = -1
	return null

func _pilih_posisi_viewport(kamera: Camera3D, posisi_viewport: Vector2) -> Vector3:
	# Gunakan world dari kamera (SubViewport), bukan world dari viewport utama
	var physics_state = kamera.get_world_3d().direct_space_state
	var dari = kamera.project_ray_origin(posisi_viewport)
	var arah = kamera.project_ray_normal(posisi_viewport)
	var hasil = physics_state.intersect_ray(PhysicsRayQueryParameters3D.create(dari, dari + arah * 10000))
	if hasil:
		return hasil["position"]
	else:
		return Vector3.ZERO

func _dapatkan_indeks_face(objek_: Node3D, _hasil: Dictionary) -> int:
	if objek_.get("indeks_wajah") != null:
		return objek_.indeks_wajah
	return -1

func _perbarui_handles() -> void:
	if objek_terpilih:
		var offset : Vector3
		if objek_terpilih.tipe_bentuk == 0:
			offset = (objek_terpilih.ukuran / 2) + Vector3(0.10, 0.10, 0.10)
		handles.global_transform.origin = objek_terpilih.global_transform.origin
		# Tampilkan hanya handles yang sesuai dengan mode
		handle_x.visible = (mode_transformasi == "gerak" or mode_transformasi == "skala")
		handle_y.visible = (mode_transformasi == "gerak" or mode_transformasi == "skala")
		handle_z.visible = (mode_transformasi == "gerak" or mode_transformasi == "skala")
		# Sesuaikan posisi handle
		handle_x.position.x = offset.x
		handle_y.position.y = offset.y
		handle_z.position.z = offset.z
		# Untuk mode putar, kita akan menambahkan handles khusus nanti
		# Untuk saat ini, kita tampilkan semua handles dalam mode gerak
	else:
		handles.visible = false

func _mode_berikutnya(mode: String) -> String:
	if mode == "gerak":
		return "putar"
	elif mode == "putar":
		return "skala"
	else:
		return "gerak"

func _mode_sebelumnya(mode: String) -> String:
	if mode == "gerak":
		return "skala"
	elif mode == "putar":
		return "gerak"
	else:
		return "putar"

func _pilih_mode_transformasi_gerak() -> void:
	tool_aktif = "select"
	mode_transformasi = "gerak"
	_perbarui_tampilan_alat_aktif()
	print("Mode Transformasi: Posisi")
	
func _pilih_mode_transformasi_skala() -> void:
	tool_aktif = "select"
	mode_transformasi = "skala"
	_perbarui_tampilan_alat_aktif()
	print("Mode Transformasi: Skala")

func _ketika_memilih_material() -> void:
	$dialog_buka_file.title = "Pilih Material"
	$dialog_buka_file.filters = ["*.material", "*.tres"]
	$dialog_buka_file.access = FileDialog.ACCESS_FILESYSTEM
	$dialog_buka_file.current_dir = "material"
	$dialog_buka_file.connect("file_selected", self._ketika_memilih_file_material)
	$dialog_buka_file.show()

func _ketika_memilih_file_material(file_path: String) -> void:
	var material_ = load(file_path) as Material
	if material_ == null:
		material_ = load(file_path) as StandardMaterial3D
	if material_ == null:
		material_ = load(file_path) as ShaderMaterial
	if material_:
		material_terpilih = material_
		$tata_letak_vertikal/tata_letak/inspektur/VSplitContainer/tampilan_material/SubViewport/placeholder_mesh.material_override = material_terpilih
		_terapkan_material_terpilih()

func _highlight_face_seleksi() -> void:
	# Tampilkan marker highlight ketika face terpilih
	if indeks_face_terpilih >= 0 and objek_terpilih:
		face_highlight_marker.visible = true
		var wajah_yang_dipilih = objek_terpilih.dapatkan_wajah(indeks_face_terpilih)
		if wajah_yang_dipilih != null and wajah_yang_dipilih.get("indeks_wajah") != null:
			face_highlight_marker.global_transform.origin = wajah_yang_dipilih.global_transform.origin
			face_highlight_marker.global_rotation = wajah_yang_dipilih.global_rotation
			face_highlight_marker.mesh.size = wajah_yang_dipilih.mesh.size
			face_highlight_marker.mesh.orientation = wajah_yang_dipilih.mesh.orientation
			face_highlight_marker.mesh.flip_faces = wajah_yang_dipilih.mesh.flip_faces
		#print("Face terpilih: ", indeks_face_terpilih)
		select_boundary.visible = false
	else:
		_clear_face_highlight()

func _clear_face_highlight() -> void:
	face_highlight_marker.visible = false
	indeks_face_terpilih = -1
	if objek_terpilih != null:
		select_boundary.visible = true

func _process(_delta: float) -> void:
	if _cek_ukuran_kanvas != $tata_letak_vertikal/tata_letak/kanvas.size:
		_ketika_ukuran_tampilan_diubah()
		
	# Update posisi handles jika objek bergerak
	if objek_terpilih and handles.visible:
		handles.global_transform.origin = objek_terpilih.global_transform.origin

func _physics_process(_delta: float) -> void:
	if not objek_terpilih:
		return
	
	var kamera = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat
	
	# Dapatkan kamera dari viewport aktif jika berbeda
	if viewport_aktif != null and viewport_aktif != kamera.get_parent().get_parent():
		kamera = viewport_aktif.get_node("SubViewport/titik_fokus/pengamat")
	
	# Hitung arah kamera di dunia
	var kanan = kamera.global_transform.basis.x  # Arah kanan kamera
	var atas = kamera.global_transform.basis.y  # Arah atas kamera
	posisi_kursor_di_dunia = _pilih_posisi_viewport(kamera, posisi_kursor_di_viewport)
	
	# Terapkan gerak ke objek
	if (mode_transformasi == "gerak" or mode_transformasi == "skala") and sedang_meni_transformasi:
		if posisi_kursor_di_viewport != Vector2.ZERO and posisi_kursor_di_dunia != Vector3.ZERO:
			var gerak_dunia = objek_terpilih.global_position
			var posisi_baru : Vector3
			var interval_snap : float = 1.0 / jumlah_kisi_kisi
			
			if axis_yang_digunakan == Vector3(1, 0, 0):  # Sumbu X
				if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas or viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan:
					gerak_dunia = kanan * (posisi_kursor_di_dunia.x - handle_x.position.x)
					posisi_baru.x = snappedf(gerak_dunia.x, interval_snap)
					if mode_transformasi == "gerak":
						if fmod(objek_terpilih.ukuran.x / interval_snap, 2.0) == 0.0:
							objek_terpilih.global_position.x = posisi_baru.x
						else:
							var pos_target : float = snappedf(posisi_baru.x - (objek_terpilih.ukuran.x / 2), interval_snap)
							objek_terpilih.global_position.x = pos_target + (objek_terpilih.ukuran.x / 2)
						$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus.global_position = objek_terpilih.global_position
					elif mode_transformasi == "skala":
						var start_point  : float = objek_terpilih.global_position.x - (objek_terpilih.ukuran.x / 2)
						var end_point  : float = objek_terpilih.global_position.x + (objek_terpilih.ukuran.x / 2)
						var offset  : float = snappedf(posisi_baru.x - objek_terpilih.global_position.x, interval_snap)
						var skala_target  : float = snappedf((end_point + offset) - start_point, interval_snap)
						var pos_target  : float = objek_terpilih.global_position.x + (offset / 2)
						if skala_target > (interval_snap / 2):
							await RenderingServer.frame_post_draw
							objek_terpilih.ukuran.x = skala_target
							objek_terpilih.global_position.x = pos_target
							_perbarui_handles()
			elif axis_yang_digunakan == Vector3(0, 1, 0):  # Sumbu Y
				if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan or viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan:
					gerak_dunia = atas * (posisi_kursor_di_dunia.y - handle_y.position.y)
					posisi_baru.y = snappedf(gerak_dunia.y, interval_snap)
					if mode_transformasi == "gerak":
						if fmod(objek_terpilih.ukuran.y / interval_snap, 2.0) == 0.0:
							objek_terpilih.global_position.y = posisi_baru.y
						else:
							var pos_target : float = snappedf(posisi_baru.y - (objek_terpilih.ukuran.y / 2), interval_snap)
							objek_terpilih.global_position.y = pos_target + (objek_terpilih.ukuran.y / 2)
						$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus.global_position = objek_terpilih.global_position
					elif mode_transformasi == "skala":
						var start_point  : float = objek_terpilih.global_position.y - (objek_terpilih.ukuran.y / 2)
						var end_point  : float = objek_terpilih.global_position.y + (objek_terpilih.ukuran.y / 2)
						var offset  : float = snappedf(posisi_baru.y - objek_terpilih.global_position.y, interval_snap)
						var skala_target  : float = snappedf((end_point + offset) - start_point, interval_snap)
						var pos_target  : float = objek_terpilih.global_position.y + (offset / 2)
						if skala_target > (interval_snap / 2):
							await RenderingServer.frame_post_draw
							objek_terpilih.ukuran.y = skala_target
							objek_terpilih.global_position.y = pos_target
							_perbarui_handles()
			elif axis_yang_digunakan == Vector3(0, 0, 1):  # Sumbu Z
				if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas:
					gerak_dunia = atas * -(posisi_kursor_di_dunia.z - handle_z.position.z)
					posisi_baru.z = snappedf(gerak_dunia.z, interval_snap)
				elif viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan:
					gerak_dunia = kanan * -(posisi_kursor_di_dunia.z - handle_z.position.z)
					posisi_baru.z = snappedf(gerak_dunia.z, interval_snap)
				if mode_transformasi == "gerak":
					if fmod(objek_terpilih.ukuran.z / interval_snap, 2.0) == 0.0:
						objek_terpilih.global_position.z = posisi_baru.z
					else:
						var pos_target : float = snappedf(posisi_baru.z - (objek_terpilih.ukuran.z / 2), interval_snap)
						objek_terpilih.global_position.z = pos_target + (objek_terpilih.ukuran.z / 2)
					$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus.global_position = objek_terpilih.global_position
				elif mode_transformasi == "skala":
					var start_point  : float = objek_terpilih.global_position.z - (objek_terpilih.ukuran.z / 2)
					var end_point  : float = objek_terpilih.global_position.z + (objek_terpilih.ukuran.z / 2)
					var offset  : float = snappedf(posisi_baru.z - objek_terpilih.global_position.z, interval_snap)
					var skala_target  : float = snappedf((end_point + offset) - start_point, interval_snap)
					var pos_target  : float = objek_terpilih.global_position.z + (offset / 2)
					if skala_target > (interval_snap / 2):
						await RenderingServer.frame_post_draw
						objek_terpilih.ukuran.z = skala_target
						objek_terpilih.global_position.z = pos_target
						_perbarui_handles()
			
			if select_boundary != null:
				select_boundary.global_position = objek_terpilih.global_position
				if objek_terpilih.get("ukuran") != null:
					select_boundary.mesh.size = objek_terpilih.ukuran + Vector3(0.001, 0.001, 0.001)
			
			posisi_kursor_di_viewport = Vector2.ZERO
			posisi_kursor_di_dunia = Vector3.ZERO

func _ketika_perbesar_ukuran_kisi() -> void:
	"""
		2 : 50 cm
		4 : 25 cm
	"""
	if jumlah_kisi_kisi > 2:
		jumlah_kisi_kisi = jumlah_kisi_kisi * 0.5
	$tata_letak_vertikal/menu/HBoxContainer/nilai_ukuran_kisi.text = str((1.0 / float(jumlah_kisi_kisi) * 100)) + " cm"
func _ketika_perkecil_ukuran_kisi() -> void:
	if jumlah_kisi_kisi < 32:
		jumlah_kisi_kisi = jumlah_kisi_kisi * 2
	$tata_letak_vertikal/menu/HBoxContainer/nilai_ukuran_kisi.text = str((1.0 / float(jumlah_kisi_kisi) * 100)) + " cm"

func _on_select_tool_pressed() -> void:
	tool_aktif = "select"
	mode_transformasi = "gerak" # Mode default untuk select tool (bisa translasi, rotasi, skala)
	_perbarui_tampilan_alat_aktif()
	_clear_selection() # Bersihkan pemilihan saat ganti alat
	_terapkan_mode_pemilihan_objek()
	print("Alat: Select")

func _on_face_select_tool_pressed() -> void:
	tool_aktif = "face_select"
	_perbarui_tampilan_alat_aktif()
	_clear_selection() # Bersihkan pemilihan saat ganti alat
	_terapkan_mode_pemilihan_objek(true)
	print("Alat: Face Select")

func _on_knife_tool_pressed() -> void:
	tool_aktif = "knife"
	_perbarui_tampilan_alat_aktif()
	_clear_selection() # Bersihkan pemilihan saat ganti alat
	print("Alat: Knife")

func _terapkan_material_terpilih() -> void:
	if indeks_face_terpilih > -1:
		var wajah_yang_dipilih = objek_terpilih.dapatkan_wajah(indeks_face_terpilih)
		if objek_terpilih is MeshInstance3D:
			objek_terpilih.material_override = material_terpilih
		elif wajah_yang_dipilih != null and wajah_yang_dipilih.get("indeks_wajah") != null:
			wajah_yang_dipilih.atur_material(material_terpilih)
			wajah_yang_dipilih.objek_bentuk.ukuran = wajah_yang_dipilih.objek_bentuk.ukuran
	print("Alat: Material Apply")

func _ambil_material_terpilih() -> void:
	if indeks_face_terpilih > -1 and objek_terpilih != null:
		var wajah_yang_dipilih = objek_terpilih.dapatkan_wajah(indeks_face_terpilih)
		var material_
		if objek_terpilih is MeshInstance3D:
			material_ = objek_terpilih.material_override
		elif wajah_yang_dipilih != null and wajah_yang_dipilih.get("indeks_wajah") != null:
			material_ = wajah_yang_dipilih.dapatkan_material()
		material_terpilih = material_
		$tata_letak_vertikal/tata_letak/inspektur/VSplitContainer/tampilan_material/SubViewport/placeholder_mesh.material_override = material_terpilih
	print("Alat: Material Picker")

func _perbarui_tampilan_alat_aktif() -> void:
	if tool_aktif == "select":
		$tata_letak_vertikal/tata_letak/alat/VSplitContainer/move_selected_button.visible = true
		$tata_letak_vertikal/tata_letak/alat/VSplitContainer/scale_selected_button.visible = true
		if mode_transformasi == "gerak":
			$tata_letak_vertikal/tata_letak/alat/VSplitContainer/move_selected_button.button_pressed = true
		elif mode_transformasi == "skala":
			$tata_letak_vertikal/tata_letak/alat/VSplitContainer/scale_selected_button.button_pressed = true
	else:
		$tata_letak_vertikal/tata_letak/alat/VSplitContainer/move_selected_button.visible = false
		$tata_letak_vertikal/tata_letak/alat/VSplitContainer/scale_selected_button.visible = false

func _clear_selection() -> void:
	if objek_terpilih != null:
		objek_terpilih.tampilkan_di_viewport(false)
	objek_terpilih = null
	indeks_face_terpilih = -1
	handles.visible = false
	sedang_meni_transformasi = false
	_clear_face_highlight()

func _ketika_menambah_kubus() -> void:
	var kubus : Node3D = tambah_kubus($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat/titik_fokus.global_position)
	if objek_terpilih != null:
		objek_terpilih.tampilkan_di_viewport(false)
	_on_select_tool_pressed()
	objek_terpilih = kubus
	objek_terpilih.tampilkan_di_viewport(true)
	indeks_face_terpilih = -1
	_perbarui_handles()
	handles.visible = true
	print("Kubus ditambahkan dan dipilih: ", kubus.name)

func _terapkan_mode_pemilihan_objek(mode_face : bool = false) -> void:
	for objek_objek in $lingkungan.get_children():
		if objek_objek.get("pilih_wajah") != null:
			objek_objek.pilih_wajah = mode_face

func _konversi_material_menjadi_data(objek_material : StandardMaterial3D) -> Dictionary:
	"""
		Perlu Konversi Manual:
			Texture2D	: cukup gunakan path
			Color
			Vector3		: ubah menjadi array
		
		* Hanya tambahkan parameter jika nilainya berbeda dengan nilai baku
		* Abaikan parameter eksperimental
		* Untuk Tipe Data Texture2D, gunakan path file tekturnya
		* Untuk Tipe Data Color, gunakan string hex-nya, misal: "#FFBBAADD"
		
		Daftar Parameter:
			Tipe Data		|	Nama Variabel			|	Nilai Baku						| Status
			Color				albedo_color				[baku: Color(1, 1, 1, 1)]
			Texture2D			albedo_texture
			bool				albedo_texture_force_srgb	[baku: false]
			bool				albedo_texture_msdf			[baku: false]
			float				alpha_antialiasing_edge
			AlphaAntiAliasing	alpha_antialiasing_mode
			float				alpha_hash_scale
			float				alpha_scissor_threshold
			float				anisotropy					[baku: 0.0]
			bool				anisotropy_enabled			[baku: false]
			Texture2D			anisotropy_flowmap
			bool				ao_enabled					[baku: false]
			float				ao_light_affect				[baku: 0.0]
			bool				ao_on_uv2					[baku: false]
			Texture2D			ao_texture
			TextureChannel		ao_texture_channel			[baku: 0]
			Color				backlight					[baku: Color(0, 0, 0, 1)]
			bool				backlight_enabled			[baku: false]
			Texture2D			backlight_texture
			bool				bent_normal_enabled			[baku: false]
			Texture2D			bent_normal_texture
			bool				billboard_keep_scale		[baku: false]
			BillboardMode		billboard_mode				[baku: 0]
			BlendMode			blend_mode					[baku: 0]
			float				clearcoat					[baku: 1.0]
			bool				clearcoat_enabled			[baku: false]
			float				clearcoat_roughness			[baku: 0.5]
			Texture2D			clearcoat_texture
			CullMode			cull_mode					[baku: 0]
			DepthDrawMode		depth_draw_mode				[baku: 0]
			DepthTest			depth_test					[baku: 0]  						Eksperimental
			Texture2D			detail_albedo
			BlendMode			detail_blend_mode			[baku: 0]
			bool				detail_enabled				[baku: false]
			Texture2D			detail_mask
			Texture2D			detail_normal
			DetailUV			detail_uv_layer				[baku: 0]
			DiffuseMode			diffuse_mode				[baku: 0]
			bool				disable_ambient_light		[baku: false]
			bool				disable_fog					[baku: false]
			bool				disable_receive_shadows		[baku: false]
			bool				disable_specular_occlusion	[baku: false]
			float				distance_fade_max_distance	[baku: 10.0]
			float				distance_fade_min_distance	[baku: 0.0]
			DistanceFadeMode	distance_fade_mode			[baku: 0]
			Color				emission					[baku: Color(0, 0, 0, 1)]
			bool				emission_enabled			[baku: false]
			float				emission_energy_multiplier	[baku: 1.0]
			float				emission_intensity
			bool				emission_on_uv2				[baku: false]
			EmissionOperator	emission_operator			[baku: 0]
			Texture2D			emission_texture
			bool				fixed_size					[baku: false]
			float				fov_override				[baku: 75.0]
			bool				grow						[baku: false]
			float				grow_amount					[baku: 0.0]
			bool				heightmap_deep_parallax		[baku: false]
			bool				heightmap_enabled			[baku: false]
			bool				heightmap_flip_binormal		[baku: false]
			bool				heightmap_flip_tangent		[baku: false]
			bool				heightmap_flip_texture		[baku: false]
			int					heightmap_max_layers
			int					heightmap_min_layers
			float				heightmap_scale				[baku: 5.0]
			Texture2D			heightmap_texture
			float				metallic					[baku: 0.0]
			float				metallic_specular			[baku: 0.5]
			Texture2D			metallic_texture
			TextureChannel		metallic_texture_channel	[baku: 0]
			float				msdf_outline_size			[baku: 0.0]
			float				msdf_pixel_range			[baku: 4.0]
			bool				no_depth_test				[baku: false]
			bool				normal_enabled				[baku: false]
			float				normal_scale				[baku: 1.0]
			Texture2D			normal_texture
			Texture2D			orm_texture
			int					particles_anim_h_frames
			bool				particles_anim_loop
			int					particles_anim_v_frames
			float				point_size					[baku: 1.0]
			float				proximity_fade_distance		[baku: 1.0]
			bool				proximity_fade_enabled		[baku: false]
			bool				refraction_enabled			[baku: false]
			float				refraction_scale			[baku: 0.05]
			Texture2D			refraction_texture
			TextureChannel		refraction_texture_channel	[baku: 0]
			float				rim							[baku: 1.0]
			bool				rim_enabled					[baku: false]
			Texture2D			rim_texture
			float				rim_tint					[baku: 0.5]
			float				roughness					[baku: 1.0]
			Texture2D			roughness_texture
			TextureChannel		roughness_texture_channel	[baku: 0]
			ShadingMode			shading_mode				[baku: 1]
			bool				shadow_to_opacity			[baku: false]
			SpecularMode		specular_mode				[baku: 0]
			Color				stencil_color				[baku: Color(0, 0, 0, 1)]		Eksperimental
			StencilCompare		stencil_compare				[baku: 0]						Eksperimental
			int					stencil_flags				[baku: 0]						Eksperimental
			StencilMode			stencil_mode				[baku: 0]						Eksperimental
			float				stencil_outline_thickness	[baku: 0.01]					Eksperimental
			int					stencil_reference			[baku: 1]						Eksperimental
			bool				subsurf_scatter_enabled		[baku: false]
			bool				subsurf_scatter_skin_mode	[baku: false]
			float				subsurf_scatter_strength	[baku: 0.0]
			Texture2D			subsurf_scatter_texture
			float		subsurf_scatter_transmittance_boost	[baku: 0.0]
			Color		subsurf_scatter_transmittance_color	[baku: Color(1, 1, 1, 1)]
			float		subsurf_scatter_transmittance_depth	[baku: 0.1]
			bool	subsurf_scatter_transmittance_enabled	[baku: false]
			Texture2D	subsurf_scatter_transmittance_texture
			TextureFilter		texture_filter				[baku: 3]
			bool				texture_repeat				[baku: true]
			Transparency		transparency				[baku: 0]
			bool				use_fov_override			[baku: false]
			bool				use_particle_trails			[baku: false]
			bool				use_point_size				[baku: false]
			bool				use_z_clip_scale			[baku: false]
			Vector3				uv1_offset					[baku: Vector3(0, 0, 0)]
			Vector3				uv1_scale					[baku: Vector3(1, 1, 1)]
			bool				uv1_triplanar				[baku: false]
			float				uv1_triplanar_sharpness		[baku: 1.0]
			bool				uv1_world_triplanar			[baku: false]
			Vector3				uv2_offset					[baku: Vector3(0, 0, 0)]
			Vector3				uv2_scale					[baku: Vector3(1, 1, 1)]
			bool				uv2_triplanar				[baku: false]
			float				uv2_triplanar_sharpness		[baku: 1.0]
			bool				uv2_world_triplanar			[baku: false]
			bool				vertex_color_is_srgb		[baku: false]
			bool				vertex_color_use_as_albedo	[baku: false]
			float				z_clip_scale				[baku: 1.0]
	"""
	var data: Dictionary = {}
	
	# Membuat material kosong sekadar untuk melihat nilai baku aslinya
	var baku = StandardMaterial3D.new()

	# 1. Konversi Parameter Standar
	for prop in PROP_STANDAR_MATERIAL:
		var nilai = objek_material.get(prop)
		if nilai != baku.get(prop):
			data[prop] = nilai
			
	# 2. Konversi Warna (Color -> String Hex)
	for prop in PROP_WARNA_MATERIAL:
		var nilai = objek_material.get(prop)
		if nilai != baku.get(prop):
			# to_html(true) mengembalikan format RRGGBBAA (opsi true agar Alpha ikut)
			data[prop] = "#" + nilai.to_html(true)
			
	# 3. Konversi Vektor (Vector3 -> Array)
	for prop in PROP_VEKTOR_MATERIAL:
		var nilai = objek_material.get(prop)
		if nilai != baku.get(prop):
			data[prop] = [nilai.x, nilai.y, nilai.z]
			
	# 4. Konversi Tekstur (Texture2D -> Path String)
	for prop in PROP_TEKSTUR_MATERIAL:
		var nilai = objek_material.get(prop)
		# Pastikan tekstur tidak null dan memiliki path file lokal
		if nilai != null and nilai is Texture2D and nilai.resource_path != "":
			data[prop] = nilai.resource_path
	
	return data
func _konversi_data_material_menjadi_material(data_material: Dictionary) -> StandardMaterial3D:
	var hasil_material = StandardMaterial3D.new()
	
	for prop in data_material.keys():
		var nilai = data_material[prop]
		
		if prop in PROP_STANDAR_MATERIAL:
			hasil_material.set(prop, nilai)
			
		elif prop in PROP_WARNA_MATERIAL:
			# Godot otomatis mengubah "#RRGGBBAA" kembali menjadi objek Color
			hasil_material.set(prop, Color(nilai))
			
		elif prop in PROP_VEKTOR_MATERIAL:
			hasil_material.set(prop, Vector3(nilai[0], nilai[1], nilai[2]))
			
		elif prop in PROP_TEKSTUR_MATERIAL:
			# Pastikan file tekstur benar-benar ada di komputer klien/penerima sebelum di-load
			if ResourceLoader.exists(nilai):
				hasil_material.set(prop, load(nilai))
	
	return hasil_material

func _ketika_buka_file_desain(jalur_file : String) -> void:
	if $dialog_buka_desain.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		if not jalur_file.ends_with(".dmf"):
			jalur_file += ".dmf"
		jalur_file_desain = jalur_file
		simpan_desain()
	elif $dialog_buka_desain.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		if not FileAccess.file_exists(jalur_file):
			print("File tidak valid!")
			return
		var file = FileAccess.open(jalur_file, FileAccess.READ)
		if file:
			var data = file.get_var()
			for objek_desain_saat_ini in $lingkungan.get_children():
				objek_desain_saat_ini.queue_free()
			for index_objek_desain in data:
				var data_objek_desain : Dictionary = data[index_objek_desain]
				match data_objek_desain.tipe:
					"bentuk":
						match data_objek_desain.jenis:
							"kubus":
								tambah_kubus(
									data_objek_desain.posisi,
									data_objek_desain.rotasi,
									data_objek_desain.ukuran,
									data_objek_desain.material,
									false
								)
							_:
								push_error("Jenis tidak diketahui : " + data_objek_desain.jenis)
					_:
						push_error("Tipe tidak diketahui : " + data_objek_desain.tipe)
			jalur_file_desain = jalur_file
			file.close()
			Panku.notify("Membuka : " + jalur_file_desain)
			_on_select_tool_pressed()


func atur_posisi_fokus_viewport(posisi : Vector3) -> void:
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus.global_position = posisi
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus.global_position = posisi
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus.global_position = posisi

func tambah_kubus(posisi : Vector3 = Vector3.ZERO, rotasi : Vector3 = Vector3.ZERO, ukuran : Vector3 = Vector3(1.0, 1.0, 1.0), daftar_material : Dictionary = {}, snap_posisi : bool = true) -> Node3D:
	var kubus : Node3D = load("res://model/kubus.scn").instantiate()
	var interval_snap : float = 1.0 / jumlah_kisi_kisi
	$lingkungan.add_child(kubus)
	for indeks_data_material in daftar_material.keys():
		var data_material = daftar_material[indeks_data_material]
		if data_material != null:
			var wajah_kubus = kubus.dapatkan_node_wajah(indeks_data_material)
			wajah_kubus.atur_material(
				_konversi_data_material_menjadi_material(data_material)
			)
	kubus.global_position = posisi
	kubus.global_rotation = rotasi
	if snap_posisi:
		kubus.global_position.x = snappedf(kubus.global_position.x, interval_snap)
		kubus.global_position.y = snappedf(kubus.global_position.y, interval_snap)
		kubus.global_position.z = snappedf(kubus.global_position.z, interval_snap)
	kubus.ukuran = ukuran
	kubus.tampilkan_di_viewport(false)
	return kubus

func simpan_desain() -> void:
	if !DirAccess.dir_exists_absolute("user://mapsrc"):
		DirAccess.make_dir_absolute("user://mapsrc")
	if $lingkungan.get_child_count() > 0:
		if jalur_file_desain == "":
			$dialog_buka_desain.title = "Simpan Desain Sebagai"
			$dialog_buka_desain.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			$dialog_buka_desain.root_subfolder = "mapsrc"
			$dialog_buka_desain.filters = ["*.dmf"]
			$dialog_buka_desain.show()
		else:
			var file = FileAccess.open(jalur_file_desain, FileAccess.WRITE)
			var data_desain : Dictionary
			var jumlah_objek_desain : int = 0
			for objek_desain in $lingkungan.get_children():
				if objek_desain.get("tipe_bentuk") != null:
					jumlah_objek_desain += 1
					match objek_desain.tipe_bentuk:
						0:
							# Kubus
							var data_material_objek_desain : Dictionary
							for id_wajah in objek_desain.wajah.size():
								var wajah_objek_desain = objek_desain.dapatkan_wajah(id_wajah)
								if wajah_objek_desain.get("indeks_wajah") != null:
									var resource_material : Material = wajah_objek_desain.dapatkan_material()
									var nama_material : String = objek_desain.wajah[id_wajah]
									if resource_material != null:
										data_material_objek_desain[nama_material] = _konversi_material_menjadi_data(resource_material)
							data_desain[jumlah_objek_desain] = {
								"tipe"		: "bentuk",
								"jenis"		: "kubus",
								"posisi"	: objek_desain.global_position,
								"rotasi"	: objek_desain.global_rotation,
								"ukuran"	: objek_desain.ukuran,
								"material"	: data_material_objek_desain
							}
						1:
							# Segitiga
							pass
						2:
							# Silinder
							pass
			if file:
				file.store_var(data_desain)
				file.close()
			Panku.notify(jalur_file_desain + " disimpan.")
	else:
		Panku.notify("Tidak ada perubahan yang perlu disimpan")

func buka_desain() -> void:
	if !DirAccess.dir_exists_absolute("user://mapsrc"):
		DirAccess.make_dir_absolute("user://mapsrc")
	$dialog_buka_desain.title = "Buka Desain"
	$dialog_buka_desain.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	$dialog_buka_desain.root_subfolder = "mapsrc"
	$dialog_buka_desain.filters = ["*.dmf"]
	$dialog_buka_desain.show()
