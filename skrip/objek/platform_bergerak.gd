extends Area3D

var karakter : CharacterBody3D
var daftar_entitas : Array[entitas]
var posisi_sebelumnya = Vector3.ZERO

func atur_proses(nilai : bool) -> void:
	monitoring = nilai
	set_process(nilai)
	set_physics_process(nilai)

func _physics_process(delta: float) -> void:
	if karakter != null or daftar_entitas.size() > 0:
		var posisi_saat_ini = global_transform.origin
		if posisi_sebelumnya != Vector3.ZERO:
			var percepatan : Vector3 = (posisi_saat_ini - posisi_sebelumnya) / delta
		
			if is_instance_valid(karakter):
				karakter.velocity += percepatan
				karakter.move_and_slide()
			
			for node_entitas in daftar_entitas:
				if is_instance_valid(node_entitas):
					if node_entitas.get("linear_velocity") != null:
						node_entitas.linear_velocity = percepatan
				else:
					daftar_entitas.erase(node_entitas)
		
		posisi_sebelumnya = posisi_saat_ini

func _ketika_body_entered(body: Node3D) -> void:
	#Panku.notify("cek! [%s]" % str(body))
	if body is Karakter and body.id_pemain == client.id_koneksi:
		karakter = body
	elif body is entitas and body.id_proses == client.id_koneksi and body != get_parent():
		daftar_entitas.append(body)

func _ketika_body_exited(body: Node3D) -> void:
	if body is Karakter and body.id_pemain == client.id_koneksi:
		karakter = null
	elif body is entitas and body.id_proses == client.id_koneksi:
		if daftar_entitas.has(body):
			daftar_entitas.erase(body)
