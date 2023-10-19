extends Control

# 22/09/23 @programmerindonesia44

var kontrol = false
var gerak = false
var arah_gerak : Vector2

signal gerakan(arah, objek)

func _ketika_kursor_memasuki_area():	kontrol = true
func _ketika_kursor_keluar_area():		kontrol = false

func _input(event):
	if kontrol: if Input.is_action_just_pressed("aksi1"): gerak = true
	if event is InputEventMouseMotion and gerak:
		arah_gerak = event.relative * 0.25
		emit_signal("gerakan", arah_gerak, self)
	if Input.is_action_just_released("aksi1"):
		#print_debug("oaaaa");
		gerak = false;
		arah_gerak = Vector2.ZERO
		emit_signal("gerakan", arah_gerak, self)

func _ready():
	connect("mouse_entered",self._ketika_kursor_memasuki_area)
	connect("mouse_exited", self._ketika_kursor_keluar_area)
