@tool
extends Node3D

# TODO : frekuensi model vegetasi (batu = 0.25, semak = 0.5, pohon = 1)
# TODO : kalau draw_calls >= 1000 atau vertex >= 100000 dan fps <= 25, kurangi jarak render pengamat

@export var debug_culling = false :
	set(mode):
		if Engine.is_editor_hint(): set_process(mode)
		debug_culling = mode
@export var gunakan_frustum_culling = false
@export var gunakan_object_culling = false
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
			posisi_terakhir = kamera.global_transform.origin
			rotasi_terakhir = kamera.global_rotation_degrees
			pengamat = kamera
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
 {
 	"detail":	load("res://model/alam/pohon1/detail.res"),
 	"lod1": 	load("res://model/alam/pohon1/lod1.res"), 	"jarak_lod1": 	20,
 	"lod2": 	load("res://model/alam/pohon1/lod2.res"), 	"jarak_lod2": 	65
 },
 {
	"detail":	load("res://model/alam/pohon2/detail.res"),
 	"lod1": 	load("res://model/alam/pohon2/lod1.res"), 	"jarak_lod1": 	15,
 	"lod2": 	load("res://model/alam/pohon2/lod2.res"), 	"jarak_lod2": 	60
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
 load("res://model/alam/placeholder_semak.tres"),
 load("res://model/alam/placeholder_semak.tres"),
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

var fisik : StaticBody3D
var posisi_terakhir : Vector3
var rotasi_terakhir : Vector3
var arah_target_pengamat : Marker3D
var posisi_relatif_pengamat : Marker3D

@onready var scenario = get_world_3d().scenario

func _enter_tree():
	var p_arah_target_pengamat = Node3D.new()
	arah_target_pengamat	= Marker3D.new()
	posisi_relatif_pengamat = Marker3D.new()
	add_child(p_arah_target_pengamat)
	p_arah_target_pengamat.add_child(arah_target_pengamat)
	add_child(posisi_relatif_pengamat)
func _ready():
	if Engine.is_editor_hint(): set_process(debug_culling)
	else: server.permainan.permukaan = self
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
				var lebar_terrain_x = ((potongan[pt]["lebar_x"] * (float(jumlah_potongan) / 2)) * 1.25) * jumlah_potongan
				var lebar_terrain_y = ((potongan[pt]["lebar_y"] * (float(jumlah_potongan) / 2)) * 1.25) * jumlah_potongan
				
				var posisi = {
					'x': potongan[pt]["start_x"] * (ukuran * 0.25) - (lebar_terrain_x / 2),
					'y': potongan[pt]["start_y"] * (ukuran * 0.25) - (lebar_terrain_y / 2)
				}
				var batas = {
					'x': potongan[pt]["lebar_x"] * (ukuran * 0.25),
					'y': potongan[pt]["lebar_y"] * (ukuran * 0.25)
				}
				var posisi_pengamat : Vector3
				
				# hitung posisi relatif pengamat berdasarkan posisi globalnya
				if posisi_relatif_pengamat != null:
					posisi_relatif_pengamat.global_transform.origin = pengamat.global_transform.origin
					posisi_pengamat = posisi_relatif_pengamat.position
					#print_debug("feels like")
				else:
					posisi_pengamat = pengamat.position
				
				# cek pengamat mengarah kemana?, potongan mana saja yang harus visible dan invisible?
				if get_node_or_null("bentuk_" + potongan[pt]["indeks"]) != null and gunakan_frustum_culling:
					# kalo pengamat berada pada potongan, render potongan tersebut
					if posisi_pengamat.x >= posisi.x and posisi_pengamat.x <= (posisi.x + batas.x) and \
						posisi_pengamat.z >= posisi.y and posisi_pengamat.z <= (posisi.y + batas.y):
						
						get_node("bentuk_" + potongan[pt]["indeks"]).visible = true
						if server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT:
							get_node("fisik/fisik_" + potongan[pt]["indeks"]).disabled = false
						
						#get_parent().get_node("debug_pos_chunk").transform.origin = Vector3(
						#	potongan[pt]["pusat_x"],
						#	0,
						#	potongan[pt]["pusat_y"]
						#)
					
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
						#var potongan_tengah = potongan_node.transform.origin + Vector3(batas.x / 2, 0, batas.y / 2)
						var potongan_tengah = Vector3(
							potongan[pt]["pusat_x"],
							0,
							potongan[pt]["pusat_y"]
						)
						#get_parent().get_node("debug_pos_chunk").transform.origin = potongan_tengah
						
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
						# menghitung sudut antara vektor arah_pandang dan posisi potongan
						if arah_target_pengamat != null:
							var sudut = abs(arah_target_pengamat.rotation_degrees.y)
							var jarak = max(potongan[pt]["lebar_x"], potongan[pt]["lebar_y"]) / 0.405453467695
							#get_parent().get_node("debug/Label").text = str(jarak_render)+" <= "+str(jarak)+"\n"\
							#											+str(sudut)+" <= 175"
							if sudut <= (pengamat.fov + (pengamat.fov * 0.405453467695)):
								#if pt == 0: print_debug("bentuk_" + potongan[pt]["indeks"]+" "+str(sudut)+" < "+str(pengamat.fov + (pengamat.fov * 0.405453467695))+" : visibel"); await get_tree().create_timer(0.5).timeout
								if (jarak_render <= (jarak * 2)):
									if !potongan_node.visible:
										potongan_node.visible = true
										potongan_fisik.disabled = false
									if gunakan_object_culling:
										atur_visibilitas_potongan_vegetasi(pt, true)
								else:
									potongan_node.visible = false
									potongan_fisik.disabled = true
									if gunakan_object_culling:
										atur_visibilitas_potongan_vegetasi(pt, false)
							elif jarak_render <= jarak and sudut <= 175:
								#if pt == 0: print_debug("bentuk_" + potongan[pt]["indeks"]+" jarak < lebar : visibel")
								if !potongan_node.visible:
									potongan_node.visible = true
									potongan_fisik.disabled = false
									if gunakan_object_culling:
										if sudut < 90:
											atur_visibilitas_potongan_vegetasi(pt, true)
										else:
											atur_visibilitas_potongan_vegetasi(pt, false)
							else:
								#if pt == 0: print_debug("bentuk_" + potongan[pt]["indeks"]+" umum : tidak-visibel")
								if potongan_node.visible:
									potongan_node.visible = false
									potongan_fisik.disabled = true
									if gunakan_object_culling:
										atur_visibilitas_potongan_vegetasi(pt, false)
							arah_target_pengamat.rotation_degrees.y = 0
func _exit_tree():
#	RenderingServer.free() # INFO : memory leak | hapus RID satu-persatu!
	print("menghapus vegetasi permukaan")
	for pt in potongan.size():
		var indeks_vegetasi = potongan[pt]["vegetasi"].keys()
		for vg in potongan[pt]["vegetasi"].size():
			RenderingServer.free_rid(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["detail"])
			RenderingServer.free_rid(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod1"])
			RenderingServer.free_rid(potongan[pt]["vegetasi"][indeks_vegetasi[vg]]["lod2"])

func hasilkan_terrain():
	var arr_mesh = ArrayMesh.new()
	var surftool = SurfaceTool.new()
	
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
			
			# penempatan vegetasi
			if hasilkan_vegetasi:
				if randf() < float(frekuensi_vegetasi)/10 and vertex.y >= float(tinggi_maks)/10:  # hanya berada pada rumput | frekuensi penempatan vegetasi (0.5)
					tempatkan_vegetasi(Vector3(vertex.x, vertex.y, vertex.z))
	
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
	if FileAccess.file_exists("res://model/permukaan.scn"):
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
						var lebar_terrain_x = ((potongan[pt]["lebar_x"] * (float(jumlah_potongan) / 2)) * 1.25) * jumlah_potongan
						var lebar_terrain_y = ((potongan[pt]["lebar_y"] * (float(jumlah_potongan) / 2)) * 1.25) * jumlah_potongan
						
						var posisi = {
							'x' : potongan[pt]["start_x"] * (ukuran * 0.25) - (lebar_terrain_x / 2),
							'y' : potongan[pt]["start_y"] * (ukuran * 0.25) - (lebar_terrain_y / 2)
						}
						var batas = {
							'x' : potongan[pt]["lebar_x"] * (ukuran * 0.25),
							'y' : potongan[pt]["lebar_y"] * (ukuran * 0.25)
						}
						
						if posisi_vegetasi.x >= posisi.x and posisi_vegetasi.x <= (posisi.x + batas.x): pass
						else: continue
						if posisi_vegetasi.z >= posisi.y and posisi_vegetasi.z <= (posisi.y + batas.y): pass
						else: continue
						
						potongan[pt]["vegetasi"][v] = {
							"detail":	instance,
							"lod1":		instance_lod1,
							"lod2":		instance_lod2
						}
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
				x, y, nama_potongan,
				gambar_noise
			)
			var new_instance = MeshInstance3D.new()
			new_instance.name = "bentuk_" + nama_potongan
			new_instance.mesh = new_mesh
			new_instance.material_override = material
			new_instance.lod_bias = 2.0
			#new_instance.position = Vector3(
			#	(x * slice_res_x) * ukuran, 
			#	0, 
			#	(y * slice_res_y) * ukuran
			#)
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
func _buat_bagian_potongan(terrain_surface, start_x, start_y, res_x, res_y, potongan_ke_x, potongan_ke_y, bagian_potongan, gambar_noise):
	var slice_mesh = ArrayMesh.new()
	var surftool = SurfaceTool.new()
	var data_potongan = {}
	#var potongan_awal = false

	var lebar_terrain_x = ((res_x * (float(jumlah_potongan) / 2)) * 1.25) * jumlah_potongan
	var lebar_terrain_y = ((res_y * (float(jumlah_potongan) / 2)) * 1.25) * jumlah_potongan

	#if start_x == 0: res_x -= 1 rusak
	#if start_x == 0: res_y -= 1 gak ngaruh, yang ada malah ngurangin verteks akhir
	#if start_y == 0: start_y = 1; if start_x == 0: potongan_awal = true

	#print_debug(str(start_y)+" & "+str(start_x)+" : "+str(res_y)+" & "+str(res_x))
	#print_debug(
	#	str(
	#		potongan_ke + 0.5
	#	) + " * " +
	#	str(
	#		lebar_terrain_x / jumlah_potongan
	#	) + " = " +
	#	str(
	#		(potongan_ke + 0.5) * (lebar_terrain_x / jumlah_potongan) - (lebar_terrain_x / 2)
	#	)
	#)

	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	data_potongan["indeks"]  = bagian_potongan
	data_potongan["start_x"] = start_x
	data_potongan["start_y"] = start_y
	data_potongan["lebar_x"] = res_x
	data_potongan["lebar_y"] = res_y
	data_potongan["pusat_x"] = ((potongan_ke_x + 0.5) * (lebar_terrain_x / jumlah_potongan)) - (lebar_terrain_x / 2)
	data_potongan["pusat_y"] = ((potongan_ke_y + 0.5) * (lebar_terrain_y / jumlah_potongan)) - (lebar_terrain_y / 2)
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
	var tipe_vegetasi = randi() % 3  # Pohon, Semak, Batu
	var array_model = []
	var data_vegetasi = {}

	match tipe_vegetasi:
		0: array_model = pohon; data_vegetasi["tipe"] = "pohon"
		1: array_model = semak; data_vegetasi["tipe"] = "semak"
		2: array_model = batu; 	data_vegetasi["tipe"] = "batu"

	if array_model.size() > 0:
		var indeks_model = randi() % array_model.size()
		#model_vegetasi = array_model[indeks_model]
		#var vegetation_instance = model_vegetasi.instantiate()
		#vegetation_instance.transform.origin = posisi
		#vegetation_instance.transform.basis = Basis(Vector3(0, 1, 0), deg_to_rad(randf_range(0, 360)))
		data_vegetasi["model"] 	= indeks_model
		data_vegetasi["posisi"] = posisi
		data_vegetasi["rotasi"] = Basis(Vector3(0, 1, 0), deg_to_rad(randf_range(0, 360)))
		#add_child(vegetation_instance)
		vegetasi.append(data_vegetasi)
func atur_visibilitas_potongan_vegetasi(id_potongan, nilai):
	var indeks_vegetasi = potongan[id_potongan]["vegetasi"].keys()
	for vg in potongan[id_potongan]["vegetasi"].size():
		if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"].is_valid():
			RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"], nilai)
		else: print("instance ["+str(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["detail"])+"] tidak valid!")
		if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"].is_valid():
			RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod1"], nilai)
		if potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"].is_valid():
			RenderingServer.instance_set_visible(potongan[id_potongan]["vegetasi"][indeks_vegetasi[vg]]["lod2"], nilai)
