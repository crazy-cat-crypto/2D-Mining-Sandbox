# Script: explorer.gd — the child player character for Minor Dai
extends CharacterBody2D

# movement constants (Section 2 specs)
const MOVE_SPEED: float = 165.0
const JUMP_FORCE: float = -390.0
const GRAVITY: float = 920.0
const ACCEL: float = 850.0
const FRICTION: float = 700.0

# combat constants
var attack_damage: int = 40
var attack_range: float = 65.0
var attack_cooldown: float = 0.35
var can_attack: bool = true

# health system
const MAX_HEALTH: int = 100
var current_health: int = MAX_HEALTH
var is_invincible: bool = false
var invincibility_timer: float = 0.0
const INVINCIBILITY_DURATION: float = 1.0

# tracking depth and shards
var max_depth_reached: float = 0.0
var is_dead: bool = false

# references
var game_controller: Node = null
var sacred_stones_collected: int = 0

# audio references (linked from scene)
@onready var mine_sound: AudioStreamPlayer = $MineSound
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var pickup_sound: AudioStreamPlayer = $PickupSound

# visual components - child character design
var visual_node: Node2D = null
var flash_timer: float = 0.0
var blink_timer: float = 3.0

# face direction tracking
var facing_right: bool = true

func _ready() -> void:
	add_to_group("player")
	_create_child_visuals()
	# set up collision shape
	var collision: CollisionShape2D = $CollisionShape
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(16, 26)

# create the child character appearance using ColorRects
func _create_child_visuals() -> void:
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	add_child(visual_node)
	
	# Hair (brown)
	var hair = ColorRect.new()
	hair.name = "hair"
	hair.size = Vector2(20, 5)
	hair.position = Vector2(-10, -34)
	hair.color = Color("#3B2506")
	visual_node.add_child(hair)
	
	# Head (skin tone)
	var head = ColorRect.new()
	head.name = "head"
	head.size = Vector2(18, 18)
	head.position = Vector2(-9, -30)
	head.color = Color("#F4C58A")
	visual_node.add_child(head)
	
	# Left eye (black)
	var eye_l = ColorRect.new()
	eye_l.name = "eye_l"
	eye_l.size = Vector2(3, 3)
	eye_l.position = Vector2(-6, -24)
	eye_l.color = Color("#222222")
	visual_node.add_child(eye_l)
	
	# Right eye (black)
	var eye_r = ColorRect.new()
	eye_r.name = "eye_r"
	eye_r.size = Vector2(3, 3)
	eye_r.position = Vector2(2, -24)
	eye_r.color = Color("#222222")
	visual_node.add_child(eye_r)
	
	# Left blush (pink)
	var blush_l = ColorRect.new()
	blush_l.name = "blush_l"
	blush_l.size = Vector2(3, 2)
	blush_l.position = Vector2(-7, -21)
	blush_l.color = Color("#FFB3A7")
	visual_node.add_child(blush_l)
	
	# Right blush (pink)
	var blush_r = ColorRect.new()
	blush_r.name = "blush_r"
	blush_r.size = Vector2(3, 2)
	blush_r.position = Vector2(3, -21)
	blush_r.color = Color("#FFB3A7")
	visual_node.add_child(blush_r)
	
	# Body (red shirt)
	var body = ColorRect.new()
	body.name = "body"
	body.size = Vector2(14, 16)
	body.position = Vector2(-7, -12)
	body.color = Color("#E63946")
	visual_node.add_child(body)
	
	# Left pants (dark green)
	var pants_l = ColorRect.new()
	pants_l.name = "pants_l"
	pants_l.size = Vector2(5, 12)
	pants_l.position = Vector2(-7, 4)
	pants_l.color = Color("#264653")
	visual_node.add_child(pants_l)
	
	# Right pants (dark green)
	var pants_r = ColorRect.new()
	pants_r.name = "pants_r"
	pants_r.size = Vector2(5, 12)
	pants_r.position = Vector2(1, 4)
	pants_r.color = Color("#264653")
	visual_node.add_child(pants_r)
	
	# Left arm (skin tone)
	var arm_l = ColorRect.new()
	arm_l.name = "arm_l"
	arm_l.size = Vector2(4, 11)
	arm_l.position = Vector2(-11, -11)
	arm_l.color = Color("#F4C58A")
	visual_node.add_child(arm_l)
	
	# Right arm (with pickaxe)
	var arm_r = Node2D.new()
	arm_r.name = "arm_r"
	arm_r.position = Vector2(7, -11)
	visual_node.add_child(arm_r)
	
	var arm_skin = ColorRect.new()
	arm_skin.name = "arm_skin"
	arm_skin.size = Vector2(4, 11)
	arm_skin.position = Vector2(0, 0)
	arm_skin.color = Color("#F4C58A")
	arm_r.add_child(arm_skin)
	
	var pickaxe = ColorRect.new()
	pickaxe.name = "pickaxe"
	pickaxe.size = Vector2(16, 3)
	pickaxe.position = Vector2(2, 6)
	pickaxe.color = Color("#888888")
	pickaxe.rotation_degrees = -40
	arm_r.add_child(pickaxe)

