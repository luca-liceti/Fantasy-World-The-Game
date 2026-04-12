extends SceneTree
func _init():
    var l = DirectionalLight3D.new()
    print("Mask prop exists: ", "cull_mask" in l, ", Value: ", l.cull_mask)
    quit()
