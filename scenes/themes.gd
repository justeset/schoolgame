extends Panel

@onready var close_button: Button = $VBoxContainer/Header/HBoxContainer/CloseButton


func _ready() -> void:
	set_process_unhandled_input(true)
	var tabs := $VBoxContainer/TabContainer as TabContainer
	if tabs:
		tabs.set_tab_title(0, "Сортировка пузырьком")
		tabs.set_tab_title(1, "Словари и частоты")
		tabs.set_tab_title(2, "Бинарный поиск")
		tabs.set_tab_title(3, "Множества")
	close_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_button_pressed()


func _on_close_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
