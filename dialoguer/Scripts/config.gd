extends Window


@export var start_node: Node2D

@onready var auto_open_output_folder: CheckBox = %AutoOpenOutputFolder
@onready var auto_cleanup: CheckBox = %AutoCleanup

@onready var disable_title_shaders: CheckBox = %DisableTitleShaders

@onready var title_shadered: Sprite2D = %TitleShadered

@onready var remember_last_name: CheckBox = %RememberLastName
@onready var remember_last_path: CheckBox = %RememberLastPath
@onready var remember_last_type: CheckBox = %RememberLastType

var title_shader_material = ShaderMaterial.new()
const TITLE_SHADER = preload("res://Scripts/title.gdshader")

func _ready() -> void:
	title_shader_material.shader = TITLE_SHADER
	if FileAccess.file_exists("user://settings.cfg"):
		if load_config("graphics", "title_shader_enabled", true) == false:
			title_shadered.material = null
			disable_title_shaders.button_pressed = true
			print("Title Shader Disabled")
		else:
			title_shadered.material = title_shader_material
			disable_title_shaders.button_pressed = false
			print("Title Shader Enabled")
		
		if load_config("general", "auto_open_output", false) == true:
			Global.auto_open_output = true
			auto_open_output_folder.button_pressed = true
			print("Auto Open Output Folder: true")
		else:
			Global.auto_open_output = false
			auto_open_output_folder.button_pressed = false
			print("Auto Open Output Folder: false")
		
		if load_config("general", "auto_cleanup", false) == true:
			Global.auto_cleanup = true
			auto_cleanup.button_pressed = true
			print("Auto Cleanup Frames: true")
		else:
			Global.auto_cleanup = false
			auto_cleanup.button_pressed = false
			print("Auto Cleanup Frames: false")
		
		Global.last_name = load_config("general", "last_name", "")
		Global.last_path = load_config("general", "last_path", "")
		Global.last_type = load_config("general", "last_type", 0)
		
	
	else:
		title_shadered.material = title_shader_material
		print("Title Shader Enabled")
	
	auto_open_output_folder.toggled.connect(_on_auto_open_output_folder_toggled)
	auto_cleanup.toggled.connect(_on_auto_cleanup_toggled)
	
	

func save_config(section: String, key: String, value):
	var config = ConfigFile.new()
	var path = "user://settings.cfg"
	
	if FileAccess.file_exists(path):
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

func _on_exit_pressed() -> void:
	hide()


func _on_close_requested() -> void:
	hide()


func _on_disable_title_shaders_toggled(toggled_on: bool) -> void:
	await get_tree().process_frame
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
	%OutputDeleteConfirmation.popup()


func _on_delete_assets_folders_pressed() -> void:
	%AssetsDeleteConfirmation.popup()


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
