extends XROrigin3D

var aktif = false : 
	set(akt):
		set_process(akt)
		aktif = akt
var interface : MobileVRInterface
var karakter : Karakter

var bantuan_aksi_1 : bool = false :
	set(visibilitas):
		$antarmuka/antarmuka_vr/bantuan_input/aksi1.visible = visibilitas
		bantuan_aksi_1 = visibilitas
var bantuan_aksi_2 : bool = false :
	set(visibilitas):
		$antarmuka/antarmuka_vr/bantuan_input/aksi2.visible = visibilitas
		bantuan_aksi_2 = visibilitas
var teks_bantuan_aksi_1 : StringName = "" :
	set(nama_aksi):
		$antarmuka/antarmuka_vr/bantuan_input/aksi1/teks.text = nama_aksi
		teks_bantuan_aksi_1 = nama_aksi
var teks_bantuan_aksi_2 : StringName = "" :
	set(nama_aksi):
		$antarmuka/antarmuka_vr/bantuan_input/aksi2/teks.text = nama_aksi
		teks_bantuan_aksi_2 = nama_aksi

var _translasi_posisi_z : float = 0

func _enter_tree() -> void:
	set_process(aktif)
func _ready() -> void:
	# atur tampilan HUD
	var material_antarmuka_vr : Material = StandardMaterial3D.new()
	var tekstur_antarmuka_vr : ViewportTexture = $antarmuka.get_texture()
	$antarmuka_vr/debug.visible = false
	$antarmuka_vr/bantuan_input/aksi1.visible = server.permainan.bantuan_aksi_1
	$antarmuka_vr/bantuan_input/aksi2.visible = server.permainan.bantuan_aksi_2
	$antarmuka_vr.reparent($antarmuka)
	$antarmuka/antarmuka_vr.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	$XRCamera3D/tampilan_antarmuka.mesh.set("material", material_antarmuka_vr)
	material_antarmuka_vr.resource_local_to_scene = true
	material_antarmuka_vr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_antarmuka_vr.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_antarmuka_vr.no_depth_test = true
	material_antarmuka_vr.albedo_texture = tekstur_antarmuka_vr
	
	# atur tampilan menu
	var material_antarmuka_menu_vr : Material = StandardMaterial3D.new()
	var tekstur_antarmuka_menu_vr : ViewportTexture = $antarmuka_menu.get_texture()
	$antarmuka_menu_horizontal.visible = false
	$antarmuka_menu_horizontal/menu_jeda.visible = false
	$antarmuka_menu_horizontal/setelan.visible = false
	$antarmuka_menu_horizontal.reparent($antarmuka_menu)
	$antarmuka_menu/antarmuka_menu_horizontal.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	$menu/tampilan_antarmuka.mesh.set("material", material_antarmuka_menu_vr)
	material_antarmuka_menu_vr.resource_local_to_scene = true
	material_antarmuka_menu_vr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_antarmuka_menu_vr.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_antarmuka_menu_vr.no_depth_test = true
	material_antarmuka_menu_vr.albedo_texture = tekstur_antarmuka_menu_vr

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and aktif:
		server.permainan._ketika_mengatur_mode_vr(false)
	if Input.is_action_just_pressed("menu_vr") and aktif:
		if get_node_or_null("antarmuka_menu/antarmuka_menu_horizontal") == null: return
		if $antarmuka_menu/antarmuka_menu_horizontal.visible:
			_lanjutkan_permainan()
		else:
			_jeda_permainan()
	if Input.is_action_just_pressed("aksi1") and $antarmuka_menu/antarmuka_menu_horizontal.visible:
		if $XRCamera3D/target_kursor.is_colliding() and $XRCamera3D/target_kursor.get_collider() == $menu/tampilan_antarmuka/target_kursor:
			var tombol_aksi = InputEventMouseButton.new()
			tombol_aksi.position = _dapatkan_posisi_kursor()
			tombol_aksi.button_index = 1
			tombol_aksi.pressed = true
			$antarmuka_menu.push_input(tombol_aksi)
		else:
			_sesuaikan_arah_tampilan()
	if Input.is_action_just_released("aksi1") and $antarmuka_menu/antarmuka_menu_horizontal.visible:
		var tombol_aksi = InputEventMouseButton.new()
		tombol_aksi.position = _dapatkan_posisi_kursor()
		tombol_aksi.button_index = 1
		tombol_aksi.pressed = false
		$antarmuka_menu.push_input(tombol_aksi)
	if Input.is_action_just_pressed("aksi2") and $antarmuka_menu/antarmuka_menu_horizontal.visible:
		if $antarmuka_menu/antarmuka_menu_horizontal/setelan.visible:
			$antarmuka_menu/antarmuka_menu_horizontal/setelan.visible = false
	if Input.is_action_just_pressed("kiri") and $antarmuka_menu/antarmuka_menu_horizontal.visible:
		var tombol_aksi = InputEventMouseButton.new()
		tombol_aksi.position = _dapatkan_posisi_kursor()
		tombol_aksi.button_index = 5
		tombol_aksi.pressed = true
		$antarmuka_menu.push_input(tombol_aksi)
	if Input.is_action_just_released("kiri") and $antarmuka_menu/antarmuka_menu_horizontal.visible:
		var tombol_aksi = InputEventMouseButton.new()
		tombol_aksi.position = _dapatkan_posisi_kursor()
		tombol_aksi.button_index = 5
		tombol_aksi.pressed = false
		$antarmuka_menu.push_input(tombol_aksi)
	if Input.is_action_just_pressed("kanan") and $antarmuka_menu/antarmuka_menu_horizontal.visible:
		var tombol_aksi = InputEventMouseButton.new()
		tombol_aksi.position = _dapatkan_posisi_kursor()
		tombol_aksi.button_index = 4
		tombol_aksi.pressed = true
		$antarmuka_menu.push_input(tombol_aksi)
	if Input.is_action_just_released("kanan") and $antarmuka_menu/antarmuka_menu_horizontal.visible:
		var tombol_aksi = InputEventMouseButton.new()
		tombol_aksi.position = _dapatkan_posisi_kursor()
		tombol_aksi.button_index = 4
		tombol_aksi.pressed = false
		$antarmuka_menu.push_input(tombol_aksi)
	if Input.is_action_just_pressed("berbicara"):
		$antarmuka/antarmuka_vr/indikator_mikrofon.button_pressed = true
	if Input.is_action_just_released("berbicara"):
		$antarmuka/antarmuka_vr/indikator_mikrofon.button_pressed = false
