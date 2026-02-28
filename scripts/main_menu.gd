# Script: main_menu.gd — title screen for "Minor Dai"  
extends Control

const TITLE = "MINOR DAI"
const COLORS = [
	Color("#FFD700"), Color("#FFB700"), Color("#FF8C00"),
	Color("#00E5FF"), Color("#00BFFF"), Color("#0099CC")
]

var title_letters: Array[Label] = []
var torch_lights: Array[PointLight2D] = []
var flickering_subtitle: Label = null

func _ready() -> void:
	_build_background()
	_build_particles()
	_build_torch_lights()
	_build_animated_title()
	_build_subtitles()
	_build_buttons()

func _process(_delta: float) -> void:
	# Animate letter bobbing
	for i in range(title_letters.size()):
		var letter = title_letters[i]
		letter.position.y += sin(Time.get_ticks_msec() * 0.002 + i * 0.5) * 0.4
	
	# Animate torch lights
	for light in torch_lights:
		light.energy = 0.7 + sin(Time.get_ticks_msec() * 0.004) * 0.25

# full screen dark background
func _build_background() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color("#080810")
	add_child(bg)

# falling dust particles with torch atmosphere
func _build_particles() -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.position = Vector2(640, -10)
	particles.amount = 80
	particles.lifetime = 6.0
	particles.direction = Vector2(0.0, 1.0)
	particles.spread = 45.0
	particles.gravity = Vector2(0.0, 15.0)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 40.0
	particles.color = Color(1.0, 1.0, 1.0, 0.3)
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(600.0, 2.0)
	particles.emitting = true
	add_child(particles)

# torch lighting effects on left and right
func _build_torch_lights() -> void:
	# Left torch
	var left_torch = PointLight2D.new()
	left_torch.position = Vector2(150, 360)
	left_torch.energy = 0.7
	left_torch.color = Color("#FF8C00")
	left_torch.texture_scale = 1.2
	torch_lights.append(left_torch)
	add_child(left_torch)
	
	# Right torch  
	var right_torch = PointLight2D.new()
	right_torch.position = Vector2(1130, 360)
	right_torch.energy = 0.7
	right_torch.color = Color("#FF8C00")
	right_torch.texture_scale = 1.2
	torch_lights.append(right_torch)
	add_child(right_torch)

# animated title with falling letters
func _build_animated_title() -> void:
	var letter_spacing: int = 65
	var start_x: int = (1280 - (TITLE.length() * letter_spacing)) / 2.0 as int
	
	for i in range(TITLE.length()):
		var letter = Label.new()
		letter.text = TITLE[i]
		letter.add_theme_font_size_override("font_size", 72)
		letter.add_theme_color_override("font_color", COLORS[i % COLORS.size()])
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.size = Vector2(letter_spacing, 90)
		letter.position = Vector2(start_x + i * letter_spacing, -200)  # Start off-screen
		
		# Mouse hover detection
		var area = Area2D.new()
		var collision = RectangleShape2D.new()
		collision.size = Vector2(letter_spacing, 90)
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = collision
		area.add_child(collision_shape)
		letter.add_child(area)
		
		area.mouse_entered.connect(_on_letter_hover.bind(letter))
		area.mouse_exited.connect(_on_letter_unhover.bind(letter))
		
		title_letters.append(letter)
		add_child(letter)
		
		# Animate letter falling into place with delay
		var tween = create_tween()
		tween.tween_interval(i * 0.09)
		tween.tween_property(letter, "position:y", 180, 0.6)
		tween.set_trans(Tween.TRANS_BACK)  
		tween.set_ease(Tween.EASE_OUT)

func _on_letter_hover(letter: Label) -> void:
	var tween = create_tween()
	tween.tween_property(letter, "scale", Vector2(1.4, 1.4), 0.1)
	# TODO: Add tick sound effect here

func _on_letter_unhover(letter: Label) -> void:
	var tween = create_tween()
	tween.tween_property(letter, "scale", Vector2(1.0, 1.0), 0.1)

# subtitle text below animated title
func _build_subtitles() -> void:
	# First subtitle
	var subtitle1: Label = Label.new()
	subtitle1.text = "Khanna ura, gahiro ja."
	subtitle1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle1.size = Vector2(1280.0, 30.0)
	subtitle1.position = Vector2(0.0, 280.0)
	subtitle1.add_theme_font_size_override("font_size", 18)
	subtitle1.add_theme_color_override("font_color", Color("#AAAAAA"))
	add_child(subtitle1)
	
	# Second subtitle with flicker
	var subtitle2: Label = Label.new()
	subtitle2.text = "Mine 10 Echo Shards. Dodge zombies. Go deep."
	subtitle2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle2.size = Vector2(1280.0, 25.0)
	subtitle2.position = Vector2(0.0, 310.0)
	subtitle2.add_theme_font_size_override("font_size", 14)
	subtitle2.add_theme_color_override("font_color", Color.WHITE)
	add_child(subtitle2)
	
	# Flicker effect for subtitle2
	var flicker_tween = create_tween()
	flicker_tween.set_loops(-1)  # Infinite loops
	flicker_tween.tween_method(_flicker_subtitle_animation, 0.0, 6.28, 2.0)
	
	# Store reference for the animation
	flickering_subtitle = subtitle2

func _flicker_subtitle_animation(value: float) -> void:
	if flickering_subtitle:
		var alpha = 0.7 + sin(value) * 0.3
		flickering_subtitle.modulate.a = alpha

# begin descent and quit buttons with hover effects
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
	play_btn.mouse_entered.connect(_on_button_hover.bind(play_btn))
	play_btn.mouse_exited.connect(_on_button_unhover.bind(play_btn))
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
	quit_btn.mouse_entered.connect(_on_button_hover.bind(quit_btn))
	quit_btn.mouse_exited.connect(_on_button_unhover.bind(quit_btn))
	add_child(quit_btn)

func _on_button_hover(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

# creates the shared button StyleBox (dark bg, cyan border)
func _make_button_style() -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color("#111122")
	s.border_color = Color("#00E5FF")
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
	GameManager.restart_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
