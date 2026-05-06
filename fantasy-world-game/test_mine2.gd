extends SceneTree

func _init():
    var n = Node3D.new()
    n.rotation_degrees.y = 180
    print(n.rotation_degrees)
    quit()
