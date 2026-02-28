# Script: main_game.gd — the core game controller that manages everything
extends Node2D

# the terrain generator creates our underground world
var terrain: Node = null
var terrain_visuals: Node2D = null
var explorer: CharacterBody2D = null
var hud: CanvasLayer = null
var game_timer: float = 0.0
var game_won: bool = false
var all_stones_collected: bool = false
var return_message_shown: bool = false

# cell size matches terrain generator
const CELL_SIZE: int = 32

# preload scripts for enemies and collectibles
var terrain_gen_script: GDScript = preload("res://scripts/terrain_generator.gd")
var explorer_scene: PackedScene = preload("res://scenes/explorer.tscn")
var hud_script: GDScript = preload("res://scripts/game_hud.gd")
var yeti_script: GDScript = preload("res://scripts/yeti_cub.gd")
var naga_script: GDScript = preload("res://scripts/naga.gd")
var firefly_script: GDScript = preload("res://scripts/bhoot_firefly.gd")
var stone_script: GDScript = preload("res://scripts/sacred_stone.gd")
var particle_script: GDScript = preload("res://scripts/mine_particles.gd")
var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
var creeper_scene: PackedScene = preload("res://scenes/creeper.tscn")

# world-space position of the player spawn point (set after _spawn_explorer)
var player_spawn_world_pos: Vector2 = Vector2.ZERO
const ENEMY_SPAWN_EXCLUSION_PX: float = 300.0

# audio placeholders
var win_sound: AudioStreamPlayer = null

func _ready() -> void:
	# set up the win sound placeholder
	win_sound = AudioStreamPlayer.new()
	win_sound.name = "WinSound"
	# TODO: add sound file
	add_child(win_sound)
	
	# create the parallax background
	_create_parallax_background()
	
	# generate terrain
	terrain = terrain_gen_script.new()
	add_child(terrain)
	terrain.generate_world()
	
	# draw the terrain blocks as colored rectangles
	_draw_terrain()
	
	# spawn the player at the surface
	_spawn_explorer()
	
	# create the HUD
	_create_hud()
	
	# spawn sacred stones throughout the underground
	_spawn_sacred_stones()
	
	# spawn enemies in their layers
	_spawn_enemies()

# create a simple parallax background with colored layers
func _create_parallax_background() -> void:
	var parallax_bg: ParallaxBackground = ParallaxBackground.new()
	add_child(parallax_bg)
	
	# layer 1 — deep dark blue, slow scroll
	var layer_1: ParallaxLayer = ParallaxLayer.new()
	layer_1.motion_scale = Vector2(0.1, 0.1)
	var bg_1: ColorRect = ColorRect.new()
	bg_1.position = Vector2(-1000, -500)
	bg_1.size = Vector2(4000, 3000)
	bg_1.color = Color(0.04, 0.02, 0.12)
	layer_1.add_child(bg_1)
	parallax_bg.add_child(layer_1)
	
	# layer 2 — slightly lighter, medium scroll
	var layer_2: ParallaxLayer = ParallaxLayer.new()
	layer_2.motion_scale = Vector2(0.3, 0.2)
	var bg_2: ColorRect = ColorRect.new()
	bg_2.position = Vector2(-1000, -200)
	bg_2.size = Vector2(4000, 2500)
	bg_2.color = Color(0.06, 0.04, 0.15, 0.5)
	layer_2.add_child(bg_2)
	parallax_bg.add_child(layer_2)
	
	# layer 3 — subtle foreground depth
	var layer_3: ParallaxLayer = ParallaxLayer.new()
	layer_3.motion_scale = Vector2(0.5, 0.3)
	var bg_3: ColorRect = ColorRect.new()
	bg_3.position = Vector2(-500, 0)
	bg_3.size = Vector2(3000, 2500)
	bg_3.color = Color(0.08, 0.05, 0.18, 0.3)
	layer_3.add_child(bg_3)
	parallax_bg.add_child(layer_3)

