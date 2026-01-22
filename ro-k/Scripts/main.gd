extends Node2D

@onready var player = $CharacterBody2D
@onready var dog = $DogEnemy 
@onready var battle_hud = $BattleHUD 
# MAKE SURE THIS PATH MATCHES YOUR SCENE TREE:
@onready var camera = $CharacterBody2D/Camera2D 

var is_combat_active = false

func _ready():
	# 1. Connect Signals
	if player.has_node("CombatDetector"):
		player.get_node("CombatDetector").area_entered.connect(_on_combat_triggered)
	
	if battle_hud:
		battle_hud.attack_hit.connect(_on_rhythm_hit)
		
	if dog and dog.has_signal("enemy_died"):
		dog.enemy_died.connect(_on_enemy_defeated)

func _on_combat_triggered(area):
	if is_combat_active: return
	if area.name == "CombatTrigger":
		start_combat()

func start_combat():
	print("MAIN: Starting Combat Sequence")
	is_combat_active = true
	
	# 1. Lock Player (Gravity still works)
	if player.has_method("enter_combat_state"):
		player.enter_combat_state()
	player.animation.play("Idle Animation")
	
	# 2. Lock Camera (Stops panning)
	if camera: camera.lock_camera()
	
	# 3. Lock Enemy
	if dog and is_instance_valid(dog):
		dog.enter_combat_mode()
	
	# 4. Start HUD
	battle_hud.start_combat_mode()

func _on_rhythm_hit(damage_amount):
	player.animation.stop() 
	player.animation.play("Attack Animation")
	
	if dog and is_instance_valid(dog):
		dog.take_damage(damage_amount)

func _on_enemy_defeated():
	print("MAIN: Enemy Defeated!")
	is_combat_active = false
	
	# 1. FORCE STOP HUD
	battle_hud.stop_combat()
	
	# 2. Unlock Player
	if player.has_method("exit_combat_state"):
		player.exit_combat_state()
	
	# 3. Unlock Camera
	if camera: camera.unlock_camera()
	
	player.animation.play("Idle Animation")
