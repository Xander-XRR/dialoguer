extends Control


var text_array: String

@onready var sub_viewport: SubViewport = %SubViewport

@onready var char_timer = %CharacterTimer
@onready var line_timer = %LineTimer
@onready var custom_timer = %CustomTimer

@onready var dialog_icon: Node2D = %DialogIcon
@onready var icon: Sprite2D = %Icon
@onready var textbox: Sprite2D = %Textbox
@onready var label: RichTextLabel =%Text

var framecount = 0
var recording = true


func _ready():
	label.text = ""
	text_array = Global.assets_path + "/Dialogue/" + Global.json_path
	print("Selected File: " + Global.json_path)
	type_text(text_array)

func _process(_delta: float) -> void:
	if recording:
		var img = sub_viewport.get_viewport().get_texture().get_image()
		img.save_png(Global.assets_path + "/Frames/frame%05d.png" % framecount)
		framecount += 1

## Types out the provided text in a typewriter style. Provided Text has to be in a JSON file.
func type_text(given_text: String):
	label.text = ""
	visible = true
	var full_text = load_dialog(given_text)
	var current_index = 0
	
	while current_index < full_text.size():
		var current_line = full_text[current_index]
		var line_text = current_line.get("text", "")
		
		label.text = line_text.replace("&", "\u200B")
		
		# Reset values
		label.visible_characters = 0
		icon.texture = null
		for child in %Prefixes.get_children():
			child.visible = false
		
		var raw_text = strip_bbcode(line_text)
		
			# Load the approptiate Icon, textbox/icon color, etc.
		for key in current_line:
			match key:
				"font":
					var font_data = current_line[key]
					var font_path = Global.assets_path + "/Fonts/" + font_data[0]
					var font_file = FontFile.new()
					
					if font_data[0] == "default" or "":
						label.remove_theme_font_override("normal_font")
					else:
						font_file.load_dynamic_font(font_path)
						label.add_theme_font_override("normal_font", font_file)
					
					if font_data[1] == 0:
						label.remove_theme_font_size_override("normal_font_size")
					else:
						label.add_theme_font_size_override("normal_font_size", font_data[1])
					
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
							if current_line.get("prefix delay", null) == null:
								%Prefixes.get_child(index).visible = true
						index += 1
				"prefix color":
					var prefix_colors = current_line[key]
					var index = 0
					for color in prefix_colors:
						if color != "":
							%Prefixes.get_child(index).self_modulate = color
						index += 1
				"prefix delay":
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
		
		while label.visible_characters < label.get_total_character_count():
			
			# Increases the visible characters, then waits the appropriate amount of time
			label.visible_characters += current_line.get("amount", 1)
			char_timer.wait_time = current_line.get("delay", 0.03)
			
			var current_char = raw_text[label.visible_characters - 1]
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
			if end_delay <= 0:
				end_delay = 0.001
			await get_tree().create_timer(end_delay).timeout
		else:
			var end_delay = current_line.get("end delay", 1)
			if end_delay <= 0:
				end_delay = 1
			await get_tree().create_timer(end_delay).timeout
			recording = false
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
	

func _on_timer_timeout(timer: Timer, sprite: Sprite2D):
	sprite.visible = true
	timer.queue_free()
