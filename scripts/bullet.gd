# Script: bullet.gd — gun projectile that one-shots enemies
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var lifetime: float = 2.0

func _ready() -> void:
	# Collision setup — detect enemies (layer 3, bitmask value 4)
	collision_layer = 0
	collision_mask = 4
	monitoring = true

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(8, 4)
	collision.shape = shape
	add_child(collision)

	# Visual — bright yellow bullet
	var visual = ColorRect.new()
	visual.size = Vector2(8, 4)
	visual.position = Vector2(-4, -2)
	visual.color = Color("#FFD700")
	add_child(visual)

	# Muzzle flash trail
	var trail = ColorRect.new()
	trail.size = Vector2(6, 2)
	trail.position = Vector2(-10, -1)
	trail.color = Color("#FFA500")
	trail.modulate.a = 0.6
	add_child(trail)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		body.take_hit(9999)
	elif body.is_in_group("enemies"):
		body.queue_free()
	queue_free()
