# Script: explorer.gd — the player character controller
extends CharacterBody2D

# movement constants
const MOVE_SPEED: float = 150.0
const JUMP_FORCE: float = -320.0
const GRAVITY: float = 600.0

# health system — 100-point scale for environmental damage
const MAX_HEALTH: int = 100
var current_health: int = MAX_HEALTH
var max_health: int = MAX_HEALTH
var is_invincible: bool = false
var invincibility_timer: float = 0.0
const INVINCIBILITY_DURATION: float = 1.0

# tracking depth and stones
var max_depth_reached: float = 0.0
var sacred_stones_collected: int = 0
const TOTAL_SACRED_STONES: int = 7
var is_dead: bool = false

# references set by main_game.gd
var game_controller: Node = null

# visual components created in _ready
var body_visuals: Node2D = null
var flash_timer: float = 0.0

# audio placeholders
@onready var mine_sound: AudioStreamPlayer = $MineSound
@onready var hurt_sound: AudioStreamPlayer = $HurtSound
@onready var pickup_sound: AudioStreamPlayer = $PickupSound

func _ready() -> void:
	# build the character out of colored polygons
	_create_character_visuals()
	# set up collision shape
	var collision: CollisionShape2D = $CollisionShape
	collision.shape = RectangleShape2D.new()
	collision.shape.size = Vector2(20, 28)

# create the polygon-based character appearance
func _create_character_visuals() -> void:
	body_visuals = Node2D.new()
	add_child(body_visuals)
	
	# hard hat (yellow rectangle on top)
	var hat: Polygon2D = Polygon2D.new()
	hat.polygon = PackedVector2Array([
		Vector2(-10, -22), Vector2(10, -22),
		Vector2(10, -16), Vector2(-10, -16)
	])
	hat.color = Color(0.95, 0.85, 0.2)
	body_visuals.add_child(hat)
	
	# face (skin colored square)
	var face: Polygon2D = Polygon2D.new()
	face.polygon = PackedVector2Array([
		Vector2(-7, -16), Vector2(7, -16),
		Vector2(7, -8), Vector2(-7, -8)
	])
	face.color = Color(0.87, 0.72, 0.53)
	body_visuals.add_child(face)
	
	# left eye (black dot)
	var left_eye: Polygon2D = Polygon2D.new()
	left_eye.polygon = PackedVector2Array([
		Vector2(-4, -14), Vector2(-2, -14),
		Vector2(-2, -12), Vector2(-4, -12)
	])
	left_eye.color = Color(0.1, 0.1, 0.1)
	body_visuals.add_child(left_eye)
	
	# right eye (black dot)
	var right_eye: Polygon2D = Polygon2D.new()
	right_eye.polygon = PackedVector2Array([
		Vector2(2, -14), Vector2(4, -14),
		Vector2(4, -12), Vector2(2, -12)
	])
	right_eye.color = Color(0.1, 0.1, 0.1)
	body_visuals.add_child(right_eye)
	
	# torso (blue rectangle)
	var torso: Polygon2D = Polygon2D.new()
	torso.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8),
		Vector2(8, 4), Vector2(-8, 4)
	])
	torso.color = Color(0.25, 0.4, 0.7)
	body_visuals.add_child(torso)
	
	# left leg (dark rectangle)
	var left_leg: Polygon2D = Polygon2D.new()
	left_leg.polygon = PackedVector2Array([
		Vector2(-7, 4), Vector2(-2, 4),
		Vector2(-2, 14), Vector2(-7, 14)
	])
	left_leg.color = Color(0.2, 0.2, 0.25)
	body_visuals.add_child(left_leg)
	
	# right leg (dark rectangle)
	var right_leg: Polygon2D = Polygon2D.new()
	right_leg.polygon = PackedVector2Array([
		Vector2(2, 4), Vector2(7, 4),
		Vector2(7, 14), Vector2(2, 14)
	])
	right_leg.color = Color(0.2, 0.2, 0.25)
	body_visuals.add_child(right_leg)
	
	# pickaxe using Line2D (brown handle + gray head)
	var pickaxe: Line2D = Line2D.new()
	pickaxe.points = PackedVector2Array([
		Vector2(8, -4), Vector2(16, -12)
	])
	pickaxe.width = 2.0
	pickaxe.default_color = Color(0.45, 0.3, 0.15)
	body_visuals.add_child(pickaxe)
	
	# pickaxe head
	var pick_head: Line2D = Line2D.new()
	pick_head.points = PackedVector2Array([
		Vector2(12, -16), Vector2(20, -10)
	])
	pick_head.width = 3.0
	pick_head.default_color = Color(0.6, 0.6, 0.65)
	body_visuals.add_child(pick_head)

func _physics_process(delta: float) -> void:
	if is_dead:
		# only listen for restart when dead
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	
	# apply gravity
	velocity.y += GRAVITY * delta
	
	# horizontal movement with arrow keys
	var direction: float = 0.0
	if Input.is_action_pressed("move_left"):
		direction = -1.0
	elif Input.is_action_pressed("move_right"):
		direction = 1.0
	
	velocity.x = direction * MOVE_SPEED
	
	# flip character based on movement direction
	if direction != 0.0:
		body_visuals.scale.x = sign(direction)
	
	# jumping — only when on the floor
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE
	
	move_and_slide()
	
	# update depth tracking
	var current_depth: float = position.y / 32.0
	if current_depth > max_depth_reached:
		max_depth_reached = current_depth
	
	# handle invincibility countdown
	if is_invincible:
		invincibility_timer -= delta
		flash_timer -= delta
		# flash effect — toggle visibility rapidly
		if flash_timer <= 0.0:
			body_visuals.visible = !body_visuals.visible
			flash_timer = 0.06
		if invincibility_timer <= 0.0:
			is_invincible = false
			body_visuals.visible = true

# take_damage — used for environmental hazards (lava, fall, etc.). Enemies call die() instead.
func take_damage(amount: int) -> void:
	if is_invincible or is_dead:
		return
	current_health -= amount
	is_invincible = true
	invincibility_timer = INVINCIBILITY_DURATION
	flash_timer = 0.06
	# play hurt sound
	if hurt_sound.stream:
		hurt_sound.play()
	# check if dead
	if current_health <= 0:
		current_health = 0
		_die()
	# tell the HUD to update health bar
	if game_controller:
		game_controller.update_hud()

# public die() — called by enemies for instant death, bypasses health entirely
func die() -> void:
	if is_dead:
		return
	_die()

# handle player death — stops movement and shows the death screen
func _die() -> void:
	is_dead = true
	body_visuals.visible = true
	body_visuals.modulate = Color(0.5, 0.5, 0.5)
	velocity = Vector2.ZERO
	if game_controller:
		game_controller.show_death_screen()

# called when player picks up a sacred stone
func collect_stone() -> void:
	sacred_stones_collected += 1
	# play pickup sound
	if pickup_sound.stream:
		pickup_sound.play()
	if game_controller:
		game_controller.update_hud()
		# check if all stones collected
		if sacred_stones_collected >= TOTAL_SACRED_STONES:
			game_controller.show_return_message()