func _physics_process(delta: float) -> void:
	if is_dead:
		# only listen for restart when dead
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	
	var is_on_ground = is_on_floor()
	
	# Horizontal movement (A/D keys + arrow keys)
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		velocity.x = move_toward(velocity.x, MOVE_SPEED, ACCEL * delta)
		facing_right = true
	elif Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		velocity.x = move_toward(velocity.x, -MOVE_SPEED, ACCEL * delta)
		facing_right = false
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	# Jump (Space key)
	if is_on_ground and Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_FORCE
	
	# Gravity
	if not is_on_ground:
		velocity.y += GRAVITY * delta
	
	velocity.y = clamp(velocity.y, -1500, 900)
	move_and_slide()
	
	# Update depth tracking for GameManager
	var current_depth: float = position.y / 32.0
	if current_depth > max_depth_reached:
		max_depth_reached = current_depth
		GameManager.update_depth(current_depth)
	
	# Handle invincibility countdown
	if is_invincible:
		invincibility_timer -= delta
		flash_timer -= delta
		if flash_timer <= 0.0:
			visual_node.visible = !visual_node.visible
			flash_timer = 0.06
		if invincibility_timer <= 0.0:
			is_invincible = false
			visual_node.visible = true
	
	# Handle animations
	_update_animations(delta)

func _process(delta: float) -> void:
	# Walking bob animation
	if velocity.x != 0 and is_on_floor():
		visual_node.position.y = sin(Time.get_ticks_msec() * 0.01) * 2.0
	else:
		visual_node.position.y = 0
	
	# Face direction
	visual_node.scale.x = -1 if not facing_right else 1
	
	# Eye blinking
	blink_timer -= delta
	if blink_timer <= 0.0:
		_blink()
		blink_timer = 3.0

func _update_animations(_delta: float) -> void:
	pass  # Placeholder for additional animations

func _blink() -> void:
	# Make eyes thin for blink
	visual_node.get_node("eye_l").size.y = 1
	visual_node.get_node("eye_r").size.y = 1
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		visual_node.get_node("eye_l").size.y = 3
		visual_node.get_node("eye_r").size.y = 3

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_attack_or_mine()

func _try_attack_or_mine() -> void:
	# Check if any enemy is in melee range first
	var hit_enemy = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null: 
			continue
		if global_position.distance_to(enemy.global_position) <= attack_range:
			if can_attack:
				_swing_pickaxe()
				enemy.take_hit(attack_damage)
				hit_enemy = true
				break
	# If no enemy hit, fall through to normal mining (existing system handles it)

func _swing_pickaxe() -> void:
	can_attack = false
	var arm_r = visual_node.get_node("arm_r")
	var tween = create_tween()
	tween.tween_property(arm_r, "rotation_degrees", 75.0, 0.15)
	tween.tween_property(arm_r, "rotation_degrees", -40.0, 0.15)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# take_damage — used for environmental hazards  
func take_damage(amount: int) -> void:
	if is_invincible or is_dead:
		return
	current_health -= amount
	is_invincible = true
	invincibility_timer = INVINCIBILITY_DURATION
	flash_timer = 0.06
	
	# check if dead
	if current_health <= 0:
		current_health = 0
		die()

# public die() — called by enemies for instant death
func die() -> void:
	if is_dead:
		return
	is_dead = true
	visual_node.visible = true
	visual_node.modulate = Color(0.5, 0.5, 0.5)
	velocity = Vector2.ZERO
	GameManager.trigger_death()

# called when player picks up a shard
func collect_shard() -> void:
	GameManager.collect_shard()
