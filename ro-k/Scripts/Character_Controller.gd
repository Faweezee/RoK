extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -400.0
const FALL_GRAVITY_MULTIPLIER = 2.0

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D

var is_combat_locked = false 

func _physics_process(delta: float) -> void:
	# 1. Apply Gravity (ALWAYS RUNS)
	if not is_on_floor():
		var current_gravity = get_gravity()
		if velocity.y > 0:
			velocity += current_gravity * FALL_GRAVITY_MULTIPLIER * delta
		else:
			velocity += current_gravity * delta

	# 2. COMBAT LOCK CHECK
	if is_combat_locked:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		
		# If locked on floor, ensure we aren't stuck in a walk loop
		if is_on_floor() and animation.current_animation != "Attack Animation":
			animation.play("Idle Animation")
		return 

	# 3. INPUT GUARD
	var is_busy = false
	if animation.current_animation == "Attack Animation" and animation.is_playing():
		is_busy = true
	# Lock input during Jump Squat (start of jump)
	elif animation.current_animation == "Jump Animation" and is_on_floor():
		is_busy = true
		
	if is_busy:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return 

	# 4. Handle Inputs
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		animation.play("Jump Animation", 0.1)
		# REMOVED: apply_jump_force() 
		# We let the AnimationPlayer Method Track call it later!
		
	if Input.is_action_just_pressed("Attack"):
		animation.play("Attack Animation", 0.1)
		velocity.x = 0 

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

# Called by the Animation Player Track (Do not call manually!)
func apply_jump_force():
	velocity.y = JUMP_VELOCITY

func update_animations(direction):
	if animation.current_animation == "Attack Animation": return 
	if animation.current_animation == "Jump Animation": return 

	if direction != 0:
		animation.play("Walk Animation", 0.1)
	else:
		animation.play("Idle Animation", 0.1)

# --- PUBLIC FUNCTIONS ---
func enter_combat_state():
	is_combat_locked = true
	velocity.x = 0 
	
func exit_combat_state():
	is_combat_locked = false
