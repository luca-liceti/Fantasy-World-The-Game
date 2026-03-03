@tool
extends EditorScript



## Run this script in the Godot editor to generate the medieval theme resource
## Use Script > Run (Ctrl+Shift+X) in the editor

func _run() -> void:
	print("Generating Medieval Theme...")
	
	var theme := MedievalThemeBuilder.create_theme()
	
	# Ensure directory exists
	var dir := DirAccess.open("res://assets")
	if dir:
		if not dir.dir_exists("themes"):
			dir.make_dir("themes")
	
	# Save the theme
	var path := "res://assets/themes/medieval_theme.tres"
	var err := ResourceSaver.save(theme, path)
	
	if err == OK:
		print("Medieval Theme saved successfully to: ", path)
	else:
		push_error("Failed to save theme: ", err)
