extends Panel

const _DEFAULT_CHECKER_API_URL := "https://schoolgame-1i34.onrender.com"
const _DEFAULT_AI_HINT_API_URL := "http://127.0.0.1:8001"
const GROQ_API_URL := "https://api.groq.com/openai/v1/chat/completions"
const GROQ_MODEL := "llama-3.1-8b-instant"

@onready var answer_edit: TextEdit = $VBoxContainer/Content/TaskPanel/AnswerEdit
@onready var ask_ai_button: Button = $VBoxContainer/Content/TaskPanel/TaskButtons/AskAIButton
@onready var http_request: HTTPRequest = HTTPRequest.new()

var _ai_http_request: HTTPRequest
var _failed_task_check_count: int = 0
var _offer_ask_ai_in_toolbar: bool = false
var _groq_key_resolved: bool = false
var _groq_api_key: String = ""
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


func _get_groq_api_key() -> String:
	if not _groq_key_resolved:
		_groq_api_key = _resolve_groq_api_key()
		_groq_key_resolved = true
	return _groq_api_key


func _resolve_groq_api_key() -> String:
	var k := OS.get_environment("GROQ_API_KEY").strip_edges()
	if k != "":
		return k
	k = _read_key_from_web_env()
	if k != "":
		return k
	k = _read_key_from_env_file("res://res/.env")
	if k != "":
		return k
	return _read_key_from_env_file("res://builds/web/.env")


func _read_key_from_web_env() -> String:
	if not OS.has_feature("web"):
		return ""
	var js_value: Variant = JavaScriptBridge.eval(
		"(window.GROQ_API_KEY || " \
		+ "(window.env && window.env.GROQ_API_KEY) || " \
		+ "(window.__ENV && window.__ENV.GROQ_API_KEY) || '')"
	)
	var key := str(js_value).strip_edges()
	if key == "__GROQ_API_KEY__":
		return ""
	return key


func _read_key_from_env_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	const PREFIX := "GROQ_API_KEY="
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with(PREFIX):
			var val: String = line.substr(PREFIX.length()).strip_edges()
			if val.length() >= 2:
				var q0 := val[0]
				var q1 := val[val.length() - 1]
				if (q0 == '"' and q1 == '"') or (q0 == "'" and q1 == "'"):
					val = val.substr(1, val.length() - 2)
			return val
	return ""


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
		_mark_task_completed("bubble_sort")
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
	ask_ai_button.text = "Отправка…" if loading else "Спросить у ИИ"


func _on_ask_ai_button_pressed() -> void:
	_set_ask_ai_toolbar_loading(true)
	
	var code_text := answer_edit.text.strip_edges()
	var prompt := (
		"Ты помощник по обучению Python. Игрок пишет функцию bubble_sort (пузырьковая сортировка массива по убыванию). "
		+ "Ниже его код. Дай краткую подсказку: на что обратить внимание или что исправить, без полного готового решения. Ответ по-русски.\n\n"
		+ "```python\n"
		+ code_text
		+ "\n```"
	)
	
	var payload := {
		"task_type": "bubble_sort",
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
		var sync := TaskProgressSyncService.get_singleton()
		if sync:
			sync.push_task_completed(task_id)
