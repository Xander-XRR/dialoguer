extends Control


var text_array: String

@onready var sub_viewport: SubViewport = %SubViewport

@onready var char_timer = %CharacterTimer
@onready var line_timer = %LineTimer
@onready var custom_timer = %CustomTimer

@onready var dialog_icon: Node2D = %DialogIcon
@onready var icon: Sprite2D = %Icon
@onready var textbox: Sprite2D = %Textbox
@onready var text_label: RichTextLabel = %Text
@onready var text_sprite: Sprite2D = %TextSprite

var assets_path = Global.assets_path
var sound = ""

var framecount: int = 0
var recording: bool = false

var ready_to_type: bool = false

var audio_recording: bool = false
var record_effect: AudioEffectRecord

func _ready():
	text_label.text = ""
	text_array = Global.assets_path.path_join("Dialogue").path_join(Global.json_path)
	print("Selected File: " + Global.json_path)
	
	if Global.format == "GIF":
		recording = true
		type_text(text_array)
	elif Global.format == "Image":
		capture_images(text_array)
	elif Global.format == "MP4":
		recording = true
		audio_recording = true
		start_audio_recording()
		type_text(text_array)
	elif Global.format == "Audio":
		audio_recording = true
		start_audio_recording()
		type_text(text_array)

func _process(_delta: float) -> void:
	if ready_to_type == false:
		ready_to_type = true
		return
	if recording:
		var img = sub_viewport.get_viewport().get_texture().get_image()
		img.save_png(Global.temp_path.path_join("Frames") + "/frame%05d.png" % framecount)
		framecount += 1
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		abort()

## Types out the provided text in a typewriter style. Provided Text has to be in a JSON file.
func type_text(given_text: String):
	text_label.text = ""
	for child in %Prefixes.get_children():
		child.visible = false
	visible = true
	var full_text = load_dialog(given_text)
	var current_index = 0
	
	while current_index < full_text.size():
		var current_line = full_text[current_index]
		var line_text = current_line.get("text", "")
		
		text_label.text = line_text.replace("&", "\u200B")
		
		# Reset values
		text_label.visible_characters = 0
		
		var raw_text = strip_bbcode(line_text)
		
			# Load the approptiate Icon, textbox/icon color, etc.
		match_keys(current_line, false)
		
		while text_label.visible_characters < text_label.get_total_character_count():
			#var current_char = raw_text[text_label.visible_characters - 1]
			
			var current_index_char = text_label.visible_characters
			var current_char = ""
			
			if current_index_char < raw_text.length():
				current_char = raw_text[current_index_char]
			
			# Increases the visible characters, then waits the appropriate amount of time
			text_label.visible_characters += current_line.get("amount", 1)
			if typeof(sound) != TYPE_STRING and current_char != "&":
				%AudioStreamPlayer.stop()
				%AudioStreamPlayer.stream = sound
				%AudioStreamPlayer.play()
			char_timer.wait_time = current_line.get("delay", 0.03)
			
			if current_char in [".", "!", "?"]:
				char_timer.wait_time += 0.5
			elif current_char in ",":
				char_timer.wait_time += 0.3
			elif current_char in "&":
				custom_timer.start(current_line.get("custom delay", 0.5))
				await custom_timer.timeout
			
			char_timer.start()
			await char_timer.timeout
		
		current_index += 1
		
		# When the text is done typing, wait for the next input or auto-continue
		if current_index < full_text.size():
			var end_delay = current_line.get("end delay", 1.5)
			if typeof(end_delay) != TYPE_FLOAT:
				print_wrong_type("end delay", "float", type_string(typeof(end_delay)), end_delay)
				end_delay = 1
			elif end_delay <= 0:
				end_delay = 0.001
			await get_tree().create_timer(end_delay).timeout
		else:
			var end_delay = current_line.get("end delay", 1.5)
			if typeof(end_delay) != TYPE_FLOAT:
				print_wrong_type("end delay", "float", type_string(typeof(end_delay)), end_delay)
				end_delay = 1
			elif end_delay <= 0:
				end_delay = 1
			await get_tree().create_timer(end_delay).timeout
			recording = false
			text_label.text = ""
			if audio_recording == true:
				if Global.format != "Audio":
					stop_audio_recording(false)
				else:
					stop_audio_recording(true)
			get_tree().change_scene_to_file("res://Scenes/done.tscn")
	

func capture_images(given_text: String):
	text_label.text = ""
	visible = true
	var full_text = load_dialog(given_text)
	var current_index = 0
	
	while current_index < full_text.size():
		var current_line = full_text[current_index]
		var line_text = current_line.get("text", "")
		
		text_label.text = line_text.replace("&", "\u200B")
		text_label.visible_characters = -1
		
		# Load the approptiate Icon, textbox/icon color, etc.
		match_keys(current_line, true)
		
		current_index += 1
		
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		if current_index < full_text.size():
			var img = sub_viewport.get_viewport().get_texture().get_image()
			img.save_png(assets_path.path_join("Output").path_join(Global.output_name + "%03d.png" % framecount))
			framecount += 1
		else:
			var img = sub_viewport.get_viewport().get_texture().get_image()
			img.save_png(assets_path.path_join("Output").path_join(Global.output_name + "%03d.png" % framecount))
			framecount += 1
			text_label.text = ""
			get_tree().change_scene_to_file("res://Scenes/done.tscn")

