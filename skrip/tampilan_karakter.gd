extends SubViewportContainer

var target_karakter : Karakter

func _enter_tree():
	set_physics_process(false)
func _ready():
	visible = false
	$SubViewport/arah/latar.visible = false

func dapatkan_tampilan(karakter : Karakter) -> Image:
	# root.dunia.get_node("tampilan_karakter").dapatkan_tampilan(root.karakter)
	# root._atur_daftar_pemain(1, "gambar", root.dunia.get_node("tampilan_karakter").dapatkan_tampilan(root.karakter))
	if is_instance_valid(karakter):
		visible = true
		target_karakter = karakter
		#set_physics_process(true)
		if target_karakter.id_pemain == client.id_koneksi: get_tree().paused = true
		$lantai/CollisionShape3D.disabled = false
		$SubViewport/arah/latar.visible = true
		$lantai.global_position = karakter.global_position
		$SubViewport/arah.global_position = karakter.global_position
		$SubViewport/arah.global_rotation.y = karakter.global_rotation.y
		$SubViewport/arah/latar.position.z = -karakter.get_node("pengamat").position.y
		$SubViewport/arah/kamera.position.z = -karakter.get_node("pengamat").position.y
		#await RenderingServer.frame_post_draw
		await get_tree().create_timer(0.5).timeout
		var hasil : Image = $SubViewport.get_texture().get_image()
		#$SubViewport.get_texture().get_image().save_png("user://uji_pp.png")
		$SubViewport/arah/latar.visible = false
		$lantai/CollisionShape3D.disabled = true
		if target_karakter.id_pemain == client.id_koneksi: get_tree().paused = false
		#set_physics_process(false)
		visible = false
		target_karakter = null
		Panku.notify("mengatur gambar ikon karakter")
		return hasil
	else:
		return Image.new()

func _physics_process(_delta):
	if is_instance_valid(target_karakter):
		$lantai.global_position = target_karakter.global_position
		$SubViewport/arah.global_rotation.y = target_karakter.global_rotation.y
		$SubViewport/arah.global_rotation.y = target_karakter.global_rotation.y
		$SubViewport/arah/latar.position.z = -target_karakter.get_node("pengamat").position.y
		$SubViewport/arah/kamera.position.z = -target_karakter.get_node("pengamat").position.y
