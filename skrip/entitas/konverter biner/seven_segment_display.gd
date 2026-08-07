extends MeshInstance3D

@export var led_color : Color = Color.RED :
	set(new_color):
		if led_material != null:
			led_material.albedo_color = new_color
			led_material.emission = new_color
		led_color = new_color

var animation_query : Array = [false, false, false, false, false, false, false]
var led_material : StandardMaterial3D

func _ready() -> void:
	led_material = StandardMaterial3D.new()
	led_material.emission_enabled = true
	led_material.emission_energy_multiplier = 5.0
	$A.material_override = led_material
	$B.material_override = led_material
	$C.material_override = led_material
	$D.material_override = led_material
	$E.material_override = led_material
	$F.material_override = led_material
	$G.material_override = led_material
	led_color = led_color
	$G.visible = true

func set_value(value : int) -> void:
	match value:
		0:	animation_query = [true,	true,	true,	true,	true,	true,	false]
		1:	animation_query = [false,	true,	true,	false,	false,	false,	false]
		2:	animation_query = [true,	true,	false,	true,	true,	false,	true]
		3:	animation_query = [true,	true,	true,	true,	false,	false,	true]
		4:	animation_query = [false,	true,	true,	false,	false,	true,	true]
		5:	animation_query = [true,	false,	true,	true,	false,	true,	true]
		6:	animation_query = [true,	false,	true,	true,	true,	true,	true]
		7:	animation_query = [true,	true,	true,	false,	false,	false,	false]
		8:	animation_query = [true,	true,	true,	true,	true,	true,	true]
		9:	animation_query = [true,	true,	true,	true,	false,	true,	true]
		-1:	animation_query = [false,	false,	false,	false,	false,	false,	false]
	$animation.stop(true)
	$animation.play("change_value")

func animation_frame_1() -> void:
	if animation_query[0]:
		$A.visible = true
	else:
		$A.visible = false
func animation_frame_2() -> void:
	if animation_query[1]:
		$B.visible = true
	else:
		$B.visible = false
func animation_frame_3() -> void:
	if animation_query[2]:
		$C.visible = true
	else:
		$C.visible = false
func animation_frame_4() -> void:
	if animation_query[3]:
		$D.visible = true
	else:
		$D.visible = false
func animation_frame_5() -> void:
	if animation_query[4]:
		$E.visible = true
	else:
		$E.visible = false
func animation_frame_6() -> void:
	if animation_query[5]:
		$F.visible = true
	else:
		$F.visible = false
func animation_frame_7() -> void:
	if animation_query[6]:
		$G.visible = true
	else:
		$G.visible = false
