extends Control

const API_BASE := "https://schoolgame-64wq.onrender.com"

@onready var _name_edit: LineEdit = $CenterContainer/MainPanel/Margin/VBox/NameEdit
@onready var _email_edit: LineEdit = $CenterContainer/MainPanel/Margin/VBox/EmailEdit
@onready var _password_edit: LineEdit = $CenterContainer/MainPanel/Margin/VBox/PasswordEdit
@onready var _status_label: Label = $CenterContainer/MainPanel/Margin/VBox/StatusLabel
@onready var _save_button: Button = $CenterContainer/MainPanel/Margin/VBox/SaveButton
@onready var _reset_button: Button = $CenterContainer/MainPanel/Margin/VBox/ResetProgressButton
@onready var _delete_button: Button = $CenterContainer/MainPanel/Margin/VBox/DeleteProfileButton
@onready var _back_button: Button = $CenterContainer/MainPanel/Margin/VBox/BackButton
@onready var _confirm_dialog: ConfirmationDialog = $ConfirmDeleteDialog

var _http: HTTPRequest
var _pending: String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_password_edit.secret = true
	_confirm_dialog.confirmed.connect(_on_delete_confirmed)
	_fill_from_session()


func _fill_from_session() -> void:
	if not GameSession.is_logged_in():
		get_tree().change_scene_to_file("res://scenes/auth_screen.tscn")
		return
	var user := GameSession.get_user()
	_name_edit.text = str(user.get("name", ""))
	_email_edit.text = str(user.get("email", ""))
	_status_ok("Настройки профиля")


func _current_user_id() -> int:
	return int(GameSession.get_user().get("id", 0))


func _set_busy(busy: bool) -> void:
	_save_button.disabled = busy
	_reset_button.disabled = busy
	_delete_button.disabled = busy
	_back_button.disabled = busy


func _status_ok(message: String) -> void:
	_status_label.remove_theme_color_override("font_color")
	_status_label.text = message


func _status_error(message: String) -> void:
	_status_label.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
	_status_label.text = message


func _api_request(path: String, method: HTTPClient.Method, body: String = "") -> void:
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(API_BASE + path, headers, method, body)
	if err != OK:
		_pending = ""
		_set_busy(false)
		_status_error("Не удалось отправить запрос.")


func _on_save_button_pressed() -> void:
	var user_id := _current_user_id()
	if user_id <= 0:
		_status_error("Сессия не найдена, войдите снова.")
		return
	var name := _name_edit.text.strip_edges()
	var email := _email_edit.text.strip_edges()
	var password := _password_edit.text
	if name.is_empty() or email.is_empty():
		_status_error("Имя и email обязательны.")
		return
	_pending = "update"
	_set_busy(true)
	_status_ok("Сохраняем профиль...")
	var payload := {
		"name": name,
		"email": email,
	}
	if not password.is_empty():
		payload["password"] = password
	_api_request("/users/%d" % user_id, HTTPClient.METHOD_PUT, JSON.stringify(payload))


func _on_reset_progress_button_pressed() -> void:
	var user_id := _current_user_id()
	if user_id <= 0:
		_status_error("Сессия не найдена, войдите снова.")
		return
	_pending = "reset"
	_set_busy(true)
	_status_ok("Сбрасываем прогресс...")
	_api_request("/tasks?user_id=%d" % user_id, HTTPClient.METHOD_DELETE)


func _on_delete_profile_button_pressed() -> void:
	_confirm_dialog.popup_centered()


func _on_delete_confirmed() -> void:
	var user_id := _current_user_id()
	if user_id <= 0:
		_status_error("Сессия не найдена, войдите снова.")
		return
	_pending = "delete"
	_set_busy(true)
	_status_ok("Удаляем профиль...")
	_api_request("/users/%d" % user_id, HTTPClient.METHOD_DELETE)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://mainmenu.tscn")


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var text := body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		data = {}

	var action := _pending
	_pending = ""
	_set_busy(false)

	if response_code < 200 or response_code >= 300:
		_status_error(str((data as Dictionary).get("error", "Ошибка (%d)" % response_code)))
		return

	if action == "update":
		var user := GameSession.get_user()
		user["name"] = _name_edit.text.strip_edges()
		user["email"] = _email_edit.text.strip_edges()
		GameSession.update_user(user)
		_password_edit.text = ""
		_status_ok("Профиль обновлён.")
		return

	if action == "reset":
		_status_ok("Прогресс успешно сброшен.")
		return

	if action == "delete":
		GameSession.clear_session()
		_status_ok("Профиль удалён.")
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file("res://scenes/auth_screen.tscn")
