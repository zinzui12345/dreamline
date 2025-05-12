# 11/05/25
extends Node3D

var pengamat : Camera3D
@export var jarak_pengamat : float 
var posisi_terakhir_pengamat : Vector3
var rotasi_terakhir_pengamat : Vector3
@export var portal_a_terlihat : bool
@export var portal_b_terlihat : bool
var objek_dalam_portal_a : Array[NodePath]
var objek_dalam_portal_b : Array[NodePath]
var node_tampilan_portal_a : Dictionary
var node_tampilan_portal_b : Dictionary

func _ready() -> void:
	$portal_a/tampilan_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
	$portal_b/tampilan_b.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var pencahayaan : Environment = dunia.get_node("pencahayaan").environment.duplicate()
	pencahayaan.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	$portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.environment = pencahayaan
	$portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.environment = pencahayaan
	set_process(false)

# atur mode render subviewport berdasarkan posisi pemain
func _ketika_pemain_memasuki_wilayah_portal_a(node_pemain : Node3D) -> void:
	if node_pemain == dunia.get_node_or_null("pemain/"+str(client.id_koneksi)):
		$portal_b/tampilan_b.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
func _ketika_pemain_meninggalkan_wilayah_portal_a(node_pemain : Node3D) -> void:
	if node_pemain == dunia.get_node_or_null("pemain/"+str(client.id_koneksi)):
		$portal_b/tampilan_b.render_target_update_mode = SubViewport.UPDATE_DISABLED
func _ketika_pemain_memasuki_wilayah_portal_b(node_pemain : Node3D) -> void:
	if node_pemain == dunia.get_node_or_null("pemain/"+str(client.id_koneksi)):
		$portal_a/tampilan_a.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
func _ketika_pemain_meninggalkan_wilayah_portal_b(node_pemain : Node3D) -> void:
	if node_pemain == dunia.get_node_or_null("pemain/"+str(client.id_koneksi)):
		$portal_a/tampilan_a.render_target_update_mode = SubViewport.UPDATE_DISABLED

# atur proses render portal berdasarkan visibilitasnya
func _ketika_portal_a_terlihat() -> void:
	set_process(true)
	portal_a_terlihat = true
func _ketika_portal_a_tidak_terlihat() -> void:
	$portal_b/tampilan_b.size = Vector2.ZERO
	if !portal_b_terlihat: set_process(false)
	portal_a_terlihat = false
func _ketika_portal_b_terlihat() -> void:
	set_process(true)
	portal_b_terlihat = true
func _ketika_portal_b_tidak_terlihat() -> void:
	$portal_a/tampilan_a.size = Vector2.ZERO
	if !portal_a_terlihat: set_process(false)
	portal_b_terlihat = false

# cek objek yang memasuki portal
func _ketika_objek_memasuki_portal_a(node_objek : Node3D) -> void:
	var jalur_objek : NodePath = node_objek.get_path()
	if !objek_dalam_portal_a.has(jalur_objek):
		objek_dalam_portal_a.append(jalur_objek)
	# buat node duplikat sebagai tampilan pada portal b
	if !node_tampilan_portal_b.has(str(jalur_objek)):
		# jika objek adalah karakter, buat node baru dengan kerangka duplikat
		if node_objek is Karakter:
			node_tampilan_portal_b[str(jalur_objek)] = Node3D.new()
			node_tampilan_portal_b[str(jalur_objek)].process_mode = Node.PROCESS_MODE_ALWAYS
			node_tampilan_portal_b[str(jalur_objek)].name = node_objek.name
			var kerangka_karakter : Skeleton3D = node_objek.get_node("%GeneralSkeleton")
			var model_karakter : Skeleton3D = kerangka_karakter.duplicate()
			$portal_a/area_a/pos_objek.global_position = node_objek.global_position
			$portal_a/area_a/pos_objek.global_rotation = node_objek.global_rotation
			node_tampilan_portal_b[str(jalur_objek)].position = $portal_a/area_a/pos_objek.position
			node_tampilan_portal_b[str(jalur_objek)].rotation = $portal_a/area_a/pos_objek.rotation
			node_tampilan_portal_b[str(jalur_objek)].add_child(model_karakter)
			#model_karakter.get_node("badan").rotation.x = 0
			model_karakter.get_node("badan/badan_f").visible = false
			for bentuk in model_karakter.get_children():
				if bentuk is MeshInstance3D:
					bentuk.set_layer_mask_value(2, true)
					bentuk.set_skeleton_path(kerangka_karakter.get_path())
				else:
					bentuk.queue_free()
		else:
			node_tampilan_portal_b[str(jalur_objek)] = node_objek.duplicate()
			node_tampilan_portal_b[str(jalur_objek)].process_mode = Node.PROCESS_MODE_DISABLED
		$portal_b/node_tampilan.add_child(node_tampilan_portal_b[str(jalur_objek)])
