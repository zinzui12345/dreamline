extends Node3D

enum JENIS_BENTUK {
	Kubus,
	Segitiga,
	Silinder
}

@export var tipe_bentuk := JENIS_BENTUK.Kubus
@export var ukuran : Vector3 = Vector3(1.0, 1.0, 1.0) :
	set(ukuran_baru):
		$fisik/bentuk_fisik.shape.size = ukuran_baru
		
		$wajah/kiri.position.x = -(ukuran_baru.x / 2)
		$wajah/kanan.position.x = ukuran_baru.x / 2
		$wajah/atas.mesh.size.x = ukuran_baru.x
		$wajah/atas/fisik/fisik_wajah_atas.scale.x = ukuran_baru.x
		$wajah/bawah.mesh.size.x = ukuran_baru.x
		$wajah/bawah/fisik/fisik_wajah_bawah.scale.x = ukuran_baru.x
		$wajah/depan.mesh.size.x = ukuran_baru.x
		$wajah/depan/fisik/fisik_wajah_depan.scale.x = ukuran_baru.x
		$wajah/belakang.mesh.size.x = ukuran_baru.x
		$wajah/belakang/fisik/fisik_wajah_belakang.scale.x = ukuran_baru.x
		
		$wajah/atas.position.y = ukuran_baru.y / 2
		$wajah/bawah.position.y = -(ukuran_baru.y / 2)
		$wajah/kiri.mesh.size.y = ukuran_baru.y
		$wajah/kiri/fisik/fisik_wajah_kiri.scale.y = ukuran_baru.y
		$wajah/kanan.mesh.size.y = ukuran_baru.y
		$wajah/kanan/fisik/fisik_wajah_kanan.scale.y = ukuran_baru.y
		$wajah/depan.mesh.size.y = ukuran_baru.y
		$wajah/depan/fisik/fisik_wajah_depan.scale.y = ukuran_baru.y
		$wajah/belakang.mesh.size.y = ukuran_baru.y
		$wajah/belakang/fisik/fisik_wajah_belakang.scale.y = ukuran_baru.y
		
		$wajah/depan.position.z = ukuran_baru.z / 2
		$wajah/belakang.position.z = -(ukuran_baru.z / 2)
		$wajah/atas.mesh.size.y = ukuran_baru.z
		$wajah/atas/fisik/fisik_wajah_atas.scale.z = ukuran_baru.z
		$wajah/bawah.mesh.size.y = ukuran_baru.z
		$wajah/bawah/fisik/fisik_wajah_bawah.scale.z = ukuran_baru.z
		$wajah/kiri.mesh.size.x = ukuran_baru.z
		$wajah/kiri/fisik/fisik_wajah_kiri.scale.z = ukuran_baru.z
		$wajah/kanan.mesh.size.x = ukuran_baru.z
		$wajah/kanan/fisik/fisik_wajah_kanan.scale.z = ukuran_baru.z
		
		$wajah/atas.atur_skala_material(Vector2(ukuran_baru.x, ukuran_baru.z))
		$wajah/bawah.atur_skala_material(Vector2(ukuran_baru.x, ukuran_baru.z))
		$wajah/depan.atur_skala_material(Vector2(ukuran_baru.x, ukuran_baru.y))
		$wajah/belakang.atur_skala_material(Vector2(ukuran_baru.x, ukuran_baru.y))
		$wajah/kiri.atur_skala_material(Vector2(ukuran_baru.z, ukuran_baru.y))
		$wajah/kanan.atur_skala_material(Vector2(ukuran_baru.z, ukuran_baru.y))
		
		ukuran = ukuran_baru
@export var dapat_dipilih : bool = true :
	set(aktifkan_seleksi):
		if pilih_wajah:
			$fisik/bentuk_fisik.disabled = true
			$wajah/atas/fisik/fisik_wajah_atas.disabled = !aktifkan_seleksi
			$wajah/bawah/fisik/fisik_wajah_bawah.disabled = !aktifkan_seleksi
			$wajah/kiri/fisik/fisik_wajah_kiri.disabled = !aktifkan_seleksi
			$wajah/kanan/fisik/fisik_wajah_kanan.disabled = !aktifkan_seleksi
			$wajah/depan/fisik/fisik_wajah_depan.disabled = !aktifkan_seleksi
			$wajah/belakang/fisik/fisik_wajah_belakang.disabled = !aktifkan_seleksi
		else:
			$fisik/bentuk_fisik.disabled = !aktifkan_seleksi
			$wajah/atas/fisik/fisik_wajah_atas.disabled = true
			$wajah/bawah/fisik/fisik_wajah_bawah.disabled = true
			$wajah/kiri/fisik/fisik_wajah_kiri.disabled = true
			$wajah/kanan/fisik/fisik_wajah_kanan.disabled = true
			$wajah/depan/fisik/fisik_wajah_depan.disabled = true
			$wajah/belakang/fisik/fisik_wajah_belakang.disabled = true
		dapat_dipilih = aktifkan_seleksi
@export var pilih_wajah : bool = false :
	set(aktifkan_pemilihan_wajah):
		$fisik/bentuk_fisik.disabled = aktifkan_pemilihan_wajah
		$wajah/atas/fisik/fisik_wajah_atas.disabled = !aktifkan_pemilihan_wajah
		$wajah/bawah/fisik/fisik_wajah_bawah.disabled = !aktifkan_pemilihan_wajah
		$wajah/kiri/fisik/fisik_wajah_kiri.disabled = !aktifkan_pemilihan_wajah
		$wajah/kanan/fisik/fisik_wajah_kanan.disabled = !aktifkan_pemilihan_wajah
		$wajah/depan/fisik/fisik_wajah_depan.disabled = !aktifkan_pemilihan_wajah
		$wajah/belakang/fisik/fisik_wajah_belakang.disabled = !aktifkan_pemilihan_wajah
		pilih_wajah = aktifkan_pemilihan_wajah
@export var wajah : Array

func _ready() -> void:
	add_to_group("seleksi_aktif")
	$wajah/atas.add_to_group("wajah")
	$wajah/bawah.add_to_group("wajah")
	$wajah/kiri.add_to_group("wajah")
	$wajah/kanan.add_to_group("wajah")
	$wajah/depan.add_to_group("wajah")
	$wajah/belakang.add_to_group("wajah")
	
	# buat tiap mesh pada wajah menjadi unik, agar materialnya tidak duplikat satu sama lain
	$wajah/atas.mesh = $wajah/atas.mesh.duplicate()
	$wajah/bawah.mesh = $wajah/bawah.mesh.duplicate()
	$wajah/kiri.mesh = $wajah/kiri.mesh.duplicate()
	$wajah/kanan.mesh = $wajah/kanan.mesh.duplicate()
	$wajah/depan.mesh = $wajah/depan.mesh.duplicate()
	$wajah/belakang.mesh = $wajah/belakang.mesh.duplicate()
	
	$wajah/kiri.mesh.center_offset.x = 0.0001
	$wajah/kanan.mesh.center_offset.x = -0.0001
	$wajah/depan.mesh.center_offset.z = 0.0001
	$wajah/belakang.mesh.center_offset.z = -0.0001

func dapatkan_wajah(indeks : int) -> MeshInstance3D:
	return get_node("wajah/" + wajah[indeks])
