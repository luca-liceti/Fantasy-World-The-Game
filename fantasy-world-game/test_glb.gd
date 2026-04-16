@tool
extends SceneTree

func _init():
	var path = "res://assets/models/enviroment/forest/optimized_assets/grass_medium_01_2k_opt.glb"
	var scene = load(path) as PackedScene
	if scene:
		var instance = scene.instantiate()
		for child in instance.get_children():
			print(child.name)
		instance.queue_free()
	print("DONE_PRINTING")
	quit()
