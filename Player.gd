extends CharacterBody2D

const SPEED      : float = 260.0
const JUMP_V     : float = -580.0
const GRAVITY    : float = 980.0

# ── Fart jet-pack ────────────────────────────────────────────────────────────
const FART_MAX      : float = 5.0    # seconds of gas
const FART_LIFT     : float = 620.0  # upward acceleration while farting
const FART_VCAP     : float = -340.0 # max upward speed while farting
const BALL_FUEL_COST: float = 0.7    # fuel used per fart ball shot
const BALL_COOLDOWN : float = 0.35   # seconds between shots

var fart_fuel    : float = FART_MAX
var is_farting   : bool  = false
var _shoot_timer : float = 0.0

# Small fart puff clouds
var _puff_x    : Array[float] = []
var _puff_y    : Array[float] = []
var _puff_life : Array[float] = []  # time remaining
var _puff_r    : Array[float] = []  # radius

# Fuel-bar HUD
var _bar_fill : ColorRect

# ── Death state ──────────────────────────────────────────────────────────────
var is_dead       : bool  = false
var walk_time     : float = 0.0
var visual_rot    : float = 0.0
var death_settled : bool  = false
var death_timer   : float = 0.0
var facing        : int   = 1

# ── Audio players ─────────────────────────────────────────────────────────────
var _sfx : Dictionary = {}

func _make_sfx(name: String, file: String, vol_db: float = 0.0) -> void:
	var stream : AudioStreamWAV = load("res://" + file)
	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream    = stream
	player.volume_db = vol_db
	add_child(player)
	_sfx[name] = player

func _play(name: String) -> void:
	if _sfx.has(name):
		(_sfx[name] as AudioStreamPlayer).play()

# ── Setup HUD ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_make_sfx("jump",  "sfx_jump.wav",  -2.0)
	_make_sfx("fart",  "sfx_fart.wav",  -4.0)
	_make_sfx("fire",  "sfx_fire.wav",  -3.0)
	_make_sfx("water", "sfx_water.wav", -3.0)
	_make_sfx("grass", "sfx_grass.wav", -3.0)
	var cl : CanvasLayer = CanvasLayer.new()
	add_child(cl)

	# Label
	var lbl : Label = Label.new()
	lbl.text = "💨 GAS"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.position = Vector2(16, 62)
	cl.add_child(lbl)

	# Bar background
	var bg : ColorRect = ColorRect.new()
	bg.color    = Color(0.15, 0.15, 0.15, 0.75)
	bg.size     = Vector2(160, 14)
	bg.position = Vector2(16, 82)
	cl.add_child(bg)

	# Bar fill
	_bar_fill = ColorRect.new()
	_bar_fill.color    = Color(0.25, 0.85, 0.20)
	_bar_fill.size     = Vector2(160, 14)
	_bar_fill.position = Vector2(16, 82)
	cl.add_child(_bar_fill)

# ── Main physics loop ─────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if is_dead:
		_dead_tick(delta)
		queue_redraw()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Normal jump (tap, on ground)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_V
		_play("jump")

	# Fart thrust (hold Space in the air)
	is_farting = false
	if Input.is_action_pressed("jump") and not is_on_floor() and fart_fuel > 0.0:
		velocity.y = maxf(velocity.y - FART_LIFT * delta, FART_VCAP)
		fart_fuel  = maxf(fart_fuel - delta, 0.0)
		is_farting = true
		# Spawn a puff cloud every few frames
		if Engine.get_process_frames() % 4 == 0:
			_puff_x.append(position.x + randf_range(-6.0, 6.0))
			_puff_y.append(position.y + 20.0)
			_puff_life.append(0.55)
			_puff_r.append(randf_range(8.0, 16.0))

	# Refuel slowly while standing on the ground
	if is_on_floor():
		fart_fuel = minf(fart_fuel + delta * 1.4, FART_MAX)

	# Update fuel bar colour (green → yellow → red)
	var t : float = fart_fuel / FART_MAX
	_bar_fill.size.x  = 160.0 * t
	_bar_fill.color   = Color(1.0 - t, t * 0.85, 0.05 + t * 0.15)

	# Shooting — all attacks share the cooldown timer
	_shoot_timer = maxf(_shoot_timer - delta, 0.0)
	if _shoot_timer <= 0.0:
		# Fart ball (S)
		if Input.is_action_just_pressed("shoot") and fart_fuel >= BALL_FUEL_COST:
			_shoot_fart_ball(); _play("fart")
			fart_fuel   -= BALL_FUEL_COST
			_shoot_timer = BALL_COOLDOWN
		# 🔥 Fire (F)
		elif Input.is_action_just_pressed("fire_attack") and fart_fuel >= BALL_FUEL_COST:
			_shoot_element("fire"); _play("fire")
			fart_fuel   -= BALL_FUEL_COST
			_shoot_timer = BALL_COOLDOWN
		# 💧 Water (W)
		elif Input.is_action_just_pressed("water_attack") and fart_fuel >= BALL_FUEL_COST:
			_shoot_element("water"); _play("water")
			fart_fuel   -= BALL_FUEL_COST
			_shoot_timer = BALL_COOLDOWN
		# 🌿 Grass (G)
		elif Input.is_action_just_pressed("grass_attack") and fart_fuel >= BALL_FUEL_COST:
			_shoot_element("grass"); _play("grass")
			fart_fuel   -= BALL_FUEL_COST
			_shoot_timer = BALL_COOLDOWN

	# Horizontal movement
	var dir : float = Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
		velocity.x = dir * SPEED
		if is_on_floor():
			walk_time += delta * 6.5
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	# Tick puff clouds
	for i in range(_puff_life.size() - 1, -1, -1):
		_puff_life[i] -= delta
		_puff_y[i]    -= 30.0 * delta   # drift upward
		if _puff_life[i] <= 0.0:
			_puff_x.remove_at(i)
			_puff_y.remove_at(i)
			_puff_life.remove_at(i)
			_puff_r.remove_at(i)

	queue_redraw()

