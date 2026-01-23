extends CanvasLayer

signal attack_hit(damage_amount) 
signal player_hurt(damage_amount) 
signal turn_ended

@onready var container = $Control/ReticleContainer
@onready var green_reticle = $Control/ReticleContainer/GreenReticle
@onready var feedback_label = $Control/TurnBar/RichTextLabel 
@onready var turn_bar = $Control/TurnBar
@onready var music_player = $MusicPlayer 

var tween: Tween
var is_player_turn = true 
var can_input = false
var combat_ended = false 
var turn_action_count = 0 
const PLAYER_COLOR = Color("#569e16") 
const ENEMY_COLOR = Color("#C72F2A") 

# --- RHYTHM SETTINGS ---
const BPM = 120.0
const SEC_PER_BEAT = 60.0 / BPM 
const RETICLE_DURATION = SEC_PER_BEAT * 2 
const PERFECT_SCALE = 0.0 # The scale at the exact moment of the beat

# --- MANUAL DELAY SETTINGS (Base Values) ---
var base_reticle_delays = [
	SEC_PER_BEAT * 2.7, 
	SEC_PER_BEAT * 3.5, 
	SEC_PER_BEAT * 3.5
]
# We use this var to apply corrections without ruining the base values
var current_correction = 0.0 

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

func _hide_all_ui():
	self.visible = false
	if container: container.visible = false
	if turn_bar: turn_bar.visible = false
	if green_reticle: green_reticle.visible = false
	if feedback_label: feedback_label.text = ""

func hide_reticles():
	container.visible = false
	green_reticle.visible = false

func fade_in_reticles():
	if combat_ended: return
	container.modulate.a = 0.0 
	container.visible = true
	var fade_tween = create_tween()
	fade_tween.tween_property(container, "modulate:a", 1.0, SEC_PER_BEAT) 

func stop_combat():
	combat_ended = true
	is_player_turn = false
	can_input = false
	if tween: tween.kill()
	
	if music_player and music_player.playing:
		var music_tween = create_tween()
		music_tween.tween_property(music_player, "volume_db", -80.0, 1.5)
		music_tween.tween_callback(music_player.stop)
		music_tween.tween_callback(func(): music_player.volume_db = 0.0)
	
	_hide_all_ui()

func start_combat_mode():
	combat_ended = false
	print("HUD: Combat Mode Activated")
	self.visible = true
	turn_bar.visible = true 
	
	if music_player and not music_player.playing:
		music_player.volume_db = 0.0 
		music_player.play()
	
	start_player_turn_phase()

func start_player_turn_phase():
	if combat_ended: return
	is_player_turn = true
	turn_action_count = 0
	current_correction = 0.0 # Reset sync correction for new turn
	turn_bar.color = PLAYER_COLOR
	feedback_label.text = "[center][b]PLAYERS TURN[/b][/center]"
	var screen_size = get_viewport().get_visible_rect().size
	container.global_position = Vector2(screen_size.x * 0.75, screen_size.y * 0.5) - (container.size / 2)
	
	fade_in_reticles()
	
	await get_tree().create_timer(SEC_PER_BEAT * 3).timeout
	if not combat_ended: next_reticle_cycle()

func start_enemy_turn_phase():
	if combat_ended: return
	is_player_turn = false
	turn_action_count = 0
	current_correction = 0.0 # Reset sync correction for new turn
	turn_bar.color = ENEMY_COLOR
	feedback_label.text = "[center][b]ENEMIES TURN[/b][/center]"
	var screen_size = get_viewport().get_visible_rect().size
	container.global_position = Vector2(screen_size.x * 0.25, screen_size.y * 0.5) - (container.size / 2)
	
	fade_in_reticles()
	
	await get_tree().create_timer(SEC_PER_BEAT * 3).timeout
	if not combat_ended: next_reticle_cycle()

