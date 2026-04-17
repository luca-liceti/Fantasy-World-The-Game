extends SceneTree

func _init():
	print("--- VERIFYING MATERIALS ---")
	var bm = preload("res://scripts/board/biome_material_manager.gd")
	var types = [
		[0, "Forest"], [1, "Peaks"], [2, "Wastes"], [3, "Plains"], [4, "Ashlands"], [5, "Hills"], [6, "Swamp"]
	]
	# Force texture check
	bm._check_textures_available()
	for t in types:
		var mat = bm._create_material(t[0])
		if mat is ShaderMaterial:
			print(t[1] + " is ShaderMaterial. Params:")
			for param in ["texture_albedo", "texture_normal", "texture_roughness", "texture_ao", "texture_displacement"]:
				var tex = mat.get_shader_parameter(param)
				if tex:
					print("  " + param + " = " + tex.resource_path)
				else:
					print("  " + param + " = NULL")
		elif mat is StandardMaterial3D:
			print(t[1] + " is StandardMaterial3D")
	
	print("--- VERIFYING STONE BORDER ---")
	var env = preload("res://scripts/board/board_environment.gd").new()
	var smat = env._create_stone_border_material()
	print("Stone Border: albedo=" + str(smat.albedo_texture) + " normal=" + str(smat.normal_texture) + " roughness=" + str(smat.roughness_texture) + " ao=" + str(smat.ao_texture) + " height=" + str(smat.heightmap_texture))
	
	quit()
