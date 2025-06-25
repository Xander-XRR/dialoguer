extends ConfirmationDialog


func _on_confirmed() -> void:
	Global.cleanup("GIFs")
