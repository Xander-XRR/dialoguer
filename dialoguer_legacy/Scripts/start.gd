extends Node2D


export var platform: String
export var version: String

onready var output_name: LineEdit = $OutputName
onready var file_path: LineEdit = $FilePath
onready var format_options: OptionButton = $FormatOptions

onready var start_typing: Button = $StartTyping

onready var info_dialog: AcceptDialog = $InfoDialog
onready var configurations = $Configurations

onready var title_shadered: Sprite = $TitleShadered
onready var version_label = $Version

onready var file_foundnt_dialog = $FileFoundntDialog


func _ready() -> void:
	Global.generate_necessary_folders()
	
	info_dialog.dialog_text = info_dialog.dialog_text.replace("PLATFORM", platform)
	info_dialog.dialog_text = info_dialog.dialog_text.replace("VERSION", version)
	version_label.text = version_label.text.replace("VERSION", version)
	
	if configurations.load_config("general", "remember_last_name", false) == true:
		output_name.text = Global.last_name
		configurations.remember_last_name.pressed = true
	else:
		configurations.remember_last_name.pressed = false
	
	if configurations.load_config("general", "remember_last_path", false) == true:
		file_path.text = Global.last_path
		configurations.remember_last_path.pressed = true
	else:
		configurations.remember_last_path.pressed = true
	
	if configurations.load_config("general", "remember_last_type", false) == true:
		format_options.selected = Global.last_type
		configurations.remember_last_type.pressed = true
	else:
		configurations.remember_last_type.pressed = false
	
	output_name.grab_focus()
	


func _process(_delta: float) -> void:
	if output_name.text == "" or file_path.text == "" or file_path.text.ends_with(".json") == false:
		start_typing.disabled = true
	else:
		start_typing.disabled = false


func _on_start_typing_pressed() -> void:
	Global.output_name = output_name.text.strip_edges()
	print("Selected Output Name: ", Global.output_name)
	Global.json_path = file_path.text
	print("Selected File Path: ", Global.json_path)
	Global.format = format_options.get_item_text(format_options.selected)
	print("Selected Format: ", Global.format)
	
	if configurations.load_config("general", "remember_last_name", false) == true:
		Global.last_name = output_name.text
	if configurations.load_config("general", "remember_last_path", false) == true:
		Global.last_path = file_path.text
	if configurations.load_config("general", "remember_last_type", false) == true:
		Global.last_type = format_options.selected
	
	configurations.save_config("general", "last_name", output_name.text)
	configurations.save_config("general", "last_path", file_path.text)
	configurations.save_config("general", "last_type", format_options.selected)
	
	if File.new().file_exists(ProjectSettings.globalize_path(Global.assets_path+"/Dialogue/"+Global.json_path)):
		print("Getting ready for Scene Change to res://Scenes/textbox.tscn...")
		get_tree().change_scene("res://Scenes/Textbox.tscn")
	else:
		print("JSON File at Path " + Global.json_path + " doesn't exist.")
		file_foundnt_dialog.popup()
	


func _on_info_pressed() -> void:
	info_dialog.popup()
	info_dialog.rect_position = Vector2(-376, -160)
	print("Opened dialog: " + info_dialog.name)


func _on_close_program_pressed() -> void:
	Global.cleanup("Temp")
	print("Closing Program...")
	get_tree().quit()


func _on_clear_pressed() -> void:
	Global.cleanup("Temp")


func _on_output_folder_pressed() -> void:
	Global.open_folder("Output")


func _on_config_pressed() -> void:
	configurations.popup()
	configurations.rect_position = Vector2(-296, -192)
