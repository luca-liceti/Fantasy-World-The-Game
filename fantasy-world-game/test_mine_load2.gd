extends SceneTree

func _init():
    var scn = load("res://assets/props/mines/gold_mine_lvl_1_still.glb")
    var inst = scn.instantiate()
    print("Class of root: ", inst.get_class())
    if "rotation_degrees" in inst:
        print("Has rotation_degrees")
    else:
        print("No rotation_degrees")
    quit()
