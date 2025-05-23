extends Node3D

# TODO : Multi Threading

var pengamat : Camera3D
var jarak_objek : float
var posisi_objek : Vector3
var posisi_pengamat : Vector3
var arah_target_pengamat : Marker3D
var posisi_relatif_pengamat : Node3D
var raycast_occlusion_culling : RayCast3D

# Atur node rendering
func _ready() -> void:
	posisi_relatif_pengamat = Node3D.new()
	arah_target_pengamat	= Marker3D.new()
	arah_target_pengamat.name = "arah target pengamat"
	posisi_relatif_pengamat.name = "posisi relatif pengamat"
	add_child(posisi_relatif_pengamat)
	posisi_relatif_pengamat.add_child(arah_target_pengamat)
	raycast_occlusion_culling = RayCast3D.new()
	raycast_occlusion_culling.name = "raycast_occlusion_culling"
	raycast_occlusion_culling.set_collision_mask_value(2, true)
	raycast_occlusion_culling.set_collision_mask_value(3, true)
	raycast_occlusion_culling.set_collision_mask_value(32, true)
	raycast_occlusion_culling.target_position = Vector3(0, 0, -800)
	raycast_occlusion_culling.hit_from_inside = true
	raycast_occlusion_culling.exclude_parent = false
	add_child(raycast_occlusion_culling)

func hapus_map() -> void:
	if get_node_or_null("lingkungan") != null:
		get_node("lingkungan").queue_free()
	if is_instance_valid(server.permainan.map):
		server.permainan.map.free()
	if $entitas.get_child_count() > 0:
		for _entitas in $entitas.get_children():
			_entitas.queue_free()
	if $objek.get_child_count() > 0:
		for _objek in $objek.get_children():
			_objek.queue_free()
	if $karakter.get_child_count() > 0:
		for _karakter in $karakter.get_children():
			_karakter.queue_free()
func hapus_instance_pemain() -> void:
	var jumlah_pemain := $pemain.get_child_count()
	for p : int in jumlah_pemain:
		#print_debug("menghapus pemain [%s/%s]" % [jumlah_pemain-p, jumlah_pemain])
		$pemain.get_child(jumlah_pemain - (p + 1)).queue_free()
	server.pemain.clear()