func _notification(what : int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and aktif:
		server.permainan._ketika_mengatur_mode_vr(false)

func _aktifkan() -> void:
	interface = XRServer.find_interface("Native mobile")
	if interface and interface.initialize():
		get_viewport().use_xr = true # | root._ketika_mengatur_mode_vr(true) -> debug
		set("aktif", true)
func _nonaktifkan() -> void:
	if interface != null:
		set("aktif", false)
		get_viewport().use_xr = false
		interface.uninitialize()
func _sesuaikan_arah_tampilan() -> void:
	$menu.rotation_degrees.y = $XRCamera3D.rotation_degrees.y
	$menu.rotation_degrees.x = $XRCamera3D.rotation_degrees.x

func _dapatkan_posisi_kursor() -> Vector2:
	return Vector2(
		$antarmuka_menu.size.x * $menu/tampilan_antarmuka/ref_pos_kursor/posisi_kursor.position.x,
		$antarmuka_menu.size.y * $menu/tampilan_antarmuka/ref_pos_kursor/posisi_kursor.position.y
	)

func _tampilkan_setelan() -> void:
	$antarmuka_menu/antarmuka_menu_horizontal/setelan.visible = true
func _atur_jarak_lensa(nilai) -> void:
	if interface != null:
		interface.display_to_lens = nilai
		$antarmuka_menu/antarmuka_menu_horizontal/setelan/nilai_jarak_lensa.text = str(nilai) + "cm"
func _atur_lebar_tampilan(nilai) -> void:
	if interface != null:
		interface.display_width = nilai
		$antarmuka_menu/antarmuka_menu_horizontal/setelan/nilai_lebar_tampilan.text = str(nilai)
func _atur_jarak_mata(nilai) -> void:
	if interface != null:
		interface.iod = nilai
		$antarmuka_menu/antarmuka_menu_horizontal/setelan/nilai_jarak_mata.text = str(nilai)
func _atur_bidang_pandang(nilai) -> void:
	$XRCamera3D.fov = nilai
	$antarmuka_menu/antarmuka_menu_horizontal/setelan/nilai_bidang_pandang.text = str(nilai)
func _atur_ulang_setelan() -> void:
	$antarmuka_menu/antarmuka_menu_horizontal/setelan/jarak_lensa.value = 4
	$antarmuka_menu/antarmuka_menu_horizontal/setelan/lebar_tampilan.value = 14.5
	$antarmuka_menu/antarmuka_menu_horizontal/setelan/jarak_mata.value = 6
	$antarmuka_menu/antarmuka_menu_horizontal/setelan/bidang_pandang.value = 75

func _jeda_permainan():
	$menu/animasi.play("tampilkan_antarmuka")
	server.permainan._jeda()
	_sesuaikan_arah_tampilan()
	$antarmuka/antarmuka_vr/indikator_mikrofon.visible = false
	$antarmuka_menu/antarmuka_menu_horizontal.visible = true
	$antarmuka_menu/antarmuka_menu_horizontal/menu_jeda.visible = true
	$XRCamera3D/target_kursor.enabled = true
func _lanjutkan_permainan():
	$menu/animasi.play_backwards("tampilkan_antarmuka")
	$XRCamera3D/target_kursor.enabled = false
	$antarmuka/antarmuka_vr/indikator_mikrofon.visible = true
	$antarmuka_menu/antarmuka_menu_horizontal.visible = false
	$antarmuka_menu/antarmuka_menu_horizontal/menu_jeda.visible = false
	$antarmuka_menu/antarmuka_menu_horizontal/setelan.visible = false
	server.permainan._lanjutkan()

func _process(delta: float) -> void:
	if karakter != null:
		global_position = karakter.position + karakter.transform.basis.z * _translasi_posisi_z
		if karakter.get_node("pengamat").mode_kontrol == 1:
			karakter.rotation_degrees.y = $XRCamera3D.rotation_degrees.y + $XRCamera3D/arah_pemain.rotation_degrees.y
		karakter.get_node("%target").rotation_degrees.x = -$XRCamera3D.rotation_degrees.x
		if interface != null:
			interface.eye_height = karakter.get_node("%mata_kiri").position.y
		if karakter.get("arah_pandangan") != null:
			karakter.arah_pandangan.y = $XRCamera3D.rotation_degrees.x / karakter.get_node("pengamat").putaranMaxVertikalPandangan
			if $XRCamera3D.rotation_degrees.x > 0:
				karakter.arah_pandangan.y = $XRCamera3D.rotation_degrees.x / karakter.get_node("pengamat").putaranMaxVertikalPandangan
			elif $XRCamera3D.rotation_degrees.x < 0:
				var arah_pandangan : float = -$XRCamera3D.rotation_degrees.x / karakter.get_node("pengamat").putaranMinVertikalPandangan
				var persentase_arah : float = abs(arah_pandangan)
				_translasi_posisi_z = 0.237 * persentase_arah
				karakter.arah_pandangan.y = arah_pandangan
	
	if $XRCamera3D/target_kursor.is_colliding() and $XRCamera3D/target_kursor.get_collider() == $menu/tampilan_antarmuka/target_kursor:
		var simulasi_input = InputEventMouseMotion.new()
		$menu/tampilan_antarmuka/ref_pos_kursor/posisi_kursor.global_position = $XRCamera3D/target_kursor.get_collision_point()
		$menu/tampilan_antarmuka/ref_pos_kursor/posisi_kursor.position.z = 0
		simulasi_input.position = _dapatkan_posisi_kursor()
		$antarmuka_menu.push_input(simulasi_input)
	
	if $antarmuka_menu/antarmuka_menu_horizontal.visible:
		$menu.position.y = $XRCamera3D.position.y
