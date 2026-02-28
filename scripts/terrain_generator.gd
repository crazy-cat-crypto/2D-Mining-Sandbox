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

# generates the world grid with simple layers
func generate_world() -> Array:
	grid = []
	for row: int in range(WORLD_HEIGHT):
		var row_data: Array = []
		for col: int in range(WORLD_WIDTH):
			var cell_type: int = _get_cell_type_for_row(row, col)
			row_data.append(cell_type)
		grid.append(row_data)
	return grid

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