# draw all terrain cells as colored rectangles
func _draw_terrain() -> void:
	terrain_visuals = Node2D.new()
	terrain_visuals.name = "GroundGrid"
	add_child(terrain_visuals)
	
	for row: int in range(terrain.WORLD_HEIGHT):
		for col: int in range(terrain.WORLD_WIDTH):
			var cell_type: int = terrain.grid[row][col]
			# skip air cells
			if cell_type == terrain.CellType.AIR:
				continue
			# create a static body for collision + visual
			_create_terrain_cell(row, col, cell_type)

# create a single terrain cell with visual and collision
func _create_terrain_cell(row: int, col: int, cell_type: int) -> void:
	var cell_body: StaticBody2D = StaticBody2D.new()
	cell_body.position = Vector2(col * CELL_SIZE + CELL_SIZE / 2, row * CELL_SIZE + CELL_SIZE / 2)
	cell_body.name = "Cell_" + str(row) + "_" + str(col)
	cell_body.collision_layer = 1  # terrain layer
	
	# add collision shape
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(CELL_SIZE, CELL_SIZE)
	collision.shape = shape
	cell_body.add_child(collision)
	
	# add colored rectangle visual
	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(CELL_SIZE, CELL_SIZE)
	visual.position = Vector2(-CELL_SIZE / 2, -CELL_SIZE / 2)
	visual.color = terrain.get_cell_color(cell_type)
	cell_body.add_child(visual)
	
	# store the grid coords as metadata for mining
	cell_body.set_meta("grid_row", row)
	cell_body.set_meta("grid_col", col)
	cell_body.set_meta("cell_type", cell_type)
	
	terrain_visuals.add_child(cell_body)

# spawn the player explorer at the surface
func _spawn_explorer() -> void:
	explorer = explorer_scene.instantiate()
	# place player a few blocks above the surface, in the middle
	var spawn_col: int = terrain.WORLD_WIDTH / 2
	var spawn_row: int = terrain.SURFACE_ROW - 2
	explorer.position = Vector2(
		spawn_col * CELL_SIZE + CELL_SIZE / 2,
		spawn_row * CELL_SIZE
	)
	# record spawn position so enemy spawner can maintain exclusion zone
	player_spawn_world_pos = explorer.position
	explorer.game_controller = self
	explorer.add_to_group("explorer")
	add_child(explorer)

# create the HUD overlay
func _create_hud() -> void:
	hud = CanvasLayer.new()
	hud.set_script(hud_script)
	hud.name = "GameHUD"
	add_child(hud)

func _process(delta: float) -> void:
	if game_won or explorer.is_dead:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	
	game_timer += delta
	
	# update depth display
	var current_depth: float = (explorer.position.y / CELL_SIZE) - terrain.SURFACE_ROW
	if current_depth < 0.0:
		current_depth = 0.0
	hud.update_depth(current_depth)
	
	# handle mining with left click
	if Input.is_action_just_pressed("mine"):
		_try_mine()
	
	# check win condition — player at surface with all stones
	if all_stones_collected and explorer.position.y < terrain.SURFACE_ROW * CELL_SIZE:
		_win_game()

# try to mine the block closest to where the player clicked
func _try_mine() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	# convert mouse position to grid coordinates
	var target_col: int = int(mouse_pos.x / CELL_SIZE)
	var target_row: int = int(mouse_pos.y / CELL_SIZE)
	
	# check if the block is adjacent to the player (within 2 cells)
	var player_col: int = int(explorer.position.x / CELL_SIZE)
	var player_row: int = int(explorer.position.y / CELL_SIZE)
	var col_dist: int = abs(target_col - player_col)
	var row_dist: int = abs(target_row - player_row)
	
	if col_dist > 2 or row_dist > 2:
		return  # too far away
	
	# check if the cell is mineable
	if not terrain.is_mineable(target_row, target_col):
		return
	
	# get the cell type for particle color before breaking
	var cell_type: int = terrain.grid[target_row][target_col]
	var block_color: Color = terrain.get_cell_color(cell_type)
	
	# break the block
	terrain.break_cell(target_row, target_col)
	
	# remove the visual/collision node
	var cell_name: String = "Cell_" + str(target_row) + "_" + str(target_col)
	var cell_node: Node = terrain_visuals.get_node_or_null(cell_name)
	if cell_node:
		cell_node.queue_free()
	
	# spawn mine particles
	_spawn_mine_particles(
		Vector2(target_col * CELL_SIZE + CELL_SIZE / 2, target_row * CELL_SIZE + CELL_SIZE / 2),
		block_color
	)
	
	# play mine sound
	if explorer.mine_sound.stream:
		explorer.mine_sound.play()

