extends "res://scripts/enemy.gd"
class_name EnemyMossBeast

# Fodder enemy. Slow, low HP.

func _init() -> void:
	enemy_name = "Moss-beast"
	max_hp = 50
	speed_px_per_s = 60.0
	gold_reward = 5
	leak_damage = 1
	sprite_path = "res://assets/enemies/mossbeast.png"
