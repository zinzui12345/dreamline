extends Node

class_name Client

@onready var permainan = get_tree().get_root().get_node("Dreamline")

var interface = null
var peer : ENetMultiplayerPeer
var listener : ServerListener
var id_koneksi = -44
var pilih_server = ButtonGroup.new()
var data_suara : PackedByteArray

func cari_server():
	listener = ServerListener.new()
	listener.name = "pencari jodoh"
	listener.listenPort = 10568
	permainan.add_child(listener)
	listener.connect("new_server", self._tambahkan_server)
	listener.connect("remove_server", self._hapus_server)
func hentikan_pencarian_server():
	if listener != null:
		listener.queue_free()
		listener = null

func sambungkan_server(ip):
	interface = MultiplayerAPI.create_default_interface()
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, 10567)
	interface.set_multiplayer_peer(peer)
	interface.connect("connection_failed", self._ketika_gagal_menghubungkan_server)
	interface.connect("server_disconnected", self._ketika_terputus_dari_server)
	get_tree().set_multiplayer(interface)
	get_tree().get_root().get_node("dunia/spawner_pemain").connect("spawned", self.tambah_pemain)
	print("menghubungkan ke server {%s}" % [ip])
func putuskan_server():
	if interface != null:
		peer.close()
		peer = null
		interface.clear()
		interface.set_root_path(NodePath("/root"))
		interface = null
		get_tree().get_root().get_node("dunia/spawner_pemain").disconnect("spawned", self.tambah_pemain)

func cek_koneksi():
	if peer != null:
		match peer.get_connection_status():
			0: print("koneksi terputus")
			1: print("menghubungkan")
			2: print("koneksi terhubung")

func _uji_koneksi(): sambungkan_server("127.0.0.1")
func _tambahkan_server(data):
	permainan._tambah_server_lan(data.ip, data.sys, data.nama, data.map, data.jml_pemain, data.max_pemain)
func _hapus_server(ip): permainan._hapus_server_lan(ip)
func _pilih_server(ip): permainan._pilih_server_lan(ip)
func _ketika_gagal_menghubungkan_server():
	print("tidak dapat terhubung ke server")
	permainan._sembunyikan_proses_koneksi()
	permainan._tampilkan_popup_informasi("%koneksigagal", permainan.get_node("daftar_server/panel/panel_input/sambungkan"))
func _ketika_terputus_dari_server():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	permainan.putuskan_server()
	if permainan.get_node("proses_koneksi").visible:
		if permainan.get_node("daftar_server").visible:
			permainan._sembunyikan_daftar_server()
		_ketika_gagal_menghubungkan_server()
	else:
		permainan._tampilkan_popup_informasi("%koneksiputus", permainan.get_node("menu_utama/menu/Panel/gabung_server"))
		print("koneksi server terputus.")

func tambah_pemain(pemain):
	# INFO : tambah info pemain ke daftar pemain
	#if pemain.id_pemain != id_koneksi:
	permainan._tambah_daftar_pemain(pemain.id_pemain, {
		"nama"	: pemain.nama,
		"sistem": pemain.platform_pemain,
		"id_sys": str(pemain.id_pemain),
		"gender": pemain.gender
	})
	print("spawn pemain "+str(pemain))

@rpc("authority") func gabung_ke_server(nama_map, posisi, rotasi):
	print("telah terhubung ke server")
	id_koneksi = interface.get_unique_id()
	permainan._mulai_permainan(nama_map, posisi, rotasi)
@rpc("authority") func tambahkan_pemain(daftar : Dictionary):
	var data = daftar.keys()
	for p in data.size(): permainan._tambahkan_pemain(int(data[p]), daftar[data[p]])
@rpc("authority") func dapatkan_objek(data : Dictionary):
	var objek = data.keys()
	var nama_node = ""
	var instansi_node : Node3D
	# INFO (5b5) instansi dan atur properti objek
	for o in objek.size():
		var jalur_asal = objek[o]											# /root/dunia/entitas/entitas_1
		var potong = jalur_asal.split('/', false)							# [root, dunia, entitas, entitas_1]
		var jalur_node = '/'+("/".join(potong.slice(0, -1)))				# /root/dunia/entitas
		nama_node = "".join(potong.slice(potong.size() - 1, potong.size()))	# entitas_1
		server.objek[jalur_asal] = server.objek.size()
		#Panku.notify("spawn : "+str(jalur_asal)+" ["+str(jalur_node)+"] << "+str(nama_node))
		if get_node(jalur_node).get_node_or_null(nama_node) == null and data[objek[o]].get("sumber") != null:
			instansi_node = load(data[objek[o]]["sumber"]).instantiate()
			instansi_node.name = nama_node	# nama harus di-set sebelum ditambah ke node, supaya jalur di server.objek sesuai dan node gak kehapus
			get_node(jalur_node).add_child(instansi_node)
		#	Panku.notify("berhasil spawn : "+str(jalur_asal))
		#else:
		#	Panku.notify("gagal spawn : "+str(jalur_asal))
		instansi_node = get_node(jalur_node+'/'+nama_node)
		var properti = data[objek[o]].keys()
		for p in properti.size():
			if instansi_node.get_indexed(properti[p]) != null:
				instansi_node.set_indexed(properti[p], data[objek[o]][properti[p]])
@rpc("authority") func edit_objek(fungsi : bool, jalur_objek = ""):
	if fungsi:
		permainan._edit_objek(jalur_objek);
		if permainan.edit_objek is VehicleBody3D: pass
		else: server.atur_properti_objek(permainan.edit_objek.get_path(), "freeze", true)
		Panku.notify("mengedit objek : "+jalur_objek)
	else:
		permainan._berhenti_mengedit_objek();
		Panku.notify("berhenti mengedit objek")
@rpc("authority") func dapatkan_posisi_entitas(nama_entitas : String, posisi : Vector3, rotasi : Vector3):
	var t_entitas : Node3D = permainan.dunia.get_node("entitas/" + nama_entitas)
	if t_entitas != null:
		t_entitas.global_transform.origin = posisi
		t_entitas.rotation_degrees = rotasi
