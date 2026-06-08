extends Node2D
class_name Game

# Game state machine + wave controller + gold economy + input.
# Owns the gameplay loop. Lives as a child of Main.

@export var starting_gold: int = 100
@export var player_hp: int = 20

# Wave definitions: each wave is a list of (enemy_scene, count, interval) tuples
# Levels progress in difficulty: fodder -> mixed -> speed + flying -> miniboss
const WAVE_DEFINITIONS: Array = [
	# Level 1: tutorial wave (5 moss-beasts, 5 seconds total)
	[{"enemy": "mossbeast", "count": 5, "interval": 1.0}],
	# Level 2: skeletons join (4+4 over ~9 seconds)
	[{"enemy": "mossbeast", "count": 4, "interval": 1.0},
	 {"enemy": "skeleton", "count": 4, "interval": 1.2}],
	# Level 3: gnolls force path coverage (3 groups, faster pace)
	[{"enemy": "mossbeast", "count": 4, "interval": 0.9},
	 {"enemy": "gnoll", "count": 4, "interval": 0.7},
	 {"enemy": "skeleton", "count": 4, "interval": 1.1}],
	# Level 4: harpies join (flying, only ranged towers can hit)
	[{"enemy": "mossbeast", "count": 4, "interval": 0.8},
	 {"enemy": "harpy", "count": 3, "interval": 0.9},
	 {"enemy": "gnoll", "count": 4, "interval": 0.7},
	 {"enemy": "skeleton", "count": 4, "interval": 1.0}],
	# Level 5: brute miniboss finale (1 brute, 14 fodder)
	[{"enemy": "skeleton", "count": 5, "interval": 0.7},
	 {"enemy": "gnoll", "count": 5, "interval": 0.5},
	 {"enemy": "harpy", "count": 4, "interval": 0.6},
	 {"enemy": "corrupted_brute", "count": 1, "interval": 0.0}],
]

@onready var map_node: Node2D = get_tree().current_scene.get_node("Map")
@onready var enemies_layer: Node2D = map_node.get_node("EnemiesLayer") if map_node else null
@onready var towers_layer: Node2D = map_node.get_node("TowersLayer") if map_node else null

var gold: int
var base_hp: int
var current_level: int = 0
var current_wave_idx: int = 0
var current_group: Dictionary = {}  # current spawn group being processed
var group_spawned: int = 0
var group_timer: float = 0.0
var waiting_for_next_wave: bool = true
var game_state: String = "build_phase"  # build_phase, wave_phase, win, lose
var build_menu: BuildMenu = null
var pending_build_type: String = ""  # "" or "archer" / "mage" / "trebuchet"
var _frame_count: int = 0

signal gold_changed(new_gold: int)
signal base_hp_changed(new_hp: int)
signal state_changed(new_state: String)

func _ready() -> void:
	gold = starting_gold
	base_hp = player_hp
	print("[GAME] Ready, gold=%d, base_hp=%d" % [gold, base_hp])
	# Build menu UI — defer add_child to avoid busy-parent error during _ready.
	build_menu = BuildMenu.new()
	build_menu.position = Vector2(20, 1700)
	build_menu.game = self
	get_tree().current_scene.add_child.call_deferred(build_menu)
	# Start the first level automatically for the prototype.
	# Real flow: a level select / "start level" button.
	call_deferred("_start_wave_phase")

func _process(delta: float) -> void:
	_frame_count += 1
	if _frame_count % 60 == 0:
		var alive := _count_alive_enemies()
		print("[GAME] frame %d, state=%s, level=%d, group=%d, alive=%d" % [_frame_count, game_state, current_level, current_wave_idx, alive])
	if game_state != "wave_phase":
		return
	# Process current group
	if current_group.is_empty():
		# Move to next group in the wave
		current_wave_idx += 1
		if current_wave_idx >= WAVE_DEFINITIONS[current_level].size():
			# End of wave
			if _count_alive_enemies() == 0:
				_on_wave_complete()
			return
		current_group = WAVE_DEFINITIONS[current_level][current_wave_idx]
		group_spawned = 0
		group_timer = 0.0
		print("[GAME] Group %d: %s x%d every %.2fs" % [current_wave_idx, current_group["enemy"], current_group["count"], current_group["interval"]])
		return
	group_timer += delta
	if group_spawned < current_group["count"] and group_timer >= current_group["interval"]:
		group_timer = 0.0
		_spawn_enemy(current_group["enemy"])
		group_spawned += 1
		print("[GAME] Spawned %s #%d" % [current_group["enemy"], group_spawned])

func _count_alive_enemies() -> int:
	return get_tree().get_nodes_in_group("active_enemies").size()

