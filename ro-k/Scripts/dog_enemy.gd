extends CharacterBody2D

signal enemy_died # Tell Main script we died

# --- SETTINGS ---
@export var patrol_distance: float = 200.0  
@export var patrol_speed: float = 60.0
@export var max_health: float = 100.0
@export var damage_amount: float = 20.0

# --- STATE MACHINE ---
enum State { PATROL, COMBAT_IDLE, HURT, DEAD } 
var current_state: State = State.PATROL
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_health: float
var start_x: float
var heading_right: bool = true

# --- NODES ---
@onready var pivot: Node2D = $Pivot 
@onready var anim_player: AnimationPlayer = $Pivot/AnimationPlayer
@onready var health_bar: TextureProgressBar = $TextureProgressBar

func _ready() -> void:
	current_health = max_health
	start_x = global_position.x 
	_update_health_bar()
	
	health_bar.max_value = max_health
	health_bar.value = current_health

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	match current_state:
		State.PATROL:
			_state_patrol(delta)
		State.COMBAT_IDLE:
			velocity.x = 0
			# Only play idle if we aren't hurting/dying
			if anim_player.current_animation != "hurt" and anim_player.current_animation != "death":
				anim_player.play("idle")
		State.HURT:
			velocity.x = 0
		State.DEAD:
			velocity.x = 0

	move_and_slide()

func _state_patrol(delta):
	anim_player.play("walk")
	
	if heading_right:
		velocity.x = patrol_speed
		if global_position.x >= start_x + patrol_distance:
			heading_right = false
	else:
		velocity.x = -patrol_speed
		if global_position.x <= start_x - patrol_distance:
			heading_right = true
			
	if velocity.x > 0: pivot.scale.x = 1
	elif velocity.x < 0: pivot.scale.x = -1

func enter_combat_mode():
	current_state = State.COMBAT_IDLE
	pivot.scale.x = -1 
	anim_player.play("idle")

func take_damage(amount: float):
	current_health -= amount
	_update_health_bar()
	
	if current_health <= 0:
		die()
	else:
		# 1. Play Hurt Animation
		current_state = State.HURT
		await get_tree().create_timer(0.4).timeout
		anim_player.play("hurt")
		
		# 2. Wait for it to finish
		await anim_player.animation_finished
		
		await get_tree().create_timer(0.1).timeout
		
		# 3. Return to Idle (if still alive)
		if current_state != State.DEAD:
			current_state = State.COMBAT_IDLE
			anim_player.play("idle")

func die():
	current_state = State.DEAD
	emit_signal("enemy_died") # Notify Main!
	
	# 1. Play Death Animation
	anim_player.play("death")
	
	# 2. Wait for animation to finish
	await anim_player.animation_finished
	
	# 3. Wait 1 extra second (Corpse stays on floor)
	await get_tree().create_timer(1.2).timeout
	
	# 4. Despawn
	queue_free()

func _update_health_bar():
	health_bar.value = current_health
