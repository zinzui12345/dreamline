@tool
extends Node3D

# TODO : tambah model pohon
# TODO : kalau draw_calls >= 1000 atau vertex >= 100000 dan fps <= 25, kurangi jarak render pengamat

@export var gunakan_frustum_culling = false
@export var gunakan_occlusion_culling = false
@export var gunakan_level_of_detail = true:
	set(nilai):
		for pt in potongan.size():
			for vg in potongan[pt]["vegetasi"].size():
				var indeks_vegetasi = potongan[pt]["vegetasi"].keys()
				if nilai:
					# aktifkan culling detail vegetasi
					if potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["detail"].is_valid():
						RenderingServer.instance_set_ignore_culling(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["detail"], false)
					# aktifkan visibilitas lod1 dan lod2 vegetasi
					if potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod1"].is_valid():
						RenderingServer.instance_set_visible(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod1"], true)
					if potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod2"].is_valid():
						RenderingServer.instance_set_visible(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod2"], true)
				else:
					if potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["detail"].is_valid():
						RenderingServer.instance_set_ignore_culling(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["detail"], true)
					if potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod1"].is_valid():
						RenderingServer.instance_set_visible(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod1"], false)
					if potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod2"].is_valid():
						RenderingServer.instance_set_visible(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod2"], false)
		gunakan_level_of_detail = nilai
@export var hasilkan_vegetasi = false
@export var hasilkan_fisik = false
@export var hasilkan_potongan = false
@export_range(2, 10, 2) var jumlah_potongan := 4
@export var hasilkan_lod = false
@export_range(10,400, 1) var ukuran := 10
@export var tinggi_maks = 20
@export var titik_offset = 0.5
@export var pengamat : Camera3D :
	set(kamera):
		if is_instance_valid(kamera):
			#posisi_terakhir = kamera.global_transform.origin
			#rotasi_terakhir = kamera.global_rotation_degrees
			pengamat = kamera
			# debug raycast
			#var debug_raycast = raycast_occlusion_culling.duplicate()
			#pengamat.add_child(debug_raycast)
			#debug_raycast.position.z = 5
			#debug_raycast.set_collision_mask_value(32, false)
@export var frekuensi_vegetasi = 0.5
@export var tekstur : Image
@export var potongan = []
@export var vegetasi = []
@export var perbarui = false :
	set(nilai):
		if nilai:
			print("menghasilkan permukaan...")
			hasilkan_terrain()
		perbarui = false
@export var simpan = false :
	set(nilai):
		if nilai: simpan_terrain()
		simpan = false

# data vegetasi
var pohon = [
 "res://skena/objek/pohon_besar_1.scn",
 "res://skena/objek/pohon_besar_2.scn",
 {
	"detail":	load("res://model/alam/pohon2/detail.res"),
 	"lod1": 	load("res://model/alam/pohon2/lod1.res"), 	"jarak_lod1": 	15,
 	"lod2": 	load("res://model/alam/pohon2/lod2.res"), 	"jarak_lod2": 	50
 },
 { 
	"detail": load("res://model/alam/placeholder_pohon.tres"),
	"lod1": null,	"jarak_lod1": 0,
	"lod2": null,	"jarak_lod2": 0
 },
 { 
	"detail": load("res://model/alam/placeholder_pohon.tres"),
	"lod1": null,	"jarak_lod1": 0,
	"lod2": null,	"jarak_lod2": 0
 }
]
var semak = [
 load("res://model/alam/semak1.res"),
 load("res://model/alam/semak2.res"),
 load("res://model/alam/placeholder_semak.tres"),
 load("res://model/alam/placeholder_semak.tres"),
 load("res://model/alam/placeholder_semak.tres")
]
var batu = [
	"res://skena/objek/batu_1.scn",
	"res://skena/objek/batu_2.scn",
	"res://skena/objek/batu_3.scn",
	"res://skena/objek/batu_4.scn",
	"res://skena/objek/batu_5.scn",
	"res://skena/objek/batu_6.scn",
	"res://skena/objek/batu_7.scn",
	"res://skena/objek/batu_8.scn",
	"res://skena/objek/batu_9.scn"
]

var total_pohon = 0
var total_semak = 0
var total_batu = 0
var total_pencemaran = 0
var total_bunga_nektar = 0

var shader_air : MeshInstance3D
var fisik : StaticBody3D
var posisi_terakhir : Vector3
var rotasi_terakhir : Vector3
var arah_target_pengamat : Marker3D
var posisi_relatif_pengamat : Marker3D
var raycast_occlusion_culling : RayCast3D

@onready var scenario = get_world_3d().scenario

func _enter_tree():
	var p_arah_target_pengamat = Node3D.new()
	arah_target_pengamat	= Marker3D.new()
	posisi_relatif_pengamat = Marker3D.new()
	raycast_occlusion_culling = RayCast3D.new()
	add_child(p_arah_target_pengamat)
	p_arah_target_pengamat.add_child(arah_target_pengamat)
	add_child(posisi_relatif_pengamat)
	raycast_occlusion_culling.name = "raycast_occlusion_culling"
	raycast_occlusion_culling.set_collision_mask_value(2, true)
	raycast_occlusion_culling.set_collision_mask_value(3, true)
	raycast_occlusion_culling.set_collision_mask_value(32, true)
	raycast_occlusion_culling.target_position = Vector3(0, 0, -800)
	raycast_occlusion_culling.hit_from_inside = true
	raycast_occlusion_culling.exclude_parent = false
	add_child(raycast_occlusion_culling)
	# debug
	#for rd in 8:
	#	var raycast_debug = raycast_occlusion_culling.duplicate()
	#	raycast_debug.name = "raycast_debug_"+str(rd+1)
	#	add_child(raycast_debug)
	#	raycast_debug.enabled = true
	if Engine.is_editor_hint():
		if get_node_or_null("placeholder_permukaan") == null:
			print("memuat data permukaan")
			if ResourceLoader.exists("res://model/permukaan.scn"):
				var data = load("res://model/permukaan.scn").instantiate()
				data.name = "placeholder_permukaan"
				print("membuat tampilan permukaan")
				$tanah.add_child(data)
func _ready():
	if Engine.is_editor_hint(): pass
	else:
		if is_instance_valid(server.permainan): server.permainan.permukaan = self
		muat_terrain()
		if get_node_or_null("air") != null and get_node_or_null("air/shader_air") != null:
			shader_air = get_node("air/shader_air")
func _process(_delta):
	# jangan cek kalo gak ada
	if pengamat != null:
		# gak usah cull kalau kondisi gak berubah
		if posisi_terakhir.distance_to(pengamat.global_transform.origin) < 0.05 and \
			rotasi_terakhir == pengamat.global_rotation_degrees: # TODO : coba bandingkan rotasi apakah perbedaannya kurang dari 2.5 derajat
			return
		else:
			posisi_terakhir = pengamat.global_transform.origin
			rotasi_terakhir = pengamat.global_rotation_degrees
		
		# pastiin jumlah chunk lebih dari 0
		if potongan.size() > 0:
			for pt in potongan.size():
				var posisi = {
					'x': potongan[pt]["start_x"],
					'y': potongan[pt]["start_y"]
				}
				var batas = {
					'x': potongan[pt]["lebar_x"],
					'y': potongan[pt]["lebar_y"]
				}
				var posisi_pengamat : Vector3
				
				# hitung posisi relatif pengamat berdasarkan posisi globalnya
				if posisi_relatif_pengamat != null:
					posisi_relatif_pengamat.global_transform.origin = pengamat.global_transform.origin
					posisi_pengamat = posisi_relatif_pengamat.position
				else:
					posisi_pengamat = pengamat.position
				
				# cek pengamat mengarah kemana?, potongan mana saja yang harus visible dan invisible?
				if get_node_or_null("tanah/bentuk_" + potongan[pt]["indeks"]) != null:
					if gunakan_frustum_culling:
						# kalo pengamat berada pada potongan, render potongan tersebut
						if posisi_pengamat.x >= posisi.x and posisi_pengamat.x <= (posisi.x + batas.x) and \
							posisi_pengamat.z >= posisi.y and posisi_pengamat.z <= (posisi.y + batas.y):
							
							get_node("tanah/bentuk_" + potongan[pt]["indeks"]).visible = true
							atur_fisik_potongan(pt, true)
							
							#get_parent().get_node("debug_pos_chunk").transform.origin = Vector3(
							#	potongan[pt]["pusat_x"],
							#	0,
							#	potongan[pt]["pusat_y"]
							#)
							potongan[pt]["m_render"] = "detail"
						
						# hanya render potongan yang terlihat di pandangan pengamat
						else:
							var potongan_node = get_node("tanah/bentuk_" + potongan[pt]["indeks"])
							
							# atur arah arah_target_pengamat ke potongan_node dengan look_at()
							# tentukan batas sudut arah_target_pengamat berdasarkan jarak titik tengah potongan_node
							# kalau misalnya >= 90, non-aktifkan visibilitas potongan_node
							# selain itu aktifkan.
							# 20/08/2023 :: metode ini kutemukan sendiri gatau apa namanya, aku menyebutnya direction culling
							# + dibandingkan dengan frustum culling, metode ini menggunakan lebih sedikit instruksi pada CPU
							# + aku membuat metode ini sepenuhnya dengan hati tanpa bantuan AI kecuali baca dokumentasi
							# - metode ini gak berguna kalau bounding box objek yang ingin di cull != 1:1 atau > 1:4
							# * metode ini akan jauh lebih optimal lagi kalau digabung dengan RenderingServer dan diproses pada Thread
							
							# mendapatkan posisi tengah potongan
							var potongan_tengah = Vector3(
								potongan[pt]["pusat_x"],
								0,
								potongan[pt]["pusat_y"]
							)
							
							# menghitung jarak antara kamera dan potongan
							var jarak_render = posisi_pengamat.distance_to(potongan_tengah)
							
							# mengarahkan arah_target_pengamat dari kamera ke potongan
							if arah_target_pengamat != null:
								arah_target_pengamat.get_parent().position = posisi_pengamat
								arah_target_pengamat.get_parent().global_rotation_degrees = pengamat.global_rotation_degrees
								arah_target_pengamat.look_at(
									potongan_tengah, 
									Vector3.UP,
									false
								)
							 
							# menghitung sudut antara vektor arah_pandang dan posisi potongan
							if arah_target_pengamat != null:
								var sudut = abs(arah_target_pengamat.rotation_degrees.y)
								var jarak = max(potongan[pt]["lebar_x"], potongan[pt]["lebar_y"])
								
								if (jarak_render <= (jarak * 2)):
									if sudut <= (pengamat.fov * 1.1):
										if !potongan_node.visible:
											potongan_node.visible = true
											atur_fisik_potongan(pt, true)
									elif jarak_render >= jarak and potongan_node.visible:
										potongan_node.visible = false
										atur_fisik_potongan(pt, false)
										potongan[pt]["m_render"] = "cull"
								elif potongan_node.visible:
									potongan_node.visible = false
									atur_fisik_potongan(pt, false)
									potongan[pt]["m_render"] = ""
								arah_target_pengamat.rotation_degrees.y = 0
					else:
						if !get_node("tanah/bentuk_" + potongan[pt]["indeks"]).visible:
							get_node("tanah/bentuk_" + potongan[pt]["indeks"]).visible = true
							atur_fisik_potongan(pt, true)
						potongan[pt]["m_render"] = "detail"
		
		# posisikan shader air (kalau ada) mengikuti posisi horizontal pengamat
		if shader_air != null:
			shader_air.global_position.x = pengamat.global_position.x
			shader_air.global_position.z = pengamat.global_position.z
			shader_air.get_surface_override_material(0).set_shader_parameter(
				"posisi_offset",
				Vector2(
					-shader_air.position.x,
					-shader_air.position.z
				)
			)
func _exit_tree():
	if Engine.is_editor_hint():
		if $tanah.get_node_or_null("placeholder_permukaan") != null:
			print("menghapus tampilan permukaan")
			var tmp = $tanah.get_node("placeholder_permukaan")
			$tanah.remove_child(tmp)
			tmp.queue_free()

func hasilkan_terrain():
	var arr_mesh = ArrayMesh.new()
	var surftool = SurfaceTool.new()
	var posisi_vegetasi = []
	
	# hapus child
	if get_child_count() > 0:
		print("menghapus terrain sebelumnya")
		for i in get_children():
			i.free()
	
	# buat noise dari gambar
	print("membuat noise dari gambar")
	var gambar_tekstur = ImageTexture.create_from_image(tekstur)
	var gambar_noise : Image = gambar_tekstur.get_image()
	
	# buat vertex
	print("menghasilkan vertex dari pixel")
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	if hasilkan_vegetasi:
		vegetasi = []
		print("menempatkan vegetasi")
	for y in gambar_noise.get_height()+1:
		for x in gambar_noise.get_width()+1:
			# dapatkan warna dari pixel
			var warna_pixel : Color
			var tmp_px_x = x; var tmp_px_y = y
			if tmp_px_x >= gambar_noise.get_width(): tmp_px_x = gambar_noise.get_width() - 1
			if tmp_px_y >= gambar_noise.get_width(): tmp_px_y = gambar_noise.get_width() - 1
			warna_pixel = gambar_noise.get_pixel(tmp_px_x, tmp_px_y)

			# konversi warna pixel ke nilai noise (misal., menggunakan grayscale)
			var nilai_grayscale = (warna_pixel.r + warna_pixel.g + warna_pixel.b) / 3.0

			# terapkan nilai ke terrain
			var jarak = Vector2(x,y) / ((gambar_noise.get_width() * 0.15) / (128 * 0.15)) # resolusi (512px sama dengan 1.280m atau 1.28km)
			var titik_jari_jari = Vector3(
				jarak.x - ((gambar_noise.get_width() / ((gambar_noise.get_width() * 0.15) / (128 * 0.15))) * titik_offset),
				0,
				jarak.y - ((gambar_noise.get_height() / ((gambar_noise.get_height() * 0.15) / (128 * 0.15))) * titik_offset)
			)
			
			var vertex : Vector3 = titik_jari_jari * ukuran;
			vertex.y = nilai_grayscale * tinggi_maks
			var uv = Vector2()
			uv.x = jarak.x
			uv.y = jarak.y
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)
			
			# tentukan penempatan vegetasi
			if hasilkan_vegetasi:
				if randf() < float(frekuensi_vegetasi)/10 and vertex.y >= float(tinggi_maks)/10:  # hanya berada pada rumput | frekuensi penempatan vegetasi (0.5)
					posisi_vegetasi.append(Vector3(vertex.x, vertex.y, vertex.z))
	
	# tentukan total tiap tipe vegetasi
	total_pohon = posisi_vegetasi.size() * 0.5
	total_semak = posisi_vegetasi.size() * 0.22
	total_batu  = posisi_vegetasi.size() * 0.2
	#total_pencemaran   = posisi_vegetasi.size() * 0.05
	#total_bunga_nektar = posisi_vegetasi.size() * 0.03
	
	# tempatkan vegetasi
	for vg in posisi_vegetasi.size(): tempatkan_vegetasi(posisi_vegetasi[vg])
	
	# buat face
	print("membuat surface")
	var vert = 0
	for y in range(gambar_noise.get_height()):
		for x in range(gambar_noise.get_width()):
			surftool.add_index(vert+0)
			surftool.add_index(vert+1)
			surftool.add_index(vert+gambar_noise.get_height()+1)
			surftool.add_index(vert+gambar_noise.get_height()+1)
			surftool.add_index(vert+1)
			surftool.add_index(vert+gambar_noise.get_height()+2)
			vert+=1
		vert+=1
	
	# terapkan titik
	print("menerapkan titik vertex")
	surftool.generate_normals()
	arr_mesh = surftool.commit()
	
	# terapkan bentuk dan material
	print("menghasilkan bentuk dan material")
	var bentuk = MeshInstance3D.new()
	$tanah.add_child(bentuk)
	bentuk.name = "bentuk"
	bentuk.mesh = arr_mesh
	bentuk.material_override = load("res://material/permukaan.material")
	var mat = bentuk.get_active_material(0)
	mat.set_shader_parameter("ketinggian_pasir_basah", 3)
	mat.set_shader_parameter("ketinggian_rumput",4)
	mat.set_shader_parameter("ketinggian_akhir_pasir",5)
	
	# buat fisik
	if hasilkan_fisik:
		print("membuat bentuk fisik")
		bentuk.create_trimesh_collision()
		fisik = bentuk.get_child(0)
		fisik.name = "fisik"
		bentuk.remove_child(fisik)
		$tanah.add_child(fisik)
	
	# potong menjadi beberapa bagian
	if hasilkan_potongan:
		self.potongan = []
		if is_instance_valid(fisik) and fisik.get_child_count() > 0: fisik.remove_child(fisik.get_child(0))
		print("memotong bentuk : 4 * 4 => 16")
		slice_terrain(gambar_noise, mat)

func simpan_terrain():
	var packed_scene 	= PackedScene.new()
	var node 			= Node3D.new()
	get_parent().get_parent().add_child(node, true)
	for data in get_children():
		var data_asal = data.duplicate(8)
		node.add_child(data_asal, true)
		data_asal.set_owner(node)
		for indeks_child in data_asal.get_child_count():
			data_asal.get_child(indeks_child).set_owner(node)
	node.name = "permukaan"
	print("menyimpan terrain")
	print(packed_scene.pack(node))
	#print_debug(node.get_children())
	ResourceSaver.save(packed_scene, "res://model/permukaan.scn")
	get_parent().get_parent().remove_child(node)
	node.queue_free()
func ekspor_terrain():
	var packed_scene 	= PackedScene.new()
	var node 			= Node3D.new()
	get_parent().get_parent().add_child(node, true)
	for data in get_children():
		var data_asal = data.duplicate(8)
		node.add_child(data_asal, true)
		data_asal.set_owner(node)
		for indeks_child in data_asal.get_child_count():
			data_asal.get_child(indeks_child).set_owner(node)
	node.name = "permukaan"
	print("mengekspor terrain [res://model/permukaan_e.scn]")
	print(packed_scene.pack(node))
	#print_debug(node.get_children())
	ResourceSaver.save(packed_scene, "res://model/permukaan_e.scn")
	get_parent().get_parent().remove_child(node)
	node.queue_free()

func muat_terrain():
	print("memuat data permukaan")
	if ResourceLoader.exists("res://model/permukaan.scn"):
		var data = load("res://model/permukaan.scn").instantiate()
		for isi_data in data.get_children():
			$tanah.add_child(isi_data.duplicate())
		data.queue_free()
		
		if vegetasi.size() > 0:
			var potongan_yang_memiliki_vegetasi = []
			var total_spawner = {
				"pencemaran": 0,
				"bunga_nektar": 0
			}
			
			print("menghasilkan vegetasi")
			for v in vegetasi.size():
				var posisi_vegetasi = vegetasi[v]["posisi"]
				if potongan.size() > 0:
					for pt in potongan.size():
						var posisi = {
							'x' : potongan[pt]["start_x"],
							'y' : potongan[pt]["start_y"]
						}
						var batas = {
							'x' : potongan[pt]["lebar_x"],
							'y' : potongan[pt]["lebar_y"]
						}
						
						if posisi_vegetasi.x >= posisi.x and posisi_vegetasi.x <= (posisi.x + batas.x): pass
						else: continue
						if posisi_vegetasi.z >= posisi.y and posisi_vegetasi.z <= (posisi.y + batas.y): pass
						else: continue
						
						if is_instance_valid(server.permainan) and server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
							match vegetasi[v]["tipe"]:
								"batu":
									var model_vegetasi = load(batu[vegetasi[v]["model"]])
									var instance_vegetasi = model_vegetasi.instantiate()
									instance_vegetasi.transform.origin = vegetasi[v]["posisi"]
									instance_vegetasi.transform.basis = vegetasi[v]["rotasi"]
									add_child(instance_vegetasi)
								"pohon":
									if pohon[vegetasi[v]["model"]] is String:
										var model_vegetasi = load(pohon[vegetasi[v]["model"]])
										var instance_vegetasi = model_vegetasi.instantiate()
										instance_vegetasi.transform.origin = vegetasi[v]["posisi"]
										instance_vegetasi.transform.basis = vegetasi[v]["rotasi"]
										add_child(instance_vegetasi)
	else: print("tidak ada data permukaan")

func slice_terrain(gambar_noise, material):
	# Hapus child bentuk yang ada sebelumnya
	if $tanah.has_node("bentuk"): $tanah.get_node("bentuk").queue_free()

	# Mendapatkan mesh yang ada pada terrain
	var terrain_mesh = $tanah/bentuk.mesh
	var terrain_surface = terrain_mesh.surface_get_arrays(0)

	# Mendapatkan informasi resolusi gambar
	var gambar_res_x = gambar_noise.get_width()
	var gambar_res_y = gambar_noise.get_height()

	# Menghitung jumlah slice pada setiap dimensi (misalnya 3x3)
	var slice_res_x = floor(gambar_res_x / jumlah_potongan)
	var slice_res_y = floor(gambar_res_y / jumlah_potongan)

	# Loop untuk membuat setiap slice
	for y in range(jumlah_potongan):
		for x in range(jumlah_potongan):
			var nama_potongan = str(y+1)+'_'+str(x+1)
			print("menghasilkan bentuk potongan [%s][%s]" % [str(y+1), str(x+1)])
			var new_mesh = _buat_bagian_potongan(
				terrain_surface,
				x * slice_res_x, y * slice_res_y,
				slice_res_x, slice_res_y,
				nama_potongan,
				gambar_noise
			)
			var new_instance = MeshInstance3D.new()
			new_instance.name = "bentuk_" + nama_potongan
			new_instance.mesh = new_mesh
			new_instance.material_override = material
			new_instance.lod_bias = 2.0
			print("menambahkan bentuk potongan")
			$tanah.add_child(new_instance)
			
			# INFO : buat fisik chunk
			if hasilkan_fisik:
				print("membuat fisik potongan [%s][%s]" % [str(y+1), str(x+1)])
				new_instance.create_trimesh_collision()
				var tmp_fisik = new_instance.get_child(0) 	# StaticBody
				var tmp_m_fisik = tmp_fisik.get_child(0)	# CollisionShape3D
				tmp_m_fisik.name = "fisik_" + nama_potongan
				tmp_fisik.remove_child(tmp_m_fisik)
				print("menambahkan fisik potongan [%s][%s]" % [str(y+1), str(x+1)])
				fisik.add_child(tmp_m_fisik)
				tmp_fisik.queue_free()
func _buat_bagian_potongan(terrain_surface, start_x, start_y, res_x, res_y, bagian_potongan, gambar_noise):
	var slice_mesh = ArrayMesh.new()
	var surftool = SurfaceTool.new()
	var data_potongan = {}
	var skala_aktual = 2.5 # ???
	
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	data_potongan["indeks"]  = bagian_potongan
	data_potongan["start_x"] = (start_x - (gambar_noise.get_width() / 2)) * skala_aktual
	data_potongan["start_y"] = (start_y - (gambar_noise.get_height() / 2))* skala_aktual
	data_potongan["lebar_x"] = res_x * skala_aktual
	data_potongan["lebar_y"] = res_y * skala_aktual
	data_potongan["pusat_x"] = data_potongan["start_x"] + (data_potongan["lebar_x"] / 2)
	data_potongan["pusat_y"] = data_potongan["start_y"] + (data_potongan["lebar_y"] / 2)
	data_potongan["vegetasi"]= {}
	potongan.append(data_potongan)
	
	for z in range(start_y, start_y + res_y + 1):
		for x in range(start_x, start_x + res_x + 1):
			var vertex_index = z * (gambar_noise.get_width() + 1) + x
			var vertex = terrain_surface[Mesh.ARRAY_VERTEX][vertex_index]
			var uv = terrain_surface[Mesh.ARRAY_TEX_UV][vertex_index]
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)
			
			#if hasilkan_vegetasi:
			#	for vg in vegetasi.size(): gak recomended karena bakal lama banget kalau cek tiap vegetasi di tiap titik
			#		if vegetasi[vg]["posisi"] == vertex:
			#			vegetasi[vg]["chunk"] = potongan

	var vert = 0
	for z in range(start_y, start_y + res_y):
		for x in range(start_x, start_x + res_x):
			var base_vertex = vert
			surftool.add_index(base_vertex)
			surftool.add_index(base_vertex + 1)
			surftool.add_index(base_vertex + res_y + 1)
			surftool.add_index(base_vertex + res_y + 1)
			surftool.add_index(base_vertex + 1)
			surftool.add_index(base_vertex + res_y + 2)
			vert += 1
		vert += 1
	
	print("menghasilkan bentuk potongan")
	surftool.generate_normals()
	
	# LOD
	if hasilkan_lod:
		print("menghasilkan LOD")
		slice_mesh = surftool.commit_to_arrays()
		var importer := ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, slice_mesh)
		importer.generate_lods(25.0, 25.0, [])
		return importer.get_mesh()
	else:
		slice_mesh = surftool.commit()
		return slice_mesh

func tempatkan_vegetasi(posisi : Vector3):
	var tipe_vegetasi = randi() % 5  # Pohon, Semak, Batu, Pencemaran, Bunga Nektar
	var array_model = []
	var data_vegetasi = {}
	
	match tipe_vegetasi:
		0: array_model = pohon; data_vegetasi["tipe"] = "pohon";
		1: array_model = semak; data_vegetasi["tipe"] = "semak";
		2: array_model = batu; 	data_vegetasi["tipe"] = "batu";
		3: 						data_vegetasi["tipe"] = "pencemaran";
		4: 						data_vegetasi["tipe"] = "bunga_nektar";

	if array_model.size() > 0:
		var indeks_model = randi() % array_model.size()
		if tipe_vegetasi == 0:
			if total_pohon <= 0:	tempatkan_vegetasi(posisi); return
			else:					total_pohon -= 1
		elif tipe_vegetasi == 1:
			if total_semak <= 0:	tempatkan_vegetasi(posisi); return
			else:					total_semak -= 1
		elif tipe_vegetasi == 2:
			if total_batu <= 0:		tempatkan_vegetasi(posisi); return
			else:					total_batu -= 1
		data_vegetasi["model"] 	= indeks_model
		data_vegetasi["rotasi"] = Basis(Vector3(0, 1, 0), deg_to_rad(randf_range(0, 360)))
		
	if data_vegetasi.get("tipe") != null:
		data_vegetasi["posisi"] = posisi
		vegetasi.append(data_vegetasi)
func atur_fisik_potongan(id_potongan : int, nilai : bool):
	if is_instance_valid(server.permainan) and server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: pass
	else: get_node("tanah/fisik/fisik_" + potongan[id_potongan]["indeks"]).disabled = !nilai
