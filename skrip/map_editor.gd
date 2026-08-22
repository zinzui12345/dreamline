extends Control

var _cek_ukuran_kanvas : Vector2

# Seleksi dan transformasi
var objek_terpilih : Node3D = null
var mode_transformasi : String = "gerak"  # gerak, putar, skala
var tool_aktif : String = "select" # select, face_select, knife
var viewport_aktif : SubViewportContainer
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
	var highlight_box = BoxMesh.new()
	highlight_box.size = Vector3(0.2, 0.2, 0.2)
	face_highlight_marker.mesh = highlight_box
	var highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(1, 1, 0, 0.7)
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	face_highlight_marker.material_override = highlight_material
	face_highlight_marker.visible = false
	add_child(face_highlight_marker)
	
	# Tambahkan tombol material selector ke panel inspektor
	var inspektor = $tata_letak_vertikal/tata_letak/inspektur
	button_material = Button.new()
	button_material.text = "Pilih Material"
	button_material.size = Vector2(120, 30)
	button_material.position = Vector2(10, 10)
	button_material.connect("pressed", self._ketika_memilih_material)
	inspektor.add_child(button_material)
	
	# Hubungkan tombol alat baru
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/select_tool_button.connect("pressed", self._on_select_tool_pressed)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/face_select_tool_button.connect("pressed", self._on_face_select_tool_pressed)
	$tata_letak_vertikal/tata_letak/alat/VSplitContainer/knife_tool_button.connect("pressed", self._on_knife_tool_pressed)
	
	# Hubungkan tombol tambah kubus
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
				else:
					_clear_selection() # Bersihkan pemilihan
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
		if rect.has_point(posisi_layar):
			# Konversi posisi layar global ke posisi relatif viewport
			var posisi_relatif = posisi_layar - container.get_global_position()
			var objek_ = _pilih_objek_dari_viewport(kamera, posisi_relatif, viewport["is_3d"])
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

func _cek_viewport_dari_klik(posisi_layar: Vector2) -> void:
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
		if rect.has_point(posisi_layar):
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

func _pilih_objek_dari_viewport(kamera: Camera3D, posisi_viewport: Vector2, is_3d: bool) -> Node3D:
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
				# Jika dalam viewport 3D DAN tool face select aktif, coba dapatkan informasi face
				if is_3d and tool_aktif == "face_select":
					indeks_face_terpilih = _dapatkan_indeks_face(objek_, hasil)
				else:
					indeks_face_terpilih = -1
				return objek_
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
	# Mencoba mendapatkan indeks face dari hasil raycast
	# Ini hanya bekerja jika objek adalah MeshInstance3D dan kita mengakses meshnya
	if objek_ is MeshInstance3D:
		var mesh = objek_.mesh
		if mesh and mesh is ArrayMesh:
			# Untuk ArrayMesh, kita bisa mendapatkan indeks face dari hasil
			# Namun, Godot tidak langsung menyediakan indeks face dalam hasil raycast
			# Kita akan kembali -1 sebagai placeholder (perlu implementasi lebih lanjut)
			return -1
	return -1

func _perbarui_handles() -> void:
	if objek_terpilih:
		var offset : Vector3
		if objek_terpilih.mesh is BoxMesh:
			offset = (objek_terpilih.mesh.size / 2) + Vector3(0.10, 0.10, 0.10)
		handles.global_transform.origin = objek_terpilih.global_transform.origin
		# Tampilkan hanya handles yang sesuai dengan mode
		handle_x.visible = (mode_transformasi == "gerak")
		handle_y.visible = (mode_transformasi == "gerak")
		handle_z.visible = (mode_transformasi == "gerak")
		# Sesuaikan posisi handle
		handle_x.position.x = offset.x
		handle_y.position.y = offset.y
		handle_z.position.z = offset.z
		# Untuk mode putar dan skala, kita akan menambahkan handles khusus nanti
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

func _ketika_memilih_material() -> void:
	var file_dialog = FileDialog.new()
	file_dialog.title = "Pilih Material"
	file_dialog.mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.tres"]
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected", self._on_file_selected)
	add_child(file_dialog)

func _on_file_selected(file_path: String) -> void:
	var material_ = load(file_path) as Material
	if material_:
		material_terpilih = material_
		if objek_terpilih:
			# Jika ada face terpilih, kita ingin mengubah material hanya untuk face tersebut
			# Namun, untuk saat ini, kita akan mengubah seluruh objek
			# TODO: Implementasi perubahan material per face
			if objek_terpilih is MeshInstance3D:
				objek_terpilih.material_override = material_terpilih
			# Jika bukan MeshInstance3H, kita bisa coba mengubah material melalui surface tool
			# Namun, untuk kesederhanaan, kita hanya handle MeshInstance3D
		else:
			push_warning("Tidak ada objek yang dipilih")

