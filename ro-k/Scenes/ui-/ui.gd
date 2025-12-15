extends Control

@onready var option_pane: ColorRect = $ColorRect
@onready var volume_bar: HSlider = %Volume_bar


var Background_music = 0

func _ready() -> void:
	volume_bar.value = 1
	option_pane.visible = false
	pass
	
	

func _on_start_pressed() -> void:
	pass # Replace with function body.
	


func _on_options_pressed() -> void:
	option_pane.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()
	


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		print("Fullscreen")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		


func _on_back_pressed() -> void:
	_ready()
	pass # Replace with function body.


func _on_h_slider_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(Background_music, db_value)
	pass # Replace with function body.
