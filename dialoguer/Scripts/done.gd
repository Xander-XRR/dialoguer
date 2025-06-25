extends Node2D


@onready var command_output: TextEdit = $CommandOutput
@onready var confirmation: ConfirmationDialog = $ConfirmationDialog

signal gif_ready(message: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("gif_ready", _on_gif_ready)
	
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents_path == "":
		var home = OS.get_environment("HOME")
		documents_path = home.path_join("Documents")
	var base_path = documents_path.path_join("Dialoguer Assets")
	
	Global.assets_path = base_path
	
	var frames = ProjectSettings.globalize_path(Global.assets_path.path_join("Frames"))
	var output = Global.output_name + ".gif"
	var gif_path = ProjectSettings.globalize_path(Global.assets_path.path_join("GIFs"))
	
	await get_tree().process_frame
	generate_gif(frames, gif_path, output)
	
	if Global.auto_cleanup == true:
		Global.cleanup("Frames")
	

func generate_gif(frames_path: String, gifs_path: String, output_name: String) -> void:
	var command = [
		"-y",
		"-framerate", "30",
		"-i", frames_path.path_join("frame%05d.png"),
		"-vf", "scale=iw:-1:flags=lanczos",
		gifs_path.path_join(output_name)
	]
	
	print("Executing ffmpeg Command with arguments: " + str(command))
	
	var result = OS.execute("ffmpeg", command, [])
	
	if result == OK:
		print("GIF generated successfully!")
		emit_signal("gif_ready", "GIF generated successfully!")
	else:
		print("GIF couldn't be generated. Error Code: ", result)
		emit_signal("gif_ready", "GIF couldn't be generated. Error Code: [" + str(result) + "]\nMake sure you have ffmpeg installed, or that you're using the right version of this program.")
	


func _on_clear_pressed() -> void:
	Global.cleanup("Frames")


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


func _on_confirmation_dialog_canceled() -> void:
	get_tree().quit()


func _on_confirmation_dialog_confirmed() -> void:
	Global.cleanup("Frames")
	get_tree().quit()


func _on_new_process_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/start.tscn")


func _on_open_frames_pressed() -> void:
	Global.open_folder("GIFs")


func _on_gif_ready(message: String) -> void:
	%CommandOutput.text = message