func next_reticle_cycle():
	if combat_ended: return
	if turn_action_count >= 3:
		if is_player_turn: start_enemy_turn_phase()
		else: start_player_turn_phase()
		return

	if not container.visible:
		fade_in_reticles()

	green_reticle.visible = false
	feedback_label.text = "[center][b]GET READY...[/b][/center]"
	feedback_label.visible = true 
	
	# --- AUTO-SYNC LOGIC ---
	# Base delay + the correction from the previous hit
	var calculated_delay = base_reticle_delays[turn_action_count] + current_correction
	
	# Clamp to prevent negative times or extremely long waits
	calculated_delay = max(0.1, calculated_delay)
	
	# Reset correction so it doesn't compound forever
	current_correction = 0.0 
	
	await get_tree().create_timer(calculated_delay).timeout
	if not combat_ended: spawn_reticle()

func spawn_reticle():
	if combat_ended: return
	
	if is_player_turn: feedback_label.text = "[center][b]HIT![/b][/center]"
	else: feedback_label.text = "[center][b]DODGE![/b][/center]"
	green_reticle.visible = true
	green_reticle.scale = Vector2(3.5, 3.5)
	can_input = true
	
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(green_reticle, "scale", Vector2(0, 0), RETICLE_DURATION)
	tween.finished.connect(_on_miss)

func _input(event):
	if not can_input: return
	if event.is_action_pressed("Attack"): check_timing()

func check_timing():
	if tween and tween.is_running():
		tween.stop()
		can_input = false 
		var current_scale = green_reticle.scale.x
		
		# --- CALCULATE SYNC CORRECTION ---
		# current_scale tells us how much "Time" was left in the tween.
		# Range: 3.5 (Start) -> 0.0 (End/Perfect Beat)
		# If scale is > 0, they pressed EARLY. We need to WAIT LONGER next time.
		
		# Calculate exact time remaining in seconds based on scale
		# Formula: (Current Scale / Max Scale) * Duration
		var time_remaining = (current_scale / 3.5) * RETICLE_DURATION
		
		# If we hit around scale 1.0 (Beat minus 0.25s), we compare against the 'Perfect' point.
		# But simpler logic: whatever time was "saved" by clicking early
		# must be added to the NEXT delay to realign with the beat grid.
		
		# We target roughly the 0.25s mark (Zip time) before 0.0
		# So if they click at 0.3s remaining, they are 0.05s EARLY.
		# Next delay should be +0.05s.
		
		var target_hit_time = 0.25 # The ideal time remaining (Zip speed)
		var diff = time_remaining - target_hit_time
		
		# Apply the difference to the next delay
		current_correction = diff
		
		# --- STANDARD HIT LOGIC ---
		if is_player_turn:
			if current_scale <= 1.1 and current_scale >= 0.8: _resolve_result("[center][b]GREAT![/b][/center]", 35, true)
			elif current_scale <= 1.6 and current_scale > 1.1: _resolve_result("[center][b]GOOD![/b][/center]", 15, true)
			else: _resolve_result("[center][b]MISS[/b][/center]", 0, true)
		else:
			if current_scale <= 1.1 and current_scale >= 0.8: _resolve_result("[center][b]PERFECT DODGE![/b][/center]", 0, false)
			elif current_scale <= 1.6 and current_scale > 1.1: _resolve_result("[center][b]PARTIAL DODGE[/b][/center]", 25, false) 
			else: _resolve_result("[center][b]HIT![/b][/center]", 34, false) 

func _on_miss():
	if can_input:
		can_input = false
		
		# If they completely missed (time ran out), we are essentially ON BEAT
		# because the tween finished fully. No correction needed usually,
		# or we reset to baseline.
		current_correction = 0.0
		
		if is_player_turn: _resolve_result("[center][b]MISS[/b][/center]", 0, true)
		else: _resolve_result("[center][b]HIT![/b][/center]", 34, false)

func _resolve_result(text, value, is_attack):
	feedback_label.text = text
	feedback_label.visible = true
	
	if is_attack:
		emit_signal("attack_hit", value) 
	else:
		emit_signal("player_hurt", value) 
	
	green_reticle.visible = false
	
	if value > 0 or (not is_attack and value == 0): 
		container.visible = false 
	
	turn_action_count += 1
	
	# Wait 3 beats (1.5s) for animation to finish
	await get_tree().create_timer(SEC_PER_BEAT * 3).timeout
	if not combat_ended: next_reticle_cycle()
