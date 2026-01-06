extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const FALL_GRAVITY_MULTIPLIER = 2.0

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity (Modified for snappier falling)
	if not is_on_floor():
		var current_gravity = get_gravity()
		
		# If we are falling (velocity.y > 0), make gravity stronger
		if velocity.y > 0:
			velocity += current_gravity * FALL_GRAVITY_MULTIPLIER * delta
		else:
			# Normal gravity while going up
			velocity += current_gravity * delta

	# 2. INPUT GUARD (The Lock)
	var is_busy = false
	
	if animation.current_animation == "Attack Animation" and animation.is_playing():
		is_busy = true
	elif animation.current_animation == "Jump Animation" and is_on_floor():
		is_busy = true
		
	if is_busy:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return # STOP EVERYTHING BELOW THIS LINE

	# 3. Handle Inputs (Only runs if NOT busy)
	
	# Jump Trigger
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		animation.play("Jump Animation", 0.1) 
		
	# Attack Trigger
	if Input.is_action_just_pressed("Attack"):
		animation.play("Attack Animation", 0.1)
		velocity.x = 0 

	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if direction < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(direction)

# Called by the Animation Player Track
func apply_jump_force():
	velocity.y = JUMP_VELOCITY

func update_animations(direction):
	if animation.current_animation == "Attack Animation":
		return 
	if animation.current_animation == "Jump Animation":
		return 

	if direction != 0:
		animation.play("Walk Animation", 0.1)
	else:
		animation.play("Idle Animation", 0.1)
