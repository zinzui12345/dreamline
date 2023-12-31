extends Camera3D


# Sort the exports under this category
@export_category("Glow Boarder Effect Camera")

## Reference to the glow border effect renderer for update of
## camera parameters and transforms.
@export var glow_border_effect_renderer : GlowBorderEffectRenderer


# Called when the node enters the scene tree for the first time.
func _ready():
	# Update the internal cameras in the glow border effect renderer.
	glow_border_effect_renderer.set_camera_parameters(self)
	
	# Turn on notification for camera transform changes.
	set_notify_transform(true)


# Called when the node receive notifications.
func _notification(what):
	# Update the camera transform each time the camera transform change.
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		glow_border_effect_renderer.camera_transform_changed(self)
