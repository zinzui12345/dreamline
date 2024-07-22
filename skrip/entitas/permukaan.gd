@tool
extends Node3D

# ------------------------------------------------ #
#		 		Permukaan (Terrain)				   #
# ------------------------------------------------ #
# Node ini harus berada pada child lingkungan
# Posisi node ini harus di (0, 0, 0)!

# TODO : kalau draw_calls >= 1000 atau vertex >= 100000 dan fps <= 25, kurangi jarak render pengamat

@export var nama_permukaan = "pulau"
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

func _enter_tree():
	if Engine.is_editor_hint():
		if get_node_or_null("placeholder_permukaan") == null:
			print("memuat data permukaan")
			if ResourceLoader.exists("res://model/permukaan/"+nama_permukaan+".scn"):
				var data = load("res://model/permukaan/"+nama_permukaan+".scn").instantiate()
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
	if $tanah.get_child_count() > 0:
		print("menghapus terrain sebelumnya")
		for i in $tanah.get_children():
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
	bentuk.set("surface_material_override/0", load("res://material/permukaan.material"))
	var mat = bentuk.get("surface_material_override/0")
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
	for data in potongan:
		var bagian_potongan = load(data["data"]).instantiate()
		bagian_potongan.position.x = data["pusat_x"]
		bagian_potongan.position.z = data["pusat_y"]
		node.add_child(bagian_potongan)
		bagian_potongan.set_owner(node)
	node.name = "permukaan"
	print("menyimpan terrain")
	print(packed_scene.pack(node))
	#print_debug(node.get_children())
	ResourceSaver.save(packed_scene, "res://model/permukaan/"+nama_permukaan+".scn")
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
	if ResourceLoader.exists("res://model/permukaan/"+nama_permukaan+".scn"):
		if is_instance_valid(server.permainan) and server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			var data = load("res://model/permukaan/"+nama_permukaan+".scn").instantiate()
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
			var skena_bagian_potongan := PackedScene.new()
			var instance_bagian_potongan := StaticBody3D.new()
			var jalur_skena_potongan : String = "res://map/"+nama_permukaan+"/"
			var jalur_data_skena_potongan : String = jalur_skena_potongan+nama_potongan+".scn"
			print("menghasilkan bentuk potongan [%s][%s]" % [str(y+1), str(x+1)])
			var new_mesh = _buat_bagian_potongan(
				terrain_surface,
				x * slice_res_x, y * slice_res_y,
				slice_res_x, slice_res_y,
				nama_potongan,
				gambar_noise,
				jalur_data_skena_potongan
			)
			
			var new_instance = MeshInstance3D.new()
			new_instance.name = "bentuk"
			new_instance.mesh = new_mesh
			new_instance.material_override = material
			new_instance.lod_bias = 2.0
			new_instance.position = Vector3(
				-potongan[potongan.size()-1]["pusat_x"],
				0,
				-potongan[potongan.size()-1]["pusat_y"]
			)
			print("menambahkan bentuk potongan")
			instance_bagian_potongan.name = "permukaan_" + nama_potongan
			instance_bagian_potongan.add_child(new_instance, true)
			new_instance.set_owner(instance_bagian_potongan)
			
			# INFO : buat fisik chunk
			if hasilkan_fisik:
				print("membuat fisik potongan [%s][%s]" % [str(y+1), str(x+1)])
				new_instance.create_trimesh_collision()
				var tmp_fisik = new_instance.get_child(0) 	# StaticBody
				var tmp_m_fisik = tmp_fisik.get_child(0)	# CollisionShape3D
				tmp_m_fisik.name = "fisik"
				tmp_m_fisik.position = Vector3(
					-potongan[potongan.size()-1]["pusat_x"],
					0,
					-potongan[potongan.size()-1]["pusat_y"]
				)
				tmp_fisik.remove_child(tmp_m_fisik)
				print("menambahkan fisik potongan [%s][%s]" % [str(y+1), str(x+1)])
				tmp_m_fisik.set_owner(null)
				instance_bagian_potongan.add_child(tmp_m_fisik, true)
				tmp_m_fisik.set_owner(instance_bagian_potongan)
				new_instance.remove_child(tmp_fisik)
			
			# 20/07/24 :: simpan tiap potongan ke skena_bagian_potongan dengan tipe objek (StaticBody3D)
			#             ke folder res://map/nama_permukaan dengan nama indeks_permukaan mis. (1-1)
			instance_bagian_potongan.set_script(load("res://skrip/objek/potongan_permukaan.gd"))
			instance_bagian_potongan.jalur_instance = jalur_data_skena_potongan
			instance_bagian_potongan.jarak_render = abs(abs(potongan[potongan.size()-1]["start_x"]) - abs(potongan[potongan.size()-1]["pusat_x"])) * (PI * 1.618)
			instance_bagian_potongan.radius_keterlihatan = abs(abs(potongan[potongan.size()-1]["start_y"]) - abs(potongan[potongan.size()-1]["pusat_y"])) * 1.618
			print(skena_bagian_potongan.pack(instance_bagian_potongan))
			if !DirAccess.dir_exists_absolute(jalur_skena_potongan):
				DirAccess.make_dir_absolute(jalur_skena_potongan)
			ResourceSaver.save(skena_bagian_potongan, jalur_data_skena_potongan)
func _buat_bagian_potongan(terrain_surface, start_x, start_y, res_x, res_y, bagian_potongan, gambar_noise, data_skena_potongan : String) -> Mesh:
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
	data_potongan["data"]	 = data_skena_potongan
	potongan.append(data_potongan)
	
	for z in range(start_y, start_y + res_y + 1):
		for x in range(start_x, start_x + res_x + 1):
			var vertex_index = z * (gambar_noise.get_width() + 1) + x
			var vertex = terrain_surface[Mesh.ARRAY_VERTEX][vertex_index]
			var uv = terrain_surface[Mesh.ARRAY_TEX_UV][vertex_index]
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)
	
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
