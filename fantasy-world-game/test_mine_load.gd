extends SceneTree

func _init():
    var scn = load("res://assets/models/buildings/mine_level1.glb")
    var inst = scn.instantiate()
    print("Class of root: ", inst.get_class())
    if "rotation_degrees" in inst:
        print("Has rotation_degrees")
    else:
        print("No rotation_degrees")
    quit()
