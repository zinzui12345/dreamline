extends LineEdit

@export var blok_kode : BlokKode

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

var _previous_name : String = ""

func _setup() -> void:
	# Inisialisasi nama lama dari blok_kode (jika ada) atau dari LineEdit saat ini
	if blok_kode != null and blok_kode.has_method("get_nama_variabel"):
		_previous_name = blok_kode.get_nama_variabel()
	else:
		_previous_name = text

func nama_diubah(nama_baru : String) -> void:
	nama_baru = nama_baru.strip_edges() # trim spasi di kiri/kanan

	# Resize dinamis
	custom_minimum_size.x = clamp((nama_baru.length() * 10) + 10, 68.5, 500)

	# Cegah nama kosong
	if nama_baru == "":
		push_error("Nama variabel tidak boleh kosong.")
		text = _previous_name
		return

	# Validasi regex: mulai huruf atau underscore, lalu huruf/angka/underscore
	var re := RegEx.new()
	var err := re.compile("^[A-Za-z_][A-Za-z0-9_]*$")
	if err != OK or not re.search(nama_baru):
		#server.permainan._tampilkan_popup_informasi("Nama variabel tidak valid. Gunakan huruf, angka, underscore; jangan mulai dengan angka.", self)
		push_error("Nama variabel tidak valid. Gunakan huruf, angka, underscore; jangan mulai dengan angka.") # FIXME : gunakan popup setelah implementasi!
		text = _previous_name
		return

	# Jika tidak ada perubahan, hentikan
	if nama_baru == _previous_name:
		return

	# Simpan nama lama untuk log, lalu update
	print("Mengubah nama variabel: '%s' >> '%s'" % [_previous_name, nama_baru])
	_previous_name = nama_baru

	# Panggil fungsi pengubah nama — pastikan blok_kode ada dan memiliki method yang tepat
	if blok_kode != null:
		EditorKode.ubah_nama_variabel(blok_kode.var_id, nama_baru)
	else:
		push_error("blok_kode belum di-set.")
