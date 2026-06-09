extends Node2D

# Hand-designed prototype map.
# Vertical S-curve path from top of screen to bottom.
# Build spots placed near path corners.
# Player's base (keep) at the bottom, enemy spawn at the top.

const VIEWPORT_WIDTH := 1024
const VIEWPORT_HEIGHT := 1792

# Path waypoints, top to bottom, in pixels.
# Vertical S-curve: top-right, mid-left, mid-right, bottom-left.
const PATH_POINTS: Array[Vector2] = [
	Vector2(700, 100),    # spawn (top-right area)
	Vector2(700, 350),
	Vector2(280, 500),    # first big S-bend to the left
	Vector2(280, 750),
	Vector2(720, 950),    # second S-bend to the right
	Vector2(720, 1200),
	Vector2(320, 1450),   # final bend back to center-left
	Vector2(320, 1700),   # base (bottom area)
]

# Build spots — placed near path corners where a tower can hit enemies as they pass.
const BUILD_SPOTS: Array[Vector2] = [
	Vector2(450, 350),    # between top-right start and first bend
	Vector2(530, 550),    # right of the first bend
	Vector2(280, 850),    # below first bend
	Vector2(530, 1000),   # near second bend
	Vector2(720, 1300),   # below second bend
	Vector2(450, 1500),   # between second bend and base
]

const BASE_POSITION := Vector2(320, 1700)
const SPAWN_POSITION := Vector2(700, 100)

const BACKGROUND_PATH := "res://assets/environment/background_misty_forest.jpg"
const PATH_STONE_TILE_PATH := "res://assets/environment/path_stone_tile.jpg"
const BASE_KEEP_PATH := "res://assets/environment/base_keep.png"
const BUILDSPOT_TILE_PATH := "res://assets/environment/buildspot_tile.png"

@onready var path_layer: Node2D = $PathLayer
@onready var build_spots_layer: Node2D = $BuildSpotsLayer
@onready var base_layer: Node2D = $BaseLayer
@onready var background_layer: Node2D = $Background

var path_follow: Path2D
var build_spot_nodes: Array[Node2D] = []

func _ready() -> void:
	_draw_background()
	_draw_path()
	_spawn_build_spots()
	_draw_base()
	print("[TD] Map ready: %d path points, %d build spots" % [PATH_POINTS.size(), BUILD_SPOTS.size()])

func _draw_background() -> void:
	var bg_tex := load(BACKGROUND_PATH) as Texture2D
	if bg_tex == null:
		# Fallback to a dark green ColorRect.
		var cr := ColorRect.new()
		cr.color = Color(0.18, 0.22, 0.16, 1)
		cr.offset_right = VIEWPORT_WIDTH
		cr.offset_bottom = VIEWPORT_HEIGHT
		cr.position = Vector2.ZERO
		background_layer.add_child(cr)
		return

	var sprite := Sprite2D.new()
	sprite.name = "BackgroundArt"
	sprite.texture = bg_tex
	# Center the sprite in the viewport, scale to cover.
	sprite.position = Vector2(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0)
	var tex_w := float(bg_tex.get_width())
	var tex_h := float(bg_tex.get_height())
	var scale_x := VIEWPORT_WIDTH / tex_w
	var scale_y := VIEWPORT_HEIGHT / tex_h
	# Use the larger scale so the image covers the whole viewport (cropping the
	# longer axis). Keeps the painterly framing without stretching.
	var s: float = max(scale_x, scale_y)
	sprite.scale = Vector2(s, s)
	sprite.modulate = Color(1, 1, 1, 1)
	background_layer.add_child(sprite)

func _draw_path() -> void:
	# Build a Path2D from the waypoints so enemies can follow it.
	var path := Path2D.new()
	var curve := Curve2D.new()
	for i in PATH_POINTS.size():
		var in_handle := Vector2.ZERO
		var out_handle := Vector2.ZERO
		if i > 0:
			in_handle = (PATH_POINTS[i] - PATH_POINTS[i - 1]) * 0.3
		if i < PATH_POINTS.size() - 1:
			out_handle = (PATH_POINTS[i + 1] - PATH_POINTS[i]) * 0.3
		curve.add_point(PATH_POINTS[i], in_handle, out_handle)
	path.curve = curve
	path_layer.add_child(path)
	path_follow = path

	# Path visual: thick stone-coloured Line2D with a darker shadow line on top.
	# Width is wide enough to read as a road (~110px) with painterly shadow.
	var body := Line2D.new()
	body.width = 110.0
	body.default_color = Color(0.62, 0.58, 0.50, 1.0)  # warm stone grey-tan
	body.points = PATH_POINTS
	body.joint_mode = Line2D.LINE_JOINT_ROUND
	body.begin_cap_mode = Line2D.LINE_CAP_ROUND
	body.end_cap_mode = Line2D.LINE_CAP_ROUND
	body.z_index = 1
	path_layer.add_child(body)

	# A slightly darker, narrower inner line for visual depth (shadow at the
	# centre of the path).
	var shadow := Line2D.new()
	shadow.width = 80.0
	shadow.default_color = Color(0.45, 0.40, 0.32, 0.45)
	shadow.points = PATH_POINTS
	shadow.joint_mode = Line2D.LINE_JOINT_ROUND
	shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.z_index = 2
	path_layer.add_child(shadow)

	# A bright top-edge highlight that runs along the path, giving the path
	# the painterly "edges of the stones" look.
	var highlight := Line2D.new()
	highlight.width = 14.0
	highlight.default_color = Color(0.85, 0.78, 0.62, 0.55)  # sandy highlight
	highlight.points = PATH_POINTS
	highlight.joint_mode = Line2D.LINE_JOINT_ROUND
	highlight.begin_cap_mode = Line2D.LINE_CAP_ROUND
	highlight.end_cap_mode = Line2D.LINE_CAP_ROUND
	highlight.z_index = 3
	path_layer.add_child(highlight)

	# Spawn marker at the top.
	_draw_marker(SPAWN_POSITION, Color(0.9, 0.2, 0.2, 0.6), 32)

