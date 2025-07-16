extends Node


onready var start_node = get_parent()

onready var auto_open_output_folder = $TabContainer/General/VBoxContainer/AutoOpenOutputFolder
onready var auto_cleanup = $TabContainer/General/VBoxContainer/AutoCleanup

onready var disable_title_shaders = $"TabContainer/Audio-Visual/VBoxContainer/DisableTitleShaders"

onready var title_shadered: Sprite = get_parent().get_child(14)

onready var remember_last_name = $TabContainer/General/VBoxContainer/RememberLastName
onready var remember_last_path = $TabContainer/General/VBoxContainer/RememberLastPath
onready var remember_last_type = $TabContainer/General/VBoxContainer/RememberLastType

onready var output_delete_confirmation: ConfirmationDialog = $OutputDeleteConfirmation
onready var assets_delete_confirmation: ConfirmationDialog = $AssetsDeleteConfirmation

var title_shader_material = ShaderMaterial.new()
const TITLE_SHADER = preload("res://Scripts/title.gdshader")

func _ready() -> void:
	title_shader_material.shader = TITLE_SHADER
	if File.new().file_exists("user://settings.cfg"):
		if title_shadered:
			if load_config("graphics", "title_shader_enabled", true) == false:
				title_shadered.material = null
				disable_title_shaders.pressed = true
				print("Title Shader Disabled")
			else:
				title_shadered.material = title_shader_material
				disable_title_shaders.pressed = false
				print("Title Shader Enabled")
		
		if load_config("general", "auto_open_output", false) == true:
			Global.auto_open_output = true
			auto_open_output_folder.pressed = true
			print("Auto Open Output Folder: true")
		else:
			Global.auto_open_output = false
			auto_open_output_folder.pressed = false
			print("Auto Open Output Folder: false")
		
		if load_config("general", "auto_cleanup", false) == true:
			Global.auto_cleanup = true
			auto_cleanup.pressed = true
			print("Auto Cleanup Frames: true")
		else:
			Global.auto_cleanup = false
			auto_cleanup.pressed = false
			print("Auto Cleanup Frames: false")
		
		Global.last_name = load_config("general", "last_name", "")
		Global.last_path = load_config("general", "last_path", "")
		Global.last_type = load_config("general", "last_type", 0)
		
	
	else:
		title_shadered.material = title_shader_material
		print("Title Shader Enabled")
	
	auto_open_output_folder.connect("toggled", self, "_on_auto_open_output_folder_toggled")
	auto_cleanup.connect("toggled", self, "_on_auto_cleanup_toggled")
	
	

func save_config(section: String, key: String, value):
	var config = ConfigFile.new()
	var path = "user://settings.cfg"
	
	if File.new().file_exists(path):
		config.load(path)
	
	config.set_value(section, key, value)
	config.save("user://settings.cfg")
	print("Save Config: Section: " + section + ", Key: " + key + ", Value: " + str(value))

func load_config(section: String, key: String, default):
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		print("Load Config:\nSection: "+section+"\nKey: "+key+"\nValue: "+str(config.get_value(section, key, null)))
		return config.get_value(section, key, default)
	else:
		return default


func _on_close_requested() -> void:
	pass # Hide()


func _on_disable_title_shaders_toggled(toggled_on: bool) -> void:
	yield(get_tree(), "idle_frame")
	if toggled_on == true:
		title_shadered.material = null
		save_config("graphics", "title_shader_enabled", false)
		print("Title Shader Disabled")
	else:
		title_shadered.material = title_shader_material
		save_config("graphics", "title_shader_enabled", true)
		print("Title Shader Enabled")


func _on_auto_open_output_folder_toggled(toggled_on: bool) -> void:
	Global.auto_open_output = toggled_on
	save_config("general", "auto_open_output", toggled_on)
	print("Open Output Folder when done: " + str(toggled_on))


func _on_auto_cleanup_toggled(toggled_on: bool) -> void:
	Global.auto_cleanup = toggled_on
	save_config("general", "auto_cleanup", toggled_on)
	print("Cleanup Frames Folder when done: " + str(toggled_on))


func _on_delete_output_pressed() -> void:
	output_delete_confirmation.popup()


func _on_delete_assets_folders_pressed() -> void:
	assets_delete_confirmation.popup()


func _on_remember_last_name_toggled(toggled_on: bool) -> void:
	save_config("general", "remember_last_name", toggled_on)
	save_config("general", "last_name", start_node.output_name.text)
	print("Remember last used Name: " + str(toggled_on))


func _on_remember_last_path_toggled(toggled_on: bool) -> void:
	save_config("general", "remember_last_path", toggled_on)
	save_config("general", "last_path", start_node.file_path.text)
	print("Remember last used Path: " + str(toggled_on))


func _on_remember_last_type_toggled(toggled_on: bool) -> void:
	save_config("general", "remember_last_type", toggled_on)
	save_config("general", "last_type", start_node.format_options.selected)
	print("Remember last used Type: " + str(toggled_on))


func _on_window_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if !output_delete_confirmation.visible or !assets_delete_confirmation.visible:
			pass # Hide()