# Optimasi rendering | Object Culling
func _physics_process(_delta : float) -> void:
	if server.mode_replay and not server.mode_uji_performa: pass # 06/07/24 :: jangan optimasi ketika memainkan replay
	elif is_instance_valid(server.permainan) and is_instance_valid(server.permainan.karakter) and $objek.get_child_count() > 0:
		# atur collider raycast occlusion culling jika belum ada
		if pengamat.get_node_or_null("target_raycast_culling") == null:
			var tmp_bb_fisik_pengamat = BoxShape3D.new()
			var tmp_b_fisik_pengamat = CollisionShape3D.new()
			var tmp_fisik_pengamat = StaticBody3D.new()
			tmp_fisik_pengamat.name = "target_raycast_culling"
			pengamat.add_child(tmp_fisik_pengamat)
			tmp_fisik_pengamat.set_collision_layer_value(1, false)
			tmp_fisik_pengamat.set_collision_layer_value(32, true)
			tmp_b_fisik_pengamat.name = "fisik"
			tmp_b_fisik_pengamat.shape = tmp_bb_fisik_pengamat
			tmp_fisik_pengamat.add_child(tmp_b_fisik_pengamat)
			tmp_bb_fisik_pengamat.size = Vector3(0.5, 0.5, 0.5)
		
		# loop setiap objek
		for m_objek : Node in $objek.get_children():
			# Direction Culling / Frustum Culling
			if server.permainan.gunakan_frustum_culling:
				# dapatkan posisi global kamera
				posisi_pengamat = pengamat.global_position
				
				# dapatkan posisi global kamera
				posisi_objek = m_objek.global_position
				
				# kalkulasi jarak kamera dengan objek
				jarak_objek = posisi_pengamat.distance_to(posisi_objek)
				
				# jika jarak kamera dengan objek lebih dari radius keterlihatan
				if jarak_objek > m_objek.radius_keterlihatan:
					# atur posisi dan rotasi posisi_relatif_pengamat dengan posisi dan rotasi pengamat
					posisi_relatif_pengamat.global_position = pengamat.global_position
					posisi_relatif_pengamat.global_rotation_degrees = pengamat.global_rotation_degrees
					arah_target_pengamat.look_at(
						posisi_objek, 
						Vector3.UP,
						false
					)
					
					# kalkulasi sudut arah_target_pengamat
					var sudut : float = abs(arah_target_pengamat.rotation_degrees.y)
					
					# jika objek berada di belakang kamera
					if sudut > (pengamat.fov * 1.125):
						# non-aktifkan visibilitas objek
						if m_objek.visible: 
							m_objek.visible = false
							m_objek.tak_terlihat = true
							# debug
							#Panku.notify(m_objek.name+" tak terlihat")
					# jika objek berada di depan kamera dan tidak terhalang
					elif !m_objek.visible and !m_objek.terhalang:
						# aktifkan visibilitas objek
						m_objek.visible = true
						m_objek.tak_terlihat = false
						# debug
						#Panku.notify(m_objek.name+" terlihat")
				# jika objek tidak visible dan tidak terhalang
				elif !m_objek.visible and !m_objek.terhalang:
					# aktifkan visibilitas objek
					m_objek.visible = true
					m_objek.tak_terlihat = false
					# debug
					#Panku.notify(m_objek.name+" terlihat")
			elif m_objek.tak_terlihat or !m_objek.terhalang:
				m_objek.visible = true
				m_objek.tak_terlihat = false
			
			# Occlusion Culling
			# FIXME : jangan cek ketika posisi pengamat berada didekat objek / titik
			# 23/06/24 :: jangan cek ketika arah pengamat membelakangi objek atau occlusion culling dinonaktifkan
			if !m_objek.tak_terlihat and (m_objek.get("abaikan_occlusion_culling") == null or m_objek.get("abaikan_occlusion_culling") == false):
				if server.permainan.gunakan_occlusion_culling and m_objek.titik_sudut.size() > 0:
					# pastikan cek titik yang valid
					if m_objek.cek_titik < m_objek.titik_sudut.size():
						# 23/06/24 :: kalkulasi posisi titik berdasarkan posisi global dunia
						raycast_occlusion_culling.global_position = m_objek.position + m_objek.transform.basis * m_objek.titik_sudut[m_objek.cek_titik]
						# arahkan rayacast ke pengamat
						raycast_occlusion_culling.look_at(pengamat.global_position)
						# exclude raycast dengan m_objek jika m_objek adalah CollisionObject3D
						if m_objek is CollisionObject3D:
							raycast_occlusion_culling.add_exception(m_objek) # 03/07/24 :: ini mengatasi jika m_objek adalah objek solid
						# cek apakah raycast mengenai sesuatu
						raycast_occlusion_culling.force_raycast_update()
						var mengenai_sesuatu : bool = raycast_occlusion_culling.is_colliding()
						# jika raycast mengenai pengamat, atur ulang indeks cek titik | objek terlihat
						if mengenai_sesuatu and raycast_occlusion_culling.get_collider().get_parent() == pengamat:
							m_objek.cek_titik = 0
							m_objek.terhalang = false
						# jika raycast terhalang, tambah dan cek jumlah indeks cek titik
						else:
							# jika semua titik terhalang, atur ulang indeks cek titik, non-aktifkan visibilitas objek | objek terhalang
							if m_objek.visible and m_objek.cek_titik == m_objek.titik_sudut.size() - 1:
								m_objek.visible = false
								m_objek.terhalang = true
								m_objek.cek_titik = 0
								# debug
								#Panku.notify(m_objek.name+" terhalang")
							# jika masih ada titik yang belum dicek, tambah indeks cek titik
							else:
								m_objek.cek_titik += 1
						# hentikan exclude raycast dengan m_objek jika m_objek adalah CollisionObject3D
						if m_objek is CollisionObject3D:
							raycast_occlusion_culling.remove_exception(m_objek)
					else:
						m_objek.cek_titik = 0
				elif m_objek.visible == false:
					m_objek.visible = true
