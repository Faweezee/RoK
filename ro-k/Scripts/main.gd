extends Node2D

@onready var player = $CharacterBody2D
@onready var dog = $DogEnemy 
@onready var battle_hud = $BattleHUD 
@onready var camera = $CharacterBody2D/Camera2D 

var is_combat_active = false

func _ready():
	if player.has_node("CombatDetector"):
		player.get_node("CombatDetector").area_entered.connect(_on_combat_triggered)
	if battle_hud:
		battle_hud.attack_hit.connect(_on_player_attack_hit)
		battle_hud.player_hurt.connect(_on_player_hurt_by_enemy)
	if dog and dog.has_signal("enemy_died"):
		dog.enemy_died.connect(_on_enemy_defeated)
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_defeated)

func _on_combat_triggered(area):
	if is_combat_active: return
	if area.name == "CombatTrigger": start_combat()

func start_combat():
	print("MAIN: Starting Combat")
	is_combat_active = true
	if player.has_method("enter_combat_state"): player.enter_combat_state()
	player.animation.play("Idle Animation")
	if camera: camera.lock_camera()
	if dog and is_instance_valid(dog): dog.enter_combat_mode()
	battle_hud.start_combat_mode()

# --- PLAYER ATTACK TURN ---
func _on_player_attack_hit(damage_amount):
	if dog and is_instance_valid(dog):
		battle_hud.hide_reticles()
		
		# CHECK: Did we hit?
		var is_hit = (damage_amount > 0)
		
		# 1. Player always zips in (Sound only plays if is_hit == true)
		player.perform_zip_attack(dog.global_position, is_hit)
		
		# 2. Sync wait
		await get_tree().create_timer(0.25).timeout 
		
		if is_hit:
			dog.take_damage(damage_amount)
		else:
			print("MAIN: Player Missed! Dog Dodging.")
			dog.perform_dodge()
	else:
		player.animation.play("Attack Animation")

# --- ENEMY ATTACK TURN ---
func _on_player_hurt_by_enemy(damage_amount):
	battle_hud.hide_reticles()
	
	if dog and is_instance_valid(dog):
		
		# CASE A: PERFECT DODGE (0 Damage)
		if damage_amount == 0:
			print("MAIN: Perfect Dodge!")
			player.perform_dodge_zip(200.0)
			# Enemy attacks original spot -> FALSE for no sound
			dog.perform_attack(player.original_combat_position, false)
			
		# CASE B: PARTIAL DODGE (Partial Damage)
		elif damage_amount < 34: 
			print("MAIN: Partial Dodge!")
			player.perform_dodge_zip(100.0)
			await get_tree().create_timer(0.05).timeout
			# Enemy attacks new spot -> TRUE for sound (still a hit)
			dog.perform_attack(player.global_position, true)
			
			await get_tree().create_timer(0.25).timeout
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
			
		# CASE C: FULL HIT
		else:
			print("MAIN: Direct Hit!")
			# Enemy attacks Player directly -> TRUE for sound
			dog.perform_attack(player.global_position, true)
			
			await get_tree().create_timer(0.25).timeout
			if player.has_method("take_damage"):
				player.take_damage(damage_amount)
	else:
		print("MAIN: Player Dodged! (No Dog found)")

func _on_enemy_defeated():
	print("MAIN: Enemy Defeated!")
	_end_combat()

# --- FADE TO BLACK AND RESPAWN ---
func _on_player_defeated():
	print("MAIN: Player Defeated! Fading out...")
	_end_combat()
	
	# 1. Wait for Player Sprite to fade
	await get_tree().create_timer(1.5).timeout
	
	# Make HUD visible for overlay
	battle_hud.visible = true
	
	# 2. Create a black screen overlay
	var overlay = ColorRect.new()
	overlay.color = Color.BLACK
	overlay.color.a = 0.0 
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	battle_hud.add_child(overlay) 
	
	# 3. Fade to Black
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	await tween.finished
	
	# 4. Hold
	await get_tree().create_timer(0.5).timeout
	
	# 5. Reload Scene
	get_tree().reload_current_scene()

func _end_combat():
	is_combat_active = false
	battle_hud.stop_combat()
	if player.has_method("exit_combat_state"): player.exit_combat_state()
	if camera: camera.unlock_camera()
	player.animation.play("Idle Animation")
