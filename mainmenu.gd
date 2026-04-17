extends Control


func _on_start_button_pressed() -> void:
	LevelReturnState.clear_pending_spawn()
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_screen.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth_screen.tscn")
