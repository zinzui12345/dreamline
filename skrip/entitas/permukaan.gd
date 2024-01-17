@tool
extends Node3D

# FIXME : jangan disable fisik chunk yang di-cull pada server
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
			var tmp_bb_fisik_pengamat = BoxShape3D.new()
			var tmp_b_fisik_pengamat = CollisionShape3D.new()
			var tmp_fisik_pengamat = StaticBody3D.new()
			tmp_fisik_pengamat.name = "target_raycast_culling"
			kamera.add_child(tmp_fisik_pengamat)
			tmp_fisik_pengamat.set_collision_layer_value(1, false)
			tmp_fisik_pengamat.set_collision_layer_value(32, true)
			tmp_b_fisik_pengamat.name = "fisik"
			tmp_b_fisik_pengamat.shape = tmp_bb_fisik_pengamat
			tmp_fisik_pengamat.add_child(tmp_b_fisik_pengamat)
			tmp_bb_fisik_pengamat.size = Vector3(0.5, 0.5, 0.5)
			posisi_terakhir = kamera.global_transform.origin
			rotasi_terakhir = kamera.global_rotation_degrees
			pengamat = kamera
@export var frekuensi_vegetasi = 0.5
@export var tekstur : Image
@export var potongan = []
@export var vegetasi = []
@export var hapus_rid_vegetasi = false :
	set(nilai):
		if nilai:
			hapus_rid()
		hapus_rid_vegetasi = false
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
 {
 	"detail":	load("res://model/alam/pohon1/detail.res"),
 	"lod1": 	load("res://model/alam/pohon1/lod1.res"), 	"jarak_lod1": 	20,
 	"lod2": 	load("res://model/alam/pohon1/lod2.res"), 	"jarak_lod2": 	50
 },
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
 load("res://model/alam/placeholder_batu.tres"),
 load("res://model/alam/placeholder_batu.tres"),
 load("res://model/alam/placeholder_batu.tres"),
 load("res://model/alam/placeholder_batu.tres"),
 load("res://model/alam/placeholder_batu.tres")
]

var total_pohon = 0
var total_semak = 0
var total_batu = 0
var total_pencemaran = 0
var total_bunga_nektar = 0

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
	raycast_occlusion_culling.target_position = Vector3(0, 0, -400)
	add_child(raycast_occlusion_culling)
func _ready():
	if Engine.is_editor_hint(): pass
	else:
		if is_instance_valid(server.permainan): server.permainan.permukaan = self
		muat_terrain()
