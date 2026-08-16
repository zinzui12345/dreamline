extends entitas

const jalur_instance = "res://skena/entitas/puzzle/puzzle_biner_a.scn"
const sinkron_kondisi = [
	["input_biner_1", false],
	["input_biner_2", false],
	["input_biner_4", false],
	["input_biner_8", false],
	["input_biner_16", false],
	["input_biner_32", false],
	["input_biner_64", false],
	["input_biner_128", false],
	["output_desimal", 0]
]

@export var input_biner_1 : bool
@export var input_biner_2 : bool
@export var input_biner_4 : bool
@export var input_biner_8 : bool
@export var input_biner_16 : bool
@export var input_biner_32 : bool
@export var input_biner_64 : bool
@export var input_biner_128 : bool
@export var output_desimal : int :
	set(nilai_baru):
		var dec_str : String = str(nilai_baru).reverse()
		var split_dec : PackedStringArray = dec_str.split()
		for digit_pos in split_dec.size():
			$dec_output.get_child(digit_pos-1).set_value(int(split_dec[digit_pos-1]))
		output_desimal = nilai_baru

#func mulai() -> void:
	#Panku.notify("test")

func cek_nilai(id_pengguna : int) -> void:
	if client.id_koneksi == id_proses:
		var biner_input : Array = [
			int(input_biner_128),
			int(input_biner_64),
			int(input_biner_32),
			int(input_biner_16),
			int(input_biner_8),
			int(input_biner_4),
			int(input_biner_2),
			int(input_biner_1)
		]
		var input_desimal : int = 0
		
		for bit in biner_input:
			input_desimal = (input_desimal << 1) | bit
		
		if input_desimal == output_desimal:
			Panku.notify("benar")
		else:
			Panku.notify("salahh!")
		output_desimal = 0

func proses(_waktu_delta : float) -> void:
	if output_desimal == 0:
		output_desimal = server.permainan.hasilkanAngkaAcak(5, 99)
