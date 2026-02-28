# Script: mining_cursor.gd — draws tile highlight border and mining progress arc in world space
extends Node2D

# position of the highlighted tile (top-left corner in world coords)
var tile_world_pos: Vector2 = Vector2.ZERO
var has_highlight: bool = false
# 0.0 = no progress, 1.0 = fully mined
var mine_progress: float = 0.0

const CELL_SIZE: int = 32

# this draws the cyan border and arc every frame
func _draw() -> void:
	if not has_highlight:
		return
	# draw cyan rectangle border around the hovered tile
	var rect: Rect2 = Rect2(tile_world_pos, Vector2(CELL_SIZE, CELL_SIZE))
	draw_rect(rect, Color(0.0, 1.0, 1.0, 0.5), false, 2.0)
	# draw a clockwise white arc showing mining progress
	if mine_progress > 0.0:
		var center: Vector2 = tile_world_pos + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
		var start_angle: float = -PI / 2.0
		var end_angle: float = start_angle + mine_progress * TAU
		draw_arc(center, 16.0, start_angle, end_angle, 32, Color.WHITE, 3.0)

# called each frame from main_game to update what tile we are hovering
func update_cursor(pos: Vector2, active: bool, progress: float) -> void:
	tile_world_pos = pos
	has_highlight = active
	mine_progress = progress
	queue_redraw()
