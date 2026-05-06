extends SceneTree
func _init():
    var l = OmniLight3D.new()
    print("PROPERTIES:")
    for prop in l.get_property_list():
        if "mask" in prop.name:
            print(prop.name)
    quit()
