extends SubViewportContainer
class_name GlowBorderEffectRenderer
# Collection of viewports and shaders to create the glowing border effect.
# The GlowBorderEffectRender configure the needed viewports and
# ViewportContainers to create the glowing border effect.
# To align the internal cameras with the current camera of your
# scene call the camera_transform_changed.

@export_category("Glow Boarder Effect Renderer")

# Cull mask for cameras
## Set the cull mask used to view the visuall layer defined
## for the GlowBorderEffectObject.
@export_flags_3d_render var effect_cull_mask = 0x00400 : set = set_effect_cull_mask # (int, LAYERS_3D_RENDER)
## Set the cull mask use to render the scene. Should
## not include the effect_cull_mask bit.
@export_flags_3d_render var scene_cull_mask = 0xffbff : set = set_scene_cull_mask # (int, LAYERS_3D_RENDER)
## Set the intensity of the border.
@export var intensity = 3.0 : set = set_intensity # (float, 0.0, 5.0, 0.1)

@export_group("External Viewport","external_viewport_")
## Use an external viewport for rendering.
@export var external_viewport_use_external : bool = false
#" The external viewport to use if use external is enabled.
@export var external_viewport_viewport : Viewport = null

# Create references to the internal cameras
@onready var camera_prepass = %Camera3DPrepass
@onready var camera_scene = %Camera3DScene

# Create references to the internal viewports
@onready var view_prepass = $ViewportBlure/ViewportContainerBlureX/ViewportHalfBlure/ViewportContainerBlureY/ViewportPrepass
@onready var view_half_blure = $ViewportBlure/ViewportContainerBlureX/ViewportHalfBlure
@onready var view_blure = $ViewportBlure
@onready var view_scene = $ViewportScene

# Create references to the internal viewport containers
@onready var container_gaussian_y = $ViewportBlure/ViewportContainerBlureX/ViewportHalfBlure/ViewportContainerBlureY
@onready var container_gaussian_x = $ViewportBlure/ViewportContainerBlureX


# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup the shader inputs
	if material != null:
		material.set_shader_parameter("intensity", intensity)
		material.set_shader_parameter("view_prepass", view_prepass.get_texture())
		material.set_shader_parameter("view_blure", view_blure.get_texture())
		
		if external_viewport_use_external and external_viewport_viewport:
			material.set_shader_parameter("view_scene", external_viewport_viewport.get_texture())
		else:
			material.set_shader_parameter("view_scene", view_scene.get_texture())
	
	# Ensure that the internal cameras cull sceen and shadow objects
	camera_prepass.cull_mask = effect_cull_mask
	camera_scene.cull_mask = scene_cull_mask


# Setter function for the effect_cull_mask. Ensure update of prepass camera
func set_effect_cull_mask(val):
	effect_cull_mask = val
	if camera_prepass:
		camera_prepass.cull_mask = effect_cull_mask


# Setter function for the effect_cull_mask. Ensure update of scene camera
func set_scene_cull_mask(val):
	scene_cull_mask = val
	if camera_scene:
		camera_scene.cull_mask = scene_cull_mask


# Setter function for the intensity. Enusre update of the internal shader
func set_intensity(val):
	intensity = val
	if material != null:
		material.set_shader_parameter("intensity", intensity)

# Setter function to enable/disable render process
func atur_proses_render(nilai : bool) -> void:
	if nilai and (!Konfigurasi.render_objek_interaktif or server.permainan.mode_vr): return
	$ViewportBlure/ViewportContainerBlureX/ViewportHalfBlure/ViewportContainerBlureY.visible = nilai
	$ViewportBlure/ViewportContainerBlureX.visible = nilai
	get_viewport().disable_3d = nilai
	%Camera3DPrepass.current = nilai
	%Camera3DScene.current = nilai
	visible = nilai

# Setter function to enable/disable virtual reality mode
func atur_mode_vr(nilai : bool):
	if nilai and visible: atur_proses_render(false)

# Call this function to align the internal cameras in the
# GlowBorderEffectRenderer with an external camera
func camera_transform_changed(camera : Camera3D):
	var transform = camera.global_transform
	camera_prepass.global_transform = transform
	camera_scene.global_transform = transform


# Call this function to update internal cameras with parameters
# from external camera. 
func set_camera_parameters(camera : Camera3D):
	# No need to update the following camera parameters:
	# cull_mask as handled by separate functions
	# current, doppler_tracking as this dosn't affect the geometry of the rendering
	
	# Unhandled properties: attributes, doppler_tracking?
	
	# Update parameters effecting the rendering
	camera_prepass.far = camera.far
	camera_scene.far = camera.far
	
	camera_prepass.fov = camera.fov
	camera_scene.fov = camera.fov
	
	camera_prepass.frustum_offset = camera.frustum_offset
	camera_scene.frustum_offset = camera.frustum_offset
	
	camera_prepass.h_offset = camera.h_offset
	camera_scene.h_offset = camera.h_offset
	
	camera_prepass.keep_aspect = camera.keep_aspect
	camera_scene.keep_aspect = camera.keep_aspect
	
	camera_prepass.near = camera.near
	camera_scene.near = camera.near
	
	camera_prepass.projection = camera.projection
	camera_scene.projection = camera.projection
	
	camera_prepass.size = camera.size
	camera_scene.size = camera.size
	
	camera_prepass.v_offset = camera.v_offset
	camera_scene.v_offset = camera.v_offset


# Callback to receive the current camera transform
func _on_camera_transform_changed(camera : Camera3D):
	camera_transform_changed(camera)
