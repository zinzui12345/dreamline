extends Node2D

# Original By kubecz3k
# Converted By CSGames18
# Release Date: 22/05/2019

# How To Use:
# 1.
# The Analog scene should be nested under a Control node that has its Rect.Size filled out.
# The controls rect will be required if you want to use the dynamic placement feature of the Virtual Analog
# The controls rect will act as a bounding box for where on the screen the dynamic Virtual Analog can be used
# 2.
# Connect the analog_force_change signal on the Analog node to a listening node.
# This signal gives the direction vector2 of the analog, and the name given to the analog.
# Use the analogName variable if you need to handle different analog's at the same listening point.

signal touch_start()
signal touch_move(vector2, analog)
signal touch_stop()

const INACTIVE_IDX = -1

var isDynamicallyShowing = true
@export var analogName = ""

var ball
var bg 
var animationPlayer
var parent

var centerPoint = Vector2(0,0)
var currentForce = Vector2(0,0)
var halfSize = Vector2()
var ballPos = Vector2()
var squaredHalfSizeLength = 0
var currentPointerIDX = INACTIVE_IDX;

func _ready():
	set_process_input(true)
	get_nodes()
	calculate_node_sizes()
	
	if isDynamicallyShowing:
		#Hide the dynamic analog imediately
		self.modulate.a = 0

func get_nodes():
	bg = get_node("Background")
	ball = get_node("Ball")	
	animationPlayer = get_node("AnimationPlayer")
	parent = get_parent()

func calculate_node_sizes():
	halfSize = bg.get_rect().size / 2
	squaredHalfSizeLength = halfSize.x * halfSize.y
	
func _input(event):
	if get_parent().visible:
		if visible or isDynamicallyShowing:		#untuk mencegah deteksi ketika analog disable
			var incomingPointer = extract_pointer_index(event)
			if incomingPointer == INACTIVE_IDX:
				#Input was not a touch
				return
			
			if check_change_active_pointer(event):
				if (currentPointerIDX != incomingPointer) and event.is_pressed():
					currentPointerIDX = incomingPointer;
					show_at_position(Vector2(event.position.x, event.position.y))

			var theSamePointer = currentPointerIDX == incomingPointer
			if is_active() and theSamePointer:
				#Touch is the same as the current touch
				process_input(event)

func check_change_active_pointer(event):
	var touch = event is InputEventScreenTouch
	
	if touch:
		if isDynamicallyShowing:
			#Determines if the touch was within the dynamic bounding rectangle (from parent Control node)
			return get_parent().get_global_rect().has_point(Vector2(event.position.x, event.position.y))
		else:
			#Determines if the touch was within the static virtual analog
			var length = (self.global_position - Vector2(event.position.x, event.position.y)).length_squared();
			return length < squaredHalfSizeLength
	else:
		#Not a touch event
		return false

func is_active():
	return currentPointerIDX != INACTIVE_IDX

func extract_pointer_index(event):
	var touch = event is InputEventScreenTouch
	var drag = event is InputEventScreenDrag
	
	if touch or drag:
		#Returns the touch index (incase of multi-touch)
		return event.index
	else:
		#Represents no touch happening
		return INACTIVE_IDX
		
func process_input(event):
	calculate_force(event.position.x - self.global_position.x, event.position.y - self.global_position.y)
	updateBallPos()
	
	var isReleasedd = isReleased(event)
	if isReleasedd:
		reset()


func reset():
	currentPointerIDX = INACTIVE_IDX
	calculate_force(0, 0)

	if isDynamicallyShowing:
		updateBallPos()
		_hide()
	else:
		updateBallPos()

func show_at_position(pos):
	#If virtual analog is dynamic, makes the analog appear at touch position
	if isDynamicallyShowing and get_parent().visible:
		animationPlayer.play("alpha_in")
		emit_signal("touch_start")
		self.global_position = pos

func _hide():
	emit_signal("touch_stop")
	animationPlayer.play("alpha_out") 

func updateBallPos():
	ballPos.x = halfSize.x * currentForce.x #+ halfSize.x
	ballPos.y = halfSize.y * -currentForce.y #+ halfSize.y
	ball.position = ballPos

func calculate_force(x, y):
	#gets direction
	currentForce.x =  (x - centerPoint.x)/halfSize.x
	currentForce.y = -(y - centerPoint.y)/halfSize.y
	
	#limit 
	#if currentForce.length_squared()>1:
	#	currentForce=currentForce/currentForce.length()
	
	emit_signal("touch_move", currentForce, self)

func isPressed(event):
	if event.type == InputEventScreenTouch:
		return event.pressed

func isReleased(event):
	if event is InputEventScreenTouch:
		return !event.pressed
