extends Area2D

# "fire", "water", or "grass"
var element   : String = "fire"
var direction : int    = 1

var _age      : float = 0.0
var _traveled : float = 0.0
var _start_y  : float = 0.0   # for water wave

# Per-element tuning
const SPEEDS : Dictionary = {"fire": 600.0, "water": 380.0, "grass": 320.0}
const RANGES : Dictionary = {"fire": 520.0, "water": 780.0, "grass": 620.0}

func _ready() -> void:
	body_entered.connect(_on_hit)
	_start_y = position.y

func _process(delta: float) -> void:
	_age      += delta
	var spd   : float = SPEEDS.get(element, 500.0)
	var step  : float = spd * delta
	_traveled += step
	position.x += step * float(direction)

	# Water weaves up and down gently
	if element == "water":
		position.y = _start_y + sin(_traveled * 0.018) * 55.0

	if _traveled >= float(RANGES.get(element, 600.0)):
		queue_free()
		return

	queue_redraw()

func _on_hit(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("die"):
		body.die()
		_on_impact()
		queue_free()

func _on_impact() -> void:
	pass  # could add explosion particles here later!

func _draw() -> void:
	match element:
		"fire":  _draw_fire()
		"water": _draw_water()
		"grass": _draw_grass()

# ── FIRE ─────────────────────────────────────────────────────────────────────
func _draw_fire() -> void:
	var flicker : float = sin(_age * 22.0) * 3.0

	# Flame trail behind the ball
	var td : float = float(-direction)
	for i in 5:
		var tx : float  = td * (14.0 + i * 12.0)
		var ty : float  = sin(_age * 15.0 + i) * 4.0
		var tr : float  = 10.0 - i * 1.5
		var ta : float  = 0.55 - i * 0.09
		draw_circle(Vector2(tx, ty), tr, Color(0.90, 0.30, 0.00, ta))

	# Outer glow
	draw_circle(Vector2(0, flicker), 17.0, Color(0.80, 0.12, 0.00, 0.70))
	# Mid fire
	draw_circle(Vector2(0, flicker), 13.0, Color(1.00, 0.42, 0.00, 0.90))
	# Bright core
	draw_circle(Vector2(0, flicker),  8.0, Color(1.00, 0.85, 0.10, 1.00))
	# White-hot centre
	draw_circle(Vector2(0, flicker),  3.5, Color(1.00, 1.00, 0.90, 1.00))

	# Sparks spinning outward
	for i in 6:
		var a  : float   = _age * 8.0 + i * (PI / 3.0)
		var sp : Vector2 = Vector2(cos(a) * 18.0, sin(a) * 10.0 + flicker)
		draw_circle(sp, 2.0, Color(1.00, 0.70, 0.10, 0.85))

# ── WATER ────────────────────────────────────────────────────────────────────
func _draw_water() -> void:
	var wave : float = sin(_age * 12.0) * 2.5

	# Water tail droplets
	var td : float = float(-direction)
	for i in 4:
		var tx : float = td * (12.0 + i * 11.0)
		var ty : float = sin(_age * 10.0 + i * 1.2) * 5.0
		draw_circle(Vector2(tx, ty), 7.0 - i, Color(0.20, 0.65, 1.00, 0.45 - i * 0.08))

	# Outer splash ring
	draw_circle(Vector2(0, wave), 16.0, Color(0.05, 0.30, 0.80, 0.65))
	# Main body
	draw_circle(Vector2(0, wave), 12.0, Color(0.15, 0.60, 0.95, 0.90))
	# Bright core
	draw_circle(Vector2(0, wave),  7.0, Color(0.60, 0.90, 1.00, 1.00))
	# Shine
	draw_circle(Vector2(-3.0, wave - 3.0), 2.5, Color(1.00, 1.00, 1.00, 0.90))

	# Orbiting bubbles
	for i in 3:
		var a  : float   = _age * 4.0 + i * (TAU / 3.0)
		var sp : Vector2 = Vector2(cos(a) * 18.0, sin(a) * 11.0 + wave)
		draw_circle(sp, 3.0, Color(0.70, 0.92, 1.00, 0.75))
		draw_circle(sp, 1.2, Color(1.00, 1.00, 1.00, 0.80))

# ── GRASS / LEAF ──────────────────────────────────────────────────────────────
func _draw_grass() -> void:
	var spin : float = _age * 6.0

	# Leaf trail
	var td : float = float(-direction)
	for i in 3:
		var tx : float  = td * (10.0 + i * 13.0)
		var ta : float  = 0.40 - i * 0.10
		_draw_leaf(Vector2(tx, sin(spin + i) * 5.0), spin + i * 1.2,
				   Color(0.20, 0.70, 0.10, ta), 7.0)

	# Outer glow
	draw_circle(Vector2.ZERO, 16.0, Color(0.10, 0.50, 0.05, 0.65))
	# Core
	draw_circle(Vector2.ZERO, 11.0, Color(0.25, 0.78, 0.10, 0.90))
	# Bright centre
	draw_circle(Vector2.ZERO,  6.0, Color(0.70, 1.00, 0.25, 1.00))
	draw_circle(Vector2.ZERO,  2.5, Color(1.00, 1.00, 0.60, 1.00))

	# Spinning leaves orbiting
	for i in 5:
		var a   : float   = spin + i * (TAU / 5.0)
		var lp  : Vector2 = Vector2(cos(a) * 19.0, sin(a) * 11.0)
		var col : Color   = Color(0.15, 0.65, 0.10, 0.85)
		_draw_leaf(lp, a + PI * 0.5, col, 8.0)

# Draws a simple leaf shape (elongated oval)
func _draw_leaf(pos: Vector2, angle: float, col: Color, size: float) -> void:
	var pts : PackedVector2Array = PackedVector2Array()
	var c   : float = cos(angle)
	var s   : float = sin(angle)
	for i in 8:
		var t   : float   = float(i) / 7.0
		var lx  : float   = (t - 0.5) * size * 2.2
		var ly  : float   = sin(t * PI) * size * 0.7 * (1.0 if i < 4 else -1.0)
		pts.append(pos + Vector2(lx * c - ly * s, lx * s + ly * c))
	if pts.size() >= 3:
		draw_colored_polygon(pts, col)
