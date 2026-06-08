extends Node2D

# Main scene root for the tower defence prototype.
# Hosts: map, towers, enemies, UI, wave controller.

@onready var map: Node2D = $Map

func _ready() -> void:
	print("[TD] Main scene ready, viewport size: ", get_viewport().get_visible_rect().size)
	# TODO(#6): spawn build spots
	# TODO(#7): wire up enemy spawner
	# TODO(#5): wire up wave controller

func _process(_delta: float) -> void:
	pass
