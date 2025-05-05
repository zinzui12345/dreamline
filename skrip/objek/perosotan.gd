extends placeholder_objek

func mulai() -> void:
	set_process(false)
	set_physics_process(false)
	set("wilayah_render", $bentuk.get_aabb())

func fokus():
	server.permainan.set("tombol_aksi_2", "meluncur")
	if $area_luncur.monitoring:
		server.permainan.set("tombol_aksi_2", "berjalan")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
func gunakan(id_pengguna) -> void:
	if id_pengguna == client.id_koneksi and dunia.get_node_or_null("pemain/"+str(id_pengguna)) != null:
		var pemain_meluncur : Karakter = dunia.get_node("pemain/"+str(id_pengguna))
		var tween_posisi_pemain = get_tree().create_tween()
		var tween_rotasi_pemain = get_tree().create_tween()
		tween_posisi_pemain.tween_property(pemain_meluncur, "global_position", $posisi_mulai.global_position, 1).set_trans(Tween.TRANS_BOUNCE)
		tween_rotasi_pemain.tween_property(pemain_meluncur, "global_rotation:y", $posisi_mulai.global_rotation.y, 1)
		$area_luncur.set_monitoring(true)
		server.permainan.set("tombol_aksi_4", "meluncur")

func ketika_pemain_mulai_meluncur(pemain) -> void:
	if pemain is Karakter and pemain == dunia.get_node("pemain/"+str(client.id_koneksi)):
		pemain.pose_duduk = "meluncur"
		pemain.gestur = "duduk"
		pemain.get_node("pengamat").atur_mode_kendaraan(true)
func ketika_pemain_berhenti_meluncur(pemain) -> void:
	if pemain is Karakter and pemain == dunia.get_node("pemain/"+str(client.id_koneksi)):
		pemain.gestur = "berdiri"
		pemain.pose_duduk = "normal"
		pemain.get_node("pengamat").atur_mode_kendaraan(false)
		$area_luncur.set_deferred("monitoring", false)
		server.permainan.set("tombol_aksi_4", "berlari")
