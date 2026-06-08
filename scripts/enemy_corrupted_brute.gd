extends "res://scripts/enemy.gd"
class_name EnemyCorruptedBrute

# Boss-tier miniboss. High HP, slow, AoE explosion on death.
# (AoE explosion is handled in the wave controller / projectile system,
# not here — for prototype we just give it a death callback.)

func _init() -> void:
	enemy_name = "Corrupted Brute"
	max_hp = 500
	speed_px_per_s = 40.0
	gold_reward = 50
	leak_damage = 5
	sprite_path = "res://assets/enemies/corrupted_brute.jpg"
	scale_factor = 0.32

func _die() -> void:
	# AoE explosion: damage nearby towers and trigger visual.
	# For prototype, we just notify the wave controller via on_killed callback.
	# A more complete impl would damage towers in radius; that's a future task.
	is_alive = false
	if on_killed.is_valid():
		on_killed.call(gold_reward)
	# Visual: brief ring
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.3, 0.1, 0.9)
	var points: Array[Vector2] = []
	for i in 32:
		var angle := TAU * i / 32
		points.append(Vector2(cos(angle), sin(angle)) * 50)
	points.append(points[0])
	ring.points = points
	ring.position = global_position
	get_tree().current_scene.add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.5)
	tween.tween_callback(ring.queue_free)
	queue_free()
