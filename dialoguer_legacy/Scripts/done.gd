extends Node2D


onready var new_process: Button = $NewProcess

onready var command_output: TextEdit = $CommandOutput

signal file_ready(message)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("file_ready", self,  "_on_file_ready")
	
	Global.generate_necessary_folders()
	
	var output: String
	
	yield(get_tree(), "idle_frame")
	
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
		OS.execute("ffmpeg", ["-i", Global.assets_path+"/Output/audio.wav", "-filter:a", '"volume=5.0"', Global.assets_path+"Output/audio_loud.wav"])
		print("Generated Increased Volume File!")
	
	if Global.auto_cleanup == true:
		Global.cleanup("Temp")
	
	if Global.auto_open_output == true:
		Global.open_folder("Output")
	
	new_process.grab_focus()
	

func generate_gif_file(output_name: String) -> void:
	var frames_path: String = ProjectSettings.globalize_path(Global.temp_path+"/Frames")
	var palette_path: String = ProjectSettings.globalize_path(Global.temp_path+"/palette.png")
	var output_path: String = ProjectSettings.globalize_path(Global.assets_path+"/Output")
	
	var palette_command = [
		"-y",
		"-framerate", 30,
		"-i", frames_path+"/frame%05d.png",
		"-vf", '"fps=30,palettegen"', palette_path
	]
	
	OS.execute("ffmpeg", palette_command, true)
	
	var command = [
		"-y",
		"-framerate", 30,
		"-i", frames_path+"/frame%05d.png",
		"-i", palette_path,
		"-lavfi", '"fps=30,scale=iw:-1:flags=lanczos,paletteuse=dither=bayer:bayer_scale=5"',
		output_path+"/"+output_name
	]
	
	print("Executing ffmpeg Command with arguments: " + str(command))
	
	var result = OS.execute("ffmpeg", command, true)
	
	if result == OK:
		print(Global.format + " generated successfully!")
		emit_signal("file_ready", Global.format + " generated successfully!")
	else:
		print(Global.format + " couldn't be generated. Error Code: ", result)
		emit_signal("file_ready",  Global.format+" couldn't be generated. Error Code: ["+str(result)+"]\nMake sure you have ffmpeg installed, or that you're using the right version of this program.")
	


func generate_video_file(output_name: String) -> void:
	var frames_path: String = ProjectSettings.globalize_path(Global.temp_path+"/Frames")
	var audio_path: String = ProjectSettings.globalize_path(Global.temp_path+"/Audio")
	var output_path: String = ProjectSettings.globalize_path(Global.assets_path+"/Output")
	
	var command = [
		"-framerate", "30",
		"-i", frames_path+"/frame%05d.png",
		"-i", audio_path+"/audio.wav",
		"-c:v", "libx264",
		"-c:a", "aac",
		"-pix_fmt", "yuv420p",
		"-movflags", "+faststart",
		output_path+"/"+output_name
	]
	
	if File.new().file_exists(output_path+"/"+output_name):
		Directory.new().remove(output_path+"/"+output_name)
	
	print("Executing ffmpeg Command with arguments: " + str(command))
	var result = OS.execute("ffmpeg", command, true)
	
	if result == OK:
		print(Global.format + " generated successfully!")
		emit_signal("file_ready", Global.format + " generated successfully!")
	else:
		print(Global.format + " couldn't be generated. Error Code: ", result)
		emit_signal("file_ready",  Global.format+" '"+output_name+"' couldn't be generated. Error Code: ["+str(result)+"]\nMake sure you have ffmpeg installed, or that you're using the right version of this program.")
	


func _on_close_pressed() -> void:
	Global.cleanup("Temp")
	get_tree().quit()


func _on_clear_pressed() -> void:
	Global.cleanup("Temp")


func _on_new_process_pressed() -> void:
	get_tree().change_scene("res://Scenes/Start.tscn")


func _on_open_output_folder_pressed() -> void:
	Global.open_folder("Output")


func _on_file_ready(message: String) -> void:
	command_output.text = message
