extends "res://scripts/tower.gd"
class_name TowerMage

# Mage tower: magical AoE, slow.
# Sprite: mage (tall spire with glowing crystal).

const AoE_RADIUS := 40.0

func _init() -> void:
	tower_name = "Mage"
	build_cost = 100
	damage = 25
	range_px = 100.0
	cooldown_s = 2.0
	projectile_speed = 450.0
	projectile_color = Color(0.4, 0.7, 1.0, 1.0)
	sprite_path = "res://assets/towers/mage.png"

func _fire() -> void:
	if not is_instance_valid(current_target):
		return
	# Mage: AoE damage at the target's position, no projectile travel.
	var pos := current_target.global_position
	for enemy in enemies_layer.get_children():
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if "is_alive" in enemy and not enemy.is_alive:
			continue
		if enemy.global_position.distance_to(pos) <= AoE_RADIUS:
			if "take_damage" in enemy:
				enemy.take_damage(damage)
	# Visual: brief AoE ring
	_spawn_aoe_ring(pos)
	# Mage still consumes cooldown
	cooldown_timer = cooldown_s

func _spawn_aoe_ring(pos: Vector2) -> void:
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(0.4, 0.7, 1.0, 0.7)
	var points: Array[Vector2] = []
	for i in 32:
		var angle := TAU * i / 32
		points.append(Vector2(cos(angle), sin(angle)) * AoE_RADIUS)
	points.append(points[0])
	ring.points = points
	ring.position = pos
	get_tree().current_scene.add_child(ring)
	# Fade out
	var tween := create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.5)
	tween.tween_callback(ring.queue_free)