func _process(_delta):
	# jangan cek kalo gak ada
	if pengamat != null:
		# gak usah cull kalau kondisi gak berubah
		if posisi_terakhir == pengamat.global_transform.origin and \
			rotasi_terakhir == pengamat.global_rotation_degrees:
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
				if get_node_or_null("bentuk_" + potongan[pt]["indeks"]) != null:
					if gunakan_frustum_culling:
						# kalo pengamat berada pada potongan, render potongan tersebut
						if posisi_pengamat.x >= posisi.x and posisi_pengamat.x <= (posisi.x + batas.x) and \
							posisi_pengamat.z >= posisi.y and posisi_pengamat.z <= (posisi.y + batas.y):
							
							get_node("bentuk_" + potongan[pt]["indeks"]).visible = true
							get_node("fisik/fisik_" + potongan[pt]["indeks"]).disabled = false
							
							#get_parent().get_node("debug_pos_chunk").transform.origin = Vector3(
							#	potongan[pt]["pusat_x"],
							#	0,
							#	potongan[pt]["pusat_y"]
							#)
							potongan[pt]["m_render"] = "detail"
							
							atur_visibilitas_lod_potongan_vegetasi(pt, false)
							atur_visibilitas_vegetasi_potongan(pt, posisi_pengamat, pengamat.global_rotation, pengamat.fov)
						
						# hanya render potongan yang terlihat di pandangan pengamat
						else:
							var potongan_node = get_node("bentuk_" + potongan[pt]["indeks"])
							var potongan_fisik = get_node("fisik/fisik_" + potongan[pt]["indeks"])
							
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
											potongan_fisik.disabled = false
										if jarak_render < jarak:
											atur_visibilitas_potongan_vegetasi(pt, true)
											atur_visibilitas_lod_potongan_vegetasi(pt, false)
											potongan[pt]["m_render"] = "lod"
										else:
											atur_visibilitas_potongan_vegetasi(pt, false)
											atur_visibilitas_lod_potongan_vegetasi(pt, true)
											potongan[pt]["m_render"] = "gpu instance"
											if gunakan_occlusion_culling and potongan[pt].get("aabb") != null:
												var aabb_instance = potongan[pt]["aabb"]
												
												# dapatkan aabb instance lod vegetasi
												# loop tiap posisi aabb :
												# - atur posisi raycast ke posisi sudut aabb
												# - arahkan raycast ke pengamat
												# - dapatkan objek yang terkena raycast:
												# - - jika objek raycast adalah pengamat, hentikan proses eksekusi | return
												# non-aktifkan visibilitas instance lod vegetasi.
												# 15/01/24 :: occlusion culling mengecek kedalaman (depth) tiap pixel, itu cukup rumit pada hardware rendah, apalagi jika terdapat banyak objek
												# ^ sama seperti frustum culling, metode ini meng-kalkulasi (axis-aligned bounding box) AABB / (bounding box) dari suatu objek
												# + dibandingkan dengan occlusion culling aslinya, metode ini menggunakan lebih sedikit instruksi pada CPU
												# - tetapi visibilitas objek kurang akurat, kadang tetap di-render walau semestinya tidak terlihat
												
												# FIXME : jangan pake loop, karena gak bisa di-jeda | pake fungsi yang saling memanggil!
												for titik in 8:
													raycast_occlusion_culling.global_position = aabb_instance[titik]
													raycast_occlusion_culling.look_at(pengamat.global_position)
													Panku.notify(str(titik)+" => aktifkan raycast")
													raycast_occlusion_culling.enabled = true
													await get_tree().create_timer(0.5).timeout # FIXME : proses gak berurut!
													if raycast_occlusion_culling.is_colliding():
														var objek_raycast = raycast_occlusion_culling.get_collider()
														if objek_raycast.get_parent() == pengamat:
															Panku.notify(str(titik)+" => kena cuyy")
															return # harusnya loop berhenti dan baris 288 udah gak ke-eksekusi karena vegetasi udah terlihat
													# setelah selesai, atur raycast enabled menjadi false
													raycast_occlusion_culling.enabled = false
													Panku.notify(str(titik)+" => matikan raycast")
												gunakan_occlusion_culling = false # debug
												Panku.notify("ini ke-print gak?")
									elif jarak_render >= jarak and potongan_node.visible:
										potongan_node.visible = false
										potongan_fisik.disabled = true
										atur_visibilitas_potongan_vegetasi(pt, false)
										atur_visibilitas_lod_potongan_vegetasi(pt, false)
										potongan[pt]["m_render"] = "cull"
								elif potongan_node.visible:
									potongan_node.visible = false
									potongan_fisik.disabled = true
									atur_visibilitas_potongan_vegetasi(pt, false)
									atur_visibilitas_lod_potongan_vegetasi(pt, false)
									potongan[pt]["m_render"] = ""
								arah_target_pengamat.rotation_degrees.y = 0
					else:
						if !get_node("bentuk_" + potongan[pt]["indeks"]).visible:
							get_node("bentuk_" + potongan[pt]["indeks"]).visible = true
							get_node("fisik/fisik_" + potongan[pt]["indeks"]).disabled = false
						atur_visibilitas_potongan_vegetasi(pt, true)
						atur_visibilitas_lod_potongan_vegetasi(pt, false)
						potongan[pt]["m_render"] = "detail"
