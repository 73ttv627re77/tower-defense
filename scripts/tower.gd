extends Node2D
class_name Tower

# Base tower class. Subclasses override stats and projectile type.
# Each tower:
#   - Sits on a build spot
#   - Has a range, damage, attack speed
#   - Targets the first enemy in range (closest to base)
#   - Spawns a projectile that travels to the target
#   - On hit, deals damage

# Subclass-overridable stats
@export var tower_name: String = "Tower"
@export var build_cost: int = 50
@export var damage: int = 8
@export var range_px: float = 120.0
@export var cooldown_s: float = 1.2
@export var projectile_speed: float = 600.0
@export var projectile_color: Color = Color(0.9, 0.85, 0.5, 1.0)
@export var sprite_path: String = "res://assets/towers/archer.jpg"
@export var projectile_scene: PackedScene = null  # subclasses can set their own

var sprite: Sprite2D
var range_indicator: Line2D
var cooldown_timer: float = 0.0
var current_target: Node2D = null
var enemies_layer: Node2D = null

func _ready() -> void:
	add_to_group("towers")
	# Sprite
	sprite = Sprite2D.new()
	var tex := load(sprite_path) as Texture2D
	if tex:
		sprite.texture = tex
	sprite.scale = Vector2(0.4, 0.4)  # 1024px sprite -> ~410px in game
	sprite.position = Vector2(0, 0)
	add_child(sprite)
	# Range indicator (hidden by default, shown on hover/tap)
	range_indicator = _make_range_circle(range_px, Color(0.6, 0.7, 0.9, 0.18))
	range_indicator.visible = false
	add_child(range_indicator)

func _process(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta
	_acquire_target()
	if current_target and is_instance_valid(current_target):
		_face_target(current_target.global_position)
		if cooldown_timer <= 0:
			_fire()
			cooldown_timer = cooldown_s
	else:
		current_target = null

func _acquire_target() -> void:
	if current_target and is_instance_valid(current_target):
		var dist := global_position.distance_to(current_target.global_position)
		if dist <= range_px:
			return
	current_target = null
	if not enemies_layer:
		return
	var best: Node2D = null
	var best_progress: float = -1.0  # we want the enemy furthest along the path
	for enemy in enemies_layer.get_children():
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if "is_alive" in enemy and not enemy.is_alive:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist > range_px:
			continue
		var progress: float = enemy.get("path_progress") if "path_progress" in enemy else 0.0
		if progress > best_progress:
			best_progress = progress
			best = enemy
	current_target = best

func _face_target(target_pos: Vector2) -> void:
	# Subclasses with directional sprites (archer bow, ballista) can override.
	pass

func _fire() -> void:
	if not current_target:
		return
	# Default: spawn a Projectile that travels to the target.
	var p := Projectile.new()
	p.global_position = global_position
	p.set("target", current_target)
	p.set("damage", damage)
	p.set("speed", projectile_speed)
	p.set("color", projectile_color)
	get_tree().current_scene.add_child(p)

func set_enemies_layer(layer: Node2D) -> void:
	enemies_layer = layer

func show_range(show: bool) -> void:
	range_indicator.visible = show

func _make_range_circle(radius: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	var points: Array[Vector2] = []
	var segments := 64
	for i in segments:
		var angle := TAU * i / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	points.append(points[0])
	line.points = points
	return line
