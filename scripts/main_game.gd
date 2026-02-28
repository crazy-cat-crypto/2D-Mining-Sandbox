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

# echo shard collection tracking (Section 3)
var shards_collected: int = 0
const shards_needed: int = 10
const total_shards: int = 15

# hold-mining state (Section 4)
var mining_cursor: Node2D = null
var is_mining: bool = false
var mining_row: int = -1
var mining_col: int = -1
var mine_progress: float = 0.0
# break times per cell type in seconds (snappy: all under 0.8s)
const MINE_TIME: Dictionary = { 1: 0.35, 2: 0.55, 3: 0.75 }  # dirt, stone, obsidian
# screen shake state
var shake_magnitude: float = 0.0
var shake_timer: float = 0.0

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
	
	# mark 15 solid tiles as echo shard tiles and give them a cyan glow
	_place_echo_shards()
	
	# spawn the player at the surface
	_spawn_explorer()
	
	# create the HUD
	_create_hud()
	
	# create the mining cursor overlay (drawn in world space)
	var cursor_script: GDScript = preload("res://scripts/mining_cursor.gd")
	mining_cursor = Node2D.new()
	mining_cursor.set_script(cursor_script)
	add_child(mining_cursor)
	
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
	
	# update depth display every frame
	var current_depth: float = (explorer.position.y / CELL_SIZE) - terrain.SURFACE_ROW
	if current_depth < 0.0:
		current_depth = 0.0
	hud.update_depth(current_depth)
	
	# apply screen shake to the player camera
	if shake_timer > 0.0:
		shake_timer -= delta
		var camera: Camera2D = explorer.get_node_or_null("Camera")
		if camera:
			camera.offset = Vector2(
				randf_range(-shake_magnitude, shake_magnitude),
				randf_range(-shake_magnitude, shake_magnitude)
			)
		if shake_timer <= 0.0 and camera:
			camera.offset = Vector2.ZERO
	
	# update HUD (health bar, shard count)
	update_hud()
	
	# update hold-mining every frame
	_handle_mining(delta)
	
	# check win condition — player at surface with all stones
	if all_stones_collected and explorer.position.y < terrain.SURFACE_ROW * CELL_SIZE:
		_win_game()

