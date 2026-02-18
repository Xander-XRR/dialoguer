extends Control


var text_array: String

onready var sub_viewport = $ViewportContainer/SubViewport

onready var char_timer = $ViewportContainer/SubViewport/CharacterTimer
onready var line_timer = $ViewportContainer/SubViewport/LineTimer
onready var custom_timer = $ViewportContainer/SubViewport/CustomTimer

onready var dialog_icon = $ViewportContainer/SubViewport/DialogIcon
onready var icon = $ViewportContainer/SubViewport/DialogIcon/Icon
onready var textbox = $ViewportContainer/SubViewport/Textbox
onready var text_label = $ViewportContainer2/Viewport2/Text
onready var text_sprite = $ViewportContainer/SubViewport/TextSprite
onready var prefixes_node = $ViewportContainer/SubViewport/Prefixes

onready var audio_stream_player = $ViewportContainer/SubViewport/AudioStreamPlayer

var assets_path = Global.assets_path
var sound = ""

var framecount: int = 0
var recording: bool = false

var ready_to_type: bool = false

var audio_recording: bool = false
var record_effect: AudioEffectRecord

var timers_map: Dictionary = {}

func _ready():
	text_label.text = ""
	text_array = Global.assets_path+"/Dialogue/"+Global.json_path
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
		var img = sub_viewport.get_texture().get_data()
		img.flip_y()
		img.lock()
		img.unlock()
		img.save_png(Global.temp_path+"/Frames/frame%05d.png" % framecount)
		framecount += 1
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		abort()

## Types out the provided text in a typewriter style. Provided Text has to be in a JSON file.
func type_text(given_text: String):
	text_label.text = ""
	
	for child in prefixes_node.get_children():
		child.visible = false
	visible = true
	
	var full_text = load_dialog(given_text)
	var current_index = 0
	
	while current_index < full_text.size():
		var current_line = full_text[current_index]
		var line_text = current_line.get("text", "")
		
		text_label.text = line_text.replace("&", "\u200B")
		
		# Reset values
		text_label.visible_characters = -1
		
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
				audio_stream_player.stop()
				audio_stream_player.stream = sound
				audio_stream_player.play()
			char_timer.wait_time = current_line.get("delay", 0.03)
			
			if current_char in [".", "!", "?"]:
				char_timer.wait_time += 0.5
			elif current_char in ",":
				char_timer.wait_time += 0.3
			elif current_char in "&":
				custom_timer.start(current_line.get("custom delay", 0.5))
				yield(custom_timer, "timeout")
			
			char_timer.start()
			yield(char_timer, "timeout")
		
		current_index += 1
		
		# When the text is done typing, wait for the next input or auto-continue
		if current_index < full_text.size():
			var end_delay = current_line.get("end delay", 1.5)
			if typeof(end_delay) != TYPE_REAL:
				print_wrong_type("end delay", "float", typeof(end_delay), end_delay)
				end_delay = 1
			elif end_delay <= 0:
				end_delay = 0.001
			yield(self, get_tree().create_timer(end_delay).timeout)
		else:
			var end_delay = current_line.get("end delay", 1.5)
			if typeof(end_delay) != TYPE_REAL:
				print_wrong_type("end delay", "float", typeof(end_delay), end_delay)
				end_delay = 1
			elif end_delay <= 0:
				end_delay = 1
			yield(get_tree().create_timer(end_delay), "timeout")
			recording = false
			text_label.text = ""
			if audio_recording == true:
				if Global.format != "Audio":
					stop_audio_recording(false)
				else:
					stop_audio_recording(true)
			get_tree().change_scene("res://Scenes/Done.tscn")
	

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
		
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		
		if current_index < full_text.size():
			var img = sub_viewport.get_texture().get_data()
			img.flip_y()
			img.lock()
			img.unlock()
			img.save_png(assets_path+"/Output/"+Global.output_name + "%03d.png" % framecount)
			framecount += 1
		else:
			var img = sub_viewport.get_texture().get_data()
			img.flip_y()
			img.lock()
			img.unlock()
			img.save_png(assets_path+"/Output/"+Global.output_name + "%03d.png" % framecount)
			framecount += 1
			text_label.text = ""
			get_tree().change_scene("res://Scenes/Done.tscn")

## Strips the provided String of any BBCode handlers and returns the raw Text.
func strip_bbcode(bbcode_text: String):
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(bbcode_text, "", true)
	

## Parses the provided JSON file and returns the parsed File.
func load_dialog(path: String) -> Array:
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		var file_text = file.get_as_text()
		file.close()
		
		var json = JSON.parse(file_text)
		if json.error == OK:
			var parsed_text = json.result
			
			if parsed_text == null:
				return []
			
			if parsed_text is Array:
				return parsed_text
			
			else:
				return []
		else:
			print("JSON parse error: " + json.error_string)
			return []
	else:
		print("File doesn't exist: " + path)
		return []


