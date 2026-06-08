extends Area2D

const SPEED    : float = 520.0
const MAX_DIST : float = 650.0

var direction  : int   = 1   # 1=right, -1=left
var _traveled  : float = 0.0
var _age       : float = 0.0  # for wobble animation

func _ready() -> void:
	body_entered.connect(_on_hit)

func _process(delta: float) -> void:
	var move : float = SPEED * float(direction) * delta
	position.x += move
	_traveled  += absf(move)
	_age       += delta

	# Die if we've gone too far
	if _traveled >= MAX_DIST:
		queue_free()
		return

	queue_redraw()

func _on_hit(body: Node) -> void:
	# Only kill things in the "enemies" group
	if body.is_in_group("enemies") and body.has_method("die"):
		body.die()
		queue_free()

func _draw() -> void:
	var wobble : float = sin(_age * 18.0) * 2.5   # jiggly effect

	# Trail (behind the ball)
	var td : float = float(-direction)
	draw_circle(Vector2(td * 18.0, wobble * 0.5), 9.0,  Color(0.25, 0.80, 0.10, 0.40))
	draw_circle(Vector2(td * 30.0, 0.0),           6.0,  Color(0.25, 0.80, 0.10, 0.20))

	# Main ball — glowing green layers
	draw_circle(Vector2(0.0, wobble), 15.0, Color(0.20, 0.75, 0.05, 0.85))
	draw_circle(Vector2(0.0, wobble),  11.0, Color(0.45, 0.95, 0.10, 0.90))
	draw_circle(Vector2(0.0, wobble),   6.0, Color(0.85, 1.00, 0.40, 1.00))
	# Bright core
	draw_circle(Vector2(0.0, wobble),   2.5, Color(1.00, 1.00, 0.80, 1.00))

	# Little sparkles orbiting
	for i in 4:
		var a  : float   = _age * 5.0 + i * (PI * 0.5)
		var sp : Vector2 = Vector2(cos(a) * 17.0, sin(a) * 10.0 + wobble)
		draw_circle(sp, 2.5, Color(0.70, 1.00, 0.30, 0.80))
