extends SceneTree

func _init():
    var gltf = GLTFDocument.new()
    var state = GLTFState.new()
    var err = gltf.append_from_file("res://assets/models/d20-gold.glb", state)
    if err != OK:
        print("Failed to load GLB")
        quit()
        return
        
    var scene = gltf.generate_scene(state)
    var mi = scene.find_child("*Material*", true, false)
    if not mi:
        print("Mesh not found")
        quit()
        return
        
    var get_global_transform = func(node: Node3D):
        var t = node.transform
        var parent = node.get_parent()
        while parent and parent is Node3D:
            t = parent.transform * t
            parent = parent.get_parent()
        return t
        
    var global_t = get_global_transform.call(mi)
    var mesh = mi.mesh
    
    var faces = mesh.get_faces()
    var face_normals = []
    
    for i in range(0, faces.size(), 3):
        # Apply global transform to vertices
        var v1 = global_t * faces[i]
        var v2 = global_t * faces[i+1]
        var v3 = global_t * faces[i+2]
        
        # Area of triangle
        var cross = (v2 - v1).cross(v3 - v1)
        if cross.length() < 0.001:
            continue
            
        var normal = cross.normalized()
        
        # Check if we already have this normal
        var is_new = true
        for n in face_normals:
            if n.angle_to(normal) < 0.1:
                is_new = false
                break
        if is_new:
            face_normals.append(normal)
            
    print("Found ", face_normals.size(), " unique faces")
    for n in face_normals:
        # Find a Basis that rotates this normal to Vector3.UP
        # We can use looking_at to orient the Y axis to the normal
        # Basis.looking_at defines -Z axis.
        # But we want to rotate 'n' to 'UP'.
        # That means we want the Object's 'n' vector to become (0, 1, 0)
        # So the object's Up (Y-axis) should be 'n'.
        # We can create a basis where the Y vector is 'n'.
        var up = n
        var right = Vector3.UP.cross(up).normalized()
        if right.length() < 0.1:
            right = Vector3.RIGHT
        var fwd = right.cross(up).normalized()
        var b = Basis(right, up, fwd)
        
        # But this b transforms from local to world. 
        # So b.y = n. This means if we apply b, the local Y axis points to n.
        # We want the LOCAL 'n' to point to World 'UP'.
        # So we want the Inverse of b! 
        # world_up = b_inv * n. Since n was 'up', b_inv * b.y = (0,1,0). YES!
        var b_target = b.inverse()
        
        var euler = b_target.get_euler()
        print("Vector3(%.2f, %.2f, %.2f)," % [rad_to_deg(euler.x), rad_to_deg(euler.y), rad_to_deg(euler.z)])
        
    quit()