func load_external_texture(path: String) -> ImageTexture:
	var image := Image.new()
	if path.ends_with(".png"):
		var err := image.load(path)
		
		if err != OK:
			push_error("Error loading texture at "+path+". Exit Code: "+str(err))
			return null
		
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		
		print("Found texture at "+path+": "+str(texture))
		return texture
	
	push_error("Path doesn't end with .png: "+path)
	return null
	


func load_external_ogg(path: String) -> AudioStream:
	var file = File.new()
	
	if file.file_exists(path):
		var err = file.open(path, File.READ)
		if err != OK:
			push_error("Error loading OGG at "+path+". Exit Code: "+str(err))
			return null
		
		var data = file.get_buffer(file.get_len())
		file.close()
		
		var audio = AudioStreamOGGVorbis.new()
		audio.data = data
		print("Found OGG File at "+path+": "+str(audio))
		return audio
	else:
		push_error("Audio File doesn't exist: "+path)
		return null
	


func start_audio_recording() -> void:
	var idx = AudioServer.get_bus_index("Record")
	record_effect = AudioServer.get_bus_effect(idx, 0) as AudioEffectRecord
	record_effect.set_recording_active(true)
	print("Audio Recording Started...")


func stop_audio_recording(audio_only: bool) -> void:
	record_effect.set_recording_active(false)
	var recording_stream = record_effect.get_recording()
	var save_path: String
	
	if audio_only == true:
		save_path = assets_path+"/Output/audio.wav"
	else:
		save_path = assets_path+"/Temp/Audio/audio.wav"
	
	var err = recording_stream.save_to_wav(save_path)
	if err == OK:
		print("Audio saved to ", save_path)
	else:
		push_error("Failed to save Audio. Exit Code: %s" % err)


