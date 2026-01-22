extends Camera2D

@export var look_ahead_distance = 350.0 # How far ahead to look
@export var shift_speed = 2.0

var target_offset_x = 0.0
var is_locked = false # Combat Lock Flag

func _ready():
	# 1. Start with Player on Left (Looking Right) by default
	# This prevents the camera from "panning forward" suddenly at the start.
	target_offset_x = look_ahead_distance
	offset.x = look_ahead_distance

func _process(delta):
	# 2. If Combat is active, DO NOT move the camera offset
	if is_locked: 
		return

	# 3. Check Input Direction
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction > 0:
		# Moving Right -> Look Ahead Right (Player stays Left)
		target_offset_x = look_ahead_distance
	elif direction < 0:
		# Moving Left -> Look Ahead Left (Player stays Right)
		target_offset_x = -look_ahead_distance
		
	# 4. Smoothly transition to the target
	offset.x = lerp(offset.x, target_offset_x, shift_speed * delta)

# --- PUBLIC FUNCTIONS CALLED BY MAIN ---
func lock_camera():
	is_locked = true

func unlock_camera():
	is_locked = false
