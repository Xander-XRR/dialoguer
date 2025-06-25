extends Window


@export var start_node: Node2D

@onready var auto_open_gi_fs_folder: CheckBox = %AutoOpenGIFsFolder
@onready var auto_cleanup: CheckBox = %AutoCleanup

@onready var disable_title_shaders: CheckBox = %DisableTitleShaders

@onready var title_shadered: Sprite2D = %TitleShadered

var title_shader_material = ShaderMaterial.new()
const TITLE_SHADER = preload("res://Scripts/title.gdshader")

func _ready() -> void:
	title_shader_material.shader = TITLE_SHADER
	
	if FileAccess.file_exists("user://settings.cfg"):
		if _load_config("graphics", "title_shader_enabled", true) == false:
			title_shadered.material = null
			disable_title_shaders.button_pressed = true
			print("Title Shader Disabled")
		else:
			title_shadered.material = title_shader_material
			disable_title_shaders.button_pressed = false
			print("Title Shader Enabled")
		
		if _load_config("general", "auto_cleanup", false) == true:
			Global.auto_cleanup = true
			auto_cleanup.button_pressed = true
		else:
			Global.auto_cleanup = false
			auto_cleanup.button_pressed = false
		
	else:
		title_shadered.material = title_shader_material
		print("Title Shader Enabled")

func _save_config(section: String, key: String, value):
	var config = ConfigFile.new()
	config.set_value(section, key, value)
	config.save("user://settings.cfg")

func _load_config(section: String, key: String, default):
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		return config.get_value(section, key, default)
	else:
		return default

func _on_exit_pressed() -> void:
	hide()


func _on_close_requested() -> void:
	hide()


func _on_auto_open_gi_fs_folder_toggled(toggled_on: bool) -> void:
	await get_tree().process_frame
	Global.auto_open_gifs = toggled_on
	print("Open GIFs Folder when done: " + str(toggled_on))


func _on_disable_title_shaders_toggled(toggled_on: bool) -> void:
	await get_tree().process_frame
	if toggled_on == true:
		title_shadered.material = null
		_save_config("graphics", "title_shader_enabled", false)
		print("Title Shader Disabled")
	else:
		title_shadered.material = title_shader_material
		_save_config("graphics", "title_shader_enabled", true)
		print("Title Shader Enabled")


func _on_auto_cleanup_toggled(toggled_on: bool) -> void:
	await get_tree().process_frame
	Global.auto_cleanup = toggled_on
	print("Cleanup Frames Folder when done: " + str(toggled_on))
	_save_config("general", "auto_cleanup", toggled_on)


func _on_delete_gi_fs_pressed() -> void:
	%GIFDeleteConfirmation.popup()


func _on_delete_assets_folders_pressed() -> void:
	%AssetsDeleteConfirmation.popup()
