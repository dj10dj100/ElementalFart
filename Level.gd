extends Node2D

# ── constants ────────────────────────────────────────────────────────────────────
const GROUND_Y   : float = 580.0
const MIN_PLAT_Y : float = 170.0
const MAX_PLAT_Y : float = 500.0

# Persists between scene reloads — no autoload needed
static var current_level : int = 1

# ── instance state ───────────────────────────────────────────────────────────────
var level            : int   = 1
var rng              : RandomNumberGenerator = RandomNumberGenerator.new()
var _lw              : float = 2000.0
var _waiting_restart : bool  = false
var _go_to_next      : bool  = true

# Platform data stored in typed arrays (avoids all Variant issues)
var _plat_x : Array[float] = []
var _plat_y : Array[float] = []
var _plat_w : Array[float] = []

# ── entry point ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	level = current_level
	rng.seed = level * 73856093
	_lw = 2000.0 + float(level) * 25.0

	_make_sky()
	_make_ground()
	_make_platforms()
	_make_spikes()
	if level >= 21:
		_make_enemies()
	_make_death_zone()
	_make_finish_line()
	_spawn_player()
	_make_hud()

# ── SKY ──────────────────────────────────────────────────────────────────────────
func _make_sky() -> void:
	var t   : float = float(level - 1) / 99.0
	var sky : Color = Color(0.50 - t * 0.30, 0.78 - t * 0.45, 0.97 - t * 0.30)
	var bg  : ColorRect = ColorRect.new()
	bg.color = sky
	bg.size  = Vector2(_lw, GROUND_Y)
	add_child(bg)

# ── GROUND ───────────────────────────────────────────────────────────────────────
func _make_ground() -> void:
	_add_platform(_lw * 0.5, GROUND_Y + 20.0, _lw, 50.0, Color(0.38, 0.22, 0.09))

# ── PLATFORMS ────────────────────────────────────────────────────────────────────
func _make_platforms() -> void:
	_plat_x.clear()
	_plat_y.clear()
	_plat_w.clear()

	var x       : float = 150.0
	var y       : float = GROUND_Y - 90.0
	var max_gap : float = minf(180.0 + float(level) * 0.8, 300.0)

	while x < _lw - 320.0:
		y = clampf(y + rng.randf_range(-130.0, 130.0), MIN_PLAT_Y, MAX_PLAT_Y)
		var w   : float = rng.randf_range(130.0, 210.0)
		var t   : float = float(level - 1) / 99.0
		var col : Color = Color(0.22 + t * 0.30, 0.60 - t * 0.30, 0.25 - t * 0.10)
		_add_platform(x + w * 0.5, y, w, 22.0, col)
		_plat_x.append(x)
		_plat_y.append(y)
		_plat_w.append(w)
		x += w + rng.randf_range(150.0, max_gap)

# ── SPIKES ───────────────────────────────────────────────────────────────────────
func _make_spikes() -> void:
	var spike_scene : PackedScene = load("res://Spike.tscn")

	# Ground spikes
	var ground_count : int = mini(3 + int(float(level) * 0.7), 65)
	for _i in ground_count:
		var sx    : float = rng.randf_range(180.0, _lw - 200.0)
		var spike : Node  = spike_scene.instantiate()
		spike.position = Vector2(sx, GROUND_Y - 9.0)
		add_child(spike)

	# Platform spikes (from level 40+)
	if level >= 40:
		var prob : float = float(level - 40) / 60.0 * 0.55
		for i in _plat_x.size():
			var pw : float = _plat_w[i]
			if rng.randf() < prob and pw > 80.0:
				var sx    : float = _plat_x[i] + rng.randf_range(12.0, pw - 12.0)
				var spike : Node  = spike_scene.instantiate()
				spike.position = Vector2(sx, _plat_y[i] - 9.0)
				add_child(spike)

# ── ENEMIES (appear at level 21) ─────────────────────────────────────────────────
func _make_enemies() -> void:
	var enemy_scene : PackedScene = load("res://Enemy.tscn")
	var spd  : float = 60.0 + float(level - 21) * 2.3
	var prob : float = float(level - 20) / 80.0

	for i in _plat_x.size():
		var px : float = _plat_x[i]
		var py : float = _plat_y[i]
		var pw : float = _plat_w[i]
		if rng.randf() < prob and pw > 80.0:
			var enemy : Node = enemy_scene.instantiate()
			enemy.speed        = spd
			enemy.patrol_left  = px + 15.0
			enemy.patrol_right = px + pw - 15.0
			enemy.position     = Vector2(px + pw * 0.5, py - 26.0)
			add_child(enemy)

# ── DEATH ZONE ───────────────────────────────────────────────────────────────────
func _make_death_zone() -> void:
	var area  : Area2D = Area2D.new()
	area.body_entered.connect(func(body: Node) -> void:
		if body.has_method("die"): body.die()
	)
	var col   : CollisionShape2D  = CollisionShape2D.new()
	var shape : RectangleShape2D  = RectangleShape2D.new()
	shape.size = Vector2(_lw * 2.0, 60.0)
	col.shape  = shape
	area.add_child(col)
	area.position = Vector2(_lw * 0.5, GROUND_Y + 120.0)
	add_child(area)

