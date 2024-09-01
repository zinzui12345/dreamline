extends AudioStreamPlayer3D

@export var array_suara : Array = []

var sedang_berbicara : bool = false

func _ready() -> void:
	connect("finished", Callable(self, "_ketika_buffer_selesai_dimainkan"))

func bicara(lanjutkan : bool = false) -> void:
	if sedang_berbicara and !lanjutkan: return
	var audio_stream_wav := AudioStreamWAV.new()
	audio_stream_wav.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream_wav.data = array_suara.pop_front()
	#print_debug("pemain %s berbicara dengan BPM : %s" % [get_parent().id_pemain, audio_stream_wav.get_bpm()]) # get_bpm gak di extend di AudioStreamWAV
	stream = audio_stream_wav
	play()
	sedang_berbicara = true
	%balon_bicara.visible = true

func _ketika_buffer_selesai_dimainkan() -> void:
	if array_suara.size() > 0: bicara(true);	%balon_bicara.visible = true
	else: stop();	sedang_berbicara = false;	%balon_bicara.visible = false
