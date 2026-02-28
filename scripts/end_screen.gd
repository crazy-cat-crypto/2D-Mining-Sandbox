# Script: end_screen.gd — Win/Death screens for Minor Dai
extends Control

var did_win: bool = false
var shards: int = 0
var depth: int = 0

func _ready() -> void:
	# Get data from GameManager
	did_win = GameManager.shards_collected >= 10
	shards = GameManager.shards_collected
	depth = int(GameManager.max_depth_reached)
	setup(did_win, shards, depth)

# build the appropriate screen based on outcome
func setup(win_state: bool, shard_count: int, depth_reached: int) -> void:
	if win_state:
		_show_win(shard_count, depth_reached)
	else:
		_show_death(shard_count, depth_reached)

# ─── WIN SCREEN ─── (Section 6 specs)
func _show_win(shard_count: int, depth_reached: int) -> void:
	# Deep blue-black background
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color("#020818")
	add_child(bg)

	# Animated "MINOR DAI WINS!" title (dropping letters like main menu)
	await _create_animated_win_title()
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "You found the echoes. The mountain remembers your name."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size = Vector2(1280.0, 40.0)
	subtitle.position = Vector2(0.0, 320.0)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	add_child(subtitle)

	# Stats
	var stats = Label.new()
	stats.text = "SHARDS RECOVERED: %d/10\nDEEPEST POINT: %dm" % [shard_count, depth_reached]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.size = Vector2(1280.0, 80.0)
	stats.position = Vector2(0.0, 380.0)
	stats.add_theme_font_size_override("font_size", 22)
	stats.add_theme_color_override("font_color", Color("#AAAAAA"))
	add_child(stats)

	# Button
	_add_button("DESCEND AGAIN", Vector2(500.0, 490.0), Color("#FFD700"))

# Create animated falling title letters
func _create_animated_win_title() -> void:
	const WIN_TITLE = "MINOR DAI WINS!"
	const COLORS = [Color("#FFD700"), Color("#FFB700"), Color("#FF8C00")]
	
	var letter_spacing = 45
	var start_x = (1280 - (WIN_TITLE.length() * letter_spacing)) / 2
	
	for i in range(WIN_TITLE.length()):
		var letter = Label.new()
		letter.text = WIN_TITLE[i]
		letter.add_theme_font_size_override("font_size", 56)
		letter.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.size = Vector2(letter_spacing, 80)
		letter.position = Vector2(start_x + i * letter_spacing, -100)  # Start off-screen
		add_child(letter)
		
		# Animate letter falling into place
		await get_tree().create_timer(i * 0.06).timeout
		var tween = create_tween()
		tween.tween_property(letter, "position:y", 220, 0.4)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)

# ─── DEATH SCREEN ─── (Section 6 specs)
func _show_death(shard_count: int, depth_reached: int) -> void:
	# Black background
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color("#000000")
	add_child(bg)

	# Glitch bars
	_spawn_glitch_bars()

	# Animated "SIGNAL LOST" title
	await _create_glitch_death_title()

	# Subtitle  
	var subtitle = Label.new()
	subtitle.text = "Your echo fades. The stone remembers nothing."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size = Vector2(1280.0, 40.0)
	subtitle.position = Vector2(0.0, 320.0)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#666666"))
	add_child(subtitle)

	# Stats
	var stats = Label.new()
	stats.text = "SHARDS BEFORE SILENCE: %d/10\nDEPTH REACHED: %dm" % [shard_count, depth_reached]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.size = Vector2(1280.0, 80.0)
	stats.position = Vector2(0.0, 380.0)
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color("#888888"))
	add_child(stats)

	# Button
	_add_button("TRY AGAIN", Vector2(500.0, 490.0), Color("#FF2222"))

# Create glitchy animated death title
func _create_glitch_death_title() -> void:
	const DEATH_TITLE = "SIGNAL LOST"
	
	var letter_spacing = 60
	var start_x = (1280 - (DEATH_TITLE.length() * letter_spacing)) / 2
	
	for i in range(DEATH_TITLE.length()):
		var letter = Label.new()
		letter.text = DEATH_TITLE[i]
		letter.add_theme_font_size_override("font_size", 56)
		letter.add_theme_color_override("font_color", Color("#FF2222"))
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.size = Vector2(letter_spacing, 80)
		letter.position = Vector2(start_x + i * letter_spacing, 220)
		
		# Add glitch offset initially
		letter.position.x += randf_range(-10, 10)
		letter.position.y += randf_range(-5, 5)
		add_child(letter)
		
		# Wait a bit, then snap to proper position
		await get_tree().create_timer(i * 0.08 + randf_range(0.1, 0.3)).timeout
		var tween = create_tween()
		tween.tween_property(letter, "position", Vector2(start_x + i * letter_spacing, 220), 0.1)

# 3 horizontal grey glitch bars that randomly reposition
func _spawn_glitch_bars() -> void:
	for i in range(3):
		var bar = ColorRect.new()
		bar.size = Vector2(1280, randi_range(3, 8))
		bar.position = Vector2(0, randf_range(100, 600))
		bar.color = Color("#666666")
		add_child(bar)
		
		# Timer to reposition every 0.06 seconds
		var timer = Timer.new()
		timer.wait_time = 0.06
		timer.autostart = true
		timer.timeout.connect(func(): bar.position.y = randf_range(100, 600))
		add_child(timer)

# Shared button builder
func _add_button(label_text: String, pos: Vector2, accent: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#111122")
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	var btn = Button.new()
	btn.text = label_text
	btn.size = Vector2(280.0, 54.0)
	btn.position = pos
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.pressed.connect(_on_restart_pressed)
	add_child(btn)

func _on_restart_pressed() -> void:
	GameManager.restart_game()
