# Script: creeper.gd — stationary enemy that fuses and explodes when player gets close
extends StaticBody2D

# how close the player must be to trigger the fuse (in pixels)
const TRIGGER_RANGE: float = 150.0
# how close the player must be to die from the explosion
const EXPLOSION_RANGE: float = 120.0
# how long the fuse burns before exploding (seconds)
const FUSE_DURATION: float = 1.5
# how fast the flash alternates during fuse
const FLASH_INTERVAL: float = 0.1

# current fuse state
var fuse_active: bool = false
var fuse_timer: float = 0.0
var flash_timer: float = 0.0
var is_exploded: bool = false

# colors used for flashing
const COLOR_IDLE: Color = Color(0.2, 0.85, 0.2, 1.0)
const COLOR_FLASH: Color = Color(1.0, 1.0, 1.0, 1.0)

var body_rect: ColorRect = null

# this sets up visuals and registers in the enemies group
func _ready() -> void:
	add_to_group("enemies")
	_create_visuals()

# creates the bright green rectangle body (placeholder, replace with sprite later)
func _create_visuals() -> void:
	body_rect = ColorRect.new()
	body_rect.size = Vector2(22, 28)
	body_rect.position = Vector2(-11, -28)
	body_rect.color = COLOR_IDLE
	add_child(body_rect)

	# two dark eyes
	var eye_left: ColorRect = ColorRect.new()
	eye_left.size = Vector2(4, 4)
	eye_left.position = Vector2(-8, -22)
	eye_left.color = Color(0.0, 0.2, 0.0)
	add_child(eye_left)

	var eye_right: ColorRect = ColorRect.new()
	eye_right.size = Vector2(4, 4)
	eye_right.position = Vector2(4, -22)
	eye_right.color = Color(0.0, 0.2, 0.0)
	add_child(eye_right)

	# collision shape
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(22, 28)
	col.shape = shape
	col.position = Vector2(0, -14)
	add_child(col)

# this checks player distance every frame and manages fuse/explosion state
func _process(delta: float) -> void:
	if is_exploded:
		return
	var player: Node2D = _get_player()
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)

	if dist <= TRIGGER_RANGE:
		# player is close enough — run or maintain fuse
		if not fuse_active:
			fuse_active = true
			fuse_timer = 0.0
			flash_timer = 0.0
		fuse_timer += delta
		flash_timer += delta
		# alternate between white and green flash
		if flash_timer >= FLASH_INTERVAL:
			flash_timer = 0.0
			if body_rect.color == COLOR_IDLE:
				body_rect.color = COLOR_FLASH
			else:
				body_rect.color = COLOR_IDLE
		# check if fuse is done — explode
		if fuse_timer >= FUSE_DURATION:
			_explode(player, dist)
	else:
		# player left range — reset fuse
		if fuse_active:
			fuse_active = false
			fuse_timer = 0.0
			flash_timer = 0.0
			body_rect.color = COLOR_IDLE

# this triggers the explosion — kills player if close enough and removes self
func _explode(player: Node2D, dist: float) -> void:
	is_exploded = true
	if dist <= EXPLOSION_RANGE and player.has_method("die"):
		player.die()
	queue_free()

# this returns the player node from the explorer group
func _get_player() -> Node2D:
	var players: Array = get_tree().get_nodes_in_group("explorer")
	if players.is_empty():
		return null
	return players[0] as Node2D