# this runs every frame and handles hold-to-mine logic with cursor overlay
func _handle_mining(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var hovered_col: int = int(mouse_pos.x / CELL_SIZE)
	var hovered_row: int = int(mouse_pos.y / CELL_SIZE)
	var player_col: int = int(explorer.position.x / CELL_SIZE)
	var player_row: int = int(explorer.position.y / CELL_SIZE)
	var in_range: bool = abs(hovered_col - player_col) <= 2 and abs(hovered_row - player_row) <= 2
	var can_mine: bool = in_range and terrain.is_mineable(hovered_row, hovered_col)
	
	if Input.is_action_pressed("mine") and can_mine:
		# if we switched target tile, reset progress
		if hovered_row != mining_row or hovered_col != mining_col:
			mining_row = hovered_row
			mining_col = hovered_col
			mine_progress = 0.0
		is_mining = true
		# look up how long this cell type takes to break
		var cell_type: int = terrain.grid[mining_row][mining_col]
		var break_time: float = MINE_TIME.get(cell_type, 0.5)
		mine_progress += delta / break_time
		# update cursor arc to show progress
		var tile_tl: Vector2 = Vector2(mining_col * CELL_SIZE, mining_row * CELL_SIZE)
		mining_cursor.update_cursor(tile_tl, true, minf(mine_progress, 1.0))
		# break tile when progress hits 1.0
		if mine_progress >= 1.0:
			_break_tile(mining_row, mining_col)
			mine_progress = 0.0
			is_mining = false
	else:
		# mouse released or no valid target — show highlight only, reset progress if switched
		is_mining = false
		mine_progress = 0.0
		if can_mine:
			var tile_tl: Vector2 = Vector2(hovered_col * CELL_SIZE, hovered_row * CELL_SIZE)
			mining_cursor.update_cursor(tile_tl, true, 0.0)
		else:
			mining_cursor.update_cursor(Vector2.ZERO, false, 0.0)

# this breaks a tile, spawns effects, and checks for echo shards
func _break_tile(row: int, col: int) -> void:
	if not terrain.is_mineable(row, col):
		return
	var cell_type: int = terrain.grid[row][col]
	var block_color: Color = terrain.get_cell_color(cell_type)
	var world_center: Vector2 = Vector2(col * CELL_SIZE + CELL_SIZE / 2, row * CELL_SIZE + CELL_SIZE / 2)
	
	# check if this tile hides an echo shard BEFORE freeing the node
	var cell_name: String = "Cell_" + str(row) + "_" + str(col)
	var cell_node: Node = terrain_visuals.get_node_or_null(cell_name)
	var has_shard: bool = false
	if cell_node and cell_node.has_meta("has_shard"):
		has_shard = cell_node.get_meta("has_shard", false)
	
	# update grid and free the visual node
	terrain.break_cell(row, col)
	if cell_node:
		cell_node.queue_free()
	
	# play mine sound
	if explorer.mine_sound.stream:
		explorer.mine_sound.play()
	
	# spawn colored particle dust burst
	_spawn_mine_particles(world_center, block_color)
	
	# screen shake — small jolt on every break
	shake_magnitude = 1.5
	shake_timer = 0.15
	
	# shard reward if this was a shard tile
	if has_shard:
		collect_shard(world_center)

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
	hud.update_health(explorer.current_health, explorer.MAX_HEALTH)
	hud.update_shards(shards_collected, shards_needed)

# show message telling player to return to surface
func show_return_message() -> void:
	all_stones_collected = true
	return_message_shown = true
	hud.show_message("All stones collected! Return to the surface!")

# show the death screen — transitions to end_screen.tscn with metadata
func show_death_screen() -> void:
	var depth: int = int(explorer.max_depth_reached - terrain.SURFACE_ROW)
	if depth < 0:
		depth = 0
	trigger_death_screen(shards_collected, depth)

# trigger_death_screen — store data in tree metadata and change scene
func trigger_death_screen(shards: int, depth: int) -> void:
	get_tree().set_meta("end_won", false)
	get_tree().set_meta("end_shards", shards)
	get_tree().set_meta("end_depth", depth)
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")

# handle the win condition — transition to end_screen.tscn
func _win_game() -> void:
	game_won = true
	var depth: int = int(explorer.max_depth_reached - terrain.SURFACE_ROW)
	if depth < 0:
		depth = 0
	if win_sound.stream:
		win_sound.play()
	trigger_win_screen(shards_collected, depth)

# trigger_win_screen — store data in tree metadata and change scene
func trigger_win_screen(shards: int, depth: int) -> void:
	get_tree().set_meta("end_won", true)
	get_tree().set_meta("end_shards", shards)
	get_tree().set_meta("end_depth", depth)
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")

# ─── ECHO SHARD SYSTEM ────────────────────────────────────────────────────────

# mark exactly 15 solid tiles as shard tiles, distributed by depth layer
# we do this after _draw_terrain() so the StaticBody2D nodes already exist
func _place_echo_shards() -> void:
	# depth band definitions: [min_row, max_row, shard_count]
	var bands: Array = [
		[terrain.SURFACE_ROW,      terrain.DIRT_END - 1,    3],
		[terrain.DIRT_END,         terrain.STONE_END - 1,   4],
		[terrain.STONE_END,        terrain.OBSIDIAN_END - 1, 5],
		[terrain.OBSIDIAN_END,     terrain.WORLD_HEIGHT - 2, 3],
	]
	for band: Array in bands:
		var min_row: int = band[0]
		var max_row: int = band[1]
		var count: int   = band[2]
		var placed: int  = 0
		var attempts: int = 0
		while placed < count and attempts < 400:
			attempts += 1
			var row: int = randi_range(min_row, max_row)
			var col: int = randi_range(1, terrain.WORLD_WIDTH - 2)
			# must be a solid mineable tile
			if not terrain.is_mineable(row, col):
				continue
			var cell_name: String = "Cell_" + str(row) + "_" + str(col)
			var cell_node: StaticBody2D = terrain_visuals.get_node_or_null(cell_name)
			if cell_node == null:
				continue
			# skip if already tagged
			if cell_node.has_meta("has_shard"):
				continue
			# tag the tile
			cell_node.set_meta("has_shard", true)
			# add subtle cyan PointLight2D glow so it appears identical but glows softly
			var glow: PointLight2D = PointLight2D.new()
			glow.color = Color(0.0, 1.0, 1.0, 1.0)  # cyan #00FFFF
			glow.energy = 0.4
			glow.texture = _create_light_texture()
			glow.texture_scale = 0.8
			cell_node.add_child(glow)
			placed += 1

# create a simple radial gradient texture for the PointLight2D
func _create_light_texture() -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to  = Vector2(1.0, 0.5)
	tex.width  = 64
	tex.height = 64
	return tex

# called when a shard tile is broken — updates counter and checks win
func collect_shard(world_pos: Vector2) -> void:
	shards_collected += 1
	hud.update_shards(shards_collected, shards_needed)
	_show_shard_pickup_effect(world_pos)
	# check if player has enough shards to win
	if shards_collected >= shards_needed:
		trigger_win_screen(shards_collected, int(explorer.max_depth_reached - terrain.SURFACE_ROW))

# show a white flash + rising "+1 ECHO SHARD" floating text at the tile position
func _show_shard_pickup_effect(world_pos: Vector2) -> void:
	# brief white flash rectangle that fades out
	var flash: ColorRect = ColorRect.new()
	flash.size = Vector2(CELL_SIZE, CELL_SIZE)
	flash.position = world_pos - Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	flash.color = Color(1.0, 1.0, 1.0, 0.85)
	add_child(flash)
	var fade: Tween = create_tween()
	fade.tween_property(flash, "modulate:a", 0.0, 0.25)
	fade.tween_callback(flash.queue_free)
	
	# floating "+1 ECHO SHARD" text that rises and fades over 1 second
	var label: Label = Label.new()
	label.text = "+1 ECHO SHARD"
	label.position = world_pos - Vector2(50, 10)
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)
	var rise: Tween = create_tween()
	rise.tween_property(label, "position:y", label.position.y - 50.0, 1.0)
	rise.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	rise.tween_callback(label.queue_free)

