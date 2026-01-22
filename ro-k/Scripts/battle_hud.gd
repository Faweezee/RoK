extends CanvasLayer

signal attack_hit(damage_amount) 
signal turn_ended

# --- NODES ---
@onready var container = $Control/ReticleContainer
@onready var green_reticle = $Control/ReticleContainer/GreenReticle
@onready var feedback_label = $Control/TurnBar/RichTextLabel 
@onready var turn_bar = $Control/TurnBar

var tween: Tween
var is_player_turn = false
var can_input = false
var combat_ended = false 

func _ready():
	_hide_all_ui()
	if container: container.set_anchors_preset(Control.PRESET_CENTER)
	reset_reticle_positions()

func reset_reticle_positions():
	if not container: return
	var center_offset = container.size / 2 
	for child in container.get_children():
		if child is Control:
			child.position = center_offset - (child.size / 2)
	if green_reticle: green_reticle.pivot_offset = green_reticle.size / 2 

# --- HELPER TO HIDE EVERYTHING ---
func _hide_all_ui():
	self.visible = false
	if container: container.visible = false
	if turn_bar: turn_bar.visible = false
	if green_reticle: green_reticle.visible = false
	if feedback_label: feedback_label.text = ""

func stop_combat():
	print("HUD: Stopping Combat...")
	combat_ended = true
	is_player_turn = false
	can_input = false
	
	# Kill animation immediately
	if tween: tween.kill()
	
	# Force hide everything
	_hide_all_ui()

func start_combat_mode():
	combat_ended = false
	print("HUD: Combat Mode Activated")
	self.visible = true
	turn_bar.visible = true 
	
	feedback_label.text = "[center][b]PLAYERS TURN[/b][/center]"
	container.visible = false 
	
	# Intro Wait (1.5s)
	await get_tree().create_timer(1.5).timeout
	if not combat_ended: start_player_turn_loop()

func start_player_turn_loop():
	if combat_ended: return 
	
	is_player_turn = true
	container.visible = true
	green_reticle.visible = false
	feedback_label.text = "[center][b]GET READY...[/b][/center]"
	
	# Loop Wait (1.0s)
	await get_tree().create_timer(1.0).timeout
	if not combat_ended: spawn_reticle()

func spawn_reticle():
	if combat_ended: return
	
	feedback_label.text = "[center][b]HIT![/b][/center]"
	
	green_reticle.visible = true
	green_reticle.scale = Vector2(3.5, 3.5)
	can_input = true
	
	if tween: tween.kill()
	tween = create_tween()
	
	# Shrink Speed (1.2s)
	tween.tween_property(green_reticle, "scale", Vector2(0, 0), 1.2)
	tween.finished.connect(_on_miss)

func _input(event):
	if not is_player_turn or not can_input: return
	if event.is_action_pressed("Attack"):
		check_hit_timing()

func check_hit_timing():
	if tween and tween.is_running():
		tween.stop()
		can_input = false 
		
		var current_scale = green_reticle.scale.x
		
		if current_scale <= 1.1 and current_scale >= 0.8:
			_resolve_hit("[center][b]GREAT![/b][/center]", 35) 
		elif current_scale <= 1.6 and current_scale > 1.1:
			_resolve_hit("[center][b]GOOD![/b][/center]", 15) 
		else:
			_resolve_hit("[center][b]MISS[/b][/center]", 0)

func _on_miss():
	if can_input:
		can_input = false
		_resolve_hit("[center][b]MISS[/b][/center]", 0)

func _resolve_hit(text, damage):
	if combat_ended: return 

	feedback_label.text = text
	if damage > 0: emit_signal("attack_hit", damage)
	
	green_reticle.visible = false
	
	# Cooldown Wait (1.5s)
	await get_tree().create_timer(1.5).timeout
	if not combat_ended: start_player_turn_loop()