func _highlight_face_seleksi() -> void:
	# Tampilkan marker highlight ketika face terpilih
	if indeks_face_terpilih >= 0 and objek_terpilih:
		# Tampilkan marker highlight
		face_highlight_marker.visible = true
		# Gunakan posisi kamera saat ini sebagai placeholder; nantinya bisa disesuaikan dengan hasil raycast
		face_highlight_marker.global_transform.origin = objek_terpilih.global_transform.origin + Vector3(0.5, 0, 0) # Offset pada sumbu X
		# Orientasi marker sesuai dengan normal face
		# Untuk skimming, biarkan hanya posisi, nanti bisa diorientasikan
		#print("Face terpilih: ", indeks_face_terpilih)
	else:
		# Sembunyikan marker jika tidak ada face yang dipilih
		face_highlight_marker.visible = false
		_clear_face_highlight()

func _clear_face_highlight() -> void:
	# TODO: Hapus highlight face
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
	
	# Terapkan gerak ke objek (hanya translasi untuk saat ini)
	if mode_transformasi == "gerak" and sedang_meni_transformasi:
		if posisi_kursor_di_viewport != Vector2.ZERO and posisi_kursor_di_dunia != Vector3.ZERO:
			var gerak_dunia = objek_terpilih.global_position
			var posisi_baru : Vector3
			var interval_snap : float = 1.0 / jumlah_kisi_kisi
			
			if axis_yang_digunakan == Vector3(1, 0, 0):  # Sumbu X
				if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas or viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan:
					gerak_dunia = kanan * (posisi_kursor_di_dunia.x - handle_x.position.x)
					posisi_baru.x = snappedf(gerak_dunia.x, interval_snap)
					objek_terpilih.global_position.x = posisi_baru.x
			elif axis_yang_digunakan == Vector3(0, 1, 0):  # Sumbu Y
				if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_a/tampilan_depan or viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan:
					gerak_dunia = atas * (posisi_kursor_di_dunia.y - handle_y.position.y)
					posisi_baru.y = snappedf(gerak_dunia.y, interval_snap)
					objek_terpilih.global_position.y = posisi_baru.y
			elif axis_yang_digunakan == Vector3(0, 0, 1):  # Sumbu Z
				if viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_atas:
					gerak_dunia = atas * -(posisi_kursor_di_dunia.z - handle_z.position.z)
					posisi_baru.z = snappedf(gerak_dunia.z, interval_snap)
				elif viewport_aktif == $tata_letak_vertikal/tata_letak/kanvas/pemisah_vertikal_b/tampilan_kanan:
					gerak_dunia = kanan * -(posisi_kursor_di_dunia.z - handle_z.position.z)
					posisi_baru.z = snappedf(gerak_dunia.z, interval_snap)
				objek_terpilih.global_position.z = posisi_baru.z
			
			posisi_kursor_di_viewport = Vector2.ZERO
			posisi_kursor_di_dunia = Vector3.ZERO
		

func _on_select_tool_pressed() -> void:
	tool_aktif = "select"
	mode_transformasi = "gerak" # Mode default untuk select tool (bisa translasi, rotasi, skala)
	_perbarui_tampilan_alat_aktif()
	_clear_selection() # Bersihkan pemilihan saat ganti alat
	print("Alat: Select")

func _on_face_select_tool_pressed() -> void:
	tool_aktif = "face_select"
	_perbarui_tampilan_alat_aktif()
	_clear_selection() # Bersihkan pemilihan saat ganti alat
	print("Alat: Face Select")

func _on_knife_tool_pressed() -> void:
	tool_aktif = "knife"
	_perbarui_tampilan_alat_aktif()
	_clear_selection() # Bersihkan pemilihan saat ganti alat
	print("Alat: Knife")

func _perbarui_tampilan_alat_aktif() -> void:
	# TODO: Implementasi visual feedback untuk tombol alat yang aktif
	# Misalnya, mengubah gaya tombol yang sedang aktif
	# Kita bisa iterasi melalui semua tombol alat dan mengatur gaya mereka.
	# Untuk saat ini, kita biarkan kosong.
	pass

func _clear_selection() -> void:
	objek_terpilih = null
	indeks_face_terpilih = -1
	handles.visible = false
	sedang_meni_transformasi = false
	_clear_face_highlight()

func _ketika_menambah_kubus() -> void:
	# Buat MeshInstance3D dengan CubeMesh
	var kubus = MeshInstance3D.new()
	kubus.mesh = BoxMesh.new()
	kubus.name = "Kubus_" + str(randi() % 1000)
	
	# Tambahkan StaticBody3D + CollisionShape3D agar bisa dideteksi
	var badan = StaticBody3D.new()
	badan.name = "badan"
	kubus.add_child(badan)
	var bentuk_tabrakan = CollisionShape3D.new()
	bentuk_tabrakan.name = "bentuk_tabrakan"
	var kotak = BoxShape3D.new()
	kotak.size = Vector3(1, 1, 1)
	bentuk_tabrakan.shape = kotak
	badan.add_child(bentuk_tabrakan)
	
	# Tambahkan body fisik ke grup seleksi (MeshInstance3D, bukan StaticBody3D)
	kubus.add_to_group("seleksi_aktif")  # PERBAIKAN: Tambahkan MeshInstance3D bukan StaticBody3D
	
	# Tambahkan ke lingkungan
	$lingkungan.add_child(kubus)
	
	# Pilih objek yang baru dibuat
	objek_terpilih = kubus
	indeks_face_terpilih = -1
	_perbarui_handles()
	handles.visible = true
	print("Kubus ditambahkan dan dipilih: ", kubus.name)
