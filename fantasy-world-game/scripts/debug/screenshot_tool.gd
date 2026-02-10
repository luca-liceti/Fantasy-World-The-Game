extends SceneTree

func _initialize():
	# Wait for a few frames for everything to render
	for i in range(10):
		await get_root().get_tree().process_frame
	
	var viewport = get_root().get_viewport()
	var texture = viewport.get_texture()
	var image = texture.get_image()
	
	var save_path = "C:/Users/Luca/Documents/Github Projects/Fantasy-World-The-Game/board_review.png"
	image.save_png(save_path)
	print("Screenshot saved to: ", save_path)
	quit()
