extends "res://scripts/enemy.gd"
class_name EnemyHarpy

# Flying enemy. Same speed as skeleton, but the design intent is that
# ground-only towers (none in prototype, but barracks etc. in full-scope)
# can't hit it. For the prototype it's just a tougher fodder.

func _init() -> void:
	enemy_name = "Harpy"
	max_hp = 70
	speed_px_per_s = 80.0
	gold_reward = 12
	leak_damage = 1
	sprite_path = "res://assets/enemies/harpy.png"
	scale_factor = 0.22
