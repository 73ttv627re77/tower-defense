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

@onready var path_layer: Node2D = $PathLayer
@onready var build_spots_layer: Node2D = $BuildSpotsLayer
@onready var base_layer: Node2D = $BaseLayer

var path_follow: Path2D  # Exposed for enemies to follow
var build_spot_nodes: Array[Node2D] = []

func _ready() -> void:
	_draw_path()
	_spawn_build_spots()
	_draw_base()
	print("[TD] Map ready: %d path points, %d build spots" % [PATH_POINTS.size(), BUILD_SPOTS.size()])

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

	# Visual: thick line representing the path.
	var line := Line2D.new()
	line.width = 48.0
	line.default_color = Color(0.55, 0.52, 0.45, 1.0)  # warm stone flagstone
	line.points = PATH_POINTS
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	path_layer.add_child(line)

	# Path edge highlight (lighter inner line for contrast).
	var edge := Line2D.new()
	edge.width = 36.0
	edge.default_color = Color(0.72, 0.68, 0.58, 1.0)  # lighter inner stone
	edge.points = PATH_POINTS
	edge.joint_mode = Line2D.LINE_JOINT_ROUND
	path_layer.add_child(edge)

	# Spawn marker at the top.
	_draw_marker(SPAWN_POSITION, Color(0.9, 0.2, 0.2, 0.6), 32)

func _spawn_build_spots() -> void:
	for pos in BUILD_SPOTS:
		var spot := Node2D.new()
		spot.position = pos
		spot.set_meta("is_build_spot", true)
		spot.set_meta("is_occupied", false)

		# Visual: a circle showing where the tower can go.
		var circle := _make_circle(48, Color(0.6, 0.55, 0.4, 0.4))
		spot.add_child(circle)

		# Subtle inner ring for emphasis.
		var ring := _make_ring(48, 2.0, Color(0.9, 0.85, 0.7, 0.5))
		spot.add_child(ring)

		build_spots_layer.add_child(spot)
		build_spot_nodes.append(spot)

func _draw_base() -> void:
	# Player's keep at the bottom — stone keep with cyan portal glow.
	var base_pos := BASE_POSITION
	# Base platform.
	var platform := _make_circle(60, Color(0.45, 0.42, 0.38, 1.0))
	platform.position = base_pos
	base_layer.add_child(platform)
	# Inner platform.
	var inner := _make_circle(45, Color(0.6, 0.55, 0.45, 1.0))
	inner.position = base_pos
	base_layer.add_child(inner)
	# Cyan portal core.
	var portal := _make_circle(28, Color(0.3, 0.85, 1.0, 0.9))
	portal.position = base_pos
	base_layer.add_child(portal)
	# Portal glow ring.
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
	# Close the loop by appending the first point (Line2D in Godot 4 has no .loop).
	points.append(points[0])
	line.points = points
	return line

func get_spawn_position() -> Vector2:
	return SPAWN_POSITION

func get_base_position() -> Vector2:
	return BASE_POSITION
