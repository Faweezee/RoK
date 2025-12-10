extends CharacterBody2D

@export var speed : float = 100.0        # walking speed
@export var sprint_speed : float = 200.0 # when chasing player / attacking
var direction : int = 1                  # 1 = moving right; -1 = moving left
@onready var ray_right: RayCast2D = $Raycasts/DirectionRayRight
@onready var ray_left: RayCast2D = $Raycasts/DirectionRayLeft
@onready var ray_player_right: RayCast2D = $Raycasts/DetectionRayCast
@onready var ray_player_left: RayCast2D = $Raycasts/DetectionRayCastLeft
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: CollisionShape2D = $CollisionShape2D
@onready var Health_bar: TextureProgressBar = $TextureProgressBar
var max_enemy_health: float = 200.0
var enemy_health: float

var chasing : bool = false

func _ready():
	enemy_health = max_enemy_health
	_update_health_bar()
	ray_left.enabled = true
	ray_right.enabled = true
	ray_player_left.enabled = true
	ray_player_right.enabled = true
	sprite.flip_h = false

func _physics_process(delta: float) -> void:
	# detect walls and flip if needed
	if direction > 0 and ray_right.is_colliding():
		_flip_direction()
	elif direction < 0 and ray_left.is_colliding():
		_flip_direction()

	# detect player for chase/attack
	if direction > 0:
		chasing = ray_player_right.is_colliding()
	else:
		chasing = ray_player_left.is_colliding()

	# set horizontal velocity based on chase or patrol
	velocity.x = (sprint_speed if chasing else speed) * direction

	# optionally apply gravity (if needed)
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	velocity.y += gravity * delta

	# move the body
	move_and_slide()

	# update sprite
	sprite.flip_h = (direction < 0)
	sprite.play("attack" if chasing else"walking")

func _flip_direction():
	direction = -direction

func _update_health_bar():
	Health_bar.value = (enemy_health * 100) / max_enemy_health
