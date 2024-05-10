extends Node3D

var arah_target_pengamat : Marker3D
var posisi_relatif_pengamat : Node3D

# Mulai modus server
func _ready():
	var argumen : Array = OS.get_cmdline_args() # ["res://skena/dreamline.tscn", "--server", "empty"]
	var jumlah_argumen  = argumen.size()
	for arg in jumlah_argumen:
		if argumen[arg] == "--server":
			server.publik = true
			if arg < jumlah_argumen - 2 and argumen[arg+1] != "" and argumen[arg+2] != "":
				server.permainan.atur_map(argumen[arg+1])
				server.permainan.mulai_server(true, argumen[arg+2]);
				return
			elif arg < jumlah_argumen - 1 and argumen[arg+1] != "":
				server.permainan.atur_map(argumen[arg+1])
			server.permainan.mulai_server(true);
			return

	posisi_relatif_pengamat = Node3D.new()
	arah_target_pengamat	= Marker3D.new()
	arah_target_pengamat.name = "arah target pengamat"
	posisi_relatif_pengamat.name = "posisi relatif pengamat"
	add_child(posisi_relatif_pengamat)
	posisi_relatif_pengamat.add_child(arah_target_pengamat)

func hapus_map():
	if get_node_or_null("lingkungan") != null:
		get_node("lingkungan").queue_free()
	server.permainan.map.free()
	if $entitas.get_child_count() > 0:
		for _entitas in $entitas.get_children():
			_entitas.queue_free()
	if $objek.get_child_count() > 0:
		for _objek in $objek.get_children():
			_objek.queue_free()
func hapus_instance_pemain():
	var jumlah_pemain = $pemain.get_child_count()
	for p in jumlah_pemain:
		#print_debug("menghapus pemain [%s/%s]" % [jumlah_pemain-p, jumlah_pemain])
		$pemain.get_child(jumlah_pemain - (p + 1)).queue_free()

# Optimasi rendering | Object Culling
func _process(delta):
	if is_instance_valid(server.permainan.karakter) and $objek.get_child_count() > 0:
		# dapatkan kamera (pengamat) karakter
		var pengamat : Camera3D = server.permainan.karakter.get_node("pengamat/%pandangan")
		
		# loop setiap objek
		for m_objek in $objek.get_children():
			# Direction Culling / Frustum Culling
			if server.permainan.karakter.get_node("PlayerInput").gunakan_frustum_culling:
				# dapatkan posisi global kamera
				var posisi_pengamat : Vector3 = pengamat.global_position
				
				# dapatkan posisi global kamera
				var posisi_objek : Vector3 = m_objek.global_position
				
				# kalkulasi jarak kamera dengan objek
				var jarak_objek = posisi_pengamat.distance_to(posisi_objek)
				
				# jika jarak kamera dengan objek lebih dari jarak render objek * 0.5
				if jarak_objek > (m_objek.jarak_render * 0.5):
					# atur posisi dan rotasi posisi_relatif_pengamat dengan posisi dan rotasi pengamat
					posisi_relatif_pengamat.global_position = pengamat.global_position
					posisi_relatif_pengamat.global_rotation_degrees = pengamat.global_rotation_degrees
					arah_target_pengamat.look_at(
						posisi_objek, 
						Vector3.UP,
						false
					)
					
					# kalkulasi sudut arah_target_pengamat
					var sudut = abs(arah_target_pengamat.rotation_degrees.y)
					
					# cek arah ke objek apakah objek berada di belakang kamera
					if sudut > (pengamat.fov * 1.125):
						# non-aktifkan visibilitas objek
						m_objek.visible = false
					else:
						# aktifkan visibilitas objek
						m_objek.visible = true
				
				# debug
				#Panku.notify(abs(arah_target_pengamat.rotation_degrees.y))
			
			# Occlusion Culling
			if m_objek.visible and server.permainan.karakter.get_node("PlayerInput").gunakan_occlusion_culling:
				pass
