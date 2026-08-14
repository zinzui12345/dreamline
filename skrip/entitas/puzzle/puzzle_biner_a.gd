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
	["input_biner_128", false]
]

var input_biner_1 : bool
var input_biner_2 : bool
var input_biner_4 : bool
var input_biner_8 : bool
var input_biner_16 : bool
var input_biner_32 : bool
var input_biner_64 : bool
var input_biner_128 : bool

#func mulai() -> void:
	#Panku.notify("test")

func cek_nilai(_id_pengguna : int) -> void:
	Panku.notify("TEST")