# ── Death ────────────────────────────────────────────────────────────────────
func _dead_tick(delta: float) -> void:
	if not death_settled:
		velocity.y += GRAVITY * delta
		velocity.x  = move_toward(velocity.x, 0.0, 500.0 * delta)
		move_and_slide()
		visual_rot = minf(visual_rot + delta * 5.5, PI * 0.5)
		if is_on_floor() and visual_rot >= PI * 0.49:
			death_settled = true
			velocity      = Vector2.ZERO
	else:
		death_timer += delta
		if death_timer >= 2.0:
			get_tree().reload_current_scene()

func _shoot_element(element: String) -> void:
	var scene : PackedScene = load("res://ElementBall.tscn")
	var ball  : Node        = scene.instantiate()
	ball.element   = element
	ball.direction = facing
	ball.position  = position + Vector2(float(facing) * 22.0, -18.0)
	get_parent().add_child(ball)

func _shoot_fart_ball() -> void:
	var scene : PackedScene = load("res://FartBall.tscn")
	var ball  : Node        = scene.instantiate()
	ball.direction = facing
	# Spawn in front of the player at chest height
	ball.position  = position + Vector2(float(facing) * 22.0, -18.0)
	get_parent().add_child(ball)

func die() -> void:
	if not is_dead:
		is_dead    = true
		velocity.x *= 0.3

# ── Drawing helpers ───────────────────────────────────────────────────────────
func _rot_rect(pos: Vector2, angle: float, w: float, h: float) -> PackedVector2Array:
	var hw : float = w * 0.5
	var c  : float = cos(angle)
	var s  : float = sin(angle)
	var out : PackedVector2Array = PackedVector2Array()
	for p : Vector2 in [Vector2(-hw,0), Vector2(hw,0), Vector2(hw,h), Vector2(-hw,h)]:
		out.append(pos + Vector2(p.x*c - p.y*s, p.x*s + p.y*c))
	return out

# ── Draw ──────────────────────────────────────────────────────────────────────
func _draw() -> void:
	# Draw fart puff clouds in WORLD space (before character transform)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in _puff_x.size():
		var alpha : float = _puff_life[i] / 0.55
		var wp    : Vector2 = Vector2(_puff_x[i], _puff_y[i]) - position
		draw_circle(wp, _puff_r[i],         Color(0.55, 0.85, 0.10, alpha * 0.55))
		draw_circle(wp, _puff_r[i] * 0.55,  Color(0.80, 0.95, 0.20, alpha * 0.35))

	# Character transform (flip + death tilt)
	draw_set_transform(Vector2(0.0, 5.0), visual_rot * float(facing), Vector2(float(facing), 1.0))

	var skin   : Color = PlayerData.skin_color
	var hair   : Color = PlayerData.hair_color
	var shirt  : Color = PlayerData.shirt_color
	# Shirt glows slightly green while farting
	if is_farting:
		shirt = shirt.lerp(Color(0.3, 0.9, 0.1), 0.35)
	var pant   : Color = Color(0.15, 0.15, 0.45)
	var shoe_c : Color = Color(0.18, 0.09, 0.04)
	var eye_c  : Color = Color(0.06, 0.04, 0.04)

	var arm_sw : float = sin(walk_time) * 0.55
	var leg_sw : float = sin(walk_time) * 0.45

	# === BACK ARM ===
	draw_colored_polygon(_rot_rect(Vector2(-7.0, -16.0), -arm_sw, 7.0, 20.0), skin)

	# === BACK LEG + SHOE ===
	draw_colored_polygon(_rot_rect(Vector2(-4.0, -4.0), leg_sw, 8.0, 20.0), pant)
	draw_colored_polygon(_rot_rect(Vector2(-5.0, 14.0), leg_sw, 11.0, 8.0), shoe_c)

	# === BODY ===
	draw_rect(Rect2(-11.0, -24.0, 22.0, 30.0), shirt)

	# === FRONT LEG + SHOE ===
	draw_colored_polygon(_rot_rect(Vector2(4.0, -4.0), -leg_sw, 8.0, 20.0), pant)
	draw_colored_polygon(_rot_rect(Vector2(3.0, 14.0), -leg_sw, 11.0, 8.0), shoe_c)

	# === FRONT ARM ===
	draw_colored_polygon(_rot_rect(Vector2(7.0, -16.0), arm_sw, 7.0, 20.0), skin)

	# === HEAD ===
	draw_circle(Vector2(0.0, -38.0), 15.0, skin)

	for i in 9:
		var a  : float  = PI + i * (PI / 8.0)
		var p1 : Vector2 = Vector2(cos(a) * 13.0, sin(a) * 13.0 - 38.0)
		var p2 : Vector2 = Vector2(cos(a) * 19.0, sin(a) * 19.0 - 38.0)
		draw_line(p1, p2, hair, 3.5)

	draw_circle(Vector2(-12.0, -38.0), 6.0, skin)
	draw_circle(Vector2(7.0, -40.0), 4.5, eye_c)

	if not is_dead:
		draw_circle(Vector2(7.5, -41.5), 2.0, Color.WHITE)
	else:
		draw_line(Vector2(5.0, -43.0), Vector2(9.0, -38.0), Color.WHITE, 2.5)
		draw_line(Vector2(9.0, -43.0), Vector2(5.0, -38.0), Color.WHITE, 2.5)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
