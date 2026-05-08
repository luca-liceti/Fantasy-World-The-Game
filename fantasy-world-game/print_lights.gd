extends SceneTree

func _init():
    var main_scene = load("res://scenes/main.tscn")
    if not main_scene:
        print("Could not load main scene.")
        quit()
        return
        
    var main_node = main_scene.instantiate()
    print("Main scene instantiated.")
    
    # We need to call the setup functions. They might be called in _ready, but we can't easily trigger the whole game.
    # Actually, we can't easily run the game loop.
    quit()