# create particle effect when a block is broken
func _spawn_mine_particles(world_position: Vector2, block_color: Color) -> void:
	var particles: Node2D = Node2D.new()
	particles.set_script(particle_script)
	particles.position = world_position
	add_child(particles)
	particles.setup(block_color)

# scatter 7 sacred stones throughout the underground
func _spawn_sacred_stones() -> void:
	var stones_placed: int = 0
	var attempts: int = 0
	# place stones at increasing depths, getting rarer deeper
	while stones_placed < 7 and attempts < 500:
		attempts += 1
		# bias deeper stones to be further down
		var min_row: int = terrain.SURFACE_ROW + 3 + (stones_placed * 5)
		var max_row: int = min_row + 12
		max_row = mini(max_row, terrain.WORLD_HEIGHT - 3)
		var row: int = randi_range(min_row, max_row)
		var col: int = randi_range(2, terrain.WORLD_WIDTH - 3)
		# only place in air pockets
		if terrain.grid[row][col] == terrain.CellType.AIR:
			var stone: Area2D = Area2D.new()
			stone.set_script(stone_script)
			stone.position = Vector2(
				col * CELL_SIZE + CELL_SIZE / 2,
				row * CELL_SIZE + CELL_SIZE / 2
			)
			add_child(stone)
			stones_placed += 1
	
	# if we couldn't place all stones in air pockets, force-place remaining
	while stones_placed < 7:
		var row: int = randi_range(terrain.SURFACE_ROW + 5, terrain.WORLD_HEIGHT - 5)
		var col: int = randi_range(3, terrain.WORLD_WIDTH - 4)
		# clear the cell and place the stone
		terrain.grid[row][col] = terrain.CellType.AIR
		var cell_name: String = "Cell_" + str(row) + "_" + str(col)
		var existing: Node = terrain_visuals.get_node_or_null(cell_name)
		if existing:
			existing.queue_free()
		var stone: Area2D = Area2D.new()
		stone.set_script(stone_script)
		stone.position = Vector2(
			col * CELL_SIZE + CELL_SIZE / 2,
			row * CELL_SIZE + CELL_SIZE / 2
		)
		add_child(stone)
		stones_placed += 1

# this spawns the monsters in each layer
func _spawn_enemies() -> void:
	# spawn 8-12 yeti cubs in the dirt layer (rows 10-25)
	var yeti_count: int = randi_range(8, 12)
	for i: int in range(yeti_count):
		_spawn_scripted_enemy_in_range(yeti_script, 10, 25)
	
	# spawn 8-12 nagas in the stone layer (rows 25-40)
	var naga_count: int = randi_range(8, 12)
	for i: int in range(naga_count):
		_spawn_scripted_enemy_in_range(naga_script, 25, 40)
	
	# spawn 8-12 bhoot fireflies in the deep layer (rows 40+)
	var firefly_count: int = randi_range(8, 12)
	for i: int in range(firefly_count):
		_spawn_scripted_enemy_in_range(firefly_script, 40, terrain.WORLD_HEIGHT - 3)
	
	# spawn 12 zombies spread across all underground rows
	for i: int in range(12):
		_spawn_scene_enemy_in_range(zombie_scene, terrain.SURFACE_ROW + 2, terrain.WORLD_HEIGHT - 4)
	
	# spawn 6 creepers spread across all underground rows
	for i: int in range(6):
		_spawn_scene_enemy_in_range(creeper_scene, terrain.SURFACE_ROW + 2, terrain.WORLD_HEIGHT - 4)

