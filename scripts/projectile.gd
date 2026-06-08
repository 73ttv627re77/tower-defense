extends Node2D
class_name Projectile

# Base projectile. Travels toward its target, deals damage on hit.
# Subclasses (or just colour tweaks) differentiate arrows / orbs / boulders.

var target: Node2D = null
var damage: int = 0
var speed: float = 600.0
var color: Color = Color(0.9, 0.85, 0.5, 1.0)

var sprite: Polygon2D

func _ready() -> void:
	sprite = Polygon2D.new()
	sprite.polygon = PackedVector2Array([
		Vector2(-4, -2), Vector2(8, 0), Vector2(-4, 2)
	])
	sprite.color = color
	add_child(sprite)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	if dist < speed * delta:
		# Hit
		if "take_damage" in target:
			target.take_damage(damage)
		queue_free()
		return
	var dir := to_target / dist
	global_position += dir * speed * delta
	# Rotate sprite to face direction
	rotation = dir.angle()