## Strips the provided String of any BBCode handlers and returns the raw Text.
func strip_bbcode(bbcode_text: String):
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(bbcode_text, "", true)
	

## Parses the provided JSON file and returns the parsed File.
func load_dialog(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	
	var file_text = file.get_as_text()
	var parsed_text = JSON.parse_string(file_text)
	
	if parsed_text == null:
		return []
	
	if parsed_text is Array:
		return parsed_text
	else:
		return []


func load_external_texture(path: String) -> Texture2D:
	var image := Image.new()
	if path.ends_with(".png"):
		var err := image.load(path)
		if err != OK:
			return null
		var texture := ImageTexture.create_from_image(image)
		return texture
	return null
	


func start_audio_recording() -> void:
	var idx = AudioServer.get_bus_index("Record")
	record_effect = AudioServer.get_bus_effect(idx, 0) as AudioEffectRecord
	record_effect.set_recording_active(true)
	print("Audio Recording Started.")


func stop_audio_recording(audio_only: bool) -> void:
	record_effect.set_recording_active(false)
	var recording_stream = record_effect.get_recording() as AudioStreamWAV
	var save_path: String
	
	if audio_only == true:
		save_path = assets_path.path_join("Output").path_join("audio.wav")
	else:
		save_path = assets_path.path_join("Temp").path_join("Audio").path_join("audio.wav")
	
	var err = recording_stream.save_to_wav(save_path)
	if err == OK:
		print("Audio saved to ", save_path)
	else:
		push_error("Failed to save Audio. Exit Code: %s" % err)


func match_keys(current_line, instant: bool) -> void:
	for key in current_line:
		match key:
			"event":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("event", "String", type_string(typeof(current_line[key])), current_line[key])
				else:
					var file := FileAccess.open(ProjectSettings.globalize_path(assets_path.path_join("Events").path_join(current_line[key])), FileAccess.READ)
					if file == null:
						push_error("Could not open Script File: ", file)
					else:
						var source_code := file.get_as_text()
						file.close()
						
						var new_script := GDScript.new()
						new_script.source_code = source_code
						
						var result := new_script.reload()
						if result != OK:
							push_error("Script failed to compile! Exit Code: ", str(result))
						else:
							var instance = new_script.new()
							if instance.has_method("execute"):
								instance.execute(self)
							else:
								push_error("Script does not contain an 'execute()' method!")
			"font":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("font", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var font_data = current_line[key]
					var font_path = assets_path.path_join("Fonts").path_join(font_data[0])
					var font_file = FontFile.new()
					
					if font_data[0] == "default" or "":
						text_label.remove_theme_font_override("normal_font")
					else:
						font_file.load_dynamic_font(font_path)
						text_label.add_theme_font_override("normal_font", font_file)
					
					if font_data[1] == 0:
						text_label.remove_theme_font_size_override("normal_font_size")
					else:
						text_label.add_theme_font_size_override("normal_font_size", font_data[1])
			"sound":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("sound", "String", type_string(typeof(current_line[key])), current_line[key])
				else:
					if current_line[key] == "" or instant == true:
						sound = ""
					else:
						var audio_path = ProjectSettings.globalize_path(assets_path.path_join("Audio").path_join(current_line[key]))
						if FileAccess.file_exists(audio_path):
							var stream = AudioStreamOggVorbis.load_from_file(audio_path)
							sound = stream
			"shader":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("shader", "String", type_string(typeof(current_line[key])), current_line[key])
				else:
					if (current_line[key] != "") and (current_line[key] != "default"):
						var shader = load(assets_path.path_join("Shaders").path_join(current_line[key])).duplicate()
						if shader is Shader:
							var mat = ShaderMaterial.new()
							mat.shader = shader
							text_sprite.material = mat
						else:
							print_rich("[color=red]Failed to load Shader: ", current_line[key], "[/color]")
					else:
						text_sprite.material = null
			"shader parameters":
				if typeof(current_line[key]) != TYPE_DICTIONARY:
					print_wrong_type("shader", "Dictionary", type_string(typeof(current_line[key])), current_line[key])
				else:
					if text_sprite.material is ShaderMaterial:
						var parameters: Dictionary = current_line[key]
						for uniform in parameters:
							var value = parameters[uniform]
							text_sprite.material.set_shader_parameter(uniform, value)
			"icon":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("icon", "String", type_string(typeof(current_line[key])), current_line[key])
				else:
					if current_line[key] != "" or current_line[key] != "default":
						var texture = load_external_texture(assets_path.path_join("Dialogue Icons").path_join(current_line[key]))
						if texture:
							icon.texture = texture
						else:
							push_error("Coundn't find icon Texture: ", current_line[key])
					else:
						icon.texture = null
			"icon rotation":
				if typeof(current_line[key]) != TYPE_FLOAT:
					print_wrong_type("icon rotation", "float", type_string(typeof(current_line[key])), current_line[key])
				else:
					icon.rotation_degrees = current_line[key]
			"icon offset":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("icon offset", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					icon.offset = Vector2(current_line[key][0], current_line[key][1])
			"icon scale":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("icon scale", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					icon.scale = Vector2(current_line[key][0], current_line[key][1])
			"icon skew":
				if typeof(current_line[key]) != TYPE_FLOAT:
					print_wrong_type("icon skew", "float", type_string(typeof(current_line[key])), current_line[key])
				else:
					icon.skew = deg_to_rad(current_line[key])
			"icon color":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("icon color", "String", type_string(typeof(current_line[key])), current_line[key])
				else:
					if current_line[key] != "":
						icon.self_modulate = current_line[key]
					else:
						icon.self_modulate = "000000"
			"prefix":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var prefixes = current_line[key]
					var index = 0
					for prefix in prefixes:
						var texture = load_external_texture(assets_path.path_join("Prefixes").path_join(prefix)) as Texture2D
						if texture:
							%Prefixes.get_child(index).texture = texture
							if current_line.get("prefix delay") == null or instant == true:
								%Prefixes.get_child(index).visible = true
						elif str(current_line[key][index]) == "":
							%Prefixes.get_child(index).texture = null
						else:
							push_error("Couldn't find prefix Texture ", str(current_line[key][index]))
						index += 1
			"prefix rotation":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix rotation", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var prefix_rotations = current_line[key]
					var index = 0
					for rotations in prefix_rotations:
						%Prefixes.get_child(index).rotation = rotations
						index += 1
			"prefix offset":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix offset", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var prefix_offsets = current_line[key]
					var index = 0
					for offsets in prefix_offsets:
						if offsets == []:
							offsets = [0.0, 0.0]
						%Prefixes.get_child(index).offset = Vector2(offsets[0], offsets[1])
						index += 1
			"prefix scale":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix scale", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var prefix_scales = current_line[key]
					var index = 0
					for scales in prefix_scales:
						if scales == []:
							scales = [1.0, 1.0]
						%Prefixes.get_child(index).scale = Vector2(scales[0], scales[1])
						index += 1
			"prefix skew":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix skew", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var prefix_skews = current_line[key]
					var index = 0
					for skews in prefix_skews:
						%Prefixes.get_child(index).skew = deg_to_rad(skews)
						index += 1
			"prefix color":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix color", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var prefix_colors = current_line[key]
					var index = 0
					for color in prefix_colors:
						if color != "":
							%Prefixes.get_child(index).self_modulate = color
						else:
							%Prefixes.get_child(index).self_modulate = "ffffff"
						index += 1
			"prefix delay":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix delay", "Array", type_string(typeof(current_line[key])), current_line[key])
				else:
					var prefix_delays = current_line[key]
					var index = 0
					for delay in prefix_delays:
						if delay > 0 and instant == false:
							var timer = Timer.new()
							var sprite = %Prefixes.get_child(index)
							timer.one_shot = true
							timer.wait_time = delay
							add_child(timer)
							timer.start()
							
							timer.timeout.connect(_on_timer_timeout.bind(timer, sprite))
						else:
							%Prefixes.get_child(index).visible = true
						index += 1
			"textbox":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("textbox color", "String", type_string(typeof(current_line[key])), current_line[key])
				else:
					if current_line[key] == "default" or "":
						textbox.texture = preload("res://Assets/Textbox Textures/DefaultTextbox.png")
					else:
						var texture = load_external_texture(assets_path.path_join("Textbox Textures").path_join(current_line[key])) as Texture2D
						if texture:
							textbox.texture = texture
						else:
							push_error("Coundn't find textbox Texture: ", current_line[key])
			"textbox color":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("textbox color", "String", type_string(typeof(current_line[key])), current_line[key])
				else:
					if current_line[key] != "":
						textbox.self_modulate = current_line[key]
					else:
						textbox.self_modulate = "000000"


func abort() -> void:
	get_tree().change_scene_to_file("res://Scenes/start.tscn")
	Global.cleanup("Temp")
	print_rich("[color=red]Abort![/color]")


func print_wrong_type(variable: String, exptected_type, receieved_type, receieved_value):
	push_error("'"+variable+"' was given an invalid Value.\nExpected Type: '"+str(exptected_type)+"'.\nReceived Type: '"+str(receieved_type)+"'.\nReceived Value: '"+str(receieved_value)+"'.")


func _on_timer_timeout(timer: Timer, sprite: Sprite2D):
	sprite.visible = true
	timer.queue_free()
