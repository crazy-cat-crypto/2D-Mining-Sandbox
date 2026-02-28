# Script: mine_particles.gd — spawns small squares that fly out when a block breaks
extends Node2D

# number of particles to spawn
const PARTICLE_COUNT: int = 5
const SPREAD_SPEED: float = 80.0
const LIFETIME: float = 0.4

var particles: Array = []
var timer: float = 0.0

# initialize particles with given color (matches block color)
func setup(block_color: Color) -> void:
	for i: int in range(PARTICLE_COUNT):
		var piece: ColorRect = ColorRect.new()
		piece.size = Vector2(3, 3)
		piece.color = block_color
		add_child(piece)
		# give each piece a random velocity
		var angle: float = randf() * TAU
		var speed: float = randf_range(SPREAD_SPEED * 0.5, SPREAD_SPEED)
		particles.append({
			"node": piece,
			"velocity": Vector2(cos(angle) * speed, sin(angle) * speed),
		})

func _process(delta: float) -> void:
	timer += delta
	# move each particle and fade it out
	for particle: Dictionary in particles:
		var node: ColorRect = particle["node"]
		var vel: Vector2 = particle["velocity"]
		node.position += vel * delta
		# fade out over lifetime
		var alpha: float = 1.0 - (timer / LIFETIME)
		node.modulate.a = maxf(alpha, 0.0)
	# remove after lifetime
	if timer >= LIFETIME:
		queue_free()
