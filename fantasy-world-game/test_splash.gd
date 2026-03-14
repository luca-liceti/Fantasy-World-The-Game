extends SceneTree
func _init():
	print("Boot splash image: ", ProjectSettings.get_setting("application/boot_splash/image"))
	print("Boot splash bg_color: ", ProjectSettings.get_setting("application/boot_splash/bg_color"))
	quit()
