extends SceneTree

func _init():
    var up = Vector3(0.577, 0.577, 0.577).normalized() # a random normal
    var right = Vector3.UP.cross(up).normalized()
    var fwd = right.cross(up).normalized()
    var b = Basis(right, up, fwd).inverse()
    
    print("b * up = ", b * up)  # Should be (0, 1, 0)
    quit()
