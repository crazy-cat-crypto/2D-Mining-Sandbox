# Script: title_screen.gd — handles the title screen menu buttons
extends Control

# called when the scene loads
func _ready() -> void:
	# grab button references and connect their signals
	var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
	var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

# start the game when play is clicked
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

# quit when quit is clicked
func _on_quit_pressed() -> void:
	get_tree().quit()