func _ketika_objek_keluar_dari_portal_a(node_objek : Node3D) -> void:
	var jalur_objek : NodePath = node_objek.get_path()
	if objek_dalam_portal_a.has(jalur_objek):
		objek_dalam_portal_a.erase(jalur_objek)
	if node_tampilan_portal_b.has(str(jalur_objek)) and is_instance_valid(node_tampilan_portal_b[str(jalur_objek)]):
		node_tampilan_portal_b[str(jalur_objek)].queue_free()
		node_tampilan_portal_b.erase(str(jalur_objek))

func _process(delta: float) -> void:
	# sesuaikan pengamat
	if pengamat != get_viewport().get_camera_3d():
		pengamat = get_viewport().get_camera_3d()
	
	# sesuaikan properti tiap pengamat
	if portal_a_terlihat or portal_b_terlihat:
		# sesuaikan properti pengamat a
		if $portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.far != pengamat.far:
			$portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.far = pengamat.far
		if $portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.fov != pengamat.fov:
			$portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.fov = pengamat.fov
		if $portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.near != pengamat.near:
			$portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.near = pengamat.near
		# sesuaikan properti pengamat b
		if $portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.far != pengamat.far:
			$portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.far = pengamat.far
		if $portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.fov != pengamat.fov:
			$portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.fov = pengamat.fov
		if $portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.near != pengamat.near:
			$portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.near = pengamat.near
	
	# kalkulasi jarak pengamat terhadap setiap portal
	var jarak_pengamat_a : float = pengamat.global_position.distance_to($portal_a.global_position)
	var jarak_pengamat_b : float = pengamat.global_position.distance_to($portal_b.global_position)
	
	# render portal a
	if portal_a_terlihat:
		if posisi_terakhir_pengamat != pengamat.global_position or rotasi_terakhir_pengamat != pengamat.global_rotation:
			if jarak_pengamat_a < jarak_pengamat_b:
				jarak_pengamat = pengamat.global_position.distance_to($portal_a.global_position) * 0.001
			else:
				jarak_pengamat = pengamat.global_position.distance_to($portal_a.global_position) * 0.01
			$portal_b/tampilan_b.size = get_viewport().size * (1.0 - clamp(jarak_pengamat, 0.0, 0.95))
			$portal_a/pos_pengamat_a.global_position = pengamat.global_position
			$portal_a/pos_pengamat_a.global_rotation = pengamat.global_rotation
			$portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.position = $portal_a/pos_pengamat_a.position
			$portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.rotation = $portal_a/pos_pengamat_a.rotation
	# render portal b
	if portal_b_terlihat:
		if posisi_terakhir_pengamat != pengamat.global_position or rotasi_terakhir_pengamat != pengamat.global_rotation:
			if jarak_pengamat_b < jarak_pengamat_a:
				jarak_pengamat = pengamat.global_position.distance_to($portal_b.global_position) * 0.001
			else:
				jarak_pengamat = pengamat.global_position.distance_to($portal_b.global_position) * 0.01
			$portal_a/tampilan_a.size = get_viewport().size * (1.0 - clamp(jarak_pengamat, 0.0, 0.95))
			$portal_b/pos_pengamat_b.global_position = pengamat.global_position
			$portal_b/pos_pengamat_b.global_rotation = pengamat.global_rotation
			$portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.position = $portal_b/pos_pengamat_b.position
			$portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.rotation = $portal_b/pos_pengamat_b.rotation
	
	posisi_terakhir_pengamat = pengamat.global_position
	rotasi_terakhir_pengamat = pengamat.global_rotation

