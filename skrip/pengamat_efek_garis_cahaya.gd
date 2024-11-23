extends Camera3D

## Referensi ke perender efek garis cahaya
## parameter kamera dan transformasi.
var perender_efek_garis_cahaya : GlowBorderEffectRenderer :
	set(node):
		# Pastikan node valid
		if node != null:
			# Perbarui kamera internal pada perender efek garis cahaya.
			node.set_camera_parameters(self)
			
			# Sesuaikan lapisan render perender efek garis cahaya dengan kamera internal
			node.set_scene_cull_mask(cull_mask)
			
			# Aktifkan notifikasi transformasi untuk kamera.
			set_notify_transform(true)
		
		# Terapkan referensi node
		perender_efek_garis_cahaya = node

# Fungsi untuk mengaktifkan efek
func aktifkan_efek():
	# Atur node perender efek garis cahaya
	perender_efek_garis_cahaya = PerenderEfekGarisCahaya

# Fungsi untuk menonaktifkan efek
func nonaktifkan_efek():
	# Hapus node perender efek garis cahaya
	perender_efek_garis_cahaya = null

# Dipanggil ketika node menerima notifikasi.
func _notification(what):
	# Perbarui transformasi kamera setiap transformasi kamera berubah.
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		# Pastikan perender efek garis cahaya telah diterapkan
		if perender_efek_garis_cahaya != null:
			perender_efek_garis_cahaya.camera_transform_changed(self)
