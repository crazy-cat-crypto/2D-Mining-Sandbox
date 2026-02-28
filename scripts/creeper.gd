# Script: creeper.gd — killable creeper enemy with fusing for Minor Dai
extends CharacterBody2D

# Section 3 specs
var max_health: int = 35
var health: int = 35
var detect_range: float = 130.0
var explode_range: float = 105.0
var fuse_time: float = 1.4
var is_fusing: bool = false
var is_dead: bool = false

const GRAVITY: float = 900.0

var visual_node: Node2D = null
var hp_bg: ColorRect = null
var hp_fill: ColorRect = null
var hitbox: Area2D = null

func _ready() -> void:
	add_to_group("enemies")
	_create_creeper_visuals()

# Create creeper appearance with health bar
func _create_creeper_visuals() -> void:
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	add_child(visual_node)
	
	# Body (bright green)
	var body = ColorRect.new()
	body.name = "body"
	body.size = Vector2(16, 22)
	body.position = Vector2(-8, -22)
	body.color = Color("#3CB043")
	visual_node.add_child(body)
	
	# Black eyes
	var eye_l = ColorRect.new()
	eye_l.name = "eye_l"
	eye_l.size = Vector2(4, 5)
	eye_l.position = Vector2(-4, -18)
	eye_l.color = Color("#111111")
	visual_node.add_child(eye_l)
	
	var eye_r = ColorRect.new()
	eye_r.name = "eye_r"
	eye_r.size = Vector2(4, 5)
	eye_r.position = Vector2(1, -18)
	eye_r.color = Color("#111111")
	visual_node.add_child(eye_r)
	
	# Mouth
	var mouth = ColorRect.new()
	mouth.name = "mouth"
	mouth.size = Vector2(10, 3)
	mouth.position = Vector2(-5, -10)
	mouth.color = Color("#111111")
	visual_node.add_child(mouth)
	
	# Health bar background
	hp_bg = ColorRect.new()
	hp_bg.name = "hp_bg"
	hp_bg.size = Vector2(32, 4)
	hp_bg.position = Vector2(-16, -35)
	hp_bg.color = Color("#333333")
	add_child(hp_bg)
	
	# Health bar fill
	hp_fill = ColorRect.new()
	hp_fill.name = "hp_fill"
	hp_fill.size = Vector2(32, 4)
	hp_fill.position = Vector2(-16, -35)
	hp_fill.color = Color("#FF3333")
	add_child(hp_fill)
	
	# Physics collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 24)
	collision.shape = shape
	collision.position = Vector2(0, -11)
	add_child(collision)
	
	# Hitbox for player contact
	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	var hitbox_col = CollisionShape2D.new()
	var hitbox_shape = RectangleShape2D.new()
	hitbox_shape.size = Vector2(18, 26)
	hitbox_col.shape = hitbox_shape
	hitbox_col.position = Vector2(0, -11)
	hitbox.add_child(hitbox_col)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Update health bar
	hp_fill.size.x = 32.0 * (float(health) / float(max_health))
	
	# Fuse behavior
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		return
	var dist = global_position.distance_to(player.global_position)
	
	if dist < detect_range and not is_fusing:
		_start_fuse()
	elif dist >= detect_range and is_fusing:
		_cancel_fuse()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	velocity.y += GRAVITY * delta
	move_and_slide()

func _start_fuse() -> void:
	is_fusing = true
	var fuse_timer = get_tree().create_timer(fuse_time)
	# Flash green/white while fusing
	_flash_loop()
	await fuse_timer.timeout
	if is_fusing and not is_dead:
		_explode()

func _flash_loop() -> void:
	while is_fusing and not is_dead:
		modulate = Color.WHITE
		await get_tree().create_timer(0.12).timeout
		modulate = Color(0.24, 0.69, 0.26)
		await get_tree().create_timer(0.12).timeout

func _cancel_fuse() -> void:
	is_fusing = false
	modulate = Color(0.24, 0.69, 0.26)

func _explode() -> void:
	is_fusing = false
	is_dead = true
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < explode_range:
		player.take_damage(40)
	
	# Screen flash
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6)
	flash.size = DisplayServer.window_get_size()
	get_tree().current_scene.add_child(flash)
	var t = create_tween()
	t.tween_property(flash, "modulate:a", 0.0, 0.4)
	await t.finished
	flash.queue_free()
	queue_free()

func take_hit(dmg: int) -> void:
	if is_dead: 
		return
	health -= dmg
	if health <= 0:
		is_dead = true
		is_fusing = false
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.22)
		await tween.finished
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(15)
