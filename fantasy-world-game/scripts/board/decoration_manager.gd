## DecorationManager
## Manages MultiMeshInstance3D layers for the entire board to minimize draw calls.
extends Node3D

# Dictionary mapping asset_path -> { "sub_layers": Array[Dictionary], "transforms": Array[Transform3D] }
# sub_layers items: { "node": MultiMeshInstance3D, "mesh": Mesh, "relative_xform": Transform3D }
var _layers: Dictionary = {}

## Adds a placement request to the manager
func add_decoration(asset_path: String, xform: Transform3D) -> void:
	if not _layers.has(asset_path):
		_create_layer(asset_path)
	_layers[asset_path]["transforms"].append(xform)

## Finalizes the MultiMeshes after all tiles have registered their decorations
func build() -> void:
	var total_instances = 0
	for asset_path in _layers:
		var layer_data = _layers[asset_path]
		var transforms = layer_data["transforms"]
		
		for sub in layer_data["sub_layers"]:
			var mmi: MultiMeshInstance3D = sub["node"]
			var mesh: Mesh = sub["mesh"]
			var rel_xform: Transform3D = sub["relative_xform"]
			
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mesh
			mm.instance_count = transforms.size()
			
			for i in range(transforms.size()):
				# Apply the placement transform, then the mesh's inherent local transform
				mm.set_instance_transform(i, transforms[i] * rel_xform)
			
			mmi.multimesh = mm
			total_instances += transforms.size()
			
		var label: String = asset_path.split("|")[-1] if "|" in asset_path else asset_path.get_file()
		print("[DecorationManager] Created asset '%s' (%d meshes) with %d instances" % [label, layer_data["sub_layers"].size(), transforms.size()])
	
	print("[DecorationManager] Total decoration instances: %d" % total_instances)

func _create_layer(path: String) -> void:
	var mesh_data_list = _extract_meshes(path)
	if mesh_data_list.is_empty():
		push_error("[DecorationManager] Failed to extract any meshes from: %s" % path)
		return
	
	var sub_layers = []
	for data in mesh_data_list:
		var mmi = MultiMeshInstance3D.new()
		var mesh_name: String = data["name"]
		# Support "res://foo.glb|NodeName" — strip the suffix for the node name
		mmi.name = mesh_name.replace(".", "_").replace(" ", "_")
		add_child(mmi)
		sub_layers.append({
			"node": mmi, 
			"mesh": data["mesh"],
			"relative_xform": data["relative_xform"]
		})
		
	_layers[path] = {"sub_layers": sub_layers, "transforms": []}

func _extract_meshes(path: String) -> Array[Dictionary]:
	# Support "res://foo.glb|NodeName" to target a specific sub-mesh OR container node inside a GLB.
	var scene_path := path
	var target_node_name := ""
	if "|" in path:
		var parts := path.split("|")
		scene_path = parts[0]
		target_node_name = parts[1]
	
	var scene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[DecorationManager] Failed to load scene: %s" % scene_path)
		return []
	
	var instance = scene.instantiate()
	if instance == null:
		push_error("[DecorationManager] Failed to instantiate scene: %s" % scene_path)
		return []
	
	var results: Array[Dictionary] = []
	
	if target_node_name == "":
		# If no node specified, find first MeshInstance3D (fallback for old assets)
		for child in instance.get_children():
			if child is MeshInstance3D:
				results.append({
					"mesh": child.mesh, 
					"name": child.name,
					"relative_xform": child.transform
				})
				break
	else:
		# Find the target node
		var target = instance.find_child(target_node_name, true, false)
		if target:
			var target_xform = _get_relative_transform(target, instance)
			
			if target is MeshInstance3D:
				var rel_xform = target_xform
				rel_xform.origin = Vector3.ZERO # Center the pivot
				results.append({
					"mesh": target.mesh, 
					"name": target.name,
					"relative_xform": rel_xform
				})
			else:
				# It's a container (Node3D), find all direct MeshInstance3D children
				for child in target.get_children():
					if child is MeshInstance3D:
						var child_xform = _get_relative_transform(child, instance)
						# Keep the rotation/scale from the GLB root, but normalize the 
						# position so it's relative to the target's pivot.
						var rel_xform = child_xform
						rel_xform.origin -= target_xform.origin
						
						results.append({
							"mesh": child.mesh, 
							"name": child.name,
							"relative_xform": rel_xform
						})
						print("[DecorationManager] Extracted sub-mesh '%s' from container %s (Normalized)" % [child.name, target_node_name])
	
	instance.queue_free()
	
	if results.is_empty():
		push_error("[DecorationManager] No meshes found for '%s' in: %s" % [target_node_name, scene_path])
	
	return results

## Accumulates transforms from node up to (but not including) root.
func _get_relative_transform(node: Node3D, root: Node) -> Transform3D:
	var xform := node.transform
	var p = node.get_parent()
	while p and p != root:
		if p is Node3D:
			xform = p.transform * xform
		p = p.get_parent()
	
	# We generally want to ignore the root-level translation if we are picking 
	# a specific object from a pack, but Sketchfab models often use the 
	# translation for axis-correction. However, the user-provided placement 
	# transform should handle the world position.
	# Let's keep the rotation and scale, but zero out the origin if it's 
	# just a layout offset in the GLB.
	# Actually, to be safe and match the artist's intent for "where the pivot is",
	# we should probably keep the translation relative to the *target node name* 
	# if it's a container, or zero it if the target is the MeshInstance itself.
	
	return xform
