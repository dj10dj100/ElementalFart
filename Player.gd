extends CharacterBody2D

const SPEED   := 260.0
const JUMP_V  := -580.0
const GRAVITY := 980.0

var is_dead       := false
var walk_time     := 0.0
var visual_rot    := 0.0   # rotates to PI/2 as player falls over when dead
var death_settled := false
var death_timer   := 0.0
var facing        := 1     # 1=right, -1=left

func _physics_process(delta: float) -> void:
	if is_dead:
		_dead_tick(delta)
		queue_redraw()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_V

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0:
		facing = 1 if dir > 0 else -1
		velocity.x = dir * SPEED
		if is_on_floor():
			walk_time += delta * 6.5
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	queue_redraw()

func _dead_tick(delta: float) -> void:
	if not death_settled:
		velocity.y += GRAVITY * delta
		velocity.x = move_toward(velocity.x, 0, 500.0 * delta)
		move_and_slide()
		visual_rot = min(visual_rot + delta * 5.5, PI * 0.5)
		if is_on_floor() and visual_rot >= PI * 0.49:
			death_settled = true
			velocity = Vector2.ZERO
	else:
		death_timer += delta
		if death_timer >= 2.0:
			get_tree().reload_current_scene()

func die() -> void:
	if not is_dead:
		is_dead = true
		velocity.x *= 0.3

# Returns 4 corners of a rect starting at pos going downward, rotated by angle
func _rot_rect(pos: Vector2, angle: float, w: float, h: float) -> PackedVector2Array:
	var hw := w * 0.5
	var pts := [Vector2(-hw, 0.0), Vector2(hw, 0.0), Vector2(hw, h), Vector2(-hw, h)]
	var c := cos(angle)
	var s := sin(angle)
	var out := PackedVector2Array()
	for p in pts:
		out.append(pos + Vector2(p.x * c - p.y * s, p.x * s + p.y * c))
	return out

func _draw() -> void:
	# One transform does everything:
	#   scale.x = facing  →  mirrors the whole character when moving left
	#   rotation          →  tilts them over when dead
	#   position          →  pivot sits at hip level (y=5)
	draw_set_transform(Vector2(0.0, 5.0), visual_rot * float(facing), Vector2(float(facing), 1.0))

	var skin   := Color(1.00, 0.82, 0.65)
	var hair   := Color(0.28, 0.14, 0.04)
	var shirt  := Color(0.22, 0.44, 0.90)
	var pant   := Color(0.15, 0.15, 0.45)
	var shoe_c := Color(0.18, 0.09, 0.04)
	var eye_c  := Color(0.06, 0.04, 0.04)

	# Everything below is drawn as if facing RIGHT.
	# The transform above flips it when facing left.
	var arm_sw := sin(walk_time) * 0.55
	var leg_sw := sin(walk_time) * 0.45

	# === BACK ARM ===
	draw_colored_polygon(_rot_rect(Vector2(-7.0, -16.0), -arm_sw, 7.0, 20.0), skin)

	# === BACK LEG + SHOE ===
	draw_colored_polygon(_rot_rect(Vector2(-4.0, -4.0), leg_sw, 8.0, 20.0), pant)
	draw_colored_polygon(_rot_rect(Vector2(-5.0, 14.0), leg_sw, 11.0, 8.0), shoe_c)

	# === BODY / TORSO ===
	draw_rect(Rect2(-11.0, -24.0, 22.0, 30.0), shirt)

	# === FRONT LEG + SHOE ===
	draw_colored_polygon(_rot_rect(Vector2(4.0, -4.0), -leg_sw, 8.0, 20.0), pant)
	draw_colored_polygon(_rot_rect(Vector2(3.0, 14.0), -leg_sw, 11.0, 8.0), shoe_c)

	# === FRONT ARM ===
	draw_colored_polygon(_rot_rect(Vector2(7.0, -16.0), arm_sw, 7.0, 20.0), skin)

	# === HEAD ===
	draw_circle(Vector2(0.0, -38.0), 15.0, skin)

	# Hair (top of head, always symmetric so the flip looks fine)
	for i in 9:
		var a := PI + i * (PI / 8.0)
		var p1 := Vector2(cos(a) * 13.0, sin(a) * 13.0 - 38.0)
		var p2 := Vector2(cos(a) * 19.0, sin(a) * 19.0 - 38.0)
		draw_line(p1, p2, hair, 3.5)

	# Ear (on the LEFT = back of head when facing right)
	draw_circle(Vector2(-12.0, -38.0), 6.0, skin)

	# Eye (on the RIGHT = front/facing side)
	draw_circle(Vector2(7.0, -40.0), 4.5, eye_c)
	if not is_dead:
		draw_circle(Vector2(7.5, -41.5), 2.0, Color.WHITE)
	else:
		# X eyes when dead
		draw_line(Vector2(5.0, -43.0), Vector2(9.0, -38.0), Color.WHITE, 2.5)
		draw_line(Vector2(9.0, -43.0), Vector2(5.0, -38.0), Color.WHITE, 2.5)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
