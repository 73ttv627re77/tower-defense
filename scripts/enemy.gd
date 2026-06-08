extends Node2D
class_name Enemy

# Base enemy. Subclasses override stats.
# Walks the map's Path2D, takes damage, dies, drops gold.

# Subclass-overridable stats
@export var enemy_name: String = "Enemy"
@export var max_hp: int = 50
@export var speed_px_per_s: float = 60.0
@export var gold_reward: int = 5
@export var leak_damage: int = 1
@export var sprite_path: String = "res://assets/enemies/mossbeast.jpg"
@export var scale_factor: float = 0.25  # 1024px sprite -> ~256px in game

var hp: int
var path_follow: PathFollow2D
var sprite: Sprite2D
var hp_bar_bg: ColorRect
var hp_bar_fill: ColorRect
var is_alive: bool = true
var on_leak: Callable = Callable()  # (leak_damage) -> void
var on_killed: Callable = Callable()  # (gold_reward) -> void

# Path progress 0.0 (spawn) to 1.0 (base). Exposed for tower targeting.
var path_progress: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("active_enemies")
	hp = max_hp
	# Sprite
	sprite = Sprite2D.new()
	var tex := load(sprite_path) as Texture2D
	if tex:
		sprite.texture = tex
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(0, -sprite.texture.get_height() * scale_factor * 0.3)  # anchor near bottom-center
	add_child(sprite)
	# HP bar
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.color = Color(0, 0, 0, 0.6)
	hp_bar_bg.size = Vector2(60, 6)
	hp_bar_bg.position = Vector2(-30, -sprite.texture.get_height() * scale_factor * 0.3 - 18)
	add_child(hp_bar_bg)
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.color = Color(0.3, 0.9, 0.3, 1.0)
	hp_bar_fill.size = Vector2(60, 6)
	hp_bar_fill.position = hp_bar_bg.position
	add_child(hp_bar_fill)
	_update_hp_bar()

func _process(delta: float) -> void:
	if not is_alive:
		return
	if not path_follow:
		return
	path_follow.progress += speed_px_per_s * delta
	path_progress = path_follow.progress_ratio
	# Reached the end?
	if path_progress >= 1.0:
		_leak()

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	hp -= amount
	if hp <= 0:
		_die()
	else:
		_update_hp_bar()
		_flash_damage()

func _die() -> void:
	is_alive = false
	remove_from_group("active_enemies")
	if on_killed.is_valid():
		on_killed.call(gold_reward)
	queue_free()

func _leak() -> void:
	is_alive = false
	remove_from_group("active_enemies")
	if on_leak.is_valid():
		on_leak.call(leak_damage)
	queue_free()

func _update_hp_bar() -> void:
	if hp_bar_fill:
		var ratio: float = float(hp) / float(max_hp)
		hp_bar_fill.size.x = 60.0 * ratio
		# Color shifts from green -> yellow -> red as HP drops
		if ratio > 0.5:
			hp_bar_fill.color = Color(0.3, 0.9, 0.3, 1.0)
		elif ratio > 0.25:
			hp_bar_fill.color = Color(0.95, 0.85, 0.2, 1.0)
		else:
			hp_bar_fill.color = Color(0.95, 0.3, 0.3, 1.0)

func _flash_damage() -> void:
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15)

func attach_to_path(path: Path2D) -> void:
	path_follow = PathFollow2D.new()
	path_follow.loop = false
	path.add_child(path_follow)
	# Reparent self under the PathFollow2D so we move along the path.
	var old_parent := get_parent()
	if old_parent:
		old_parent.remove_child(self)
	path_follow.add_child(self)
	# Reset our position relative to the path follow (we sit on the path).
	position = Vector2(0, 0)
