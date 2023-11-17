# 17/11/23
extends RigidBody3D

var jalur_proyektil : NodePath :	# node proyektil
	set(jalurnya):
		if get_node_or_null(jalurnya) != null and get_node(jalurnya).has_method("hapus_peluru"):
			contact_monitor = true
			connect("body_entered", menabrak_sesuatu)
		jalur_proyektil = jalurnya
var jalur_penembak = ""		# karakter yang menembak ini
var damage_serangan = 5	# tokimeki poporon des~

func menabrak_sesuatu(node: Node):
	# fungsi serang mending pake id_penyerang apa jalur_node_penyerang?
	if server.get_node_or_null(jalur_proyektil) != null and server.get_node(jalur_proyektil).has_method("hapus_peluru"):
		# cek, jangan hapus kalo nabrak proyektil atau penembaknya sendiri!
		server.get_node(jalur_proyektil).hapus_peluru(NodePath(name))
		#Panku.notify("damage : "+str(damage_serangan))