func _exit_tree():
	hapus_vegetasi()

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
		if vegetasi.size() > 0: hapus_vegetasi(); hapus_rid()
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
			#if y == 0: print_debug(
			#	jarak.x - ((gambar_noise.get_width() / ((gambar_noise.get_width() * 0.15) / (128 * 0.15))) * titik_offset)
			#)
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
	total_pencemaran   = posisi_vegetasi.size() * 0.05
	total_bunga_nektar = posisi_vegetasi.size() * 0.03
	
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
	add_child(bentuk)
	bentuk.name = "bentuk"
	bentuk.mesh = arr_mesh
	bentuk.material_override = load("res://material/permukaan.material")
	var mat = bentuk.get_active_material(0)
	mat.set_shader_parameter("min_height",0)
	mat.set_shader_parameter("max_height",1)
	
	# buat fisik
	if hasilkan_fisik:
		print("membuat bentuk fisik")
		bentuk.create_trimesh_collision()
		fisik = bentuk.get_child(0)
		fisik.name = "fisik"
		bentuk.remove_child(fisik)
		add_child(fisik)
	
	# potong menjadi beberapa bagian
	if hasilkan_potongan:
		self.potongan = []
		if is_instance_valid(fisik) and fisik.get_child_count() > 0: fisik.remove_child(fisik.get_child(0))
		print("memotong bentuk : 4 * 4 => 16")
		slice_terrain(gambar_noise, mat)
