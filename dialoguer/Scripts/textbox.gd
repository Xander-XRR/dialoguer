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

var framecount = 0
var recording_15: bool = false
var recording_30: bool = false

var ss_frame: bool = true

var first_frame: bool = true

func _ready():
	text_label.text = ""
	text_array = Global.assets_path + "/Dialogue/" + Global.json_path
	print("Selected File: " + Global.json_path)
	
	if Global.format == "GIF":
		if Global.framerate == 15:
			recording_15 = true
			type_text(text_array)
		elif Global.framerate == 30:
			recording_30 = true
			type_text(text_array)
	elif Global.format == "Image":
		recording_15 = false
		recording_30 = false
		capture_images(text_array)

func _process(_delta: float) -> void:
	if first_frame == true:
		first_frame = false
	else:
		if recording_15:
			if ss_frame == true:
				var img = sub_viewport.get_viewport().get_texture().get_image()
				img.save_png(Global.assets_path + "/Frames/frame%05d.png" % framecount)
				framecount += 1
				ss_frame = false
			else:
				ss_frame = true
		elif recording_30:
			var img = sub_viewport.get_viewport().get_texture().get_image()
			img.save_png(Global.assets_path + "/Frames/frame%05d.png" % framecount)
			framecount += 1

## Types out the provided text in a typewriter style. Provided Text has to be in a JSON file.
func type_text(given_text: String):
	text_label.text = ""
	visible = true
	var full_text = load_dialog(given_text)
	var current_index = 0
	
	while current_index < full_text.size():
		var current_line = full_text[current_index]
		var line_text = current_line.get("text", "")
		
		text_label.text = line_text.replace("&", "\u200B")
		
		# Reset values
		text_label.visible_characters = 0
		icon.texture = null
		for child in %Prefixes.get_children():
			child.visible = false
		
		var raw_text = strip_bbcode(line_text)
		
			# Load the approptiate Icon, textbox/icon color, etc.
		for key in current_line:
			match key:
				"font":
					if typeof(current_line[key]) != TYPE_ARRAY:
						print_wrong_type("font", "Array", type_string(typeof(current_line[key])), current_line[key])
					else:
						var font_data = current_line[key]
						var font_path = Global.assets_path + "/Fonts/" + font_data[0]
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
					
				"icon":
					if typeof(current_line[key]) != TYPE_STRING:
						print_wrong_type("icon", "String", type_string(typeof(current_line[key])), current_line[key])
					else:
						var texture = load_external_texture(Global.assets_path + "/Dialogue Icons/" + current_line[key])
						if texture:
							icon.texture = texture
						else:
							print_rich("[color=red]Coundn't find icon Texture "+current_line[key]+".[/color]")
				"prefix":
					if typeof(current_line[key]) != TYPE_ARRAY:
						print_wrong_type("prefix", "Array", type_string(typeof(current_line[key])), current_line[key])
					else:
						var prefixes = current_line[key]
						var index = 0
						for prefix in prefixes:
							var texture = load_external_texture(Global.assets_path + "/Prefixes/" + prefix) as Texture2D
							if texture:
								%Prefixes.get_child(index).texture = texture
								if current_line.get("prefix delay", null) == null:
									%Prefixes.get_child(index).visible = true
							elif str(current_line[key][index]) != "":
								print_rich("[color=red]Coundn't find prefix Texture "+str(current_line[key][index])+".[/color]")
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
								%Prefixes.get_child(index).self_modulate = "000000"
							index += 1
				"prefix delay":
					if typeof(current_line[key]) != TYPE_ARRAY:
						print_wrong_type("prefix delay", "Array", type_string(typeof(current_line[key])), current_line[key])
					else:
						var prefix_delays = current_line[key]
						var index = 0
						for delay in prefix_delays:
							if delay > 0:
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
							var texture = load_external_texture(Global.assets_path + "/Textbox Textures/" + current_line[key]) as Texture2D
							if texture:
								textbox.texture = texture
							else:
								print_rich("[color=red]Coundn't find textbox Texture "+current_line[key]+".[/color]")
				"textbox color":
					if typeof(current_line[key]) != TYPE_STRING:
						print_wrong_type("textbox color", "String", type_string(typeof(current_line[key])), current_line[key])
					else:
						if current_line[key] != "":
							textbox.self_modulate = current_line[key]
						else:
							textbox.self_modulate = "000000"
				"icon color":
					if typeof(current_line[key]) != TYPE_STRING:
						print_wrong_type("icon color", "String", type_string(typeof(current_line[key])), current_line[key])
					else:
						if current_line[key] != "":
							icon.self_modulate = current_line[key]
						else:
							icon.self_modulate = "000000"
		
		while text_label.visible_characters < text_label.get_total_character_count():
			
			# Increases the visible characters, then waits the appropriate amount of time
			text_label.visible_characters += current_line.get("amount", 1)
			char_timer.wait_time = current_line.get("delay", 0.03)
			
			var current_char = raw_text[text_label.visible_characters - 1]
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
			var end_delay = current_line.get("end delay", 1)
			if typeof(end_delay) != TYPE_FLOAT:
				print_wrong_type("end delay", "float", type_string(typeof(end_delay)), end_delay)
				end_delay = 1
			elif end_delay <= 0:
				end_delay = 0.001
			await get_tree().create_timer(end_delay).timeout
		else:
			var end_delay = current_line.get("end delay", 1)
			if typeof(end_delay) != TYPE_FLOAT:
				print_wrong_type("end delay", "float", type_string(typeof(end_delay)), end_delay)
				end_delay = 1
			elif end_delay <= 0:
				end_delay = 1
			await get_tree().create_timer(end_delay).timeout
			recording_15 = false
			recording_30 = false
			text_label.text = ""
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
		for key in current_line:
			match key:
				"font":
					var font_data = current_line[key]
					var font_path = Global.assets_path + "/Fonts/" + font_data[0]
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
					
				"icon":
					var texture = load_external_texture(Global.assets_path + "/Dialogue Icons/" + current_line[key])
					if texture:
						icon.texture = texture
				"prefix":
					var prefixes = current_line[key]
					var index = 0
					for prefix in prefixes:
						var texture = load_external_texture(Global.assets_path + "/Prefixes/" + prefix) as Texture2D
						if texture:
							%Prefixes.get_child(index).texture = texture
						index += 1
				"prefix color":
					var prefix_colors = current_line[key]
					var index = 0
					for color in prefix_colors:
						if color != "":
							%Prefixes.get_child(index).self_modulate = color
						index += 1
				"textbox":
					if current_line[key] == "default" or "":
						textbox.texture = preload("res://Assets/Textbox Textures/DefaultTextbox.png")
					else:
						var texture = load_external_texture(Global.assets_path + "/Textbox Textures/" + current_line[key]) as Texture2D
						if texture:
							textbox.texture = texture
				"textbox color":
					textbox.self_modulate = current_line[key]
				"icon color":
					icon.self_modulate = current_line[key]
		
		current_index += 1
		
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		if current_index < full_text.size():
			var img = sub_viewport.get_viewport().get_texture().get_image()
			img.save_png(Global.assets_path + "/Output/" + Global.output_name + "%03d.png" % framecount)
			framecount += 1
		else:
			var img = sub_viewport.get_viewport().get_texture().get_image()
			img.save_png(Global.assets_path + "/Output/" + Global.output_name + "%03d.png" % framecount)
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
	

func print_wrong_type(variable: String, exptected_type, receieved_type, receieved_value):
	print_rich("[color=red]'"+variable+"' was given an invalid Value.\nExpected Type: '"+str(exptected_type)+"'.\nReceived Type: '"+str(receieved_type)+"'.\nReceived Value: '"+str(receieved_value)+"'.[/color]")

func _on_timer_timeout(timer: Timer, sprite: Sprite2D):
	sprite.visible = true
	timer.queue_free()