func _start_wave_phase() -> void:
	game_state = "wave_phase"
	current_level = 0
	current_wave_idx = -1
	current_group = {}
	state_changed.emit(game_state)
	print("[GAME] Wave phase started, level %d" % current_level)

func _on_wave_complete() -> void:
	# Check if all levels done
	if current_level + 1 >= WAVE_DEFINITIONS.size():
		_on_victory()
		return
	# Move to next level
	current_level += 1
	current_wave_idx = -1
	current_group = {}
	gold += 50  # bonus gold between levels
	gold_changed.emit(gold)
	print("[GAME] Level %d cleared, +50 gold, total=%d" % [current_level, gold])
	# Continue with next level's waves
	state_changed.emit(game_state)

func _on_victory() -> void:
	game_state = "win"
	state_changed.emit(game_state)
	print("[GAME] VICTORY")

func _on_enemy_leaked(damage: int) -> void:
	base_hp -= damage
	base_hp_changed.emit(base_hp)
	print("[GAME] Enemy leaked, -%d HP, base_hp=%d" % [damage, base_hp])
	if base_hp <= 0:
		game_state = "lose"
		state_changed.emit(game_state)
		print("[GAME] DEFEAT")

func _on_enemy_killed(reward: int) -> void:
	gold += reward
	gold_changed.emit(gold)

func _spawn_enemy(enemy_type: String) -> void:
	if not enemies_layer:
		return
	var enemy
	match enemy_type:
		"mossbeast":
			enemy = EnemyMossBeast.new()
		"skeleton":
			enemy = EnemySkeleton.new()
		"gnoll":
			enemy = EnemyGnoll.new()
		"harpy":
			enemy = EnemyHarpy.new()
		"corrupted_brute":
			enemy = EnemyCorruptedBrute.new()
		_:
			push_warning("Unknown enemy type: " + enemy_type)
			return
	enemy.on_leak = Callable(self, "_on_enemy_leaked")
	enemy.on_killed = Callable(self, "_on_enemy_killed")
	# Add to enemies_layer first, then attach to path (which re-parents).
	enemies_layer.add_child(enemy)
	if map_node and map_node.path_follow:
		enemy.attach_to_path(map_node.path_follow)
	# Notify towers
	for tower in towers_layer.get_children():
		if tower.has_method("set_enemies_layer"):
			tower.set_enemies_layer(enemies_layer)

func _input(event: InputEvent) -> void:
	# Detect taps on build spots
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	# Debug: tap a number key 1/2/3 to select build type, 0 to auto-place a tower
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				select_build_type("archer")
			KEY_2:
				select_build_type("mage")
			KEY_3:
				select_build_type("trebuchet")
			KEY_0:
				# Auto-place a tower for testing
				if map_node and not map_node.build_spot_nodes.is_empty():
					pending_build_type = "archer"
					_attempt_build(map_node.build_spot_nodes[2])

func _handle_tap(screen_pos: Vector2) -> void:
	if game_state == "win" or game_state == "lose":
		return
	# Build menu first
	if build_menu and build_menu.get_global_rect().has_point(screen_pos):
		build_menu.handle_tap(screen_pos)
		return
	# Then build spots
	for spot in map_node.build_spot_nodes:
		if spot.get_meta("is_occupied", false):
			continue
		if spot.global_position.distance_to(screen_pos) < 48:
			_attempt_build(spot)
			return
	# Tap on an existing tower: toggle range indicator
	for tower in towers_layer.get_children():
		if tower.global_position.distance_to(screen_pos) < 60:
			if tower.has_method("show_range"):
				tower.show_range(not tower.range_indicator.visible)
			return

func _attempt_build(spot: Node2D) -> void:
	if pending_build_type == "":
		# No type selected; show build menu as a hint
		return
	var cost: int = 0
	var tower
	match pending_build_type:
		"archer":
			cost = 50
			tower = TowerArcher.new()
		"mage":
			cost = 100
			tower = TowerMage.new()
		"trebuchet":
			cost = 150
			tower = TowerTrebuchet.new()
	if gold < cost:
		print("[GAME] Not enough gold: have %d, need %d" % [gold, cost])
		return
	gold -= cost
	gold_changed.emit(gold)
	tower.position = spot.global_position
	tower.set_enemies_layer(enemies_layer)
	towers_layer.add_child(tower)
	spot.set_meta("is_occupied", true)
	# Visually mark the spot as occupied (dim the ring)
	for child in spot.get_children():
		if child is Line2D:
			child.modulate = Color(0.5, 0.5, 0.5, 0.3)
	print("[GAME] Built %s at %s, gold=%d" % [pending_build_type, spot.global_position, gold])

func select_build_type(t: String) -> void:
	pending_build_type = t
	print("[GAME] Selected build type: %s" % t)
