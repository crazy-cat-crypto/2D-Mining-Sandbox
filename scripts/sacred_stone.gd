# Script: sacred_stone.gd — collectible sacred stone item
extends Area2D

# this runs when the stone is added to the scene
func _ready() -> void:
	# create the diamond shape (cyan colored polygon)
	var diamond: Polygon2D = Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(8, 0),
		Vector2(0, 10), Vector2(-8, 0)
	])
	diamond.color = Color(0.0, 0.9, 0.9, 0.9)
	add_child(diamond)
	
	# add a slight inner glow polygon
	var inner_glow: Polygon2D = Polygon2D.new()
	inner_glow.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(4, 0),
		Vector2(0, 5), Vector2(-4, 0)
	])
	inner_glow.color = Color(0.7, 1.0, 1.0, 0.7)
	add_child(inner_glow)
	
	# add glow light
	var glow: PointLight2D = PointLight2D.new()
	glow.color = Color(0.0, 0.8, 0.8, 0.5)
	glow.energy = 0.6
	glow.texture = _create_glow_texture()
	glow.texture_scale = 0.4
	add_child(glow)
	
	# collision shape for pickup detection
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)
	
	# set up collision layers
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)

# simple glow texture
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

# floating animation using sine wave
var time_alive: float = 0.0

func _process(delta: float) -> void:
	time_alive += delta
	# gentle floating up and down
	position.y += sin(time_alive * 3.0) * 0.3

# pick up the stone when player touches it
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_stone"):
		body.collect_stone()
		queue_free()
