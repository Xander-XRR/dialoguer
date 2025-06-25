extends Node

var assets_path: String
var output_name: String
var json_path: String

var auto_open_gifs: bool
var auto_cleanup: bool


## Opens the provided Folder in the User File Explorer.
func open_folder(folder: String):
	var output = OS.shell_open(ProjectSettings.globalize_path(Global.assets_path.path_join(folder)))
	if output == OK:
		print("Opening Folder: " + ProjectSettings.globalize_path(Global.assets_path.path_join(folder)))
	else:
		print("Unable to open GIFs Folder. Error Code: " + str(output))

## Deletes all Files with spesific endings in the Folder. Currently supports "Frames" and "GIFs".
func cleanup(folder: String):
	var dir = DirAccess.open(Global.assets_path.path_join(folder))
	var dir_name = Global.assets_path.path_join(folder)
	
	if dir_name == Global.assets_path.path_join("Frames"):
		dir.list_dir_begin()
		var filename = dir.get_next()
		
		while filename != "":
			if filename.ends_with(".png"):
				dir.remove(filename)
				print("Removed: " + filename)
				
			if filename.ends_with(".import"):
				dir.remove(filename)
				print("Removed: " + filename)
				
			filename = dir.get_next()
		dir.list_dir_end()
		
	elif dir_name == Global.assets_path.path_join("GIFs"):
		dir.list_dir_begin()
		var filename = dir.get_next()
		
		while filename != "":
			if filename.ends_with(".gif"):
				dir.remove(filename)
				print("Removed: " + filename)
				
			filename = dir.get_next()
		dir.list_dir_end()
	
	print(Global.assets_path.path_join(folder) + " has been cleared successfully.")

func generate_necessary_folders():
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents_path == "":
		var home = OS.get_environment("HOME")
		documents_path = home.path_join("Documents")
	print("User Documents Path at: " + documents_path)
	
	var base_path = documents_path.path_join("Dialoguer Assets")
	print("Dialoguer Assets Path at: " + base_path)
	
	Global.assets_path = base_path
	
	var subfolders = [
		"Dialogue Icons",
		"Prefixes",
		"Textbox Textures",
		"Dialogue",
		"Fonts",
		"Frames",
		"GIFs"
	]
	
	var dir = DirAccess.open(documents_path)
	if not dir.dir_exists(base_path):
		dir.make_dir(base_path)
		print("Dialoguer Assets Folder does not exist. Creating Folder at: " + str(base_path))
	
	for folder_name in subfolders:
		var full_path = base_path.path_join(folder_name)
		if not dir.dir_exists(full_path):
			dir.make_dir(full_path)
			print(full_path + " does not exist. Creating Directory...")
	
	print("Directory ready at: " + base_path + ". Everythings gone well!")
	
