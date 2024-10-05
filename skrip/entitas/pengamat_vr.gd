extends XROrigin3D

var aktif = false : 
	set(akt):
		set_process(akt)
		aktif = akt
var interface : MobileVRInterface
var karakter : Karakter

var _translasi_posisi_z : float = 0

func _enter_tree() -> void:
	set_process(aktif)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and aktif:
		server.permainan._ketika_mengatur_mode_vr(false)
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
		karakter.rotation_degrees.y = $XRCamera3D.rotation_degrees.y + $XRCamera3D/arah_pemain.rotation_degrees.y
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
