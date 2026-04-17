extends CanvasLayer

const STATE_LIST := "list"
const STATE_DRILL := "drill"
const STATE_QUIZ := "quiz"
const STATE_DONE := "done"
const _DEFAULT_CHECKER_API_URL := "https://schoolgame-64wq.onrender.com"

@onready var title_label: Label = $Card/VBox/Header/Title
@onready var list_block: VBoxContainer = $Card/VBox/ListBlock
@onready var drill_block: VBoxContainer = $Card/VBox/DrillBlock
@onready var quiz_block: VBoxContainer = $Card/VBox/QuizBlock
@onready var done_block: VBoxContainer = $Card/VBox/DoneBlock
@onready var progress_label: Label = $Card/VBox/ProgressLabel

@onready var list_rows_box: VBoxContainer = $Card/VBox/ListBlock/Rows
@onready var drill_name: Label = $Card/VBox/DrillBlock/ErrorName
@onready var drill_fix_text: RichTextLabel = $Card/VBox/DrillBlock/DrillColumns/FixColumn/FixText
@onready var player_code_input: TextEdit = $Card/VBox/DrillBlock/DrillColumns/CodeColumn/PlayerCodeInput
@onready var drill_feedback: Label = $Card/VBox/DrillBlock/Feedback
@onready var drill_check_button: Button = $Card/VBox/DrillBlock/DrillButtons/CheckFixButton

@onready var quiz_question: Label = $Card/VBox/QuizBlock/Question
@onready var quiz_feedback: Label = $Card/VBox/QuizBlock/Feedback
@onready var option_a: Button = $Card/VBox/QuizBlock/Options/OptionA
@onready var option_b: Button = $Card/VBox/QuizBlock/Options/OptionB
@onready var option_c: Button = $Card/VBox/QuizBlock/Options/OptionC

var _state: String = STATE_LIST
var _current_error_idx: int = 0
var _quiz_idx: int = 0
var _quiz_score: int = 0
var _checker_api_url: String = _DEFAULT_CHECKER_API_URL
var _check_request: HTTPRequest

var _errors: Array[Dictionary] = [
	{
		"name": "Пустой ответ",
		"count": 3,
		"task_id": "count_orders",
		"fix": "Добавь хотя бы каркас решения перед проверкой.\n\n[code]def count_orders(order_codes):\n    return {}[/code]",
		"player_code": ""
	},
	{
		"name": "Неверное имя функции",
		"count": 2,
		"task_id": "count_orders",
		"fix": "Переименуй функцию в ожидаемое имя задачи.\n\n[code]def count_orders(order_codes):\n    ...[/code]",
		"player_code": "def countOrder(order_codes):\n    return {}"
	},
	{
		"name": "Ошибка логики на тесте",
		"count": 2,
		"task_id": "count_orders",
		"fix": "Проверь граничные случаи и корректный подсчет повторов.\n\n[code]for code in order_codes:\n    counts[code] = counts.get(code, 0) + 1[/code]",
		"player_code": "def count_orders(order_codes):\n    return {code: 1 for code in order_codes}"
	},
]

var _quiz: Array[Dictionary] = [
	{
		"q": "Что чаще всего приводит к ошибке 'Функция не найдена'?",
		"options": [
			"Пустой список во входных данных",
			"Неверное имя функции",
			"Лишний print в коде"
		],
		"ok": 1
	},
	{
		"q": "Что сделать перед нажатием 'Проверить', чтобы избежать ошибки валидации?",
		"options": [
			"Оставить поле пустым",
			"Добавить комментарий",
			"Заполнить поле кода"
		],
		"ok": 2
	},
	{
		"q": "Если тест не проходит, но код выполняется, это обычно...",
		"options": [
			"Ошибка сети",
			"Ошибка логики решения",
			"Проблема шрифта"
		],
		"ok": 1
	},
]


func _ready() -> void:
	var checker := OS.get_environment("SCHOOLGAME_CHECKER_API_BASE").strip_edges().rstrip("/")
	if checker != "":
		_checker_api_url = checker
	_check_request = HTTPRequest.new()
	add_child(_check_request)
	_check_request.request_completed.connect(_on_drill_check_request_completed)
	set_process_unhandled_input(true)
	_build_error_rows()
	_show_state(STATE_LIST)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _state == STATE_DRILL:
		get_viewport().set_input_as_handled()
		_on_back_to_list_button_pressed()


