extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("die"):
		body.die()

func _draw() -> void:
	# Draw a shiny metal triangle spike
	var tip    := Vector2(0, -22)
	var left   := Vector2(-13, 8)
	var right  := Vector2(13, 8)

	# Main spike body
	draw_colored_polygon(PackedVector2Array([tip, right, left]), Color(0.68, 0.68, 0.74))
	# Shine on left edge
	draw_line(left, tip, Color(0.90, 0.92, 1.00, 0.8), 2.0)
	# Dark shadow on right edge
	draw_line(tip, right, Color(0.35, 0.35, 0.40, 0.9), 2.0)
