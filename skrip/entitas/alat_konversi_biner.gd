extends entitas

const sinkron_kondisi = [[ "id_pengangkat", -1 ]]
const jalur_instance = "res://skena/entitas/konverter_biner.scn"

var id_pengangkat : int = -1:
	set(id):
		if id != -1:
			set("freeze", true)
			$fisik.disabled = true
			# otomatis set ketika pos_tangan tidak valid kemudian ready(), skrip pada pos_tangan
			if get_node_or_null("pos_tangan_kanan") != null and get_node_or_null("pos_tangan_kanan").is_inside_tree() and dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kanan") != null:
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node(get_node("pos_tangan_kanan").get_path())
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
			#if get_node_or_null("pos_tangan_kiri") != null and get_node_or_null("pos_tangan_kiri").is_inside_tree() and dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kiri") != null:
				#dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node(get_node("pos_tangan_kiri").get_path())
				#dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
			call("add_collision_exception_with", dunia.get_node("pemain/"+str(id)))
		else:
			if id_pemilik != id_pengangkat:
				set("freeze", false)
				$fisik.disabled = false
			if dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
				dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").set_target_node("")
				dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").stop()
			#if dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
				#dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").set_target_node("")
				#dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").stop()
		id_pengangkat = id
var id_pemilik : int = -1:
	set(id):
		if id != -1:
			set("freeze", true)
			$fisik.disabled = true
			id_pemilik = id
var sedang_digunakan : bool = false

func _setup():
	if get_parent().get_path() != dunia.get_node("entitas").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and not server.mode_replay:
			server._tambahkan_entitas(
				jalur_instance,
				global_transform.origin,
				rotation,
				[
					[ "id_pengangkat", -1 ],
					[ "id_pemilik", id_pemilik]
				]
			)
		queue_free()
	elif id_pemilik == client.id_koneksi and server.permainan.alat_digunakan["konverter_biner"]["nama_entitas"] == "":
		server.permainan.alat_digunakan["konverter_biner"]["nama_entitas"] = name
		var posisi_entitas : Vector3 = Vector3(0, server.permainan.batas_bawah - 600, 0)
		var tmp_kondisi : Array = [["posisi", posisi_entitas]]
		global_position = posisi_entitas
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_pemilik, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_pemilik, name, tmp_kondisi)

func proses(_waktu_delta : float) -> void:
	if !is_instance_valid(server.permainan): set_process(false); return
	
	if id_pengangkat != -1:
		if id_pengangkat == client.id_koneksi:
			if dunia.get_node_or_null("pemain/"+str(id_pengangkat)) != null:
				var tmp_id_pengangkat = id_pengangkat # 18/07/24 :: id_pengangkat harus dijadiin konstan, kalau nggak pada akhir eksekusi nilainya bisa -1
				var tmp_pos_angkat = dunia.get_node("pemain/"+str(tmp_id_pengangkat)+"/%kepala").position + $posisi_angkat.position.rotated(Vector3(1, 0, 0), dunia.get_node("pemain/"+str(tmp_id_pengangkat)+"/%kepala").rotation.x)
				
				# attach posisi ke pemain
				# 12/10/24 :: jangan pake transformasi global, karena posisi gak sesuai di mode pandangan first person
				global_position = dunia.get_node("pemain/"+str(tmp_id_pengangkat)).global_position + dunia.get_node("pemain/"+str(tmp_id_pengangkat)).transform.basis * tmp_pos_angkat
				global_rotation = dunia.get_node("pemain/"+str(tmp_id_pengangkat)).global_rotation + $posisi_angkat.transform.basis * dunia.get_node("pemain/"+str(tmp_id_pengangkat)+"/%kepala").rotation
				
				# input kendali
				#if dunia.get_node("pemain/"+str(tmp_id_pengangkat)).kontrol:
					#if Input.is_action_just_pressed("aksi1") or Input.is_action_just_pressed("aksi1_sentuh"):
						#if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_just_pressed("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
						#else: server.gunakan_entitas(name, "_lempar")
				
				# jangan biarkan tombol lempar, lepas disable / bantuan input tersembunyi
				if !server.permainan.get_node("kontrol_sentuh/aksi_2").visible:
					server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
				if !server.permainan.bantuan_aksi_2: server.permainan.bantuan_aksi_2 = true
				
				# jatuhkan jika pengangkatnya menjadi ragdoll
				if dunia.get_node("pemain/"+str(tmp_id_pengangkat))._ragdoll:
					server.gunakan_entitas(name, "_lepas")
		elif server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			# kalo pengangkatnya terputus, lepas # FIXME : pool gimana caranya???
			if dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) == null:
				server._gunakan_entitas(name, 1, "_lepas")

