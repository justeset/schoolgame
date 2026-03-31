extends Panel

@onready var answer_edit: TextEdit = $VBoxContainer/Content/TaskPanel/AnswerEdit
@onready var http_request: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
	if not http_request.is_inside_tree():
		add_child(http_request)
	
	if http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.disconnect(_on_request_completed)
	
	http_request.request_completed.connect(_on_request_completed)
	
	if answer_edit:
		answer_edit.call_deferred("set", "tab_size", 4)
		answer_edit.call_deferred("set", "insert_tab", true)


func _on_close_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_clear_button_pressed() -> void:
	answer_edit.text = ""
	answer_edit.grab_focus()


func _on_check_button_pressed() -> void:
	var code_text = answer_edit.text.strip_edges()
	
	if code_text == "":
		_show_result_panel(
			false,
			"Пустой ответ",
			"Введите код перед проверкой.",
			"Напиши решение в поле ввода."
		)
		return
	
	var data = {
		"code": code_text
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	print("Отправляем запрос...")
	print("JSON:", json_data)
	
	var err = http_request.request(
		"http://127.0.0.1:8000/check",
		headers,
		HTTPClient.METHOD_POST,
		json_data
	)
	
	print("Код ошибки request(): ", err)
	
	if err != OK:
		_show_result_panel(
			false,
			"Ошибка отправки",
			"Не удалось отправить запрос на сервер.",
			"Проверь, запущен ли backend на http://127.0.0.1:8000"
		)


func _on_request_completed(result, response_code, headers, body) -> void:
	print("request_completed вызван")
	print("result:", result)
	print("response_code:", response_code)
	print("headers:", headers)
	
	var response_text = body.get_string_from_utf8()
	print("body:", response_text)
	
	if response_code != 200:
		_show_result_panel(
			false,
			"Ошибка сервера",
			"Сервер вернул код " + str(response_code),
			"Проверь backend и endpoint /check"
		)
		return
	
	var json_dict = JSON.parse_string(response_text)
	
	if json_dict == null or typeof(json_dict) != TYPE_DICTIONARY:
		_show_result_panel(
			false,
			"Ошибка ответа",
			"Сервер вернул некорректный JSON.",
			"Проверь формат ответа backend."
		)
		return
	
	var fb = json_dict.get("feedback", {})
	
	if json_dict.get("success", false):
		var passed = json_dict.get("passed_tests", 0)
		var total = json_dict.get("total_tests", 0)
		
		var explanation = fb.get(
			"explanation",
			"Все тесты успешно пройдены (%d/%d)." % [passed, total]
		)
		
		_show_result_panel(
			true,
			fb.get("title", "Поздравляем!"),
			explanation,
			fb.get("hint", "")
		)
	else:
		var title = fb.get("title", "Задание не выполнено")
		var explanation = fb.get("explanation", "Код не прошёл проверку.")
		var hint = fb.get("hint", "Попробуй внимательно проверить решение.")
		
		if json_dict.has("test_number"):
			explanation += "\n\nНе пройден тест №" + str(json_dict["test_number"])
		
		if json_dict.has("ваш_вывод") and str(json_dict["ваш_вывод"]) != "":
			explanation += "\nВаш вывод: " + str(json_dict["ваш_вывод"])
		
		if json_dict.has("ожидаемый") and str(json_dict["ожидаемый"]) != "":
			explanation += "\nОжидалось: " + str(json_dict["ожидаемый"])
		
		_show_result_panel(
			false,
			title,
			explanation,
			hint
		)


func _show_result_panel(success: bool, title: String, explanation: String, hint: String = "") -> void:
	var result_panel_scene = preload("res://scenes/resultpanel.tscn")
	
	if result_panel_scene == null:
		push_error("Не найдена сцена resultpanel.tscn")
		return
	
	var result_panel = result_panel_scene.instantiate()
	add_child(result_panel)
	
	result_panel.show_result(success, title, explanation, hint)
	
	if result_panel.has_signal("continue_pressed"):
		result_panel.continue_pressed.connect(_on_result_continue)
	
	if result_panel.has_signal("retry_pressed"):
		result_panel.retry_pressed.connect(_on_result_retry)


func _on_result_continue() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_result_retry() -> void:
	pass
