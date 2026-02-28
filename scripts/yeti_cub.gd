# Script: yeti_cub.gd — small white enemy that walks back and forth
extends CharacterBody2D

# movement speed of the yeti cub
const WALK_SPEED: float = 40.0
const GRAVITY: float = 600.0
var direction: float = 1.0
var health: int = 1

func _ready() -> void:
	add_to_group("enemies")
	# create the white rectangle body
	var body_shape: Polygon2D = Polygon2D.new()
	body_shape.polygon = PackedVector2Array([
		Vector2(-8, -12), Vector2(8, -12),
		Vector2(8, 8), Vector2(-8, 8)
	])
	body_shape.color = Color(0.92, 0.92, 0.95)
	add_child(body_shape)
	
	# left eye
	var left_eye: Polygon2D = Polygon2D.new()
	left_eye.polygon = PackedVector2Array([
		Vector2(-4, -8), Vector2(-2, -8),
		Vector2(-2, -6), Vector2(-4, -6)
	])
	left_eye.color = Color(0.1, 0.1, 0.1)
	add_child(left_eye)
	
	# right eye
	var right_eye: Polygon2D = Polygon2D.new()
	right_eye.polygon = PackedVector2Array([
		Vector2(2, -8), Vector2(4, -8),
		Vector2(4, -6), Vector2(2, -6)
	])
	right_eye.color = Color(0.1, 0.1, 0.1)
	add_child(right_eye)
	
	# set up collision
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(16, 20)
	collision.shape = shape
	add_child(collision)
	
	# set up hitbox area for player detection
	var hitbox: Area2D = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 4
	hitbox.collision_mask = 2
	var hitbox_collision: CollisionShape2D = CollisionShape2D.new()
	var hitbox_shape: RectangleShape2D = RectangleShape2D.new()
	hitbox_shape.size = Vector2(14, 18)
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# apply gravity
	velocity.y += GRAVITY * delta
	# walk in current direction
	velocity.x = direction * WALK_SPEED
	move_and_slide()
	
	# reverse direction when hitting a wall
	if is_on_wall():
		direction *= -1.0

# when player touches this enemy
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		# check if player is falling on top (stomping)
		if body.velocity.y > 10.0 and body.global_position.y < global_position.y - 6:
			# enemy dies when stomped
			_die()
			body.velocity.y = -200.0
		else:
			# player takes damage
			body.take_damage(1)

# take damage from player attack
func take_hit(dmg: int) -> void:
	health -= dmg
	if health <= 0:
		_die()

# remove enemy from scene
func _die() -> void:
	queue_free()
