extends Node

class_name Client

@onready var permainan = get_tree().get_root().get_node("Dreamline")

var interface = null
var peer : ENetMultiplayerPeer
var listener : ServerListener
var id_koneksi = -44
var id_sesi = ""
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

func sambungkan_server(ip, port=10567):
	interface = MultiplayerAPI.create_default_interface()
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	interface.set_multiplayer_peer(peer)
	interface.connect("connection_failed", self._ketika_gagal_menghubungkan_server)
	interface.connect("server_disconnected", self._ketika_terputus_dari_server)
	get_tree().set_multiplayer(interface)
	print("menghubungkan ke server {%s}" % [ip])
func putuskan_server():
	if interface != null:
		peer.close()
		peer = null
		interface.clear()
		interface.set_root_path(NodePath("/root"))
		interface = null

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

@rpc("authority") func gabung_ke_server(nama_server, nama_map, posisi, rotasi):
	print("telah terhubung ke server")
	id_koneksi = interface.get_unique_id()
	id_sesi = OS.get_unique_id()
	permainan._mulai_permainan(nama_server, nama_map, posisi, rotasi)
@rpc("authority") func tambahkan_pemain(daftar : Dictionary):
	var data = daftar.keys()
	for p in data.size(): permainan._tambahkan_pemain(int(data[p]), daftar[data[p]])
@rpc("authority") func edit_objek(fungsi : bool, jalur_objek = ""):
	if fungsi:
		permainan._edit_objek(jalur_objek);
		#Panku.notify("mengedit objek : "+jalur_objek)
	else:
		permainan._berhenti_mengedit_objek();
		#Panku.notify("berhenti mengedit objek")
@rpc("authority") func dapatkan_posisi_entitas(nama_entitas : String, posisi : Vector3, rotasi : Vector3):
	var t_entitas : Node3D = permainan.dunia.get_node("entitas/" + nama_entitas)
	if t_entitas != null:
		t_entitas.global_transform.origin = posisi
		t_entitas.rotation_degrees = rotasi
@rpc("authority") func tambah_pemain(id_pemain, data_pemain):
	permainan._tambahkan_pemain(id_pemain, data_pemain)
@rpc("authority") func hapus_pemain(id_pemain):
	permainan._hapus_daftar_pemain(id_pemain)
