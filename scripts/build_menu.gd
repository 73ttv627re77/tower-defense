extends Node2D
class_name BuildMenu

# Bottom UI strip showing 3 tower build buttons (Archer / Mage / Trebuchet).
# Tapping a button selects that tower type for placement.

var game: Game = null
var buttons: Array[Node2D] = []
var label_gold: Label = null
var label_hp: Label = null
var label_wave: Label = null
var label_state: Label = null

const BUTTON_WIDTH := 200.0
const BUTTON_HEIGHT := 80.0
const BUTTON_SPACING := 10.0

const TOWER_TYPES := [
	{"type": "archer", "label": "Archer", "cost": 50, "color": Color(0.4, 0.6, 0.3, 0.85)},
	{"type": "mage", "label": "Mage", "cost": 100, "color": Color(0.3, 0.4, 0.7, 0.85)},
	{"type": "trebuchet", "label": "Trebuchet", "cost": 150, "color": Color(0.55, 0.45, 0.35, 0.85)},
]

func _ready() -> void:
	# Background bar
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.size = Vector2(1024, 100)
	bg.position = Vector2(0, 0)
	add_child(bg)
	# Gold label
	label_gold = Label.new()
	label_gold.text = "Gold: 100"
	label_gold.position = Vector2(20, 8)
	label_gold.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	add_child(label_gold)
	# HP label
	label_hp = Label.new()
	label_hp.text = "Base HP: 20"
	label_hp.position = Vector2(20, 32)
	label_hp.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7))
	add_child(label_hp)
	# Wave label
	label_wave = Label.new()
	label_wave.text = "Level 1"
	label_wave.position = Vector2(180, 8)
	label_wave.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(label_wave)
	# State label
	label_state = Label.new()
	label_state.text = "WAVE"
	label_state.position = Vector2(180, 32)
	label_state.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	add_child(label_state)
	# Tower buttons
	var x := 600.0
	for t in TOWER_TYPES:
		var btn := _make_button(t)
		btn.position = Vector2(x, 8)
		add_child(btn)
		buttons.append(btn)
		x += BUTTON_WIDTH + BUTTON_SPACING
	# Connect game signals (if game ref is set)
	if game:
		game.gold_changed.connect(_on_gold_changed)
		game.base_hp_changed.connect(_on_hp_changed)
		game.state_changed.connect(_on_state_changed)

func _make_button(t: Dictionary) -> Node2D:
	var container := Node2D.new()
	container.set_meta("type", t["type"])
	container.set_meta("cost", t["cost"])
	# Background
	var bg := ColorRect.new()
	bg.color = t["color"]
	bg.size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	container.add_child(bg)
	# Label
	var lbl := Label.new()
	lbl.text = "%s\n%dg" % [t["label"], t["cost"]]
	lbl.position = Vector2(15, 12)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	container.add_child(lbl)
	# Hit area
	var hit := ColorRect.new()
	hit.color = Color(0, 0, 0, 0)  # invisible
	hit.size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	container.add_child(hit)
	return container

func get_global_rect() -> Rect2:
	# The menu is anchored at y=1700 in the world, size 1024x100
	var global_pos := global_position
	return Rect2(global_pos, Vector2(1024, 100))

func handle_tap(screen_pos: Vector2) -> void:
	var local := screen_pos - global_position
	for btn in buttons:
		var rect := Rect2(btn.position, Vector2(BUTTON_WIDTH, BUTTON_HEIGHT))
		if rect.has_point(local):
			var t: String = btn.get_meta("type")
			if game:
				game.select_build_type(t)
			return

func _on_gold_changed(new_gold: int) -> void:
	if label_gold:
		label_gold.text = "Gold: %d" % new_gold

func _on_hp_changed(new_hp: int) -> void:
	if label_hp:
		label_hp.text = "Base HP: %d" % new_hp

func _on_state_changed(new_state: String) -> void:
	if label_state:
		match new_state:
			"wave_phase":
				label_state.text = "WAVE"
				label_state.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
			"build_phase":
				label_state.text = "BUILD"
				label_state.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
			"win":
				label_state.text = "VICTORY"
				label_state.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			"lose":
				label_state.text = "DEFEAT"
				label_state.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
