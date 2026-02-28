# Script: naga.gd — snake-like enemy that lunges at nearby players
extends CharacterBody2D

# how far the naga can detect the player (in pixels)
const DETECTION_RANGE: float = 96.0
const LUNGE_SPEED: float = 180.0
const GRAVITY: float = 600.0
var health: int = 1
var is_lunging: bool = false
var lunge_direction: float = 0.0
var lunge_timer: float = 0.0
var cooldown_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	# create the green snake body (thin tall rectangle)
	var body_shape: Polygon2D = Polygon2D.new()
	body_shape.polygon = PackedVector2Array([
		Vector2(-5, -16), Vector2(5, -16),
		Vector2(5, 12), Vector2(-5, 12)
	])
	body_shape.color = Color(0.2, 0.6, 0.3)
	add_child(body_shape)
	
	# snake head (slightly wider)
	var head: Polygon2D = Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(-7, -20), Vector2(7, -20),
		Vector2(7, -16), Vector2(-7, -16)
	])
	head.color = Color(0.15, 0.5, 0.25)
	add_child(head)
	
	# eyes (red dots for the naga)
	var left_eye: Polygon2D = Polygon2D.new()
	left_eye.polygon = PackedVector2Array([
		Vector2(-5, -19), Vector2(-3, -19),
		Vector2(-3, -17), Vector2(-5, -17)
	])
	left_eye.color = Color(0.9, 0.2, 0.2)
	add_child(left_eye)
	
	var right_eye: Polygon2D = Polygon2D.new()
	right_eye.polygon = PackedVector2Array([
		Vector2(3, -19), Vector2(5, -19),
		Vector2(5, -17), Vector2(3, -17)
	])
	right_eye.color = Color(0.9, 0.2, 0.2)
	add_child(right_eye)
	
	# collision shape
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(14, 32)
	collision.shape = shape
	add_child(collision)
	
	# hitbox area to detect and damage the player
	var hitbox: Area2D = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 4
	hitbox.collision_mask = 2
	var hitbox_collision: CollisionShape2D = CollisionShape2D.new()
	var hitbox_shape: RectangleShape2D = RectangleShape2D.new()
	hitbox_shape.size = Vector2(12, 30)
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	
	# handle lunge attack
	if is_lunging:
		velocity.x = lunge_direction * LUNGE_SPEED
		lunge_timer -= delta
		if lunge_timer <= 0.0:
			is_lunging = false
			velocity.x = 0.0
			cooldown_timer = 1.5
	else:
		velocity.x = 0.0
		cooldown_timer -= delta
		# try to detect player and lunge
		if cooldown_timer <= 0.0:
			_check_for_player()
	
	move_and_slide()

# look for the player within detection range
func _check_for_player() -> void:
	var players: Array = get_tree().get_nodes_in_group("explorer")
	if players.size() == 0:
		return
	var player: Node2D = players[0]
	var distance: float = abs(player.global_position.x - global_position.x)
	var vertical_dist: float = abs(player.global_position.y - global_position.y)
	# only lunge if player is close horizontally and roughly same height
	if distance < DETECTION_RANGE and vertical_dist < 48.0:
		is_lunging = true
		lunge_timer = 0.3
		lunge_direction = sign(player.global_position.x - global_position.x)

# when the player touches the naga
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		# check if player stomped on top
		if body.velocity.y > 10.0 and body.global_position.y < global_position.y - 10:
			_die()
			body.velocity.y = -200.0
		else:
			# naga deals 2 damage (1.5 hearts rounds up)
			body.take_damage(2)

# take damage from player attack
func take_hit(dmg: int) -> void:
	health -= dmg
	if health <= 0:
		_die()

# remove naga from scene
func _die() -> void:
	queue_free()
