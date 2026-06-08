extends SceneTree

# Headless screenshot tool. Loads the project, runs for N frames to let
# enemies spawn and walk, then saves a PNG.
# Usage: godot --headless --rendering-driver opengl3 --script tools/screenshot.gd -- <frames>

func _initialize() -> void:
	var frames_to_run := 60
	for arg in OS.get_cmdline_user_args():
		if arg.is_valid_int():
			frames_to_run = arg.to_int()
	print("[SS] Running %d frames then capturing..." % frames_to_run)
	# Load main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var instance: Node = main_scene.instantiate()
	root.add_child(instance)
	# Run frames
	for i in frames_to_run:
		await process_frame
	# Capture
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		var err := img.save_png("/tmp/td-screens/game-render.png")
		if err == OK:
			print("[SS] Saved /tmp/td-screens/game-render.png")
		else:
			print("[SS] Save failed: %d" % err)
	else:
		print("[SS] No image")
	quit()
