extends AudioStreamPlayer3D

@export var vehicle : Vehicle
@export_group("Single Audio")
@export var sample_rpm := 4000.0
@export_group("Multi Audio")
@export var reverse_audio : AudioStream
@export var reverse_rpm := 700.0
@export var low_speed_audio : AudioStream
@export var low_speed_rpm := 1000.0
@export var middle_speed_audio : AudioStream
@export var middle_speed_rpm := 3000.0
@export var high_speed_audio : AudioStream
@export var high_speed_rpm := 4000.0

var multi_audio_mode : bool = false

func _ready() -> void:
	if low_speed_audio != null or middle_speed_audio != null or high_speed_audio != null:
		multi_audio_mode = true

func _physics_process(_delta):
	if multi_audio_mode:
		var current_rpm = vehicle.motor_rpm
		var current_gear = vehicle.current_gear
		if current_gear < 0 and reverse_audio != null:
			if stream != reverse_audio:
				stream = reverse_audio
			pitch_scale = current_rpm / reverse_rpm
		else:
			if current_rpm <= low_speed_rpm and low_speed_audio != null:
				if stream != low_speed_audio:
					stream = low_speed_audio
					play()
				pitch_scale = current_rpm / low_speed_rpm
			elif current_rpm <= middle_speed_rpm and middle_speed_audio != null and (low_speed_audio == null or current_rpm > low_speed_rpm):
				if stream != middle_speed_audio:
					stream = middle_speed_audio
					play()
				pitch_scale = current_rpm / middle_speed_rpm
			elif current_rpm <= high_speed_rpm and high_speed_audio != null and (middle_speed_audio == null or current_rpm > middle_speed_rpm):
				if stream != high_speed_audio:
					stream = high_speed_audio
					play()
				pitch_scale = current_rpm / high_speed_rpm
	else:
		pitch_scale = vehicle.motor_rpm / sample_rpm
	volume_db = linear_to_db((vehicle.throttle_amount * 0.5) + 0.5)
