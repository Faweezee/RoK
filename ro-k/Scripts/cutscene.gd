extends Label

var message: String
var number:int = 0
@onready var timer: Timer = $"../Timer"
var timer_running: bool = false
const HAZY_CITY = preload("uid://b7rn10y2rja3l")
var game = false
var allow_change = false
var trial = true
@onready var background: NinePatchRect = $"../NinePatchRect"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	message = "In a distant land not so far away, there was a hunter"
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		text = message
		number = message.length()
		timer.start()
		
		
	if Input.is_action_just_pressed("ui_accept") and allow_change == true:
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
		
	if timer_running == false and allow_change == false:
		timer_running = true
		timer.start()
	pass


func _on_timer_timeout() -> void:
	if number <= message.length() - 1:
		text = text + message[number]
		number = number + 1
		timer_running = false
		allow_change = false
	else:
		allow_change = true
