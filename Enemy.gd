extends CharacterBody2D

const GRAVITY := 980.0

var speed        := 80.0
var patrol_left  := 0.0
var patrol_right := 200.0
var direction    := 1
var walk_time    := 0.0

func _ready() -> void:
	# Kill the player when they touch us
	$HurtArea.body_entered.connect(func(body: Node) -> void:
		if body.has_method("die"):
			body.die()
	)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	velocity.x = float(direction) * speed
	move_and_slide()

	# Turn around at walls or patrol edges
	if is_on_wall() or position.x <= patrol_left or position.x >= patrol_right:
		direction *= -1

	if is_on_floor():
		walk_time += delta * 5.0

	queue_redraw()

func _draw() -> void:
	# Flip to face the direction of travel
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(direction), 1.0))

	var body_c := Color(0.15, 0.65, 0.20)
	var dark_c := Color(0.07, 0.42, 0.12)
	var hi_c   := Color(0.40, 0.88, 0.45)
	var horn_c := Color(0.75, 0.52, 0.10)
	var eye_w  := Color(0.95, 0.95, 0.95)
	var iris_c := Color(0.85, 0.10, 0.05)
	var pupil  := Color(0.06, 0.04, 0.04)

	var bob := sin(walk_time) * 2.0   # little up-down bounce

	# ── FEET ──────────────────────────────────────────────
	draw_circle(Vector2(-8.0, 4.0 + bob), 10.0, dark_c)
	draw_circle(Vector2(8.0,  5.0 + bob), 10.0, dark_c)

	# ── BODY ──────────────────────────────────────────────
	draw_circle(Vector2(0.0, -13.0 + bob), 18.0, body_c)
	draw_circle(Vector2(-5.0, -18.0 + bob), 7.0, hi_c)   # highlight

	# ── HORNS ─────────────────────────────────────────────
	draw_colored_polygon(
		PackedVector2Array([Vector2(-7.0, -28.0+bob), Vector2(-4.0, -40.0+bob), Vector2(-1.0, -28.0+bob)]),
		horn_c)
	draw_colored_polygon(
		PackedVector2Array([Vector2(3.0, -27.0+bob), Vector2(7.0, -38.0+bob), Vector2(11.0, -27.0+bob)]),
		horn_c)

	# ── EYE (angry! on the facing side) ───────────────────
	draw_circle(Vector2(8.0, -17.0 + bob), 6.5, eye_w)
	draw_circle(Vector2(9.0, -16.0 + bob), 4.5, iris_c)
	draw_circle(Vector2(10.0, -16.0 + bob), 2.5, pupil)
	draw_circle(Vector2(11.0, -17.5 + bob), 1.2, eye_w)  # shine

	# Angry eyebrow (slants inward = more scary!)
	draw_line(Vector2(3.0, -25.0+bob), Vector2(14.0, -22.0+bob), dark_c, 2.5)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
