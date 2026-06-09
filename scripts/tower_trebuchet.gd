extends "res://scripts/tower.gd"
class_name TowerTrebuchet

# Trebuchet tower: heavy siege, long range, AoE splash, slow.
# Sprite: trebuchet (low wide A-frame).

const SPLASH_RADIUS := 50.0

func _init() -> void:
	tower_name = "Trebuchet"
	build_cost = 150
	damage = 60
	range_px = 200.0
	cooldown_s = 3.0
	projectile_speed = 350.0
	projectile_color = Color(0.55, 0.45, 0.35, 1.0)
	sprite_path = "res://assets/towers/trebuchet.png"

func _fire() -> void:
	if not is_instance_valid(current_target):
		return
	# Lobbed projectile: travels in an arc, lands at target position, splash.
	var p := Projectile.new()
	p.global_position = global_position
	p.set("target", current_target)
	p.set("damage", damage)
	p.set("speed", projectile_speed)
	p.set("color", projectile_color)
	p.set("splash_radius", SPLASH_RADIUS)
	get_tree().current_scene.add_child(p)
	cooldown_timer = cooldown_s
