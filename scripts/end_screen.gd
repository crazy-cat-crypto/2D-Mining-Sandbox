# Script: end_screen.gd — handles both WIN and DEATH end states
# Data is passed via SceneTree metadata set by main_game.gd before scene change
extends Control

func _ready() -> void:
	# read data passed via tree metadata
	var did_win: bool = get_tree().get_meta("end_won", false)
	var shards: int = get_tree().get_meta("end_shards", 0)
	var depth: int = get_tree().get_meta("end_depth", 0)
	setup(did_win, shards, depth)

# build the appropriate screen based on outcome
func setup(did_win: bool, shards: int, depth: int) -> void:
	if did_win:
		_build_win_screen(shards, depth)
	else:
		_build_death_screen(shards, depth)

# ─── WIN SCREEN ───────────────────────────────────────────────────────────────
func _build_win_screen(shards: int, depth: int) -> void:
	# deep blue-black background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.008, 0.031, 0.094)  # #020818
	add_child(bg)

	# animated light rays rising from bottom
	_spawn_light_rays()

	# large gold title
	var title: Label = Label.new()
	title.text = "THE SURFACE STIRS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1280.0, 100.0)
	title.position = Vector2(0.0, 200.0)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))  # #FFD700
	add_child(title)

	# flavour text
	var sub: Label = Label.new()
	sub.text = "You recovered the echoes. The world remembers your name."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1280.0, 40.0)
	sub.position = Vector2(0.0, 300.0)
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color.WHITE)
	add_child(sub)

	# stats
	var stats: Label = Label.new()
	stats.text = "SHARDS RECOVERED: %d/10\nDEEPEST POINT: %dm" % [shards, depth]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.size = Vector2(1280.0, 80.0)
	stats.position = Vector2(0.0, 370.0)
	stats.add_theme_font_size_override("font_size", 22)
	stats.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	add_child(stats)

	# restart button
	_add_button("DESCEND AGAIN", Vector2(500.0, 490.0), Color(1.0, 0.843, 0.0))

# spawn 5 ColorRect strips that rise from the bottom via looping tweens
func _spawn_light_rays() -> void:
	for i: int in range(5):
		var ray: ColorRect = ColorRect.new()
		var ray_width: float = randf_range(30.0, 80.0)
		var ray_x: float = randf_range(80.0, 1200.0)
		ray.size = Vector2(ray_width, 720.0)
		ray.position = Vector2(ray_x, 720.0)
		ray.color = Color(0.4, 0.8, 1.0, 0.06)
		add_child(ray)
		# loop: slide up, teleport back, repeat
		var duration: float = randf_range(2.5, 4.5)
		var tween: Tween = create_tween().set_loops()
		tween.tween_property(ray, "position:y", -720.0, duration)
		tween.tween_property(ray, "position:y", 720.0, 0.0)

# ─── DEATH SCREEN ─────────────────────────────────────────────────────────────
func _build_death_screen(shards: int, depth: int) -> void:
	# pure black background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0)
	add_child(bg)

	# flickering glitch lines
	_spawn_glitch_lines()

	# large red title
	var title: Label = Label.new()
	title.text = "SIGNAL LOST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1280.0, 100.0)
	title.position = Vector2(0.0, 210.0)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.133, 0.133))  # #FF2222
	add_child(title)

	# flavour text
	var sub: Label = Label.new()
	sub.text = "Your echo fades into the stone. The depths claim another."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1280.0, 40.0)
	sub.position = Vector2(0.0, 310.0)
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))  # #666666
	add_child(sub)

	# stats
	var stats: Label = Label.new()
	stats.text = "SHARDS BEFORE SILENCE: %d/10\nDEPTH REACHED: %dm" % [shards, depth]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.size = Vector2(1280.0, 80.0)
	stats.position = Vector2(0.0, 380.0)
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	add_child(stats)

	# restart button
	_add_button("TRY AGAIN", Vector2(500.0, 490.0), Color(1.0, 0.133, 0.133))

# spawn 4 horizontal grey bars that flicker rapidly to simulate static
func _spawn_glitch_lines() -> void:
	var lines: Array = []
	for i: int in range(4):
		var line: ColorRect = ColorRect.new()
		line.size = Vector2(1280.0, float(randi_range(2, 5)))
		line.position = Vector2(0.0, float(randi_range(50, 660)))
		line.color = Color(0.4, 0.4, 0.4, 0.75)
		add_child(line)
		lines.append(line)
	# timer that toggles all line visibility every 0.05 seconds
	var flicker: Timer = Timer.new()
	flicker.wait_time = 0.05
	flicker.autostart = true
	flicker.timeout.connect(func() -> void:
		for line: ColorRect in lines:
			line.visible = !line.visible
	)
	add_child(flicker)

# shared button builder (styled with colored border)
func _add_button(label_text: String, pos: Vector2, accent: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.1)
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	var btn: Button = Button.new()
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
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
