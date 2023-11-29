# 17/11/23
extends RigidBody3D

var id = -1							# id pada dictionary node proyektil
var jalur_proyektil : NodePath :	# node proyektil
	set(jalurnya):
		if get_node_or_null(jalurnya) != null and get_node(jalurnya).has_method("hapus_peluru"):
			contact_monitor = true
			connect("body_entered", menabrak_sesuatu)
		jalur_proyektil = jalurnya
var penembak : Node3D				# karakter yang menembak ini
var damage_serangan = 5				# tokimeki poporon des~

func menabrak_sesuatu(node: Node):
	# fungsi serang mending pake id_penyerang apa jalur_node_penyerang?
	if server.get_node_or_null(jalur_proyektil) != null and server.get_node(jalur_proyektil).has_method("hapus_peluru"):
		# FIXME : cek, jangan hapus dan serang kalo nabrak proyektil atau penembaknya sendiri!
		server.get_node(jalur_proyektil).hapus_peluru(id)
		if node.has_method("serang"):
			node.call("serang", penembak, damage_serangan)
			#Panku.notify(penembak.name+" menyerang "+str(node.get_path())+" << "+str(damage_serangan))

func _physics_process(_delta):
	if id > -1 and server.get_node_or_null(jalur_proyektil) != null and server.get_node(jalur_proyektil).has_method("sinkronisasi_peluru"):
		if server.get_node(jalur_proyektil)._peluru_ditembak.get(str(id)) != null:
			server.get_node(jalur_proyektil)._peluru_ditembak[str(id)]["arah"] = global_transform.basis
			server.get_node(jalur_proyektil)._peluru_ditembak[str(id)]["posisi"] = global_transform.origin
			server.get_node(jalur_proyektil).sinkronisasi_peluru(id)