func _physics_process(delta: float) -> void:
	# cek posisi objek dalam portal a
	for jalur_objek in objek_dalam_portal_a:
		var objek_diteleportasi : Node3D
		# sesuaikan posisi dan rotasi lokal objek pada portal a
		$portal_a/area_a/pos_objek.global_position = get_node(jalur_objek).global_position
		$portal_a/area_a/pos_objek.global_rotation = get_node(jalur_objek).global_rotation
		# sesuaikan posisi dan rotasi lokal tiruan objek pada portal b
		if node_tampilan_portal_b.has(str(jalur_objek)) and is_instance_valid(node_tampilan_portal_b[str(jalur_objek)]):
			node_tampilan_portal_b[str(jalur_objek)].position = $portal_a/area_a/pos_objek.position
			node_tampilan_portal_b[str(jalur_objek)].rotation = $portal_a/area_a/pos_objek.rotation
		# jika posisi objek melewati portal a -> teleportasi objek ke portal b
		if $portal_a/area_a/pos_objek.position.z < 0:
			objek_diteleportasi = get_node(jalur_objek)
			# jika objek memiliki percepatan, putar percepatan menyesuaikan arah portal b
			if objek_diteleportasi.get("linear_velocity") != null:
				var arah_percepatan : Vector3 = $portal_b/arah.global_basis.get_euler() - $portal_a/arah.global_basis.get_euler()
				objek_diteleportasi.linear_velocity = objek_diteleportasi.linear_velocity\
					.rotated(Vector3(1, 0, 0), arah_percepatan.x)\
					.rotated(Vector3(0, 1, 0), arah_percepatan.y)\
					.rotated(Vector3(1, 0, 1), arah_percepatan.z)
				# Panku.notify("GlaDOS : speedy things come in, speedy things come out.")
		# cek apakah objek adalah pemain dengan mode pandangan 1 -> teleportasi pemain ke portal b sebelum posisi pandangannya melewati portal a
		elif get_node(jalur_objek) == dunia.get_node_or_null("pemain/"+str(client.id_koneksi)) and dunia.get_node("pemain/"+str(client.id_koneksi)+"/pengamat").mode_kontrol == 1:
			# sesuaikan posisi lokal pengamat pada portal a
			$portal_a/area_a/pos_objek.global_position = dunia.get_node("pemain/"+str(client.id_koneksi)+"/pengamat/kamera").global_position
			$portal_a/area_a/pos_objek.global_position.y = get_node(jalur_objek).global_position.y
			# jika posisi pengamat pemain melewati portal a -> teleportasi pemain ke portal b
			if $portal_a/area_a/pos_objek.position.z < $portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.near + (abs(dunia.get_node("pemain/"+str(client.id_koneksi)).arah_pandangan.y) * 0.25): 
				objek_diteleportasi = get_node(jalur_objek)
		# teleportasikan objek ke portal b
		if objek_diteleportasi != null:
			# sesuaikan posisi objek berdasarkan posisi lokal pada portal b
			$portal_b/area_b/pos_objek.position.x = $portal_a/area_a/pos_objek.position.x
			$portal_b/area_b/pos_objek.position.y = $portal_a/area_a/pos_objek.position.y
			$portal_b/area_b/pos_objek.position.z = -$portal_a/area_a/pos_objek.position.z
			objek_diteleportasi.global_position = $portal_b/area_b/pos_objek.global_position
			# sesuaikan arah objek dengan arah portal b
			$portal_a/area_a/pos_objek.global_rotation = objek_diteleportasi.global_rotation
			$portal_b/area_b/pos_objek.rotation = $portal_a/area_a/pos_objek.rotation
			objek_diteleportasi.global_rotation = $portal_b/area_b/pos_objek.global_rotation
			# hilangkan objek dari portal a
			_ketika_objek_keluar_dari_portal_a(objek_diteleportasi)
