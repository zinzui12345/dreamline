extends Area3D

var karakter : CharacterBody3D
var kalulasi_percepatan : bool = false
var posisi_sebelumnya = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if kalulasi_percepatan:
		var posisi_saat_ini = global_transform.origin
		if posisi_sebelumnya != Vector3.ZERO:
			var percepatan = (posisi_saat_ini - posisi_sebelumnya) / delta
			percepatan = percepatan
			if is_instance_valid(karakter):
				karakter.velocity += percepatan
				karakter.move_and_slide()
		posisi_sebelumnya = posisi_saat_ini


func _ketika_body_entered(body: Node3D) -> void:
	#Panku.notify("cek! [%s]" % str(body))
	if body is Karakter and body.id_pemain == client.id_koneksi:
		karakter = body
		kalulasi_percepatan = true

func _ketika_body_exited(body: Node3D) -> void:
	if body is Karakter and body.id_pemain == client.id_koneksi:
		kalulasi_percepatan = false
		karakter = null
