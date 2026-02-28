# Script: terrain_generator.gd — generates the underground world grid
extends Node

# terrain cell types
enum CellType { AIR, DIRT, STONE, OBSIDIAN, BEDROCK }

# world dimensions in cells
const WORLD_WIDTH: int = 60
const WORLD_HEIGHT: int = 60
const CELL_SIZE: int = 32

# layer boundaries (row numbers)
const SURFACE_ROW: int = 8
const DIRT_END: int = 25
const STONE_END: int = 40
const OBSIDIAN_END: int = 57

# colors for each terrain type
const CELL_COLORS: Dictionary = {
	CellType.AIR: Color(0.53, 0.81, 0.92, 0.0),
	CellType.DIRT: Color(0.48, 0.36, 0.23),
	CellType.STONE: Color(0.35, 0.39, 0.47),
	CellType.OBSIDIAN: Color(0.10, 0.04, 0.18),
	CellType.BEDROCK: Color(0.0, 0.0, 0.0),
}

# this stores the grid data: grid[row][col] = CellType
var grid: Array = []

# generates the world grid with simple layers and natural caves
func generate_world() -> Array:
	grid = []
	for row: int in range(WORLD_HEIGHT):
		var row_data: Array = []
		for col: int in range(WORLD_WIDTH):
			var cell_type: int = _get_cell_type_for_row(row, col)
			row_data.append(cell_type)
		grid.append(row_data)
	
	# Add natural cave system after base generation
	_carve_caves()
	_add_cave_decorations()
	
	return grid

# Carve natural cave tunnels using worm walkers (Section 5)
func _carve_caves() -> void:
	var num_worms = 18
	
	# Regular horizontal/curved worms
	for i in range(num_worms - 4):  # Save 4 for vertical shafts
		var worm_x = randi() % WORLD_WIDTH
		var worm_y = randi_range(10, WORLD_HEIGHT - 10)
		var worm_dir = Vector2(randf_range(-1, 1), randf_range(-0.4, 0.4)).normalized()
		var worm_length = randi_range(30, 90)
		var worm_radius = randi_range(2, 4)
		
		# Larger caves in deeper biomes
		if worm_y > 25:
			worm_radius += randi_range(1, 2)
		
		for step in range(worm_length):
			# Carve a circle of empty tiles at worm position
			for dx in range(-worm_radius, worm_radius + 1):
				for dy in range(-worm_radius, worm_radius + 1):
					if dx * dx + dy * dy <= worm_radius * worm_radius:
						var tx = worm_x + dx
						var ty = worm_y + dy
						if tx >= 0 and tx < WORLD_WIDTH and ty > 5 and ty < WORLD_HEIGHT - 1:
							grid[ty][tx] = CellType.AIR
			
			# Worm moves and curves
			worm_dir = (worm_dir + Vector2(randf_range(-0.3, 0.3), randf_range(-0.15, 0.15))).normalized()
			worm_x += int(worm_dir.x * 2)
			worm_y += int(worm_dir.y * 2)
			
			# Keep worm in bounds
			worm_x = clampi(worm_x, 1, WORLD_WIDTH - 2)
			worm_y = clampi(worm_y, 6, WORLD_HEIGHT - 2)
	
	# Add 4 vertical shafts for cave connections
	for i in range(4):
		var shaft_x = randi_range(5, WORLD_WIDTH - 5)
		var shaft_y = randi_range(8, 20)  # Start from upper areas
		var shaft_dir = Vector2(randf_range(-0.2, 0.2), 1.0).normalized()  # Mostly downward
		var shaft_length = randi_range(20, 35)
		var shaft_radius = randi_range(1, 2)
		
		for step in range(shaft_length):
			for dx in range(-shaft_radius, shaft_radius + 1):
				for dy in range(-shaft_radius, shaft_radius + 1):
					if dx * dx + dy * dy <= shaft_radius * shaft_radius:
						var tx = shaft_x + dx
						var ty = shaft_y + dy
						if tx >= 0 and tx < WORLD_WIDTH and ty > 5 and ty < WORLD_HEIGHT - 1:
							grid[ty][tx] = CellType.AIR
			
			# Move shaft mostly down with slight horizontal drift
			shaft_dir = (shaft_dir + Vector2(randf_range(-0.1, 0.1), 0.0)).normalized()
			shaft_x += int(shaft_dir.x)
			shaft_y += int(shaft_dir.y * 2)
			
			shaft_x = clampi(shaft_x, 1, WORLD_WIDTH - 2)
			if shaft_y >= WORLD_HEIGHT - 2:
				break

# Add cave decorations (Section 5)
func _add_cave_decorations() -> void:
	# Add stalactites at cave ceilings
	for row in range(1, WORLD_HEIGHT - 1):
		for col in range(1, WORLD_WIDTH - 1):
			# Check if this is air with solid above (cave ceiling)
			if grid[row][col] == CellType.AIR and grid[row - 1][col] != CellType.AIR:
				if randf() < 0.15:  # 15% chance of stalactite
					# Create thin stalactite hanging down
					var stalactite_height = randi_range(1, 3)
					for h in range(stalactite_height):
						var stala_row = row + h + 1
						if stala_row < WORLD_HEIGHT and grid[stala_row][col] == CellType.AIR:
							# Create stalactite as stone but darker
							grid[stala_row][col] = CellType.STONE

# figure out what type of block goes at this row
func _get_cell_type_for_row(row: int, col: int) -> int:
	# sky area is just air
	if row < SURFACE_ROW:
		return CellType.AIR
	# bottom row is unbreakable bedrock
	if row >= WORLD_HEIGHT - 1:
		return CellType.BEDROCK
	# dirt layer with occasional air pockets
	if row < DIRT_END:
		if randf() < 0.06:
			return CellType.AIR
		return CellType.DIRT
	# stone layer with some small caves
	if row < STONE_END:
		if randf() < 0.08:
			return CellType.AIR
		if randf() < 0.05:
			return CellType.DIRT
		return CellType.STONE
	# deep obsidian layer
	if row < OBSIDIAN_END:
		if randf() < 0.05:
			return CellType.AIR
		if randf() < 0.03:
			return CellType.STONE
		return CellType.OBSIDIAN
	# bedrock at the very bottom
	return CellType.BEDROCK

# check if a cell is mineable (not air, not bedrock)
func is_mineable(row: int, col: int) -> bool:
	if row < 0 or row >= WORLD_HEIGHT or col < 0 or col >= WORLD_WIDTH:
		return false
	var cell: int = grid[row][col]
	return cell != CellType.AIR and cell != CellType.BEDROCK

# break a block at given grid position (turn it into air)
func break_cell(row: int, col: int) -> void:
	if is_mineable(row, col):
		grid[row][col] = CellType.AIR

# check if a cell is solid (for collision)
func is_solid(row: int, col: int) -> bool:
	if row < 0 or row >= WORLD_HEIGHT or col < 0 or col >= WORLD_WIDTH:
		return true
	return grid[row][col] != CellType.AIR

# get the color for a cell type
func get_cell_color(cell_type: int) -> Color:
	if CELL_COLORS.has(cell_type):
		# add slight random variation for visual interest
		var base_color: Color = CELL_COLORS[cell_type]
		var variation: float = randf_range(-0.03, 0.03)
		return Color(
			clampf(base_color.r + variation, 0.0, 1.0),
			clampf(base_color.g + variation, 0.0, 1.0),
			clampf(base_color.b + variation, 0.0, 1.0),
			base_color.a
		)
	return Color.MAGENTA