# spawn a script-based enemy (old folklore enemies) within a row range
func _spawn_scripted_enemy_in_range(enemy_script: GDScript, min_row: int, max_row: int) -> void:
	var attempts: int = 0
	while attempts < 100:
		attempts += 1
		var row: int = randi_range(min_row, max_row)
		var col: int = randi_range(2, terrain.WORLD_WIDTH - 3)
		# place enemy in air cells that have ground below
		if terrain.grid[row][col] == terrain.CellType.AIR:
			var below_row: int = row + 1
			if below_row < terrain.WORLD_HEIGHT and terrain.is_solid(below_row, col):
				var world_pos: Vector2 = Vector2(
					col * CELL_SIZE + CELL_SIZE / 2,
					row * CELL_SIZE + CELL_SIZE / 2
				)
				# enforce 300px exclusion from player spawn
				if world_pos.distance_to(player_spawn_world_pos) < ENEMY_SPAWN_EXCLUSION_PX:
					continue
				var enemy: CharacterBody2D = CharacterBody2D.new()
				enemy.set_script(enemy_script)
				enemy.position = world_pos
				enemy.collision_layer = 4
				enemy.collision_mask = 1
				add_child(enemy)
				return

# spawn a scene-based enemy (zombie, creeper) within a row range, respecting exclusion zone
func _spawn_scene_enemy_in_range(scene: PackedScene, min_row: int, max_row: int) -> void:
	var attempts: int = 0
	while attempts < 150:
		attempts += 1
		var row: int = randi_range(min_row, max_row)
		var col: int = randi_range(2, terrain.WORLD_WIDTH - 3)
		# valid position: cell is air, cell below is solid
		if terrain.grid[row][col] != terrain.CellType.AIR:
			continue
		var below_row: int = row + 1
		if below_row >= terrain.WORLD_HEIGHT or not terrain.is_solid(below_row, col):
			continue
		var world_pos: Vector2 = Vector2(
			col * CELL_SIZE + CELL_SIZE / 2,
			row * CELL_SIZE + CELL_SIZE / 2
		)
		# enforce 300px exclusion zone around player spawn
		if world_pos.distance_to(player_spawn_world_pos) < ENEMY_SPAWN_EXCLUSION_PX:
			continue
		var enemy: Node = scene.instantiate()
		enemy.position = world_pos
		add_child(enemy)
		return

# called by explorer when HUD needs updating
func update_hud() -> void:
	hud.update_health(explorer.current_health, explorer.max_health)
	hud.update_stones(explorer.sacred_stones_collected)

# show message telling player to return to surface
func show_return_message() -> void:
	all_stones_collected = true
	return_message_shown = true
	hud.show_message("All stones collected! Return to the surface!")

# show the death screen
func show_death_screen() -> void:
	var depth: int = int(explorer.max_depth_reached - terrain.SURFACE_ROW)
	if depth < 0:
		depth = 0
	hud.show_message(
		"You fell to the depths...\n" +
		"Depth reached: " + str(depth) + " blocks\n" +
		"Press R to restart"
	)

# handle the win condition
func _win_game() -> void:
	game_won = true
	var depth: int = int(explorer.max_depth_reached - terrain.SURFACE_ROW)
	if depth < 0:
		depth = 0
	var time_seconds: int = int(game_timer)
	# play win sound
	if win_sound.stream:
		win_sound.play()
	hud.show_message(
		"You uncovered the Heart of the Mountain!\n" +
		"Depth reached: " + str(depth) + " blocks\n" +
		"Time: " + str(time_seconds) + " seconds\n" +
		"Press R to play again"
	)
