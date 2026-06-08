extends Node2D

# ── Colour palette options ────────────────────────────────────────────────────
const SHIRT_COLORS : Array[Color] = [
	Color(0.22, 0.44, 0.90),   # Blue
	Color(0.85, 0.15, 0.15),   # Red
	Color(0.15, 0.65, 0.25),   # Green
	Color(0.90, 0.75, 0.10),   # Yellow
	Color(0.55, 0.10, 0.80),   # Purple
	Color(0.18, 0.18, 0.18),   # Black
]
const HAIR_COLORS : Array[Color] = [
	Color(0.28, 0.14, 0.04),   # Brown
	Color(0.06, 0.04, 0.04),   # Black
	Color(0.88, 0.78, 0.30),   # Blonde
	Color(0.72, 0.18, 0.08),   # Red
	Color(0.72, 0.72, 0.72),   # Grey
]
const SKIN_COLORS : Array[Color] = [
	Color(1.00, 0.82, 0.65),   # Light
	Color(0.90, 0.70, 0.50),   # Medium
	Color(0.75, 0.55, 0.35),   # Tan
	Color(0.45, 0.30, 0.18),   # Dark
]

# Swatch circle positions (built in _ready)
var _shirt_pts : Array[Vector2] = []
var _hair_pts  : Array[Vector2] = []
var _skin_pts  : Array[Vector2] = []
const SWATCH_R : float = 22.0

func _ready() -> void:
	PlayerData.load_save()   # restore saved progress
	_build_swatch_positions()
	_build_ui_labels()
	queue_redraw()

# ── Place colour circles ──────────────────────────────────────────────────────
func _build_swatch_positions() -> void:
	var sx : float = 500.0
	var sp : float = 58.0
	for i in SHIRT_COLORS.size():
		_shirt_pts.append(Vector2(sx + i * sp, 300.0))
	for i in HAIR_COLORS.size():
		_hair_pts.append(Vector2(sx + i * sp, 400.0))
	for i in SKIN_COLORS.size():
		_skin_pts.append(Vector2(sx + i * sp, 490.0))

# ── Text labels & Play button (Control nodes in a CanvasLayer) ────────────────
func _build_ui_labels() -> void:
	var cl : CanvasLayer = CanvasLayer.new()
	add_child(cl)

	_make_label(cl, "ELEMENTAL FART",   Vector2(95, 25),  70, Color(1, 1, 1),
				Color(0, 0, 0, 0.65), 3)
	_make_label(cl, "Your character",   Vector2(155, 155), 20, Color(0.1, 0.05, 0),
				Color(0,0,0,0), 0)
	_make_label(cl, "Shirt colour:",    Vector2(480, 265), 19, Color(0.1, 0.05, 0),
				Color(0,0,0,0), 0)
	_make_label(cl, "Hair colour:",     Vector2(480, 365), 19, Color(0.1, 0.05, 0),
				Color(0,0,0,0), 0)
	_make_label(cl, "Skin colour:",     Vector2(480, 455), 19, Color(0.1, 0.05, 0),
				Color(0,0,0,0), 0)

	var play : Button = Button.new()
	play.text = "LET'S PLAY!  →"
	play.add_theme_font_size_override("font_size", 34)
	play.custom_minimum_size = Vector2(260, 60)
	play.position = Vector2(460, 560)
	play.pressed.connect(_on_play)
	cl.add_child(play)

	# High score / Continue card — only shown if the player has made progress
	if PlayerData.best_level > 1:
		# Trophy card background
		var card : Panel = Panel.new()
		card.size     = Vector2(310, 80)
		card.position = Vector2(90, 470)
		var style : StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color          = Color(0.95, 0.82, 0.10, 0.92)
		style.corner_radius_top_left     = 10
		style.corner_radius_top_right    = 10
		style.corner_radius_bottom_left  = 10
		style.corner_radius_bottom_right = 10
		card.add_theme_stylebox_override("panel", style)
		cl.add_child(card)

		_make_label(cl, "🏆 Best: Level " + str(PlayerData.best_level) + " / 100",
					Vector2(108, 480), 18, Color(0.15, 0.08, 0), Color(0,0,0,0), 0)

		var cont : Button = Button.new()
		cont.text = "▶  Continue from Level " + str(PlayerData.best_level)
		cont.add_theme_font_size_override("font_size", 17)
		cont.custom_minimum_size = Vector2(270, 34)
		cont.position = Vector2(103, 508)
		cont.pressed.connect(_on_continue)
		cl.add_child(cont)

func _make_label(parent: CanvasLayer, text: String, pos: Vector2,
				 size: int, col: Color, shadow: Color, sh_off: int) -> void:
	var lbl : Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_shadow_color", shadow)
	lbl.add_theme_constant_override("shadow_offset_x", sh_off)
	lbl.add_theme_constant_override("shadow_offset_y", sh_off)
	lbl.position = pos
	parent.add_child(lbl)

# ── Start the game ────────────────────────────────────────────────────────────
func _on_play() -> void:
	PlayerData.current_level = 1
	get_tree().change_scene_to_file("res://Level.tscn")

func _on_continue() -> void:
	PlayerData.current_level = PlayerData.best_level
	get_tree().change_scene_to_file("res://Level.tscn")

