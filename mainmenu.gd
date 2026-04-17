extends Control

const ProgressStoreScript = preload("res://progress_store.gd")

@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	continue_button.visible = _has_any_progress()


func _on_start_button_pressed() -> void:
	LevelReturnState.clear_pending_spawn()
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_screen.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth_screen.tscn")


func _has_any_progress() -> bool:
	if ProgressStoreScript.is_leaders_completed():
		return true

	if not FileAccess.file_exists("user://tasks_progress.save"):
		return false

	var read_file := FileAccess.open("user://tasks_progress.save", FileAccess.READ)
	if read_file == null:
		return false

	var saved_data = read_file.get_var()
	if typeof(saved_data) != TYPE_DICTIONARY:
		return false

	for value in saved_data.values():
		if bool(value):
			return true
	return false
