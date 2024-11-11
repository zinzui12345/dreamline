# 30/07/24
extends Node

signal terapkan_bahasa
signal terapkan_profil
signal login_pemain

const Util = preload("res://skrip/editor kode/code_generation/util.gd")

func _ready() -> void:
	# 1. non-aktifkan proses precache aset
	$"precache karakter/reno".set_process(false)
	$"precache karakter/reno".set_physics_process(false)
	$"precache karakter/lulu".set_process(false)
	$"precache karakter/lulu".set_physics_process(false)
	for ent in $"precache entitas".get_children():
		if ent is RigidBody3D: ent.set("freeze", true)
	# 2. muat aset
	# - kalau direktori aset belum ada, buat
	if !DirAccess.dir_exists_absolute(Konfigurasi.direktori_map):
		DirAccess.make_dir_absolute(Konfigurasi.direktori_map)
	if !DirAccess.dir_exists_absolute(Konfigurasi.direktori_aset):
		DirAccess.make_dir_absolute(Konfigurasi.direktori_aset)
	if !DirAccess.dir_exists_absolute(Konfigurasi.direktori_aset + "/objek"):
		DirAccess.make_dir_absolute(Konfigurasi.direktori_aset + "/objek")
	if !DirAccess.dir_exists_absolute(Konfigurasi.direktori_aset + "/kode"):
		DirAccess.make_dir_absolute(Konfigurasi.direktori_aset + "/kode")
	if !FileAccess.file_exists(Konfigurasi.data_aset):
		var file : FileAccess = FileAccess.open(Konfigurasi.data_aset, FileAccess.WRITE)
		var data : Dictionary = {}
		var daftar_file = Util.get_files_in_dir_recursive(Konfigurasi.direktori_aset + "/objek", "*.scn")
		for file_ in daftar_file:
			var isi_file: Node3D = load(file_).instantiate()
			var id		= isi_file.get_meta("id_aset")
			data[id] = {
				"nama"		: isi_file.name,
				"tipe"		: "objek",
				"author"	: isi_file.get_meta("author"),
				"sumber"	: file_,
				"versi"		: isi_file.get_meta("versi"),
				"setelan"	: isi_file.get_meta("setelan")
			}
			isi_file.queue_free()
		daftar_file = Util.get_files_in_dir_recursive(Konfigurasi.direktori_aset + "/kode", "*.scn")
		for file_ in daftar_file:
			var isi_file: BlockCode = load(file_).instantiate()
			var id		= isi_file.get_meta("id_aset")
			var author	= isi_file.get_meta("author")
			var versi	= isi_file.get_meta("versi")
			data[id] = {
				"tipe"		: "kode",
				"author"	: author,
				"sumber"	: file_,
				"versi"		: versi
			}
			isi_file.queue_free()
		file.store_var(data)
		file.close()
		#Panku.notify("ummai~!")
	# 3. muat / input konfigurasi
	if !FileAccess.file_exists(Konfigurasi.data_konfigurasi):
		$"panel konfigurasi/pilih bahasa".visible = true
		match Konfigurasi.kode_bahasa[Konfigurasi.bahasa]:
			"id", "id_ID":	$"panel konfigurasi/pilih bahasa/pilih_bahasa 2".button_pressed = true
			_:				$"panel konfigurasi/pilih bahasa/pilih_bahasa 1".button_pressed = true
		await terapkan_bahasa
	Konfigurasi.muat()
	# 4. muat / login / buat data pemain
	# 4.a. muat data pemain
	if FileAccess.file_exists(Konfigurasi.data_pemain):
		var file : FileAccess = FileAccess.open(Konfigurasi.data_pemain, FileAccess.READ)
		server.permainan.data = file.get_var()
		file.close()
	# 4.b. tampilkan prompt login
	else:
		$"panel konfigurasi/login".visible = true
		await login_pemain
	# 5. render precache karakter selama 1 detik
	await get_tree().create_timer(1).timeout
	# 6. tampilkan permainan
	server.permainan.call("_setup")
	queue_free()

func _ketika_memilih_bahasa_1() -> void:
	Konfigurasi.bahasa = 1
	$"panel konfigurasi/pilih bahasa/pilih_bahasa 1".button_pressed = true
	$"panel konfigurasi/pilih bahasa/pilih_bahasa 2".button_pressed = false
func _ketika_memilih_bahasa_2() -> void:
	Konfigurasi.bahasa = 2
	$"panel konfigurasi/pilih bahasa/pilih_bahasa 1".button_pressed = false
	$"panel konfigurasi/pilih bahasa/pilih_bahasa 2".button_pressed = true
func _terapkan_bahasa() -> void:
	$"panel konfigurasi/pilih bahasa".visible = false
	Konfigurasi.simpan()
	emit_signal("terapkan_bahasa")

func _ketika_login_google():
	#$"panel konfigurasi/login".visible = false
	Panku.notify("0")
func _ketika_login_guest():
	$"panel konfigurasi/login".visible = false
	$"panel konfigurasi/input profil".visible = true
	await terapkan_profil
	# TODO : mulai level 0
	emit_signal("login_pemain")
func _terapkan_profil():
	if $"panel konfigurasi/input profil/input_nama".text == "":
		# FIXME : gak keliatan!
		server.permainan._tampilkan_popup_informasi("%namakosong", $"panel konfigurasi/input profil/input_nama")
	else:
		server.permainan.data["nama"] = $"panel konfigurasi/input profil/input_nama".text
		match $"panel konfigurasi/input profil/pilih_gender".selected:
			0: server.permainan.data["gender"] = "P"
			1: server.permainan.data["gender"] = "L"
		server.permainan._ketika_menyimpan_data_karakter()
		$"panel konfigurasi/input profil".visible = false
		await get_tree().create_timer(0.1).timeout
		emit_signal("terapkan_profil")
