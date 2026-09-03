extends HBoxContainer

@export var objek_pemilik : representasi_objek
@export var id_properti : int = -1
@export var properti_tampilan : String		# nama variabel pada $nilai_properti yang dijadikan sebagai nilai
@export var sinyal_tampilan : String		# nama sinyal pada $nilai_properti yang dipanggil saat nilai diubah. sinyal harus memiliki parameter berupa nilai ubahan

func atur(nama_variabel : String, nilai : Variant) -> void:
	$nama_properti.text = nama_variabel
	$nilai_properti.set(properti_tampilan, nilai)
	$nilai_properti.connect(sinyal_tampilan, ubah_nilai)
	ubah_nilai(nilai)

func ubah_nilai(nilai : Variant) -> void:
	if objek_pemilik.daftar_properti.is_read_only():
		objek_pemilik.daftar_properti = objek_pemilik.daftar_properti.duplicate_deep()
	objek_pemilik.daftar_properti[id_properti][1] = nilai
	objek_pemilik.atur_properti(objek_pemilik.daftar_properti[id_properti][0], nilai)