# ── Detect swatch clicks ──────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not (event as InputEventMouseButton).pressed:
		return
	var mp : Vector2 = (event as InputEventMouseButton).position
	for i in _shirt_pts.size():
		if mp.distance_to(_shirt_pts[i]) <= SWATCH_R + 6.0:
			PlayerData.shirt_color = SHIRT_COLORS[i]; queue_redraw(); return
	for i in _hair_pts.size():
		if mp.distance_to(_hair_pts[i])  <= SWATCH_R + 6.0:
			PlayerData.hair_color  = HAIR_COLORS[i];  queue_redraw(); return
	for i in _skin_pts.size():
		if mp.distance_to(_skin_pts[i])  <= SWATCH_R + 6.0:
			PlayerData.skin_color  = SKIN_COLORS[i];  queue_redraw(); return

# ── Draw everything ───────────────────────────────────────────────────────────
func _draw() -> void:
	# Sky background
	draw_rect(Rect2(0, 0, 1152, 648), Color(0.50, 0.78, 0.97))

	# Fluffy clouds
	_cloud(Vector2(820, 75), 65.0)
	_cloud(Vector2(980, 45), 48.0)
	_cloud(Vector2(660, 105), 52.0)
	_cloud(Vector2(100, 90), 40.0)

	# Ground strip
	draw_rect(Rect2(0, 590, 1152, 58), Color(0.38, 0.22, 0.09))
	draw_rect(Rect2(0, 588, 1152, 6),  Color(0.22, 0.60, 0.25))

	# Character panel (frosted)
	draw_rect(Rect2(90, 150, 360, 420), Color(1, 1, 1, 0.30))
	draw_rect(Rect2(90, 150, 360, 4),   Color(1, 1, 1, 0.60))

	# Customisation panel
	draw_rect(Rect2(465, 205, 660, 405), Color(1, 1, 1, 0.30))
	draw_rect(Rect2(465, 205, 660, 4),   Color(1, 1, 1, 0.60))

	# Colour swatches
	_draw_swatches(_shirt_pts, SHIRT_COLORS, PlayerData.shirt_color)
	_draw_swatches(_hair_pts,  HAIR_COLORS,  PlayerData.hair_color)
	_draw_swatches(_skin_pts,  SKIN_COLORS,  PlayerData.skin_color)

	# Character preview (feet at y=588, scaled 1.6×)
	_draw_character(Vector2(270, 585))

func _cloud(pos: Vector2, r: float) -> void:
	draw_circle(pos,                          r,        Color(1, 1, 1, 0.85))
	draw_circle(pos + Vector2(r * 0.75, 0),   r * 0.70, Color(1, 1, 1, 0.85))
	draw_circle(pos - Vector2(r * 0.75, 0),   r * 0.70, Color(1, 1, 1, 0.85))

func _draw_swatches(pts: Array[Vector2], colors: Array[Color], selected: Color) -> void:
	for i in pts.size():
		var sel : bool = (colors[i] == selected)
		# Outer ring: yellow if selected, grey otherwise
		draw_circle(pts[i], SWATCH_R + (5.0 if sel else 2.0),
					Color(1.0, 0.9, 0.0) if sel else Color(0.45, 0.45, 0.45))
		draw_circle(pts[i], SWATCH_R, colors[i])

# ── Character preview (identical draw logic to Player.gd, idle pose) ──────────
func _rot_rect(pos: Vector2, angle: float, w: float, h: float) -> PackedVector2Array:
	var hw : float = w * 0.5
	var c  : float = cos(angle)
	var s  : float = sin(angle)
	var out : PackedVector2Array = PackedVector2Array()
	for p : Vector2 in [Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw, h), Vector2(-hw, h)]:
		out.append(pos + Vector2(p.x * c - p.y * s, p.x * s + p.y * c))
	return out

func _draw_character(feet: Vector2) -> void:
	var skin   : Color = PlayerData.skin_color
	var hair   : Color = PlayerData.hair_color
	var shirt  : Color = PlayerData.shirt_color
	var pant   : Color = Color(0.15, 0.15, 0.45)
	var shoe_c : Color = Color(0.18, 0.09, 0.04)
	var eye_c  : Color = Color(0.06, 0.04, 0.04)

	# Scale 1.6× so character is big and easy to see
	draw_set_transform(feet, 0.0, Vector2(1.6, 1.6))

	# Back arm (slight wave)
	draw_colored_polygon(_rot_rect(Vector2(-7.0, -16.0), -0.25, 7.0, 20.0), skin)
	# Back leg
	draw_colored_polygon(_rot_rect(Vector2(-4.0, -4.0), 0.15, 8.0, 20.0), pant)
	draw_colored_polygon(_rot_rect(Vector2(-5.0, 14.0), 0.15, 11.0, 8.0), shoe_c)
	# Body
	draw_rect(Rect2(-11.0, -24.0, 22.0, 30.0), shirt)
	# Front leg
	draw_colored_polygon(_rot_rect(Vector2(4.0, -4.0), -0.15, 8.0, 20.0), pant)
	draw_colored_polygon(_rot_rect(Vector2(3.0, 14.0), -0.15, 11.0, 8.0), shoe_c)
	# Front arm
	draw_colored_polygon(_rot_rect(Vector2(7.0, -16.0), 0.25, 7.0, 20.0), skin)
	# Head
	draw_circle(Vector2(0.0, -38.0), 15.0, skin)
	# Hair
	for i in 9:
		var a : float = PI + i * (PI / 8.0)
		draw_line(Vector2(cos(a) * 13.0, sin(a) * 13.0 - 38.0),
				  Vector2(cos(a) * 19.0, sin(a) * 19.0 - 38.0), hair, 3.5)
	# Ear
	draw_circle(Vector2(-12.0, -38.0), 6.0, skin)
	# Eye + shine
	draw_circle(Vector2(7.0, -40.0), 4.5, eye_c)
	draw_circle(Vector2(7.5, -41.5), 2.0, Color.WHITE)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