func hapus_vegetasi():
	print("menghapus vegetasi permukaan")
	for pt in potongan.size():
		var indeks_vegetasi = potongan[pt]["vegetasi"].keys()
		var indeks_instance_vegetasi = potongan[pt]["instance"].keys()
		for vg in potongan[pt]["vegetasi"].size():
			RenderingServer.free_rid(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["detail"])
			RenderingServer.free_rid(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod1"])
			RenderingServer.free_rid(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod2"])
		for ld2 in potongan[pt]["instance"].size():
			RenderingServer.free_rid(potongan[pt]["instance"][indeks_instance_vegetasi[ld2]]["instance"])
			RenderingServer.free_rid(potongan[pt]["instance"][indeks_instance_vegetasi[ld2]]["multimesh"])
func hapus_rid():
	print("menghapus rid vegetasi")
	for pt in potongan.size():
		potongan[pt]["instance"].clear()
		potongan[pt]["vegetasi"].clear()

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
			add_child(isi_data.duplicate())
		data.queue_free()
		if vegetasi.size() > 0:
			print("menghasilkan vegetasi")
			for v in vegetasi.size():
				var instance : RID = RenderingServer.instance_create()
				var instance_lod1 : RID; var instance_lod2 : RID
				var detail; var lod1; var lod2;
				var jarak_lod1 = 25; var jarak_lod2 = 45
				var jarak_render = 400; var transisi_render = 1;
				var posisi_vegetasi = vegetasi[v]["posisi"]
				
				match vegetasi[v]["tipe"]:
					"pohon":
						detail	= pohon[vegetasi[v]["model"]]["detail"];
						lod1 	= pohon[vegetasi[v]["model"]]["lod1"];	jarak_lod1 = pohon[vegetasi[v]["model"]]["jarak_lod1"];
						lod2 	= pohon[vegetasi[v]["model"]]["lod2"];	jarak_lod2 = pohon[vegetasi[v]["model"]]["jarak_lod2"];
					"semak": detail = semak[vegetasi[v]["model"]];  jarak_render = 50; transisi_render = 10
					"batu":  detail = batu[vegetasi[v]["model"]];	jarak_render = 25; transisi_render = 5
				var xform = Transform3D(vegetasi[v]["rotasi"], posisi_vegetasi)
				
				RenderingServer.instance_set_scenario(instance, scenario)
				RenderingServer.instance_set_base(instance, detail)
				RenderingServer.instance_geometry_set_visibility_range(instance, 0, jarak_render, 0, transisi_render, RenderingServer.VISIBILITY_RANGE_FADE_DEPENDENCIES)
				RenderingServer.instance_set_transform(instance, xform)
				
				if is_instance_valid(lod1):
					instance_lod1 = RenderingServer.instance_create2(lod1, scenario)
					RenderingServer.instance_attach_object_instance_id(instance, instance_lod1.get_id())
					RenderingServer.instance_geometry_set_visibility_range(
						instance,
						0, 					# begin
						jarak_lod1,			# end
						0,					# begin margin
						transisi_render,	# end margin
						RenderingServer.VISIBILITY_RANGE_FADE_DEPENDENCIES
					)
					RenderingServer.instance_geometry_set_visibility_range(
						instance_lod1,
						jarak_lod1, 		# begin
						jarak_lod2,			# end
						transisi_render,	# begin margin
						transisi_render,	# end margin
						RenderingServer.VISIBILITY_RANGE_FADE_DEPENDENCIES
					)
					RenderingServer.instance_set_transform(instance_lod1, xform)
					#RenderingServer.instance_set_ignore_culling(instance_lod1, true)
				if is_instance_valid(lod2):
					instance_lod2 = RenderingServer.instance_create2(lod2, scenario)
					RenderingServer.instance_attach_object_instance_id(instance, instance_lod2.get_id())
					RenderingServer.instance_geometry_set_visibility_range(
						instance_lod2,
						jarak_lod2, 			# begin
						jarak_lod2+jarak_render,# end
						transisi_render,		# begin margin
						transisi_render,		# end margin
						RenderingServer.VISIBILITY_RANGE_FADE_DEPENDENCIES
					)
					RenderingServer.instance_set_transform(instance_lod2, xform)
				
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
						
						potongan[pt]["vegetasi"][v] = {
							"terlihat":	true,
							"detail":	instance,
							"lod1":		instance_lod1,
							"lod2":		instance_lod2
						}
			
			# @ 04/01/24 : buat MeshInstance3D gabungan dari lod2 sebagai lod3 | GPU Instancing
			if potongan.size() > 0:
				for pt in potongan.size():
					potongan[pt]["instance"] = {}
					if potongan[pt]["vegetasi"].size() > 0:
						var indeks_vegetasi = potongan[pt]["vegetasi"].keys()
						for v in potongan[pt]["vegetasi"].size():
							if vegetasi[indeks_vegetasi[v]]["tipe"] == "pohon" and pohon[vegetasi[indeks_vegetasi[v]]["model"]]["lod2"] != null: # hanya pohon yang bisa terlihat dari kejauhan
								var indeks = vegetasi[indeks_vegetasi[v]]["tipe"]+"_"+str(vegetasi[indeks_vegetasi[v]]["model"])
								var mesh_lod2 : RID = pohon[vegetasi[indeks_vegetasi[v]]["model"]]["lod2"]
								var multimesh : RID
								
								if potongan[pt]["instance"].get(indeks) == null:
									multimesh = RenderingServer.multimesh_create()
									var instance : RID = RenderingServer.instance_create()
									
									RenderingServer.instance_set_base(instance, multimesh)
									RenderingServer.instance_set_scenario(instance, scenario)
									RenderingServer.multimesh_set_mesh(multimesh, mesh_lod2)
									
									potongan[pt]["m_render"] = "detail"
									potongan[pt]["instance"][indeks] = {}
									potongan[pt]["instance"][indeks]["terlihat"] = true
									potongan[pt]["instance"][indeks]["instance"] = instance
									potongan[pt]["instance"][indeks]["jumlah_instance"] = 1
									potongan[pt]["instance"][indeks]["multimesh"] = multimesh
									potongan[pt]["instance"][indeks]["buffer_transformasi"] = PackedFloat32Array()
								else:
									multimesh = potongan[pt]["instance"][indeks]["multimesh"]
									potongan[pt]["instance"][indeks]["jumlah_instance"] += 1
								
								potongan[pt]["instance"][indeks]["buffer_transformasi"].append_array(
									[
										1, 0, 0, vegetasi[indeks_vegetasi[v]]["posisi"].x,
										0, 1, 0, vegetasi[indeks_vegetasi[v]]["posisi"].y,
										0, 0, 1, vegetasi[indeks_vegetasi[v]]["posisi"].z
									]
								)
						
						var indeks_instance = potongan[pt]["instance"].keys()
						for i in potongan[pt]["instance"].size():
							var multimesh = potongan[pt]["instance"][indeks_instance[i]]["multimesh"]
							if potongan[pt].get("aabb") == null: potongan[pt]["aabb"] = AABB()
							if multimesh.is_valid():
								RenderingServer.multimesh_allocate_data(multimesh, potongan[pt]["instance"][indeks_instance[i]]["jumlah_instance"], RenderingServer.MULTIMESH_TRANSFORM_3D)
								RenderingServer.multimesh_set_buffer(multimesh, potongan[pt]["instance"][indeks_instance[i]]["buffer_transformasi"])
								potongan[pt]["instance"][indeks_instance[i]].erase("buffer_transformasi")
								potongan[pt]["aabb"] = potongan[pt]["aabb"].merge(RenderingServer.multimesh_get_aabb(multimesh))
						
						var aabb = potongan[pt]["aabb"]
						var tmp_aabb = []
						var potongan_tengah = Vector3(
								potongan[pt]["pusat_x"],
								0,
								potongan[pt]["pusat_y"]
							)
						for titik in 8:
							var tmp_vektor = aabb.get_endpoint(titik)
							# sesuaikan posisi aabb dengan titik tengah
							tmp_vektor.x += aabb.size.x / 2
							tmp_vektor.z += aabb.size.z / 2
							# ubah posisi abb menjadi posisi global
							tmp_vektor = potongan_tengah + tmp_vektor
							tmp_aabb.append(tmp_vektor)
						potongan[pt]["aabb"] = tmp_aabb
	else: print("tidak ada data permukaan")

func slice_terrain(gambar_noise, material):
	# Hapus child bentuk yang ada sebelumnya
	if has_node("bentuk"): get_node("bentuk").queue_free()

	# Mendapatkan mesh yang ada pada terrain
	var terrain_mesh = $bentuk.mesh
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
			add_child(new_instance)
			
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
		0: array_model = pohon; data_vegetasi["tipe"] = "pohon"
		1: array_model = semak; data_vegetasi["tipe"] = "semak"
		2: array_model = batu; 	data_vegetasi["tipe"] = "batu"

	# FIXME : pencemaran dan bunga nektar tidak tersebar, hanya berkumpul pada potongan awal
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
		data_vegetasi["posisi"] = posisi
		data_vegetasi["rotasi"] = Basis(Vector3(0, 1, 0), deg_to_rad(randf_range(0, 360)))
		vegetasi.append(data_vegetasi)
	elif tipe_vegetasi == 3:
		# pencemaran
		if total_pencemaran <= 0: tempatkan_vegetasi(posisi); return
		var model_vegetasi = load("res://skena/entitas/pencemaran.scn")
		var vegetation_instance = model_vegetasi.instantiate()
		# TODO : atur nama
		vegetation_instance.transform.origin = posisi
		vegetation_instance.transform.basis = Basis(Vector3(0, 1, 0), deg_to_rad(randf_range(0, 360)))
		add_child(vegetation_instance)
		total_pencemaran -= 1
	elif tipe_vegetasi == 4:
		# bunga nektar
		if total_bunga_nektar <= 0: tempatkan_vegetasi(posisi); return
		var model_vegetasi = load("res://skena/entitas/bunga_nektar.scn")
		var vegetation_instance = model_vegetasi.instantiate()
		vegetation_instance.transform.origin = posisi
		vegetation_instance.transform.basis = Basis(Vector3(0, 1, 0), deg_to_rad(randf_range(0, 360)))
		add_child(vegetation_instance)
		total_bunga_nektar -= 1
func atur_visibilitas_vegetasi_potongan(id_potongan, posisi_pengamat, rotasi_pengamat, fov_pengamat):	# atur visibilitas vegetasi satu per-satu relatif terhadap pengamat pada suatu potongan
	var indeks_vegetasi = potongan[id_potongan]["vegetasi"].keys()
	for vg in potongan[id_potongan]["vegetasi"].size():
		if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"].is_valid():
			var posisi_vegetasi : Vector3 = vegetasi[indeks_vegetasi[vg]]["posisi"]
			var arah_pengamat = Vector3.FORWARD.rotated(Vector3.UP, rotasi_pengamat.y)
			var jarak_pengamat = posisi_vegetasi.distance_to(posisi_pengamat)
			var pengamat_ke_vegetasi : Vector3 = posisi_vegetasi - posisi_pengamat
			pengamat_ke_vegetasi.y = 0 # gak usah cek ketinggian!
			#print(posisi_vegetasi) # HACK : mencetak banyak data dalam waktu bersamaan akan memperlambat kinerja cpu
			
			arah_pengamat = arah_pengamat.normalized()
			pengamat_ke_vegetasi = pengamat_ke_vegetasi.normalized()
			
			var dot_product = arah_pengamat.dot(pengamat_ke_vegetasi)
			var sudut_arah = rad_to_deg(acos(dot_product))
			
			# lakukan culling hanya jika jarak vegetasi dan pengamat > 10 atau sudut_arah lebih dari fov pengamat
			# jarak 10 ditujukan supaya pengamat dapat tetap melihat vegetasi dari dekat, ini dikarenakan bentuk model vegetasi
			if sudut_arah <= (fov_pengamat + (fov_pengamat * 0.405453467695)) or jarak_pengamat < 10:
				if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["terlihat"] != true:
					RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"], true)
					if gunakan_level_of_detail:
						if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"].is_valid():
							RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"], true)
						if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"].is_valid():
							RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"], true)
					potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["terlihat"] = true
			else:
				if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["terlihat"] != false:
					RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"], false)
					if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"].is_valid():
						RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"], false)
					if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"].is_valid():
						RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"], false)
					potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["terlihat"] = false
func atur_visibilitas_potongan_vegetasi(id_potongan, nilai : bool): 									# atur visibilitas semua vegetasi pada suatu potongan
	var indeks_vegetasi = potongan[id_potongan]["vegetasi"].keys()
	for vg in potongan[id_potongan]["vegetasi"].size():
		if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["terlihat"] != nilai:
			if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"].is_valid():
				RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"], nilai)
			else: print("instance ["+str(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"])+"] tidak valid!")
			if gunakan_level_of_detail or !nilai:
				if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"].is_valid():
					RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"], nilai)
				if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"].is_valid():
					RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"], nilai)
			potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["terlihat"] = nilai
func atur_visibilitas_lod_potongan_vegetasi(id_potongan, nilai : bool): 								# atur visibilitas semua lod vegetasi pada suatu potongan
	var indeks_instance = potongan[id_potongan]["instance"].keys()
	for i in potongan[id_potongan]["instance"].size():
		if potongan[id_potongan]["instance"][indeks_instance[i]]["instance"].is_valid():
			if potongan[id_potongan]["instance"][indeks_instance[i]]["terlihat"] != nilai:
				RenderingServer.instance_set_visible(potongan[id_potongan]["instance"][indeks_instance[i]]["instance"], nilai)
				potongan[id_potongan]["instance"][indeks_instance[i]]["terlihat"] = nilai