func _build_error_rows() -> void:
	for child in list_rows_box.get_children():
		child.queue_free()
	for i in range(_errors.size()):
		var e: Dictionary = _errors[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.custom_minimum_size = Vector2(0, 52)

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s  (%d)" % [str(e["name"]), int(e["count"])]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var btn := Button.new()
		btn.text = "Разобрать"
		btn.pressed.connect(func():
			_current_error_idx = i
			_open_drill()
		)

		row.add_child(label)
		row.add_child(btn)
		list_rows_box.add_child(row)


func _show_state(new_state: String) -> void:
	_state = new_state
	list_block.visible = _state == STATE_LIST
	drill_block.visible = _state == STATE_DRILL
	quiz_block.visible = _state == STATE_QUIZ
	done_block.visible = _state == STATE_DONE

	match _state:
		STATE_LIST:
			title_label.text = "Разбор ошибок"
			progress_label.text = ""
		STATE_DRILL:
			title_label.text = "Разбор ошибки"
		STATE_QUIZ:
			title_label.text = "Мини-тест"
		STATE_DONE:
			title_label.text = "Готово"
			progress_label.text = "Результат: %d/%d" % [_quiz_score, _quiz.size()]


func _open_drill() -> void:
	var e: Dictionary = _errors[_current_error_idx]
	drill_name.text = str(e["name"])
	drill_fix_text.text = "[b]Как исправить ошибку:[/b]\n%s" % str(e.get("fix", ""))
	player_code_input.text = str(e.get("player_code", ""))
	drill_feedback.text = ""
	drill_feedback.modulate = Color(0.9, 0.95, 1.0, 1.0)
	drill_check_button.disabled = false
	drill_check_button.text = "Проверить"
	_show_state(STATE_DRILL)


func _open_quiz() -> void:
	_quiz_idx = 0
	_quiz_score = 0
	quiz_feedback.text = ""
	_render_quiz()
	_show_state(STATE_QUIZ)


func _render_quiz() -> void:
	var q: Dictionary = _quiz[_quiz_idx]
	progress_label.text = "Вопрос %d/%d" % [_quiz_idx + 1, _quiz.size()]
	quiz_question.text = str(q["q"])
	var opts: Array = q["options"]
	option_a.text = str(opts[0])
	option_b.text = str(opts[1])
	option_c.text = str(opts[2])
	quiz_feedback.text = ""


func _answer(choice_idx: int) -> void:
	var q: Dictionary = _quiz[_quiz_idx]
	var ok_idx: int = int(q["ok"])
	if choice_idx == ok_idx:
		_quiz_score += 1
		quiz_feedback.text = "Верно."
		quiz_feedback.modulate = Color(0.0, 0.9, 0.75, 1.0)
	else:
		quiz_feedback.text = "Неверно. Правильный ответ: %s" % str((q["options"] as Array)[ok_idx])
		quiz_feedback.modulate = Color(1.0, 0.35, 0.35, 1.0)


func _on_close_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")


func _on_start_quiz_button_pressed() -> void:
	_open_quiz()


func _on_back_to_list_button_pressed() -> void:
	_show_state(STATE_LIST)


func _on_option_a_pressed() -> void:
	_answer(0)


func _on_option_b_pressed() -> void:
	_answer(1)


func _on_option_c_pressed() -> void:
	_answer(2)


func _on_next_question_button_pressed() -> void:
	if _quiz_idx + 1 < _quiz.size():
		_quiz_idx += 1
		_render_quiz()
		return
	_show_state(STATE_DONE)


func _on_check_fix_button_pressed() -> void:
	var code_text := player_code_input.text.strip_edges()
	if code_text == "":
		drill_feedback.text = "Введи код перед проверкой."
		drill_feedback.modulate = Color(1.0, 0.35, 0.35, 1.0)
		return
	var e: Dictionary = _errors[_current_error_idx]
	var task_id := str(e.get("task_id", "count_orders"))
	var payload := {
		"code": code_text,
		"task_id": task_id
	}
	var err := _check_request.request(
		_checker_api_url + "/check",
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if err != OK:
		drill_feedback.text = "Не удалось отправить запрос на сервер."
		drill_feedback.modulate = Color(1.0, 0.35, 0.35, 1.0)
		return
	drill_check_button.disabled = true
	drill_check_button.text = "Проверка..."
	drill_feedback.text = "Отправили код на проверку..."
	drill_feedback.modulate = Color(0.75, 0.85, 0.95, 1.0)


func _on_drill_check_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	drill_check_button.disabled = false
	drill_check_button.text = "Проверить"
	if response_code != 200:
		drill_feedback.text = "Сервер вернул код %d." % response_code
		drill_feedback.modulate = Color(1.0, 0.35, 0.35, 1.0)
		return
	var text := body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		drill_feedback.text = "Некорректный ответ сервера."
		drill_feedback.modulate = Color(1.0, 0.35, 0.35, 1.0)
		return
	var payload := data as Dictionary
	if bool(payload.get("success", false)):
		var passed := int(payload.get("passed_tests", 0))
		var total := int(payload.get("total_tests", 0))
		drill_feedback.text = "Отлично, код проходит проверку (%d/%d)." % [passed, total]
		drill_feedback.modulate = Color(0.0, 0.9, 0.75, 1.0)
	else:
		var feedback: Variant = payload.get("feedback", {})
		var explanation := "Код пока не прошел проверку."
		if typeof(feedback) == TYPE_DICTIONARY:
			explanation = str((feedback as Dictionary).get("explanation", explanation))
		drill_feedback.text = explanation
		drill_feedback.modulate = Color(1.0, 0.35, 0.35, 1.0)