func match_keys(current_line, instant: bool) -> void:
	print("Current line: "+str(current_line))
	for key in current_line:
		match key:
			"event":
				push_error("Events aren't and may never be implimented due to limitations with Godot 3.6.1. Sorry!")
			"font":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("font", "Array", typeof(current_line[key]), current_line[key])
				else:
					var font_data = current_line[key]
					var font_path = ProjectSettings.globalize_path(assets_path + "/Fonts/" + font_data[0])
					if font_data[0] == "default" or font_data[0] == "":
						text_label.remove_font("font")
					else:
						var dyn_font = DynamicFont.new()
						dyn_font.font_data = load(font_path)
						dyn_font.size = font_data[1]
						text_label.add_font_override("normal_font", dyn_font)

			"sound":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("sound", "String", typeof(current_line[key]), current_line[key])
				else:
					if current_line[key] == "" or instant == true:
						sound = null
					else:
						var audio_path = ProjectSettings.globalize_path(assets_path + "/Audio/" + current_line[key])
						if File.new().file_exists(audio_path):
							sound = load_external_ogg(audio_path)

			"shader":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("shader", "String", typeof(current_line[key]), current_line[key])
				else:
					if current_line[key] != "" and current_line[key] != "default":
						var shader = load(assets_path + "/Shaders/" + current_line[key]).duplicate()
						if shader is Shader:
							var mat = ShaderMaterial.new()
							mat.shader = shader
							text_sprite.material = mat
						else:
							push_error("Failed to load Shader: " + current_line[key])
					else:
						text_sprite.material = null

			"shader parameters":
				if typeof(current_line[key]) != TYPE_DICTIONARY:
					print_wrong_type("shader", "Dictionary", typeof(current_line[key]), current_line[key])
				else:
					if text_sprite.material is ShaderMaterial:
						var parameters = current_line[key]
						for uniform in parameters:
							var value = parameters[uniform]
							text_sprite.material.set_shader_param(uniform, value)
			"icon":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("icon", "String", typeof(current_line[key]), current_line[key])
				else:
					if current_line[key] != "" or current_line[key] != "default":
						var texture = load_external_texture(assets_path+"/Dialogue Icons/"+current_line[key])
						if texture:
							icon.texture = texture
						else:
							push_error("Coundn't find icon Texture: " + current_line[key])
					else:
						icon.texture = null
			"icon rotation":
				if typeof(current_line[key]) != TYPE_REAL:
					print_wrong_type("icon rotation", "float", typeof(current_line[key]), current_line[key])
				else:
					icon.rotation_degrees = current_line[key]
			"icon offset":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("icon offset", "Array", typeof(current_line[key]), current_line[key])
				else:
					icon.offset = Vector2(current_line[key][0], current_line[key][1])
			"icon scale":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("icon scale", "Array", typeof(current_line[key]), current_line[key])
				else:
					icon.scale = Vector2(current_line[key][0], current_line[key][1])
			"icon skew":
				push_error("Icon Skew is not supported in Godot 3.6.1. Sorry!")
			"icon color":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("icon color", "String", typeof(current_line[key]), current_line[key])
				else:
					if current_line[key] != "":
						icon.self_modulate = Color(current_line[key])
					else:
						icon.self_modulate = Color("ffffff")
			"prefix":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix", "Array", typeof(current_line[key]), current_line[key])
				else:
					var prefixes = current_line[key]
					var index = 0
					for prefix in prefixes:
						if prefix == "":
							continue
						var texture = load_external_texture(assets_path+"/Prefixes/"+prefix)
						if texture:
							prefixes_node.get_child(index).texture = texture
							if current_line.get("prefix delay") == null or instant == true:
								prefixes_node.get_child(index).visible = true
						elif str(current_line[key][index]) == "":
							prefixes_node.get_child(index).texture = null
						else:
							push_error("Couldn't find prefix Texture " + str(current_line[key][index]))
						index += 1
			"prefix rotation":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix rotation", "Array", typeof(current_line[key]), current_line[key])
				else:
					var prefix_rotations = current_line[key]
					var index = 0
					for rotations in prefix_rotations:
						prefixes_node.get_child(index).rotation = rotations
						index += 1
			"prefix offset":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix offset", "Array", typeof(current_line[key]), current_line[key])
				else:
					var prefix_offsets = current_line[key]
					var index = 0
					for offsets in prefix_offsets:
						if offsets == []:
							offsets = [0.0, 0.0]
						prefixes_node.get_child(index).offset = Vector2(offsets[0], offsets[1])
						index += 1
			"prefix scale":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix scale", "Array", typeof(current_line[key]), current_line[key])
				else:
					var prefix_scales = current_line[key]
					var index = 0
					for scales in prefix_scales:
						if scales == []:
							scales = [1.0, 1.0]
						prefixes_node.get_child(index).scale = Vector2(scales[0], scales[1])
						index += 1
			"prefix skew":
				push_error("Prefix Skew is not supported in Godot 3.6.1. Sorry!")
			"prefix color":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix color", "Array", typeof(current_line[key]), current_line[key])
				else:
					var prefix_colors = current_line[key]
					var index = 0
					for color in prefix_colors:
						if color != "":
							prefixes_node.get_child(index).self_modulate = Color(color)
						else:
							prefixes_node.get_child(index).self_modulate = Color("ffffff")
			"prefix delay":
				if typeof(current_line[key]) != TYPE_ARRAY:
					print_wrong_type("prefix delay", "Array", typeof(current_line[key]), current_line[key])
				else:
					var prefix_delays = current_line[key]
					var index = 0
					for delay in prefix_delays:
						if delay > 0 and instant == false:
							var timer = Timer.new()
							var sprite = prefixes_node.get_child(index)
							timer.one_shot = true
							timer.wait_time = delay
							add_child(timer)
							timer.start()
							
							timer.connect("timeout", self, "_on_timer_timeout", [sprite, timer])
						else:
							prefixes_node.get_child(index).visible = true
						index += 1
			"textbox":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("textbox color", "String", typeof(current_line[key]), current_line[key])
				else:
					if current_line[key] == "default" or "":
						textbox.texture = preload("res://Assets/Textbox Textures/DefaultTextbox.png")
					else:
						var texture = load_external_texture(assets_path+"/Textbox Textures/"+current_line[key])
						if texture:
							textbox.texture = texture
						else:
							push_error("Coundn't find Textbox Texture: " + current_line[key])
							textbox.texture = preload("res://Assets/Textbox Textures/DefaultTextbox.png")
			"textbox color":
				if typeof(current_line[key]) != TYPE_STRING:
					print_wrong_type("textbox color", "String", typeof(current_line[key]), current_line[key])
				else:
					if current_line[key] != "":
						textbox.self_modulate = Color(current_line[key])
					else:
						textbox.self_modulate = Color(0, 0, 0)
	


func abort() -> void:
	get_tree().change_scene("res://Scenes/Start.tscn")
	Global.cleanup("Temp")
	print("Abort!")


func print_wrong_type(variable: String, exptected_type, receieved_type, receieved_value):
	push_error("'"+variable+"' was given an invalid Value.\nExpected Type: '"+str(exptected_type)+"'.\nReceived Type: '"+str(receieved_type)+"'.\nReceived Value: '"+str(receieved_value)+"'.")


func _on_timer_timeout(sprite: Sprite, timer: Timer):
	sprite.visible = true
	timer.queue_free()
