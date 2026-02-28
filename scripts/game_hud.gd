# Script: game_hud.gd — Clean and minimal HUD for Minor Dai (Section 7)
extends CanvasLayer

# HUD elements (Section 7 specs)
var vitals_label: Label = null
var health_bar_bg: ColorRect = null
var health_bar_fill: ColorRect = null
var depth_label: Label = null
var shard_label: Label = null
var pulse_timer: float = 0.0

const HEALTH_BAR_WIDTH: float = 90.0
const HEALTH_BAR_HEIGHT: float = 10.0

func _ready() -> void:
	# Build clean minimal HUD
	_create_vitals_display()
	_create_depth_display()  
	_create_shard_display()
	
	# Connect to GameManager signals
	GameManager.shard_collected.connect(_on_shard_collected)

func _process(delta: float) -> void:
	# Health bar pulse when below 25%
	if health_bar_fill != null:
		var ratio = health_bar_fill.size.x / HEALTH_BAR_WIDTH
		if ratio < 0.25:
			pulse_timer += delta * 4.0  # Faster pulse
			var alpha = 0.5 + sin(pulse_timer) * 0.5
			health_bar_fill.modulate.a = alpha
		else:
			health_bar_fill.modulate.a = 1.0
	
	# Update depth display continuously
	_update_depth_display()

# Top left: Health bar (Section 7)
func _create_vitals_display() -> void:
	# "VITALS" label above
	vitals_label = Label.new()
	vitals_label.position = Vector2(20, 15)
	vitals_label.text = "VITALS"
	vitals_label.add_theme_font_size_override("font_size", 10)
	vitals_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(vitals_label)
	
	# Health bar background  
	health_bar_bg = ColorRect.new()
	health_bar_bg.position = Vector2(20, 30)
	health_bar_bg.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_bar_bg.color = Color("#333333")
	add_child(health_bar_bg)
	
	# Health bar fill
	health_bar_fill = ColorRect.new()
	health_bar_fill.position = Vector2(20, 30)
	health_bar_fill.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_bar_fill.color = Color("#FF3B3B")
	add_child(health_bar_fill)

# Top center: Depth meter (Section 7)
func _create_depth_display() -> void:
	depth_label = Label.new()
	depth_label.position = Vector2(540, 20)  # Centered
	depth_label.size = Vector2(200, 30)
	depth_label.text = "▼ 0m UNDERGROUND"
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_label.add_theme_font_size_override("font_size", 14)
	depth_label.add_theme_color_override("font_color", Color("#00FFFF"))
	add_child(depth_label)

# Top right: Shard counter (Section 7)
func _create_shard_display() -> void:
	shard_label = Label.new()  
	shard_label.position = Vector2(1080, 20)
	shard_label.size = Vector2(180, 30)
	shard_label.text = "◆ ECHOES: 0/10"
	shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shard_label.add_theme_font_size_override("font_size", 13)
	shard_label.add_theme_color_override("font_color", Color("#00FFFF"))
	add_child(shard_label)

# Update health bar based on player health
func update_health(current_hp: int, max_hp: int = 100) -> void:
	if health_bar_fill == null:
		return
	var ratio = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	health_bar_fill.size.x = HEALTH_BAR_WIDTH * ratio

# Update depth display with player position
func _update_depth_display() -> void:
	if depth_label == null:
		return
	var depth = int(GameManager.max_depth_reached)
	depth_label.text = "▼ %dm UNDERGROUND" % depth
	
	# Glow brighter cyan as depth increases
	var glow_intensity = clampf(depth / 100.0, 0.3, 1.0)
	depth_label.add_theme_color_override("font_color", Color("#00FFFF").lightened(glow_intensity * 0.3))

# Update shard counter
func update_shards(collected: int, _needed: int = 10) -> void:
	if shard_label == null:
		return  
	shard_label.text = "◆ ECHOES: %d/%d" % [collected, _needed]

# Bounce effect when shard collected (Section 7)
func _on_shard_collected(total_shards: int) -> void:
	update_shards(total_shards)
	if shard_label != null:
		var tween = create_tween()
		tween.tween_property(shard_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(shard_label, "scale", Vector2(1.0, 1.0), 0.2)

# Simplified interface for compatibility
func update_stones(_collected: int) -> void:
	pass  # Remove sacred stone counter per Section 7

func update_depth(_depth: float) -> void:
	pass  # Depth updates automatically

func show_message(_text: String) -> void:
	pass  # Remove message display per Section 7
