# Script: bhoot_firefly.gd — glowing floating enemy in the deep layer
extends CharacterBody2D

# movement parameters
const FLOAT_SPEED: float = 25.0
const CHASE_SPEED: float = 35.0
const WAVE_AMPLITUDE: float = 30.0
const WAVE_FREQUENCY: float = 2.0
var health: int = 1

# sine wave tracking
var time_alive: float = 0.0
var start_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	start_position = global_position
	
	# create the glowing yellow-orange circle (approximated with polygon)
	var glow_body: Polygon2D = Polygon2D.new()
	var circle_points: PackedVector2Array = PackedVector2Array()
	# make a small circle with 8 points
	for i: int in range(8):
		var angle: float = i * TAU / 8.0
		circle_points.append(Vector2(cos(angle) * 5, sin(angle) * 5))
	glow_body.polygon = circle_points
	glow_body.color = Color(1.0, 0.8, 0.2, 0.9)
	add_child(glow_body)
	
	# add a PointLight2D for subtle glow effect
	var glow_light: PointLight2D = PointLight2D.new()
	glow_light.color = Color(1.0, 0.85, 0.3, 0.6)
	glow_light.energy = 0.8
	glow_light.texture = _create_glow_texture()
	glow_light.texture_scale = 0.5
	add_child(glow_light)
	
	# collision shape (small circle)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	add_child(collision)
	
	# hitbox area for damaging the player
	var hitbox: Area2D = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 4
	hitbox.collision_mask = 2
	var hitbox_collision: CollisionShape2D = CollisionShape2D.new()
	var hitbox_shape: CircleShape2D = CircleShape2D.new()
	hitbox_shape.radius = 8.0
	hitbox_collision.shape = hitbox_shape
	hitbox.add_child(hitbox_collision)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_body_entered)

# create a simple gradient texture for the glow
func _create_glow_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	return texture

func _physics_process(delta: float) -> void:
	time_alive += delta
	
	# sine wave floating motion
	var wave_offset: float = sin(time_alive * WAVE_FREQUENCY) * WAVE_AMPLITUDE * delta
	velocity.y = wave_offset * 10.0
	
	# slowly move toward the player if they are nearby
	var players: Array = get_tree().get_nodes_in_group("explorer")
	if players.size() > 0:
		var player: Node2D = players[0]
		var dir_to_player: Vector2 = (player.global_position - global_position).normalized()
		var distance: float = global_position.distance_to(player.global_position)
		if distance < 200.0:
			velocity.x = dir_to_player.x * CHASE_SPEED
			velocity.y += dir_to_player.y * CHASE_SPEED * 0.5
		else:
			velocity.x = 0.0
	
	move_and_slide()

# when player touches the firefly
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		# stomping works here too
		if body.velocity.y > 10.0 and body.global_position.y < global_position.y - 4:
			_die()
			body.velocity.y = -150.0
		else:
			body.take_damage(10)

# take damage from player attack
func take_hit(dmg: int) -> void:
	health -= dmg
	if health <= 0:
		_die()

# remove firefly from scene
func _die() -> void:
	queue_free()
