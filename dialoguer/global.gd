extends Node

var assets_path: String
var temp_path: String

var output_name: String
var json_path: String
var format: String
var framerate: int = 30

var auto_open_output: bool = false
var auto_cleanup: bool = false

var last_name: String
var last_path: String
var last_type: int

## Opens the provided Folder in the User File Explorer.
func open_folder(folder: String) -> void:
	var output = OS.shell_open(ProjectSettings.globalize_path(Global.assets_path.path_join(folder)))
	if output == OK:
		print("Opening Folder: " + ProjectSettings.globalize_path(Global.assets_path.path_join(folder)))
	else:
		print("Unable to open " + folder + " Folder. Error Code: " + str(output))

## Deletes all Files with spesific endings in the Folder.
func cleanup(folder: String) -> void:
	var dir = DirAccess.open(Global.assets_path.path_join(folder))
	var dir_name = Global.assets_path.path_join(folder)
	var deleted_files: Array
	
	if dir_name == Global.temp_path:
		clean_subfolders()
		if FileAccess.file_exists(Global.temp_path.path_join("palette.png")):
			DirAccess.remove_absolute(Global.temp_path.path_join("palette.png"))
		
	elif dir_name == Global.assets_path.path_join("Output"):
		dir.list_dir_begin()
		var filename = dir.get_next()
		
		while filename != "":
			deleted_files.append(filename)
			dir.remove(filename)
			filename = dir.get_next()
		dir.list_dir_end()
		print_rich("[color=yellow]Removed: ", str(deleted_files), "[/color]")
	
	print(Global.assets_path.path_join(folder) + " has been cleared successfully.")

func clean_subfolders() -> void:
	var deleted_files: Array
	var filename
	
	var dir = DirAccess.open(Global.assets_path.path_join("Temp").path_join("Frames"))
	
	dir.list_dir_begin()
	filename = dir.get_next()
	
	while filename != "":
		deleted_files.append(filename)
		dir.remove(filename)
		filename = dir.get_next()
	dir.list_dir_end()
	
	dir = DirAccess.open(Global.assets_path.path_join("Temp").path_join("Audio"))
	dir.list_dir_begin()
	filename = dir.get_next()
	
	while filename != "":
		deleted_files.append(filename)
		dir.remove(filename)
		filename = dir.get_next()
	dir.list_dir_end()
	
	print_rich("[color=yellow]Removed: ", str(deleted_files), "[/color]")
	

func generate_necessary_folders() -> void:
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents_path == "":
		var home = OS.get_environment("HOME")
		documents_path = home.path_join("Documents")
	print("User Documents Path at: ", documents_path)
	
	var base_path = documents_path.path_join("Dialoguer Assets")
	print("Dialoguer Assets Path at: ", base_path)
	
	Global.assets_path = base_path
	
	var subfolders = [
		"Dialogue Icons",
		"Prefixes",
		"Textbox Textures",
		"Dialogue",
		"Fonts",
		"Temp",
		"Output",
		"Shaders",
		"Audio"
	]
	
	var tempfolders = [
		"Frames",
		"Audio"
	]
	
	var dir = DirAccess.open(documents_path)
	if not dir.dir_exists(base_path):
		dir.make_dir(base_path)
		print("Dialoguer Assets Folder does not exist. Creating Folder at: ", str(base_path))
	
	for folder_name in subfolders:
		var full_path = base_path.path_join(folder_name)
		if not dir.dir_exists(full_path):
			dir.make_dir(full_path)
			print(full_path, " does not exist. Creating Directory...")
	
	print("Directory ready at: ", base_path)
	
	temp_path = base_path.path_join("Temp")
	
	dir = DirAccess.open(temp_path)
	if not dir.dir_exists(temp_path):
		dir.make_dir(temp_path)
		print("Temp Folder does not exist. Creating Folder at: ", str(temp_path))
	
	for folder_name in tempfolders:
		var full_path = temp_path.path_join(folder_name)
		if not dir.dir_exists(full_path):
			dir.make_dir(full_path)
			print(full_path, " does not exist. Creating Directory...")
	