func fokus():
	server.permainan.set("tombol_aksi_2", "angkat_sesuatu")
func gunakan(_id_pemain):
	#if id_pengangkat == id_pemain:					server.gunakan_entitas(name, "_lepas")
	#el
	if id_pengangkat == -1: 						server.gunakan_entitas(name, "_angkat")

func _input(_event):
	if id_pengangkat == client.id_koneksi:
		if Input.is_action_just_pressed("aksi2"): await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_interaksi")

func _angkat(id):
	$model.rotation_degrees = Vector3(60, -180, 0)
	$fisik.rotation_degrees = Vector3(60, -180, 0)
	if id == client.id_koneksi:
		dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.bantuan_aksi_1 = false
		server.permainan.set("tombol_aksi_2", "edit_objek")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.bantuan_aksi_2 = true
		
		# ubah pemroses pada server
		var tmp_kondisi = [["id_proses", id], ["id_pengangkat", id]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur id_pengangkat dan id_proses
	id_pengangkat = id
	id_proses = id
func _lepas(id):
	$model.rotation_degrees = Vector3.ZERO
	$fisik.rotation_degrees = Vector3.ZERO
	# atur pengecualian tabrakan
	if id == client.id_koneksi and dunia.get_node_or_null("pemain/"+str(id)) != null:
		call("remove_collision_exception_with", dunia.get_node("pemain/"+str(id)))
		dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.bantuan_aksi_1 = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.bantuan_aksi_2 = false
		
		# reset pemroses pada server
		var tmp_kondisi = [["id_proses", -1], ["id_pengangkat", -1]]
		if id_pemilik != -1:
			var posisi_entitas : Vector3 = Vector3(0, server.permainan.batas_bawah - 600, 0)
			global_position = posisi_entitas
			tmp_kondisi.append(["posisi", posisi_entitas])
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur ulang id_pengangkat, id_pelempar dan id_proses
	id_pengangkat = -1
	id_proses = -1
func _interaksi(id : int) -> void:
	if id == client.id_koneksi and id == id_pengangkat:
		if id == id_pemilik:
			if !sedang_digunakan:
				dunia.get_node("pemain/"+str(id_pemilik))._atur_kendali(false)
				#dunia.get_node("pemain/"+str(id_pemilik))._atur_penarget(false)
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").fungsikan(false)
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").fokus_pandangan_belakang = $model/view
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").posisi_pandangan_belakang = 0
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").atur_mode_kendaraan(true)
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").aktifkan(false)
				server.permainan.alat_digunakan["konverter_biner"]["interaksi"] = true
				server.permainan._ketika_mengatur_mode_kontrol_pemain(false)
				$model/view.make_current()
				sedang_digunakan = true
			else:
				dunia.get_node("pemain/"+str(id_pemilik))._atur_kendali(true)
				#dunia.get_node("pemain/"+str(id_pemilik))._atur_penarget(true)
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").fungsikan(true)
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").atur_mode_kendaraan(false)
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").atur_ulang_posisi_pandangan_belakang()
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").fokus_pandangan_belakang = null
				dunia.get_node("pemain/"+str(id_pemilik)+"/pengamat").aktifkan()
				server.permainan.alat_digunakan["konverter_biner"]["interaksi"] = false
				server.permainan._ketika_mengatur_mode_kontrol_pemain(true)
				sedang_digunakan = false
		else:
			Panku.notify("Akses Ditolak")
			server.gunakan_entitas(name, "_lepas")

func hapus():
	if id_pengangkat != -1 and dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").set_target_node("")
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").stop()
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").set_target_node("")
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").stop()
	queue_free()
