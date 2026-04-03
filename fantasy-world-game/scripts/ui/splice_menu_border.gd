extends SceneTree

func _init() -> void:
	var h_img = Image.load_from_file("res://assets/textures/ui/components/horizontal_bar.png")
	var v_img = Image.load_from_file("res://assets/textures/ui/components/verticle_bar.png")
	
	if h_img == null or v_img == null:
		print("Failed to load source images.")
		quit()

	var h_w = h_img.get_width()
	var h_h = h_img.get_height()
	var v_w = v_img.get_width()
	var v_h = v_img.get_height()
	
	print("Horizontal bar: ", h_w, "x", h_h)
	print("Vertical bar: ", v_w, "x", v_h)
	
	# Assuming thickness is roughly 48 based on previous estimates
	var thick = max(h_h, v_w)
	
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	
	# Fill dark panel background
	img.fill_rect(Rect2i(0, 0, 256, 256), Color(0.06, 0.05, 0.04, 0.95))
	
	# Middle stretches
	var h_mid_rect = Rect2i(h_w / 2, 0, 1, h_h)
	var v_mid_rect = Rect2i(0, v_h / 2, v_w, 1)
	
	for y in range(thick, 256 - thick):
		img.blit_rect_blend(v_img, v_mid_rect, Vector2i(0, y))
		img.blit_rect_blend(v_img, v_mid_rect, Vector2i(256 - v_w, y))
		
	for x in range(thick, 256 - thick):
		img.blit_rect_blend(h_img, h_mid_rect, Vector2i(x, 0))
		img.blit_rect_blend(h_img, h_mid_rect, Vector2i(x, 256 - h_h))
		
	# Corners - horizontal dominates vertically, vertical dominates horizontally?
	# Draw interlocking corners by drawing both, horizontal on top usually looks like a frame cap.
	
	# Vertical ends
	img.blit_rect_blend(v_img, Rect2i(0, 0, v_w, thick), Vector2i(0, 0)) # TL
	img.blit_rect_blend(v_img, Rect2i(0, v_h - thick, v_w, thick), Vector2i(0, 256 - thick)) # BL
	img.blit_rect_blend(v_img, Rect2i(0, 0, v_w, thick), Vector2i(256 - v_w, 0)) # TR
	img.blit_rect_blend(v_img, Rect2i(0, v_h - thick, v_w, thick), Vector2i(256 - v_w, 256 - thick)) # BR

	# Horizontal ends (painted over)
	img.blit_rect_blend(h_img, Rect2i(0, 0, thick, h_h), Vector2i(0, 0)) # TL
	img.blit_rect_blend(h_img, Rect2i(0, 0, thick, h_h), Vector2i(0, 256 - h_h)) # BL
	img.blit_rect_blend(h_img, Rect2i(h_w - thick, 0, thick, h_h), Vector2i(256 - thick, 0)) # TR
	img.blit_rect_blend(h_img, Rect2i(h_w - thick, 0, thick, h_h), Vector2i(256 - thick, 256 - h_h)) # BR

	var save_path = "res://assets/textures/ui/components/menu_panel_border.png"
	img.save_png(save_path)
	print("Successfully spliced horizontally and vertically to build custom panel: ", save_path)
	
	quit()