# ── FINISH LINE ──────────────────────────────────────────────────────────────────
func _make_finish_line() -> void:
	var fx : float = _lw - 110.0

	var pole : ColorRect = ColorRect.new()
	pole.color    = Color(0.45, 0.28, 0.10)
	pole.size     = Vector2(8.0, 120.0)
	pole.position = Vector2(fx - 4.0, GROUND_Y - 120.0)
	add_child(pole)

	var flag : ColorRect = ColorRect.new()
	flag.color    = Color(1.0, 0.85, 0.1)
	flag.size     = Vector2(50.0, 30.0)
	flag.position = Vector2(fx + 4.0, GROUND_Y - 120.0)
	add_child(flag)

	var flbl : Label = Label.new()
	flbl.text = "FINISH"
	flbl.add_theme_font_size_override("font_size", 11)
	flbl.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0))
	flbl.position = Vector2(fx + 7.0, GROUND_Y - 113.0)
	add_child(flbl)

	var area  : Area2D            = Area2D.new()
	area.body_entered.connect(_on_finish_reached)
	var col   : CollisionShape2D  = CollisionShape2D.new()
	var shape : RectangleShape2D  = RectangleShape2D.new()
	shape.size = Vector2(60.0, 160.0)
	col.shape  = shape
	area.add_child(col)
	area.position = Vector2(fx + 30.0, GROUND_Y - 80.0)
	add_child(area)

func _on_finish_reached(body: Node) -> void:
	if not body.has_method("die") or body.is_dead:
		return
	body.set_physics_process(false)

	var overlay : ColorRect = ColorRect.new()
	overlay.color    = Color(0.0, 0.0, 0.0, 0.55)
	overlay.size     = Vector2(1152.0, 648.0)
	overlay.z_index  = 10
	overlay.position = body.position + Vector2(-576.0, -324.0)
	add_child(overlay)

	if level >= 100:
		_go_to_next = false
		var title : Label = Label.new()
		title.text = "YOU BEAT ALL 100 LEVELS!"
		title.add_theme_font_size_override("font_size", 52)
		title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
		title.z_index  = 11
		title.position = body.position + Vector2(-280.0, -100.0)
		add_child(title)
		var sub : Label = Label.new()
		sub.text = "You are an ABSOLUTE LEGEND!"
		sub.add_theme_font_size_override("font_size", 30)
		sub.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
		sub.z_index  = 11
		sub.position = body.position + Vector2(-185.0, -35.0)
		add_child(sub)
		var hint : Label = Label.new()
		hint.text = "Press SPACE to play again from Level 1"
		hint.add_theme_font_size_override("font_size", 22)
		hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		hint.z_index  = 11
		hint.position = body.position + Vector2(-195.0, 20.0)
		add_child(hint)
	else:
		var title : Label = Label.new()
		title.text = "Level " + str(level) + " Clear!"
		title.add_theme_font_size_override("font_size", 56)
		title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
		title.z_index  = 11
		title.position = body.position + Vector2(-210.0, -90.0)
		add_child(title)
		var hint : Label = Label.new()
		hint.text = "Press SPACE  →  Level " + str(level + 1)
		hint.add_theme_font_size_override("font_size", 28)
		hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		hint.z_index  = 11
		hint.position = body.position + Vector2(-170.0, -10.0)
		add_child(hint)

	_waiting_restart = true
	set_process(true)

func _process(_delta: float) -> void:
	if _waiting_restart and Input.is_action_just_pressed("jump"):
		current_level = (level + 1) if _go_to_next else 1
		get_tree().reload_current_scene()

# ── PLAYER ───────────────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	var ps     : PackedScene = load("res://Player.tscn")
	var player : Node        = ps.instantiate()
	player.position = Vector2(80.0, GROUND_Y - 60.0)
	add_child(player)

# ── HUD ──────────────────────────────────────────────────────────────────────────
func _make_hud() -> void:
	var canvas : CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var lbl : Label = Label.new()
	lbl.text = "Level  " + str(level) + " / 100"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.position = Vector2(16.0, 12.0)
	canvas.add_child(lbl)

	var tag : Label = Label.new()
	tag.text = _difficulty_label()
	tag.add_theme_font_size_override("font_size", 16)
	tag.add_theme_color_override("font_color", _difficulty_color())
	tag.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	tag.add_theme_constant_override("shadow_offset_x", 1)
	tag.add_theme_constant_override("shadow_offset_y", 1)
	tag.position = Vector2(16.0, 42.0)
	canvas.add_child(tag)

func _difficulty_label() -> String:
	if level <= 10: return "Easy"
	if level <= 20: return "Getting harder..."
	if level <= 40: return "Enemies appeared!"
	if level <= 60: return "Getting spooky..."
	if level <= 80: return "Very Hard!"
	if level <= 90: return "EXTREME!"
	return "PURE CHAOS!"

func _difficulty_color() -> Color:
	if level <= 10: return Color(0.4, 1.0, 0.4)
	if level <= 20: return Color(1.0, 1.0, 0.3)
	if level <= 40: return Color(1.0, 0.7, 0.1)
	if level <= 60: return Color(1.0, 0.4, 0.1)
	if level <= 80: return Color(1.0, 0.15, 0.1)
	return Color(1.0, 0.0, 0.8)

# ── PLATFORM HELPER ───────────────────────────────────────────────────────────────
func _add_platform(cx: float, cy: float, w: float, h: float, color: Color) -> void:
	var body : StaticBody2D = StaticBody2D.new()
	body.position = Vector2(cx, cy)
	var col   : CollisionShape2D = CollisionShape2D.new()
	var shape : RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(w, h)
	col.shape  = shape
	body.add_child(col)
	var vis : ColorRect = ColorRect.new()
	vis.color    = color
	vis.size     = Vector2(w, h)
	vis.position = Vector2(-w * 0.5, -h * 0.5)
	body.add_child(vis)
	add_child(body)
