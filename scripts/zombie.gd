# Script: zombie.gd — killable zombie enemy with health bar for Minor Dai
extends CharacterBody2D

# Section 3 specs
var max_health: int = 55
var health: int = 55
var speed: float = 48.0
var aggro_range: float = 210.0
var is_dead: bool = false
var spawn_pos: Vector2

const GRAVITY: float = 900.0

var visual_node: Node2D = null
var hp_bg: ColorRect = null
var hp_fill: ColorRect = null
var hitbox: Area2D = null

func _ready() -> void:
	spawn_pos = global_position
	add_to_group("enemies")
	_create_zombie_visuals()

# Create zombie appearance with health bar
func _create_zombie_visuals() -> void:
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	add_child(visual_node)
	
	# Body (green zombie color)
	var body = ColorRect.new()
	body.name = "body"
	body.size = Vector2(20, 22)
	body.position = Vector2(-10, -22)
	body.color = Color("#4A7C59")
	visual_node.add_child(body)
	
	# Head (lighter green)
	var head = ColorRect.new()
	head.name = "head"
	head.size = Vector2(18, 18)
	head.position = Vector2(-9, -40)
	head.color = Color("#6BAE6E")
	visual_node.add_child(head)
	
	# Red glowing eyes
	var eye_l = ColorRect.new()
	eye_l.name = "eye_l"
	eye_l.size = Vector2(3, 4)
	eye_l.position = Vector2(-6, -35)
	eye_l.color = Color("#FF0000")
	visual_node.add_child(eye_l)
	
	var eye_r = ColorRect.new()
	eye_r.name = "eye_r"
	eye_r.size = Vector2(3, 4)
	eye_r.position = Vector2(2, -35)
	eye_r.color = Color("#FF0000")
	visual_node.add_child(eye_r)
	
	# Arms
	var arm_l = ColorRect.new()
	arm_l.name = "arm_l"
	arm_l.size = Vector2(4, 14)
	arm_l.position = Vector2(-14, -21)
	arm_l.color = Color("#4A7C59")
	visual_node.add_child(arm_l)
	
	var arm_r = ColorRect.new()
	arm_r.name = "arm_r"
	arm_r.size = Vector2(4, 14)
	arm_r.position = Vector2(9, -21)
	arm_r.color = Color("#4A7C59")
	visual_node.add_child(arm_r)
	
	# Health bar background
	hp_bg = ColorRect.new()
	hp_bg.name = "hp_bg"
	hp_bg.size = Vector2(32, 4)
	hp_bg.position = Vector2(-16, -50)
	hp_bg.color = Color("#333333")
	add_child(hp_bg)
	
	# Health bar fill
	hp_fill = ColorRect.new()
	hp_fill.name = "hp_fill"
	hp_fill.size = Vector2(32, 4)
	hp_fill.position = Vector2(-16, -50)
	hp_fill.color = Color("#FF3333")
	add_child(hp_fill)
	
	# Physics collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 36)
	collision.shape = shape
	collision.position = Vector2(0, -7)
	add_child(collision)
	
	# Hitbox for player contact
	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	var hitbox_col = CollisionShape2D.new()
	var hitbox_shape = RectangleShape2D.new()
	hitbox_shape.size = Vector2(22, 38)
	hitbox_col.shape = hitbox_shape
	hitbox_col.position = Vector2(0, -7)
	hitbox.add_child(hitbox_col)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Update health bar
	hp_fill.size.x = 32.0 * (float(health) / float(max_health))
	
	# Always face player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		visual_node.scale.x = -1 if player.global_position.x < global_position.x else 1
		
		# Chase or patrol
		if global_position.distance_to(player.global_position) < aggro_range:
			var dir = (player.global_position - global_position).normalized()
			velocity.x = dir.x * speed
		else:
			# Simple left-right patrol
			velocity.x = speed * (1 if fmod(Time.get_ticks_msec() * 0.001, 4) < 2 else -1)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	velocity.y += GRAVITY * delta
	move_and_slide()

func take_hit(dmg: int) -> void:
	if is_dead: 
		return
	health -= dmg
	
	# Flash white
	visual_node.modulate = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if not is_dead:
		visual_node.modulate = Color(0.29, 0.49, 0.35)
	
	# Knockback
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var kb = (global_position - player.global_position).normalized() * 200
		velocity = kb
	
	if health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.28)
	await tween.finished
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
