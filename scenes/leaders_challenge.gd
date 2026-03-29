extends CanvasLayer

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
