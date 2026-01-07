extends CharacterBody2D

@export var sprint_speed: float = 300.0
@export var walk_speed: float = 100.0
@export var speed : float
var moving_right : bool = true
@onready var ray_right: RayCast2D = $Raycasts/DirectionRayRight
@onready var ray_player_right: RayCast2D = $Raycasts/DetectionRayCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurt_box: CollisionShape2D = $HurtBox
@onready var chase_ray: RayCast2D = $Raycasts/ChaseRay
@onready var hit_box: Area2D = $HitBox
@onready var Health_bar: TextureProgressBar = $TextureProgressBar
var max_enemy_health: float = 200.0
var enemy_health: float
var damage: float = 25.0

func _ready():
	enemy_health = max_enemy_health
	speed = walk_speed
	_update_health_bar()
	ray_right.enabled = true
	ray_player_right.enabled = true
	scale = Vector2.ONE

func _physics_process(delta: float) -> void:
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	velocity.y += gravity * delta
	_update_health_bar()
	if animation_player.current_animation == "attack" or animation_player.current_animation == "hurt":
		return
	
	if !ray_right.is_colliding() and is_on_floor():
		_flip_direction()	
	
	if ray_player_right.is_colliding(): 
		animation_player.play("attack")	
	elif chase_ray.is_colliding():
		speed = sprint_speed
		animation_player.play("running")
	else: 
		speed = walk_speed
		animation_player.play("walking")
	
	velocity.x = (speed if moving_right else -speed)
		
	move_and_slide()

func _on_hit_box_body_entered(body: Node2D) -> void:
	#call damage deal function from body(player), for now we reload scene
	get_tree().reload_current_scene()

func _flip_direction():
	moving_right = !moving_right
	scale.x = -scale.x

func _update_health_bar():
	Health_bar.value = (enemy_health * 100) / max_enemy_health

func play_walk():
	animation_player.play("walking")

#player will call function to make enemy get damaged
func hurt():
	animation_player.play("hurt")
	enemy_health -= damage;
	if enemy_health <= 0 :
		queue_free()
	
func hit():
	hit_box.monitoring = true

func end_hit():
	hit_box.monitoring = false
