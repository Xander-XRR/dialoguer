extends Node


var assets_path: String
var temp_path: String

var output_name: String
var json_path: String
var format: String

var auto_open_output: bool = false
var auto_cleanup: bool = false

var last_name: String
var last_path: String
var last_type: int

## Opens the provided Folder in the User File Explorer.
func open_folder(folder: String) -> void:
	var output = OS.shell_open(ProjectSettings.globalize_path(assets_path+"/"+folder))
	if output == OK:
		print("Opening Folder: " + ProjectSettings.globalize_path(assets_path+"/"+folder))
	else:
		print("Unable to open " + folder + " Folder. Error Code: " + str(output))

## Deletes all Files with spesific endings in the Folder.
func cleanup(folder: String) -> void:
	var dir_name = assets_path+"/"+folder
	var deleted_files: Array = []
	
	var dir = Directory.new()
	if dir_name == temp_path:
		clean_subfolders()
		if File.new().file_exists(temp_path+"/palette.png"):
			deleted_files.append("palette.png")
			dir.remove(temp_path+"/palette.png")
		
	elif dir_name == assets_path+"/Output":
		if dir.open(dir_name) == OK:
			dir.list_dir_begin()
			var filename = dir.get_next()
			
			while filename != "":
				if dir.current_is_dir():
					filename = dir.get_next()
					continue
				deleted_files.append(filename)
				dir.remove(filename)
				filename = dir.get_next()
			dir.list_dir_end()
			print("Removed: " + str(deleted_files))
	
	print(dir_name + " has been cleared successfully.")

func clean_subfolders() -> void:
	var deleted_files: Array = []
	var filename
	
	var dir = Directory.new()
	if dir.open(assets_path+"/Temp/Frames") == OK:
		dir.list_dir_begin()
		filename = dir.get_next()
		
		while filename != "":
			if dir.current_is_dir():
				filename = dir.get_next()
				continue
			deleted_files.append(filename)
			dir.remove(filename)
			filename = dir.get_next()
		dir.list_dir_end()
	
	if dir.open(assets_path+"/Temp/Audio") == OK:
		dir.list_dir_begin()
		filename = dir.get_next()
		
		while filename != "":
			if dir.current_is_dir():
				filename = dir.get_next()
				continue
			deleted_files.append(filename)
			dir.remove(filename)
			filename = dir.get_next()
		dir.list_dir_end()
		
	print("Removed: " + str(deleted_files))
	

func generate_necessary_folders() -> void:
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents_path == "":
		var home = OS.get_environment("HOME")
		documents_path = home+"/Documents"
	print("User Documents Path at: ", documents_path)
	
	var base_path = documents_path+"/Dialoguer Assets"
	print("Dialoguer Assets Path at: " + base_path)
	
	assets_path = base_path
	
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
	
	var dir = Directory.new()
	if not dir.dir_exists(base_path):
		dir.make_dir(base_path)
		print("Dialoguer Assets Folder does not exist. Creating Folder at: " + str(base_path))
	
	for folder_name in subfolders:
		var full_path = base_path+"/"+folder_name
		if not dir.dir_exists(full_path):
			dir.make_dir(full_path)
			print(full_path, " does not exist. Creating Directory...")
	
	print("Directory ready at: " + base_path)
	
	temp_path = base_path+"/Temp"
	
	if not dir.dir_exists(temp_path):
		dir.make_dir(temp_path)
		print("Temp Folder does not exist. Creating Folder at: " + str(temp_path))
	
	for folder_name in tempfolders:
		var full_path = temp_path+"/"+folder_name
		if not dir.dir_exists(full_path):
			dir.make_dir(full_path)
			print(full_path + " does not exist. Creating Directory...")
	
