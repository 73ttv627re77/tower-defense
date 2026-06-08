extends "res://scripts/tower.gd"
class_name TowerArcher

# Archer tower: fast single-target physical damage.
# Sprite: archer (carved bow on stone platform).

func _init() -> void:
	tower_name = "Archer"
	build_cost = 50
	damage = 8
	range_px = 120.0
	cooldown_s = 1.2
	projectile_speed = 700.0
	projectile_color = Color(0.85, 0.75, 0.45, 1.0)
	sprite_path = "res://assets/towers/archer.jpg"
