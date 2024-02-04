extends SubViewport

var target_karakter : Karakter

func _enter_tree():
	set_physics_process(false)
func _ready():
	$arah/latar.visible = false

func dapatkan_tampilan(karakter : Karakter) -> Image:
	# root.dunia.get_node("tampilan_karakter").dapatkan_tampilan(root.karakter)
	if is_instance_valid(karakter):
		$arah.global_position = karakter.get_node("%GeneralSkeleton/kepala").global_position
		target_karakter = karakter
		set_physics_process(true)
		$arah/latar.visible = true
		await RenderingServer.frame_post_draw
		var hasil = get_texture().get_image()
		set_physics_process(false)
		#$arah/latar.visible = false
		target_karakter = null
		return hasil
	else:
		return Image.new()

func _physics_process(_delta):
	if is_instance_valid(target_karakter):
		$arah.global_position = target_karakter.get_node("%GeneralSkeleton/kepala").global_position
