extends objek
class_name patung

const properti = [
	["kondisi", false],
	["kode", "func gunakan():\n\tget_node(\"../../\").berbunyi(true)"]
]
const jalur_instance = "res://skena/objek/patung_moai.scn"

@export var kondisi : bool = false :
	set(berbunyii):
		if _telah_spawn and berbunyii:
			$bunyi.play()
		kondisi = berbunyii

var _telah_spawn : bool

func mulai() -> void:
	set_process(false)
	set_physics_process(false)
	set("wilayah_render", $bentuk.get_aabb())
	$kode_ubahan.atur_kode(properti[1][1])
	$bunyi.connect("finished", _ketika_selesai_berbunyi)
	_telah_spawn = true

func berbunyi(_dummy) -> void:
	if not kondisi and _dummy:
		server.fungsikan_objek(
			name,
			"berbunyi",
			[true]
		)
		set("kondisi", true)
		await get_tree().create_timer(0.1).timeout
		server.fungsikan_objek(
			name,
			"berbunyi",
			[false]
		)
func _ketika_selesai_berbunyi(): set("kondisi", false)
