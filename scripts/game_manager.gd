# Script: game_manager.gd — Global game state manager for Minor Dai
# Handles game progression, win/death conditions, and state tracking
extends Node

var shards_collected: int = 0
var max_depth_reached: float = 0.0
var game_started: bool = false

signal shard_collected(total_shards: int)
signal game_won(shards: int, depth: float)
signal game_lost(shards: int, depth: float)

func _ready():
	print("GameManager initialized")

func collect_shard():
	shards_collected += 1
	shard_collected.emit(shards_collected)
	print("Shard collected! Total: ", shards_collected)
	
	# Check win condition
	if shards_collected >= 10:
		trigger_win()

func update_depth(depth: float):
	if depth > max_depth_reached:
		max_depth_reached = depth

func trigger_win():
	print("Game won! Shards: ", shards_collected, " Depth: ", max_depth_reached)
	game_won.emit(shards_collected, max_depth_reached)
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")

func trigger_death():
	print("Game lost! Shards: ", shards_collected, " Depth: ", max_depth_reached)
	game_lost.emit(shards_collected, max_depth_reached)
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")

func restart_game():
	shards_collected = 0
	max_depth_reached = 0.0
	game_started = true
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func go_to_menu():
	shards_collected = 0
	max_depth_reached = 0.0
	game_started = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")