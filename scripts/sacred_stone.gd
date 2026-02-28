# Script: sacred_stone.gd — collectible Echo Shard for Minor Dai
extends Area2D

var shard_light: PointLight2D = null
var shard_label: Label = null
var shard_visual: Polygon2D = null
var time_alive: float = 0.0

func _ready() -> void:
	add_to_group("collectibles")
	_create_shard_visuals()

# Create echo shard appearance with pulsing glow and floating symbol
func _create_shard_visuals() -> void:
	# Main shard diamond shape
	shard_visual = Polygon2D.new()
	shard_visual.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(8, 0),
		Vector2(0, 10), Vector2(-8, 0)
	])
	shard_visual.color = Color("#40FFFF")  # Starting cyan color
	add_child(shard_visual)
	
	# Inner glow polygon
	var inner_glow = Polygon2D.new()
	inner_glow.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(4, 0),
		Vector2(0, 5), Vector2(-4, 0)
	])
	inner_glow.color = Color("#FFFFFF")
	inner_glow.modulate.a = 0.7
	add_child(inner_glow)
	
	# Point light for glow effect
	shard_light = PointLight2D.new()
	shard_light.color = Color("#00FFFF")
	shard_light.energy = 0.9
	shard_light.texture_scale = 0.6
	add_child(shard_light)
	
	# Floating "◆" label above shard
	shard_label = Label.new()
	shard_label.text = "◆"
	shard_label.add_theme_font_size_override("font_size", 10)
	shard_label.add_theme_color_override("font_color", Color("#00FFFF"))
	shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shard_label.size = Vector2(20, 15)
	shard_label.position = Vector2(-10, -25)
	add_child(shard_label)
	
	# Collision shape for pickup detection
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)
	
	# Set up collision layers
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_alive += delta
	
	# Pulsing color effect
	var pulse = sin(Time.get_ticks_msec() * 0.003)
	var pulse_01 = (pulse + 1.0) / 2.0  # Convert -1 to 1 into 0 to 1
	shard_visual.modulate = Color.WHITE.lerp(Color("#40FFFF"), pulse_01)
	
	# Floating label bob
	shard_label.position.y = -25 + sin(time_alive * 2.0) * 2.0
	
	# Gentle floating shard
	position.y += sin(time_alive * 1.5) * 0.2

# Collection with effects
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect_shard()

func _collect_shard() -> void:
	# Full-screen cyan flash
	var flash = ColorRect.new()
	flash.color = Color("#00FFFF")
	flash.modulate.a = 0.35
	flash.size = DisplayServer.window_get_size()
	get_tree().current_scene.add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	flash_tween.tween_callback(flash.queue_free)
	
	# Floating "+1 SHARD ◆" text
	var text = Label.new()
	text.text = "+1 SHARD ◆"
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color("#00FFFF"))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.size = Vector2(200, 30)
	text.position = Vector2(global_position.x - 100, global_position.y - 20)
	get_tree().current_scene.add_child(text)
	
	var text_tween = create_tween()
	text_tween.parallel().tween_property(text, "position:y", text.position.y - 40, 1.0)
	text_tween.parallel().tween_property(text, "modulate:a", 0.0, 1.0)
	text_tween.tween_callback(text.queue_free)
	
	# Tell GameManager about collection
	GameManager.collect_shard()
	
	# Remove this shard
	queue_free()
