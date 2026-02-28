# Script: zombie.gd — unkillable contact enemy that patrols and chases the player
extends CharacterBody2D

const PATROL_SPEED: float = 35.0
const CHASE_SPEED: float = 55.0
const CHASE_RANGE: float = 200.0
const PATROL_DISTANCE: float = 120.0
const GRAVITY: float = 700.0

var spawn_position: Vector2 = Vector2.ZERO
var patrol_direction: float = 1.0
var is_chasing: bool = false
var hitbox: Area2D = null
var body_visual: Polygon2D = null

# this sets up the zombie behavior state
func _ready() -> void:
	spawn_position = global_position
	add_to_group("enemies")
	_create_visuals()

# build dark-green humanoid shape, collision, and hitbox in code (no sprites needed)
func _create_visuals() -> void:
	# dark green body rectangle
	body_visual = Polygon2D.new()
	body_visual.polygon = PackedVector2Array([
		Vector2(-10, -18), Vector2(10, -18),
		Vector2(10, 14), Vector2(-10, 14)
	])
	body_visual.color = Color(0.15, 0.35, 0.15)
	add_child(body_visual)

	# darker head block
	var head: Polygon2D = Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(-8, -28), Vector2(8, -28),
		Vector2(8, -18), Vector2(-8, -18)
	])
	head.color = Color(0.12, 0.30, 0.12)
	add_child(head)

	# two black dot eyes
	for offset_x: float in [-5.0, 2.0]:
		var eye: Polygon2D = Polygon2D.new()
		eye.polygon = PackedVector2Array([
			Vector2(offset_x, -24), Vector2(offset_x + 3, -24),
			Vector2(offset_x + 3, -21), Vector2(offset_x, -21)
		])
		eye.color = Color(0.0, 0.0, 0.0)
		add_child(eye)

	# physics collision body
	var col: CollisionShape2D = CollisionShape2D.new()
	var body_shape: RectangleShape2D = RectangleShape2D.new()
	body_shape.size = Vector2(20.0, 36.0)
	col.shape = body_shape
	col.position = Vector2(0.0, -7.0)
	add_child(col)

	# hitbox Area2D that detects player contact
	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	var hbox_col: CollisionShape2D = CollisionShape2D.new()
	var hbox_shape: RectangleShape2D = RectangleShape2D.new()
	hbox_shape.size = Vector2(22.0, 38.0)
	hbox_col.shape = hbox_shape
	hbox_col.position = Vector2(0.0, -7.0)
	hitbox.add_child(hbox_col)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_body_entered)

# this handles patrol and chase movement each frame
func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	_update_chase_state()
	if is_chasing:
		_chase_player()
	else:
		_patrol_area()
	move_and_slide()
	if is_on_wall():
		patrol_direction *= -1.0

# this switches between patrol and chase based on distance
func _update_chase_state() -> void:
	var player: Node2D = _get_player()
	if player == null:
		is_chasing = false
		return
	var distance_to_player: float = global_position.distance_to(player.global_position)
	if distance_to_player <= CHASE_RANGE:
		is_chasing = true
	elif is_chasing and distance_to_player > CHASE_RANGE:
		is_chasing = false

# this moves zombie toward the player when in chase mode
func _chase_player() -> void:
	var player: Node2D = _get_player()
	if player == null:
		velocity.x = 0.0
		return
	var direction_to_player: float = sign(player.global_position.x - global_position.x)
	velocity.x = direction_to_player * CHASE_SPEED
	if direction_to_player != 0.0:
		body_visual.scale.x = direction_to_player

# this moves zombie left/right inside 120px from its spawn point
func _patrol_area() -> void:
	var left_limit: float = spawn_position.x - PATROL_DISTANCE
	var right_limit: float = spawn_position.x + PATROL_DISTANCE
	if global_position.x <= left_limit:
		patrol_direction = 1.0
	elif global_position.x >= right_limit:
		patrol_direction = -1.0
	velocity.x = patrol_direction * PATROL_SPEED
	if patrol_direction != 0.0:
		body_visual.scale.x = patrol_direction

# this returns the current player node from the explorer group
func _get_player() -> Node2D:
	var players: Array = get_tree().get_nodes_in_group("explorer")
	if players.is_empty():
		return null
	return players[0] as Node2D

# this instantly kills the player on contact
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	elif body.has_method("_die"):
		body._die()
