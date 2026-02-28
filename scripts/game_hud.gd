# Script: game_hud.gd — displays VITALS bar, depth, and stone counter on screen
extends CanvasLayer

# VITALS bar references
var vitals_label: Label = null
var health_bar_bg: ColorRect = null
var health_bar_fill: ColorRect = null
const HEALTH_BAR_WIDTH: float = 180.0
const HEALTH_BAR_HEIGHT: float = 14.0
# pulse state for low-health warning
var pulse_timer: float = 0.0
var pulse_state: bool = false

# other HUD references
var depth_label: Label = null
var stone_label: Label = null
var message_label: Label = null
var depth_bar: ColorRect = null
var depth_bar_fill: ColorRect = null

# maximum depth for the bar display
const MAX_DEPTH_DISPLAY: float = 60.0

func _ready() -> void:
	# build the HUD layout
	_create_vitals_bar()
	_create_stone_counter()
	_create_depth_label()
	_create_depth_bar()
	_create_message_display()

# create the VITALS health bar in the top-left corner
func _create_vitals_bar() -> void:
	vitals_label = Label.new()
	vitals_label.position = Vector2(16, 14)
	vitals_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vitals_label.add_theme_font_size_override("font_size", 12)
	vitals_label.text = "VITALS"
	add_child(vitals_label)
	
	# dark background strip
	health_bar_bg = ColorRect.new()
	health_bar_bg.position = Vector2(16, 30)
	health_bar_bg.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_bar_bg.color = Color(0.15, 0.05, 0.05, 0.85)
	add_child(health_bar_bg)
	
	# red fill bar — shrinks left to right as health falls
	health_bar_fill = ColorRect.new()
	health_bar_fill.position = Vector2(16, 30)
	health_bar_fill.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_bar_fill.color = Color(1.0, 0.23, 0.23)  # #FF3B3B
	add_child(health_bar_fill)

func _process(delta: float) -> void:
	# pulse the health bar when below 25 % health
	if health_bar_fill == null:
		return
	var ratio: float = health_bar_fill.size.x / HEALTH_BAR_WIDTH
	if ratio < 0.25:
		pulse_timer += delta
		if pulse_timer >= 0.35:
			pulse_timer = 0.0
			pulse_state = !pulse_state
		health_bar_fill.color = Color(1.0, 0.23, 0.23) if not pulse_state else Color(0.55, 0.05, 0.05)
	else:
		# reset to normal red when health is OK
		health_bar_fill.color = Color(1.0, 0.23, 0.23)

# create the sacred stone counter — now positioned below the VITALS bar
func _create_stone_counter() -> void:
	stone_label = Label.new()
	stone_label.position = Vector2(16, 52)
	stone_label.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9))
	stone_label.add_theme_font_size_override("font_size", 18)
	stone_label.text = "Sacred Stones: 0/7"
	add_child(stone_label)

# create the depth counter text
func _create_depth_label() -> void:
	depth_label = Label.new()
	depth_label.position = Vector2(16, 78)
	depth_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	depth_label.add_theme_font_size_override("font_size", 16)
	depth_label.text = "Depth: 0 blocks"
	add_child(depth_label)

# create the vertical depth bar on the right side
func _create_depth_bar() -> void:
	# background bar
	depth_bar = ColorRect.new()
	depth_bar.position = Vector2(1240, 60)
	depth_bar.size = Vector2(16, 400)
	depth_bar.color = Color(0.15, 0.15, 0.2, 0.6)
	add_child(depth_bar)
	
	# fill bar (grows downward as you go deeper)
	depth_bar_fill = ColorRect.new()
	depth_bar_fill.position = Vector2(1242, 62)
	depth_bar_fill.size = Vector2(12, 0)
	depth_bar_fill.color = Color(0.3, 0.5, 0.9, 0.8)
	add_child(depth_bar_fill)
	
	# top label
	var top_label: Label = Label.new()
	top_label.position = Vector2(1220, 40)
	top_label.add_theme_font_size_override("font_size", 12)
	top_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	top_label.text = "Depth"
	add_child(top_label)

# create the center message display for win/death/return messages
func _create_message_display() -> void:
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.position = Vector2(240, 300)
	message_label.size = Vector2(800, 120)
	message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	message_label.add_theme_font_size_override("font_size", 28)
	message_label.text = ""
	message_label.visible = false
	add_child(message_label)

# update_health — accepts 0-100 value and resizes the VITALS bar fill proportionally
func update_health(current_hp: int, max_hp: int = 100) -> void:
	if health_bar_fill == null:
		return
	var ratio: float = clampf(float(current_hp) / float(max_hp), 0.0, 1.0)
	health_bar_fill.size.x = HEALTH_BAR_WIDTH * ratio

# update the sacred stone counter
func update_stones(collected: int) -> void:
	stone_label.text = "Sacred Stones: " + str(collected) + "/7"

# update the depth display and bar
func update_depth(current_depth: float) -> void:
	depth_label.text = "Depth: " + str(int(current_depth)) + " blocks"
	# update the depth bar fill
	var fill_ratio: float = clampf(current_depth / MAX_DEPTH_DISPLAY, 0.0, 1.0)
	depth_bar_fill.size.y = fill_ratio * 396.0
	# change color based on depth
	if fill_ratio > 0.7:
		depth_bar_fill.color = Color(0.7, 0.2, 0.9, 0.8)
	elif fill_ratio > 0.4:
		depth_bar_fill.color = Color(0.5, 0.5, 0.9, 0.8)
	else:
		depth_bar_fill.color = Color(0.3, 0.7, 0.4, 0.8)

# show a centered message on screen
func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