func _build_path_polygon(points: Array[Vector2], half_width: float) -> PackedVector2Array:
	# For each waypoint, compute the perpendicular offset from the local tangent
	# direction. Then build a closed polygon: forward along left side, then
	# backward along right side. (Kept around in case the textured path comes
	# back later; the active path visual is now Line2D-based.)
	var left: Array[Vector2] = []
	var right: Array[Vector2] = []
	for i in points.size():
		var p := points[i]
		var dir := Vector2.ZERO
		if i > 0:
			dir += (p - points[i - 1]).normalized()
		if i < points.size() - 1:
			dir += (points[i + 1] - p).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2(0, 1)
		dir = dir.normalized()
		var perp := Vector2(-dir.y, dir.x)
		left.append(p + perp * half_width)
		right.append(p - perp * half_width)
	var result: PackedVector2Array = PackedVector2Array()
	for p in left:
		result.append(p)
	for i in range(right.size() - 1, -1, -1):
		result.append(right[i])
	return result

func _build_path_uvs(_points: Array[Vector2], _polygon: PackedVector2Array, _tex: Texture2D) -> PackedVector2Array:
	# Legacy helper kept for compatibility; the textured path is no longer the
	# primary visual. Returns a degenerate UV array.
	return PackedVector2Array()

func _spawn_build_spots() -> void:
	var tile_tex := load(BUILDSPOT_TILE_PATH) as Texture2D
	for pos in BUILD_SPOTS:
		var spot := Node2D.new()
		spot.position = pos
		spot.set_meta("is_build_spot", true)
		spot.set_meta("is_occupied", false)

		if tile_tex:
			var sprite := Sprite2D.new()
			sprite.texture = tile_tex
			# 256x256 source. Render at 0.35 → 90px in world. Visible but
			# not so big it covers the path.
			sprite.scale = Vector2(0.35, 0.35)
			sprite.modulate = Color(1, 1, 1, 0.95)
			spot.add_child(sprite)
		else:
			# Fallback.
			var circle := _make_circle(48, Color(0.6, 0.55, 0.4, 0.4))
			spot.add_child(circle)
			var ring := _make_ring(48, 2.0, Color(0.9, 0.85, 0.7, 0.5))
			spot.add_child(ring)

		build_spots_layer.add_child(spot)
		build_spot_nodes.append(spot)

func _draw_base() -> void:
	var keep_tex := load(BASE_KEEP_PATH) as Texture2D
	if keep_tex:
		var sprite := Sprite2D.new()
		sprite.texture = keep_tex
		# 1024x1024 source. Render at 0.30 → 307px. About 2.5x larger than the
		# original 120px platform, so the keep walls are clearly visible.
		sprite.scale = Vector2(0.30, 0.30)
		# Offset the keep so the cyan portal sits at the original BASE_POSITION.
		# The keep's portal is roughly at the center of the source 1024 image,
		# so positioning the sprite center at BASE_POSITION puts the portal there.
		sprite.position = BASE_POSITION
		# Slight upward nudge to compensate for the fact that the rendered
		# sprite extends above and below the center equally.
		sprite.z_index = 2
		base_layer.add_child(sprite)
	else:
		# Fallback.
		var base_pos := BASE_POSITION
		var platform := _make_circle(60, Color(0.45, 0.42, 0.38, 1.0))
		platform.position = base_pos
		base_layer.add_child(platform)
		var inner := _make_circle(45, Color(0.6, 0.55, 0.45, 1.0))
		inner.position = base_pos
		base_layer.add_child(inner)
		var portal := _make_circle(28, Color(0.3, 0.85, 1.0, 0.9))
		portal.position = base_pos
		base_layer.add_child(portal)
		var glow := _make_ring(50, 4.0, Color(0.5, 1.0, 1.0, 0.5))
		glow.position = base_pos
		base_layer.add_child(glow)

func _draw_marker(pos: Vector2, color: Color, radius: float) -> void:
	var ring := _make_ring(radius, 3.0, color)
	ring.position = pos
	path_layer.add_child(ring)

func _make_circle(radius: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var points: Array[Vector2] = []
	var segments := 32
	for i in segments:
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	poly.color = color
	return poly

func _make_ring(radius: float, thickness: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.width = thickness
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var segments := 48
	var points: Array[Vector2] = []
	for i in segments:
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	points.append(points[0])
	line.points = points
	return line

func get_spawn_position() -> Vector2:
	return SPAWN_POSITION

func get_base_position() -> Vector2:
	return BASE_POSITION
