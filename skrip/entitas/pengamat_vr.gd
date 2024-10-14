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

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and aktif:
		server.permainan._ketika_mengatur_mode_vr(false)
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
		get_viewport().use_xr = true
		set("aktif", true)
func _nonaktifkan() -> void:
	if interface != null:
		set("aktif", false)
		get_viewport().use_xr = false
		interface.uninitialize()

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
