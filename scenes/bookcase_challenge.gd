extends Panel

const _DEFAULT_CHECKER_API_URL := "https://schoolgame-1i34.onrender.com"
const _DEFAULT_AI_HINT_API_URL := "https://ai-hints-reguest.onrender.com"

@onready var answer_edit: TextEdit = $VBoxContainer/Content/TaskPanel/AnswerEdit
@onready var ask_ai_button: Button = $VBoxContainer/Content/TaskPanel/TaskButtons/AskAIButton
@onready var http_request: HTTPRequest = HTTPRequest.new()

var _ai_http_request: HTTPRequest
var _failed_task_check_count: int = 0
var _offer_ask_ai_in_toolbar: bool = false
var _checker_api_url: String = _DEFAULT_CHECKER_API_URL
var _ai_hint_api_url: String = _DEFAULT_AI_HINT_API_URL

func _ready() -> void:
	var checker := OS.get_environment("SCHOOLGAME_CHECKER_API_BASE").strip_edges().rstrip("/")
	if checker != "":
		_checker_api_url = checker
	var ai_hint := OS.get_environment("SCHOOLGAME_AI_HINT_API_BASE").strip_edges().rstrip("/")
	if ai_hint != "":
		_ai_hint_api_url = ai_hint

	if not http_request.is_inside_tree():
		add_child(http_request)
	
	if http_request.request_completed.is_connected(_on_check_request_completed):
		http_request.request_completed.disconnect(_on_check_request_completed)
	
	http_request.request_completed.connect(_on_check_request_completed)
	
	_ai_http_request = HTTPRequest.new()
	add_child(_ai_http_request)
	_ai_http_request.request_completed.connect(_on_groq_request_completed)
	
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
	print("URL:", _checker_api_url + "/check")
	
	var err = http_request.request(
		_checker_api_url + "/check",
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
			"Проверь доступность backend."
		)


func _on_check_request_completed(result, response_code, headers, body) -> void:
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
		_mark_task_completed("binary_search")
		_offer_ask_ai_in_toolbar = false
		if ask_ai_button:
			ask_ai_button.visible = false
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
		_failed_task_check_count += 1
		if _failed_task_check_count == 1:
			_offer_ask_ai_in_toolbar = true
		elif ask_ai_button:
			ask_ai_button.visible = false
		
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


func _set_ask_ai_toolbar_loading(loading: bool) -> void:
	if ask_ai_button == null:
		return
	ask_ai_button.disabled = loading
	ask_ai_button.text = "Отправка..." if loading else "Спросить у ИИ"


func _on_ask_ai_button_pressed() -> void:
	_set_ask_ai_toolbar_loading(true)
	
	var code_text := answer_edit.text.strip_edges()
	var prompt := (
		"Ты помощник по обучению Python. Игрок пишет функцию find_book_index для бинарного поиска книги в отсортированном списке bookshelf. "
		+ "Функция должна вернуть индекс найденной книги, а если книги нет — вернуть -1. "
		+ "Ниже код игрока. Дай краткую подсказку: на что обратить внимание или что исправить, без полного готового решения. Ответ по-русски.\n\n"
		+ "```python\n"
		+ code_text
		+ "\n```"
	)
	
	var payload := {
		"task_type": "binary_search",
		"player_code": code_text,
		"task_prompt": prompt
	}
	var json_data := JSON.stringify(payload)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _ai_http_request.request(_ai_hint_api_url + "/ai_hint_reguests", headers, HTTPClient.METHOD_POST, json_data)
	if err != OK:
		_set_ask_ai_toolbar_loading(false)
		_show_ai_hint_popup("Не удалось отправить запрос к серверу подсказок (код " + str(err) + ").")


func _on_groq_request_completed(result, response_code: int, _headers, body: PackedByteArray) -> void:
	_set_ask_ai_toolbar_loading(false)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		_show_ai_hint_popup("Ошибка сети при обращении к серверу подсказок.")
		return
	
	var response_text := body.get_string_from_utf8()
	var json_dict = JSON.parse_string(response_text)
	if typeof(json_dict) != TYPE_DICTIONARY:
		if response_code != 200:
			_show_ai_hint_popup("Ошибка сервера подсказок (HTTP " + str(response_code) + ").")
		else:
			_show_ai_hint_popup("Некорректный ответ сервера подсказок.")
		return
	
	if response_code != 200:
		_show_ai_hint_popup("Ошибка сервера подсказок (HTTP " + str(response_code) + ").")
		return
	
	if not json_dict.get("ok", false):
		_show_ai_hint_popup(str(json_dict.get("error", "Сервер подсказок вернул ошибку.")))
		return
	
	var hint := str(json_dict.get("hint", "")).strip_edges()
	if hint == "":
		_show_ai_hint_popup("Сервер подсказок вернул пустой ответ.")
		return
	_show_ai_hint_popup(hint)


func _show_ai_hint_popup(message: String) -> void:
	var hint_scene: PackedScene = preload("res://scenes/ai_hint_panel.tscn")
	if hint_scene == null:
		push_error("Не найдена сцена ai_hint_panel.tscn")
		return
	var hint_panel = hint_scene.instantiate()
	add_child(hint_panel)
	hint_panel.show_hint(message)


func _on_result_continue() -> void:
	_offer_ask_ai_in_toolbar = false
	if ask_ai_button:
		ask_ai_button.visible = false
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_result_retry() -> void:
	if _offer_ask_ai_in_toolbar and _failed_task_check_count == 1 and ask_ai_button:
		ask_ai_button.visible = true
	_offer_ask_ai_in_toolbar = false


func _mark_task_completed(task_id: String) -> void:
	var completed_tasks: Dictionary = {}
	
	if FileAccess.file_exists("user://tasks_progress.save"):
		var read_file = FileAccess.open("user://tasks_progress.save", FileAccess.READ)
		if read_file:
			var saved_data = read_file.get_var()
			if typeof(saved_data) == TYPE_DICTIONARY:
				completed_tasks = saved_data
	
	completed_tasks[task_id] = true
	
	var write_file = FileAccess.open("user://tasks_progress.save", FileAccess.WRITE)
	if write_file:
		write_file.store_var(completed_tasks)
