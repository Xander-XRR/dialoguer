extends Node2D


@onready var new_process: Button = $NewProcess

@onready var command_output: TextEdit = $CommandOutput
@onready var confirmation: ConfirmationDialog = $ConfirmationDialog

signal file_ready(message: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("file_ready", _on_file_ready)
	
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents_path == "":
		var home = OS.get_environment("HOME")
		documents_path = home.path_join("Documents")
	var base_path = documents_path.path_join("Dialoguer Assets")
	
	Global.assets_path = base_path
	
	var frames = ProjectSettings.globalize_path(Global.assets_path.path_join("Frames"))
	var output
	var gif_path = ProjectSettings.globalize_path(Global.assets_path.path_join("Output"))
	
	await get_tree().process_frame
	
	if Global.format == "GIF":
		output = Global.output_name + ".gif"
		generate_video_file(frames, gif_path, output)
	elif Global.format == "Image":
		command_output.text = "Images Created successfully!"
		print("Images Created successfully!")
	
	if Global.auto_cleanup == true:
		Global.cleanup("Frames")
	
	if Global.auto_open_output == true:
		Global.open_folder("Output")
	
	new_process.grab_focus()
	

func generate_video_file(frames_path: String, gifs_path: String, output_name: String) -> void:
	var palette_command = [
		"-y",
		"-framerate", str(Global.framerate),
		"-i", frames_path.path_join("frame%05d.png"),
		"-vf", '"fps='+str(Global.framerate)+',palettegen"', "palette.png"
	]
	
	OS.execute("ffmpeg", palette_command, [], true)
	
	var command = [
		"-y",
		"-framerate", str(Global.framerate),
		"-i", frames_path.path_join("frame%05d.png"),
		"-i", "palette.png",
		"-lavfi", '"fps='+str(Global.framerate)+',scale=iw:-1:flags=lanczos,paletteuse=dither=bayer:bayer_scale=5"',
		gifs_path.path_join(output_name)
	]
	
	print("Executing ffmpeg Command with arguments: " + str(command))
	
	var result = OS.execute("ffmpeg", command, [], true)
	
	if result == OK:
		print(Global.format + " generated successfully!")
		emit_signal("file_ready", Global.format + " generated successfully!")
	else:
		print(Global.format + " couldn't be generated. Error Code: ", result)
		emit_signal("file_ready",  Global.format + " couldn't be generated. Error Code: [" + str(result) + "]\nMake sure you have ffmpeg installed, or that you're using the right version of this program.")
	


func _on_close_pressed() -> void:
	var dir = DirAccess.open(Global.assets_path.path_join("Frames"))
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if filename.ends_with(".png"):
				dir.list_dir_end()
				confirmation.popup()
				return
			if filename.ends_with(".import"):
				dir.list_dir_end()
				confirmation.popup()
				return
		dir.list_dir_end()
	get_tree().quit()


func _on_clear_pressed() -> void:
	Global.cleanup("Frames")


func _on_confirmation_dialog_canceled() -> void:
	get_tree().quit()


func _on_confirmation_dialog_confirmed() -> void:
	Global.cleanup("Frames")
	get_tree().quit()


func _on_new_process_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/start.tscn")


func _on_open_output_folder_pressed() -> void:
	Global.open_folder("Output")


func _on_file_ready(message: String) -> void:
	%CommandOutput.text = message
