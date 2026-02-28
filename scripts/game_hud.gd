# Script: game_hud.gd — displays health, depth, and stone counter on screen
extends CanvasLayer

# references to HUD elements
var health_container: HBoxContainer = null
var depth_label: Label = null
var stone_label: Label = null
var message_label: Label = null
var depth_bar: ColorRect = null
var depth_bar_fill: ColorRect = null

# maximum depth for the bar display
const MAX_DEPTH_DISPLAY: float = 60.0

func _ready() -> void:
	# build the HUD layout
	_create_health_display()
	_create_stone_counter()
	_create_depth_label()
	_create_depth_bar()
	_create_message_display()

# create the row of heart squares at the top left
func _create_health_display() -> void:
	health_container = HBoxContainer.new()
	health_container.position = Vector2(20, 20)
	health_container.add_theme_constant_override("separation", 6)
	add_child(health_container)
	# start with 5 hearts
	update_health(5)

# create the sacred stone counter
func _create_stone_counter() -> void:
	stone_label = Label.new()
	stone_label.position = Vector2(20, 55)
	stone_label.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9))
	stone_label.add_theme_font_size_override("font_size", 18)
	stone_label.text = "Sacred Stones: 0/7"
	add_child(stone_label)

# create the depth counter text
func _create_depth_label() -> void:
	depth_label = Label.new()
	depth_label.position = Vector2(20, 80)
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

# update the health hearts display
func update_health(current_health: int) -> void:
	# clear old hearts
	for child: Node in health_container.get_children():
		child.queue_free()
	# draw new hearts as red/gray squares
	for i: int in range(5):
		var heart: ColorRect = ColorRect.new()
		heart.custom_minimum_size = Vector2(20, 20)
		if i < current_health:
			heart.color = Color(0.9, 0.15, 0.15)
		else:
			heart.color = Color(0.3, 0.3, 0.3, 0.5)
		health_container.add_child(heart)

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
