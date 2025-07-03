extends Node2D


@onready var new_process: Button = $NewProcess

@onready var command_output: TextEdit = $CommandOutput
@onready var confirmation: ConfirmationDialog = $ConfirmationDialog

signal file_ready(message: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("file_ready", _on_file_ready)
	
	Global.generate_necessary_folders()
	
	var output: String
	
	await get_tree().process_frame
	
	if Global.format == "Image":
		command_output.text = "Images Created successfully!"
		print("Images Created successfully!")
	elif Global.format == "GIF":
		output = Global.output_name + ".gif"
		generate_gif_file(output)
	elif Global.format == "MP4":
		output = Global.output_name + ".mp4"
		generate_video_file(output)
	elif Global.format == "Audio":
		OS.execute("ffmpeg", ["-i", Global.assets_path.path_join("Output").path_join("audio.wav"), "-filter:a", '"volume=5.0"', Global.assets_path.path_join("Output").path_join("audio_loud.wav")])
		print("Generated Increased Volume File!")
	
	if Global.auto_cleanup == true:
		Global.cleanup("Temp")
	
	if Global.auto_open_output == true:
		Global.open_folder("Output")
	
	new_process.grab_focus()
	

func generate_gif_file(output_name: String) -> void:
	var frames_path: String = ProjectSettings.globalize_path(Global.temp_path.path_join("Frames"))
	var palette_path: String = ProjectSettings.globalize_path(Global.temp_path.path_join("palette.png"))
	var output_path: String = ProjectSettings.globalize_path(Global.assets_path.path_join("Output"))
	
	var palette_command = [
		"-y",
		"-framerate", str(Global.framerate),
		"-i", frames_path.path_join("frame%05d.png"),
		"-vf", '"fps='+str(Global.framerate)+',palettegen"', palette_path
	]
	
	OS.execute("ffmpeg", palette_command, [], true)
	
	var command = [
		"-y",
		"-framerate", str(Global.framerate),
		"-i", frames_path.path_join("frame%05d.png"),
		"-i", palette_path,
		"-lavfi", '"fps='+str(Global.framerate)+',scale=iw:-1:flags=lanczos,paletteuse=dither=bayer:bayer_scale=5"',
		output_path.path_join(output_name)
	]
	
	print("Executing ffmpeg Command with arguments: " + str(command))
	
	var result = OS.execute("ffmpeg", command, [], true)
	
	if result == OK:
		print(Global.format + " generated successfully!")
		emit_signal("file_ready", Global.format + " generated successfully!")
	else:
		print(Global.format + " couldn't be generated. Error Code: ", result)
		emit_signal("file_ready",  Global.format+" couldn't be generated. Error Code: ["+str(result)+"]\nMake sure you have ffmpeg installed, or that you're using the right version of this program.")
	


func generate_video_file(output_name: String) -> void:
	var frames_path: String = ProjectSettings.globalize_path(Global.temp_path.path_join("Frames"))
	var audio_path: String = ProjectSettings.globalize_path(Global.temp_path.path_join("Audio"))
	var output_path: String = ProjectSettings.globalize_path(Global.assets_path.path_join("Output"))
	
	var command = [
		"-framerate", "30",
		"-i", frames_path.path_join("frame%05d.png"),
		"-i", audio_path.path_join("audio.wav"),
		"-c:v", "libx264",
		"-c:a", "aac",
		"-pix_fmt", "yuv420p",
		"-movflags", "+faststart",
		output_path.path_join(output_name)
	]
	
	if FileAccess.file_exists(output_path.path_join(output_name)):
		DirAccess.remove_absolute(output_path.path_join(output_name))
	
	print("Executing ffmpeg Command with arguments: " + str(command))
	var result = OS.execute("ffmpeg", command, [], true)
	
	if result == OK:
		print(Global.format + " generated successfully!")
		emit_signal("file_ready", Global.format + " generated successfully!")
	else:
		print(Global.format + " couldn't be generated. Error Code: ", result)
		emit_signal("file_ready",  Global.format+" couldn't be generated. Error Code: ["+str(result)+"]\nMake sure you have ffmpeg installed, or that you're using the right version of this program.")
	


func _on_close_pressed() -> void:
	Global.cleanup("Temp")
	get_tree().quit()


func _on_clear_pressed() -> void:
	Global.cleanup("Temp")


func _on_new_process_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/start.tscn")


func _on_open_output_folder_pressed() -> void:
	Global.open_folder("Output")


func _on_file_ready(message: String) -> void:
	%CommandOutput.text = message
