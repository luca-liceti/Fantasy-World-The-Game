@tool
extends EditorScript

func _run():
    print("Running D20 Extractor Tool!")
    var root = Node3D.new()
    EditorInterface.get_edited_scene_root().add_child(root)
    
    var viewport = SubViewport.new()
    viewport.size = Vector2i(256, 256)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg = true
    root.add_child(viewport)
    
    var cam = Camera3D.new()
    cam.projection = Camera3D.PROJECTION_ORTHOGONAL
    cam.size = 2.5
    cam.position = Vector3(0, 3, 0)
    cam.look_at(Vector3.ZERO, Vector3.FORWARD)
    
    var light = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-60, 45, 0)
    viewport.add_child(light)
    viewport.add_child(cam)
    
    var gltf = GLTFDocument.new()
    var state = GLTFState.new()
    gltf.append_from_file("res://assets/models/d20-gold.glb", state)
    var die = gltf.generate_scene(state)
    viewport.add_child(die)
    
    var mi = die.find_child("*Material*", true, false) as MeshInstance3D
    var faces = mi.mesh.get_faces()
    var normal_areas = {}
    for i in range(0, faces.size(), 3):
        var v1 = faces[i]
        var v2 = faces[i+1]
        var v3 = faces[i+2]
        var cross = (v2 - v1).cross(v3 - v1)
        var area = cross.length() / 2.0
        if area < 0.0001: continue
        var n = cross.normalized()
        var center = (v1 + v2 + v3) / 3.0
        if n.dot(center) < 0: n = -n
        
        var matched = ""
        for k in normal_areas:
            if normal_areas[k].normal.angle_to(n) < 0.1: matched = k; break
        if matched != "": normal_areas[matched].area += area
        else: normal_areas[str(n)] = { "normal": n, "area": area }
            
    var area_list = normal_areas.values()
    area_list.sort_custom(func(a, b): return a.area > b.area)
    var cached_normals = []
    for i in range(20): cached_normals.append(area_list[i].normal)
    cached_normals.sort_custom(func(a, b):
        if abs(a.y - b.y) > 0.01: return a.y > b.y
        if abs(a.x - b.x) > 0.01: return a.x > b.x
        return a.z > b.z
    )
    
    # Use Godot's trick: we just query the mesh data bounding boxes!
    # The 'letters_0' mesh has the numbers!
    var letters_mi = die.find_child("*letters*", true, false) as MeshInstance3D
    var l_faces = letters_mi.mesh.get_faces()
    
    # We map each triangle in letters to the closet predefined Face Normal!
    var face_vertex_counts = {}
    for i in range(20): face_vertex_counts[i] = 0
    
    for i in range(0, l_faces.size(), 3):
        var v = (l_faces[i] + l_faces[i+1] + l_faces[i+2]) / 3.0
        v = v.normalized()
        
        var best_idx = -1
        var best_dot = -1.0
        for j in range(20):
            var d = cached_normals[j].dot(v)
            if d > best_dot:
                best_dot = d
                best_idx = j
        if best_dot > 0.95:
            face_vertex_counts[best_idx] += 3
            
    print("VERTEX COUNTS PER FACE:")
    for i in range(20):
        print("Face ", i, ": ", face_vertex_counts[i], " vertices")
        
    root.queue_free()
