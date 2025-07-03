extends ConfirmationDialog


func _on_confirmed() -> void:
	if Global.assets_path:
		OS.move_to_trash(Global.assets_path)
		print_rich("[color=yellow]Moved Directory to Trash: ", Global.assets_path, "[/color]")
		Global.assets_path = ""
		Global.generate_necessary_folders()
