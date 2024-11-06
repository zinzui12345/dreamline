extends Node3D

@onready var karakter = $lulu

func _ready():
	$lulu/model/AnimationPlayer.get_animation("anim/berjalan_maju").loop_mode = Animation.LOOP_LINEAR
	$lulu/model/AnimationPlayer.play("anim/berjalan_maju")
	$AnimationPlayer.play("putar_cahaya")

func _process(delta):
	$Label.text = "%s\n%sfps\n%sMib [static]" % [get_tree().get_root().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME), Engine.get_frames_per_second(), OS.get_static_memory_usage()]
