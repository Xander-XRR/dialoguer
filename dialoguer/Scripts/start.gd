extends Node2D


@export var platform: String

@onready var output_name: LineEdit = $OutputName
@onready var file_path: LineEdit = $FilePath

@onready var start_typing: Button = $StartTyping

@onready var confirmation: ConfirmationDialog = $CleanConfirmationDialog
@onready var info_dialog: AcceptDialog = $InfoDialog
@onready var configurations: Window = $Configurations

@onready var title_shadered: Sprite2D = %TitleShadered


func _ready() -> void:
	Global.generate_necessary_folders()
	
	var original_text = info_dialog.dialog_text
	var replaced_text = original_text.replace("PLATFORM", platform)
	info_dialog.dialog_text = replaced_text
	
	output_name.grab_focus()
	


func removal_prompt():
	confirmation.popup()
	print("Opened dialog: " + confirmation.name)


func _process(_delta: float) -> void:
	if output_name.text == "" or file_path.text == "" or file_path.text.ends_with(".json") == false:
		start_typing.disabled = true
	else:
		start_typing.disabled = false


func _on_start_typing_pressed() -> void:
	Global.output_name = %OutputName.text.strip_edges()
	Global.json_path = %FilePath.text
	
	if FileAccess.file_exists(ProjectSettings.globalize_path(Global.assets_path.path_join("Dialogue").path_join(Global.json_path))):
		print("Getting ready for Scene Change to res://Scenes/textbox.tscn...")
		get_tree().change_scene_to_file("res://Scenes/textbox.tscn")
	else:
		print("JSON File at Path " + Global.json_path + " doesn't exist.")
		%FileFoundntDialog.popup()


func _on_info_pressed() -> void:
	info_dialog.popup()
	print("Opened dialog: " + info_dialog.name)


func _on_close_program_pressed() -> void:
	Global.cleanup("Frames")
	print("Closing Program...")
	get_tree().quit()


func _on_clear_pressed() -> void:
	Global.cleanup("Frames")


func _on_confirmation_dialog_confirmed() -> void:
	Global.cleanup("Frames")
	print("Closing Program...")
	get_tree().quit()


func _on_confirmation_dialog_canceled() -> void:
	print("Closing Program")
	get_tree().quit()


func _on_frames_folder_pressed() -> void:
	Global.open_folder("GIFs")


func _on_config_pressed() -> void:
	configurations.popup()
