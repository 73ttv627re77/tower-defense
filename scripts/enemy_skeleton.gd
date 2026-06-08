extends "res://scripts/enemy.gd"
class_name EnemySkeleton

# Fodder enemy. Slightly tougher than moss-beast.

func _init() -> void:
	enemy_name = "Skeleton"
	max_hp = 80
	speed_px_per_s = 70.0
	gold_reward = 8
	leak_damage = 1
	sprite_path = "res://assets/enemies/skeleton.jpg"
