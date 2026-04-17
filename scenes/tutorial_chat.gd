extends CanvasLayer

signal tutorial_finished

const CHAT_MESSAGES: Array[Dictionary] = [
	{ "text": "Добро пожаловать в игру!" },
	{ "text": "Используйте WASD или стрелки для перемещения." },
	{ "text": "Нажмите E, чтобы взаимодействовать с объектами." },
	{ "text": "Ваша цель - восстановить таблицу лидеров. Удачи!" },
]

static var tutorial_shown: bool = false

@onready var messages_container: VBoxContainer = $Panel/MainVBox/ChatMargin/ChatScroll/Messages
@onready var solve_button: Button = $Panel/SolveButton


func _ready() -> void:
	if tutorial_shown:
		queue_free()
		return
	
	tutorial_shown = true
	get_tree().paused = true
	
	# Очищаем контейнер
	for child in messages_container.get_children():
		child.queue_free()
	
	# Создаём сообщения
	for data in CHAT_MESSAGES:
		var bubble = create_message_bubble(data)
		messages_container.add_child(bubble)
	
	# Настраиваем кнопку
	solve_button.text = "ПОНЯТНО"
	solve_button.visible = true
	solve_button.disabled = false
	solve_button.pressed.connect(_on_solve_button_pressed)


func create_message_bubble(data: Dictionary) -> Control:
	# Создаём главный контейнер
	var main_container = HBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_FILL
	
	# Создаём панель с фоном
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	main_container.add_child(panel)
	
	# Стиль панели
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 1.0)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	# Контейнер для содержимого
	var content = VBoxContainer.new()
	panel.add_child(content)
	
	# Добавляем текст
	var text_value = str(data.get("text", ""))
	if text_value != "":
		var label = Label.new()
		label.text = text_value
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.custom_minimum_size = Vector2(400, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)
	
	# Добавляем изображение если есть
	if data.has("image") and data["image"] != null:
		var texture_rect = TextureRect.new()
		texture_rect.texture = data["image"]
		texture_rect.custom_minimum_size = Vector2(200, 150)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		content.add_child(texture_rect)
	
	return main_container


func _on_solve_button_pressed() -> void:
	get_tree().paused = false
	tutorial_finished.emit()
	queue_free()
