extends Node2D

@onready var error_window = $ErrorWindow
@onready var ok_bottom_button: Button = $Panel/OKBottom
@onready var back_bottom_button: Button = $Panel/BackBottom

func _ready():
	set_process_unhandled_input(true)
	# Настройка кнопок
	#$ErrorWindow/VBoxContainer/OK_Button.pressed.connect(_on_close)
	#$ErrorWindow/VBoxContainer/Header/CloseButton.pressed.connect(_on_close)
	
	# Прячем изначально
	error_window.modulate.a = 0.0
	error_window.pivot_offset = error_window.size / 2
	ok_bottom_button.visible = false
	ok_bottom_button.disabled = true
	back_bottom_button.visible = false
	back_bottom_button.disabled = true
	
	# Таймер появления
	await get_tree().create_timer(2.0).timeout
	show_error()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if not back_bottom_button.visible or back_bottom_button.disabled:
		return
	get_viewport().set_input_as_handled()
	_on_back_bottom_pressed()

func show_error():
	var start_pos = error_window.position
	var center = get_viewport().get_visible_rect().size / 2 - error_window.size / 2
	
	# Перемещаем в центр
	error_window.position = center
	
	# Делаем видимым
	var tween = create_tween().set_parallel(true)
	tween.tween_property(error_window, "modulate:a", 1.0, 0.1)
	tween.tween_property(error_window, "scale", Vector2.ONE, 0.1).from(Vector2(0.1, 0.1))
	
	# Тряска (последовательная)
	var shake_tween = create_tween()
	shake_tween.tween_property(error_window, "position", center + Vector2(15, -10), 0.04)
	shake_tween.tween_property(error_window, "position", center + Vector2(-15, 10), 0.04)
	shake_tween.tween_property(error_window, "position", center + Vector2(8, -5), 0.04)
	shake_tween.tween_property(error_window, "position", center + Vector2(-8, 5), 0.04)
	shake_tween.tween_property(error_window, "position", center, 0.04)
	await shake_tween.finished
	ok_bottom_button.visible = true
	ok_bottom_button.disabled = false
	back_bottom_button.visible = true
	back_bottom_button.disabled = false

func _on_close():
	error_window.hide()


func _on_ok_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/comp_challenge.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_back_bottom_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
