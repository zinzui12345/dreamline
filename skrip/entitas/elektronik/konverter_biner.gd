extends Node3D

var binary_data : Array = [0, 0, 0, 0, 0, 0, 0, 0]

func _ready() -> void:
	$bin_input/bin_input_1.connect("pressed", binary_input_1)
	$bin_input/bin_input_2.connect("pressed", binary_input_2)
	$bin_input/bin_input_3.connect("pressed", binary_input_3)
	$bin_input/bin_input_4.connect("pressed", binary_input_4)
	$bin_input/bin_input_5.connect("pressed", binary_input_5)
	$bin_input/bin_input_6.connect("pressed", binary_input_6)
	$bin_input/bin_input_7.connect("pressed", binary_input_7)
	$bin_input/bin_input_8.connect("pressed", binary_input_8)
	$bin_output/bin_output_1.set_value(0)
	$bin_output/bin_output_2.set_value(0)
	$bin_output/bin_output_3.set_value(0)
	$bin_output/bin_output_4.set_value(0)
	$bin_output/bin_output_5.set_value(0)
	$bin_output/bin_output_6.set_value(0)
	$bin_output/bin_output_7.set_value(0)
	$bin_output/bin_output_8.set_value(0)

func binary_input_1() -> void:
	if binary_data[7] != 1:
		binary_data[7] = 1
		$bin_output/bin_output_1.set_value(1)
	else:
		binary_data[7] = 0
		$bin_output/bin_output_1.set_value(0)
	calculate_results()
func binary_input_2() -> void:
	if binary_data[6] != 1:
		binary_data[6] = 1
		$bin_output/bin_output_2.set_value(1)
	else:
		binary_data[6] = 0
		$bin_output/bin_output_2.set_value(0)
	calculate_results()
func binary_input_3() -> void:
	if binary_data[5] != 1:
		binary_data[5] = 1
		$bin_output/bin_output_3.set_value(1)
	else:
		binary_data[5] = 0
		$bin_output/bin_output_3.set_value(0)
	calculate_results()
func binary_input_4() -> void:
	if binary_data[4] != 1:
		binary_data[4] = 1
		$bin_output/bin_output_4.set_value(1)
	else:
		binary_data[4] = 0
		$bin_output/bin_output_4.set_value(0)
	calculate_results()
func binary_input_5() -> void:
	if binary_data[3] != 1:
		binary_data[3] = 1
		$bin_output/bin_output_5.set_value(1)
	else:
		binary_data[3] = 0
		$bin_output/bin_output_5.set_value(0)
	calculate_results()
func binary_input_6() -> void:
	if binary_data[2] != 1:
		binary_data[2] = 1
		$bin_output/bin_output_6.set_value(1)
	else:
		binary_data[2] = 0
		$bin_output/bin_output_6.set_value(0)
	calculate_results()
func binary_input_7() -> void:
	if binary_data[1] != 1:
		binary_data[1] = 1
		$bin_output/bin_output_7.set_value(1)
	else:
		binary_data[1] = 0
		$bin_output/bin_output_7.set_value(0)
	calculate_results()
func binary_input_8() -> void:
	if binary_data[0] != 1:
		binary_data[0] = 1
		$bin_output/bin_output_8.set_value(1)
	else:
		binary_data[0] = 0
		$bin_output/bin_output_8.set_value(0)
	calculate_results()

func calculate_results() -> void:
	var dec : int = 0
	var dec_str : String = ""
	var oct_str : String = ""
	var hex_str : String = ""
	var split_dec : PackedStringArray
	var split_oct : PackedStringArray
	
	for dec_val in $dec_output.get_children():
		dec_val.set_value(-1)
	for oct_val in $oct_output.get_children():
		oct_val.set_value(-1)
	
	for bit in binary_data:
		dec = (dec << 1) | bit
	
	dec_str = str(dec).reverse()
	split_dec = dec_str.split()
	for digit_pos in split_dec.size():
		$dec_output.get_child(digit_pos).set_value(int(split_dec[digit_pos]))
	
	oct_str = "%o" % dec
	split_oct = oct_str.reverse().split()
	for digit_pos in split_oct.size():
		$oct_output.get_child(digit_pos).set_value(int(split_oct[digit_pos]))
	
	hex_str= "%X" % dec
	$hex_output/hex_viewport/ui/hex_value.text = hex_str
	
	$sound.play()
