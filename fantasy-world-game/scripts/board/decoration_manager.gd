## DecorationManager
## Manages MultiMeshInstance3D layers for the entire board to minimize draw calls.
extends Node3D

# Dictionary mapping asset_path -> { "multimesh": MultiMeshInstance3D, "transforms": Array[Transform3D] }
var _layers: Dictionary = {}

## Adds a placement request to the manager
func add_decoration(mesh_path: String, xform: Transform3D) -> void:
	if not _layers.has(mesh_path):
		_create_layer(mesh_path)
	_layers[mesh_path]["transforms"].append(xform)

## Finalizes the MultiMeshes after all tiles have registered their decorations
func build() -> void:
	var total_decorations = 0
	for mesh_path in _layers:
		var layer = _layers[mesh_path]
		var transforms = layer["transforms"]
		var mmi: MultiMeshInstance3D = layer["node"]
		
		var mesh = _extract_mesh(mesh_path)
		if mesh == null:
			push_error("[DecorationManager] Failed to extract mesh from: %s" % mesh_path)
			continue
		
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = transforms.size()
		
		for i in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i])
		
		mmi.multimesh = mm
		
		total_decorations += transforms.size()
		print("[DecorationManager] Created %s with %d instances" % [mesh_path.get_file(), transforms.size()])
	
	print("[DecorationManager] Total decorations: %d" % total_decorations)

func _create_layer(path: String) -> void:
	var mmi = MultiMeshInstance3D.new()
	mmi.name = path.get_file().replace(".", "_")
	add_child(mmi)
	_layers[path] = {"node": mmi, "transforms": []}
	print("[DecorationManager] Created layer for: %s" % path.get_file())

func _extract_mesh(path: String) -> Mesh:
	var scene = load(path) as PackedScene
	if scene == null:
		push_error("[DecorationManager] Failed to load scene: %s" % path)
		return null
	
	var instance = scene.instantiate()
	if instance == null:
		push_error("[DecorationManager] Failed to instantiate scene: %s" % path)
		return null
	
	var mesh: Mesh = null
	for child in instance.get_children():
		if child is MeshInstance3D:
			mesh = child.mesh
			print("[DecorationManager] Extracted mesh '%s' from %s" % [mesh.get_class(), path.get_file()])
			break
	
	instance.queue_free()
	
	if mesh == null:
		push_error("[DecorationManager] No MeshInstance3D found in: %s" % path)
	
	return mesh