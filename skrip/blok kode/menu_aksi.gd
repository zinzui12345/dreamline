extends Button

@onready var daftar_aksi = $_menu_aksi/daftar_aksi

func _ready():
	connect("toggled", tampilkan_menu)

func tampilkan_menu(nilai):
	if nilai:
		for m_menu in get_node("../../").daftar_kelas_sintaks:
			if m_menu != self:
				m_menu.get_node("_menu_aksi").visible = false
				m_menu.button_pressed = false
	$_menu_aksi.visible = nilai
