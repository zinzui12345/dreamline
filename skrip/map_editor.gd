# 21/08/26
extends Control

var _cek_ukuran_kanvas : Vector2

# TODO :
# Opsi & Shortcut ubah ukuran grid (x^2) : [1, 2, 4, 8, 16, 32, 64, 128] 
# Fungsikan tool Knife

# Seleksi dan transformasi
var objek_terpilih : Node3D = null
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

# Warna handles
var warna_x = Color(1, 0, 0)
var warna_y = Color(0, 1, 0)
var warna_z = Color(0, 0, 1)

# Material selector
var material_terpilih : Material = null
var button_material : Button = null
var face_highlight_marker : MeshInstance3D = null
var posisi_face_terpilih : Vector3 = Vector3.ZERO

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
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/CanvasLayer/grid_atas.material.set_shader_parameter("resolution", $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas.size)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/CanvasLayer/grid_depan.material.set_shader_parameter("resolution", $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan.size)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/CanvasLayer/grid_kanan.material.set_shader_parameter("resolution", $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan.size)
	_cek_ukuran_kanvas = $tata_letak_vertikal/tata_letak/kanvas.size

func _ketika_viewport_ditransformasi() -> void:
	var zoom_atas : float = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat.size
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat.position.y = zoom_atas
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/CanvasLayer/grid_atas.material.set_shader_parameter("transform", Vector2($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus.global_position.x / zoom_atas, $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus.global_position.z / zoom_atas))
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/CanvasLayer/grid_atas.material.set_shader_parameter("zoom", jumlah_kisi_kisi * $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus/pengamat.position.y)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/CanvasLayer/nilai_zoom.text = str(zoom_atas / 2)
	
	var zoom_depan : float = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat.size
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat.position.z = zoom_depan
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/CanvasLayer/grid_depan.material.set_shader_parameter("transform", Vector2($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus.global_position.x / zoom_depan, -($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus.global_position.y / zoom_depan)))
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/CanvasLayer/grid_depan.material.set_shader_parameter("zoom", jumlah_kisi_kisi * $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus/pengamat.position.z)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/CanvasLayer/nilai_zoom.text = str(zoom_depan / 2)
	
	var zoom_kanan : float = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat.size
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat.position.x = zoom_kanan
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/CanvasLayer/grid_kanan.material.set_shader_parameter("transform", Vector2(-($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus.global_position.z / zoom_kanan), -($tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus.global_position.y / zoom_kanan)))
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/CanvasLayer/grid_kanan.material.set_shader_parameter("zoom", jumlah_kisi_kisi * $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus/pengamat.position.x)
	$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/CanvasLayer/nilai_zoom.text = str(zoom_kanan / 2)

func _input(event: InputEvent) -> void:
	# Sinkronisasi kamera tetap berlaku
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan/SubViewport/titik_fokus.global_position = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat/titik_fokus.global_position
		$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas/SubViewport/titik_fokus.global_position = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat/titik_fokus.global_position
		$tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan/SubViewport/titik_fokus.global_position = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat/titik_fokus.global_position
		_ketika_viewport_ditransformasi()

	# Handle pemilihan objek dan transformasi
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if tool_aktif == "select" or tool_aktif == "face_select":
				var objek_yang_diketahui = _deteksi_objek_dari_klik(event.position)
				if objek_yang_diketahui:
					objek_terpilih = objek_yang_diketahui
					if tool_aktif == "select":
						indeks_face_terpilih = -1 # Reset face selection saat tool select
					# Indeks face sudah diatur di _pilih_objek_dari_viewport jika tool_aktif == "face_select"
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
		#elif event.button_index == MOUSE_BUTTON_WHEEL_UP or _event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			## Scroll mouse untuk mengganti mode transformasi hanya jika tool_aktif adalah "select"
			#if tool_aktif == "select" and objek_terpilih:
				#if _event.button_index == MOUSE_BUTTON_WHEEL_UP:
					#mode_transformasi = _mode_berikutnya(mode_transformasi)
				#else:
					#mode_transformasi = _mode_sebelumnya(mode_transformasi)
				#_perbarui_handles()

	# Handle drag untuk transformasi
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and sedang_meni_transformasi:
			sedang_meni_transformasi = false
			handle_yang_digunakan = null
			nilai_transformasi = Vector2.ZERO
			axis_yang_digunakan = Vector3.ZERO
			posisi_kursor_di_dunia = Vector3.ZERO
			posisi_kursor_di_viewport = Vector2.ZERO
	
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
	var hasil = physics_state.intersect_ray(PhysicsRayQueryParameters3D.create(dari, dari + arah * 10000))
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
	$dialog_buka_file.connect("file_selected", self._on_file_selected)
	$dialog_buka_file.show()

func _on_file_selected(file_path: String) -> void:
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
	else:
		_clear_face_highlight()

func _clear_face_highlight() -> void:
	face_highlight_marker.visible = false
	indeks_face_terpilih = -1

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
			
			posisi_kursor_di_viewport = Vector2.ZERO
			posisi_kursor_di_dunia = Vector3.ZERO

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
	objek_terpilih = null
	indeks_face_terpilih = -1
	handles.visible = false
	sedang_meni_transformasi = false
	_clear_face_highlight()

func _ketika_menambah_kubus() -> void:
	var kubus = load("res://model/kubus.scn").instantiate()
	$lingkungan.add_child(kubus)
	kubus.global_position = $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_3d/SubViewport/pengamat/titik_fokus.global_position
	objek_terpilih = kubus
	indeks_face_terpilih = -1
	_perbarui_tampilan_alat_aktif()
	_perbarui_handles()
	handles.visible = true
	print("Kubus ditambahkan dan dipilih: ", kubus.name)

func _terapkan_mode_pemilihan_objek(mode_face : bool = false) -> void:
	for objek_objek in $lingkungan.get_children():
		if objek_objek.get("pilih_wajah") != null:
			objek_objek.pilih_wajah = mode_face
