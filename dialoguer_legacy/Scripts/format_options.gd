extends OptionButton


var formats: Array = ["Image", "GIF", "MP4", "Audio"]


# Called when the node enters the scene tree for the first time.
func _ready():
	for format in formats:
		self.add_item(format)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
