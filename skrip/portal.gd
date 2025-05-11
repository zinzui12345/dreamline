# 11/05/25
extends Node3D

var pengamat : Camera3D
@export var jarak_pengamat : float 
var posisi_terakhir_pengamat : Vector3
var rotasi_terakhir_pengamat : Vector3
@export var portal_a_terlihat : bool
@export var portal_b_terlihat : bool
var objek_dalam_portal_a : Array[NodePath]

func _ready() -> void:
	$portal_a/tampilan_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
	$portal_b/tampilan_b.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var pencahayaan : Environment = dunia.get_node("pencahayaan").environment.duplicate()
	pencahayaan.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	$portal_a/tampilan_a/translasi_pengamat_a/pengamat_a.environment = pencahayaan
	$portal_b/tampilan_b/translasi_pengamat_b/pengamat_b.environment = pencahayaan

# atur mode render subviewport berdasarkan visibilitasnya
func _ketika_portal_a_terlihat() -> void:
	$portal_b/tampilan_b.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	portal_a_terlihat = true
func _ketika_portal_a_tidak_terlihat() -> void:
	$portal_b/tampilan_b.size = Vector2.ZERO
	$portal_b/tampilan_b.render_target_update_mode = SubViewport.UPDATE_DISABLED
	portal_a_terlihat = false
func _ketika_portal_b_terlihat() -> void:
	$portal_a/tampilan_a.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	portal_b_terlihat = true
func _ketika_portal_b_tidak_terlihat() -> void:
	$portal_a/tampilan_a.size = Vector2.ZERO
	$portal_a/tampilan_a.render_target_update_mode = SubViewport.UPDATE_DISABLED
	portal_b_terlihat = false

# cek objek yang memasuki portal
func _ketika_objek_memasuki_portal_a(node_objek : Node3D) -> void:
	if !objek_dalam_portal_a.has(node_objek.get_path()):
		objek_dalam_portal_a.append(node_objek.get_path())
func _ketika_objek_keluar_dari_portal_a(node_objek : Node3D) -> void:
	if objek_dalam_portal_a.has(node_objek.get_path()):
		objek_dalam_portal_a.erase(node_objek.get_path())

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
			$portal_a/pos_pengamat_a.global_rotation = pengamat.global_rotation
			$portal_a/pos_pengamat_a.global_position = pengamat.global_position
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
		$portal_a/area_a/pos_objek.global_position = get_node(jalur_objek).global_position
		# jika posisi objek melewati portal a -> teleportasi objek ke portal b
		if $portal_a/area_a/pos_objek.position.z < 0:
			var objek_diteleportasi : Node3D = get_node(jalur_objek)
			# jika objek memiliki percepatan, putar percepatan menyesuaikan arah portal b
			if objek_diteleportasi.get("linear_velocity") != null:
				var arah_percepatan : Vector3 = $portal_b/arah.global_basis.get_euler() - $portal_a/arah.global_basis.get_euler()
				objek_diteleportasi.linear_velocity = objek_diteleportasi.linear_velocity\
					.rotated(Vector3(1, 0, 0), arah_percepatan.x)\
					.rotated(Vector3(0, 1, 0), arah_percepatan.y)\
					.rotated(Vector3(1, 0, 1), arah_percepatan.z)
			# teleportasikan objek ke portal b
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
