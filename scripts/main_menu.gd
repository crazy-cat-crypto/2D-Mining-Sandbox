# Script: main_menu.gd — title screen for "Echoes Under the Surface"
extends Control

func _ready() -> void:
	# build all UI elements in code so no external assets are needed
	_build_background()
	_build_particles()
	_build_title()
	_build_buttons()

# full screen dark background
func _build_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.039, 0.039, 0.102)  # #0A0A1A
	add_child(bg)

# falling spore/dust particle effect
func _build_particles() -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	# emit across the full top of the screen
	particles.position = Vector2(640, -10)
	particles.amount = 40
	particles.lifetime = 8.0
	particles.direction = Vector2(0.0, 1.0)
	particles.spread = 80.0
	particles.gravity = Vector2(0.0, 10.0)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.color = Color(1.0, 1.0, 1.0, 0.25)
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 1.2
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector2(660.0, 2.0)
	particles.emitting = true
	add_child(particles)

# title, subtitle labels
func _build_title() -> void:
	# main title — large cyan text
	var title: Label = Label.new()
	title.text = "ECHOES UNDER THE SURFACE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1280.0, 80.0)
	title.position = Vector2(0.0, 190.0)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.0, 0.898, 1.0))  # #00E5FF
	add_child(title)

	# subtitle — smaller grey text
	var subtitle: Label = Label.new()
	subtitle.text = "The surface is gone. What lives below is yours to find."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size = Vector2(1280.0, 40.0)
	subtitle.position = Vector2(0.0, 258.0)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.667, 0.667, 0.667))  # #AAAAAA
	add_child(subtitle)

# begin descent and quit buttons with dark+cyan style
func _build_buttons() -> void:
	var style: StyleBoxFlat = _make_button_style()

	var play_btn: Button = Button.new()
	play_btn.text = "BEGIN DESCENT"
	play_btn.size = Vector2(280.0, 54.0)
	play_btn.position = Vector2(500.0, 370.0)
	play_btn.add_theme_font_size_override("font_size", 20)
	play_btn.add_theme_color_override("font_color", Color.WHITE)
	play_btn.add_theme_stylebox_override("normal", style)
	play_btn.add_theme_stylebox_override("hover", style)
	play_btn.add_theme_stylebox_override("pressed", style)
	play_btn.pressed.connect(_on_begin_pressed)
	add_child(play_btn)

	var quit_btn: Button = Button.new()
	quit_btn.text = "QUIT"
	quit_btn.size = Vector2(280.0, 54.0)
	quit_btn.position = Vector2(500.0, 446.0)
	quit_btn.add_theme_font_size_override("font_size", 20)
	quit_btn.add_theme_color_override("font_color", Color.WHITE)
	quit_btn.add_theme_stylebox_override("normal", style)
	quit_btn.add_theme_stylebox_override("hover", style)
	quit_btn.add_theme_stylebox_override("pressed", style)
	quit_btn.pressed.connect(_on_quit_pressed)
	add_child(quit_btn)

# creates the shared button StyleBox (dark bg, cyan border)
func _make_button_style() -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.102, 0.102, 0.18)  # #1A1A2E
	s.border_color = Color(0.0, 0.898, 1.0)  # cyan
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	return s

func _on_begin_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
