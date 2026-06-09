extends "res://scripts/enemy.gd"
class_name EnemyGnoll

# Fodder enemy. Fast, fragile.

func _init() -> void:
	enemy_name = "Gnoll"
	max_hp = 60
	speed_px_per_s = 110.0
	gold_reward = 7
	leak_damage = 1
	sprite_path = "res://assets/enemies/gnoll.png"
