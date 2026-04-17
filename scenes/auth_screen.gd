extends Control

## Базовый URL Go API.
const API_BASE := "https://auth-aviz.onrender.com"

@onready var _tab: TabContainer = $CenterContainer/MainPanel/Margin/VBox/TabContainer
@onready var _login_email: LineEdit = $CenterContainer/MainPanel/Margin/VBox/TabContainer/Login/LoginFields/EmailEdit
@onready var _login_password: LineEdit = $CenterContainer/MainPanel/Margin/VBox/TabContainer/Login/LoginFields/PasswordEdit
@onready var _reg_name: LineEdit = $CenterContainer/MainPanel/Margin/VBox/TabContainer/Register/RegFields/NameEdit
@onready var _reg_email: LineEdit = $CenterContainer/MainPanel/Margin/VBox/TabContainer/Register/RegFields/RegEmailEdit
@onready var _reg_password: LineEdit = $CenterContainer/MainPanel/Margin/VBox/TabContainer/Register/RegFields/RegPasswordEdit
@onready var _status: Label = $CenterContainer/MainPanel/Margin/VBox/StatusLabel

var _http: HTTPRequest
var _pending: String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_login_password.secret = true
	_reg_password.secret = true
	if _tab.get_tab_count() >= 2:
		_tab.set_tab_title(0, "Вход")
		_tab.set_tab_title(1, "Регистрация")
	_refresh_status()


func _refresh_status() -> void:
	if GameSession.is_logged_in():
		var u: Dictionary = GameSession.get_user()
		_status.text = "Сейчас: " + str(u.get("name", u.get("email", "?")))
	else:
		_status.text = ""


func _set_busy(busy: bool) -> void:
	var login_btn := _tab.get_node_or_null("Login/LoginFields/LoginButton") as Button
	var reg_btn := _tab.get_node_or_null("Register/RegFields/RegisterButton") as Button
	if login_btn:
		login_btn.disabled = busy
	if reg_btn:
		reg_btn.disabled = busy


func _show_error(msg: String) -> void:
	_status.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
	_status.text = msg


func _show_ok(msg: String) -> void:
	_status.remove_theme_color_override("font_color")
	_status.text = msg


func _on_back_button_pressed() -> void:
	get_tree().quit()


func _on_login_button_pressed() -> void:
	var email := _login_email.text.strip_edges()
	var password := _login_password.text
	if email.is_empty() or password.is_empty():
		_show_error("Введите email и пароль.")
		return
	_pending = "login"
	_set_busy(true)
	_show_ok("Вход…")
	var body := JSON.stringify({"email": email, "password": password})
	var err := _http.request(
		API_BASE + "/auth/login",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		_set_busy(false)
		_show_error("Не удалось отправить запрос.")


func _on_register_button_pressed() -> void:
	var reg_name := _reg_name.text.strip_edges()
	var email := _reg_email.text.strip_edges()
	var password := _reg_password.text
	if reg_name.is_empty() or email.is_empty() or password.is_empty():
		_show_error("Заполните все поля регистрации.")
		return
	_pending = "register"
	_set_busy(true)
	_show_ok("Регистрация…")
	var body := JSON.stringify({"email": email, "name": reg_name, "password": password})
	var err := _http.request(
		API_BASE + "/auth/register",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		_set_busy(false)
		_show_error("Не удалось отправить запрос.")


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_set_busy(false)
	var text := body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		data = {}
	if _pending == "register":
		_pending = ""
		if response_code == 201:
			_show_ok("Аккаунт создан. Войдите с тем же email.")
			_login_email.text = _reg_email.text.strip_edges()
			_tab.current_tab = 0
		else:
			_show_error(str(data.get("error", "Ошибка регистрации (%d)" % response_code)))
		return
	if _pending == "login":
		_pending = ""
		if response_code != 200:
			_show_error(str(data.get("error", "Ошибка входа (%d)" % response_code)))
			return
		var token := str(data.get("token", ""))
		var user: Variant = data.get("user", {})
		if token.is_empty() or typeof(user) != TYPE_DICTIONARY:
			_show_error("Некорректный ответ сервера.")
			return
		GameSession.save_session(token, user as Dictionary)
		_show_ok("Добро пожаловать, " + str(user.get("name", "")) + "!")
		await get_tree().create_timer(0.35).timeout
		get_tree().change_scene_to_file("res://mainmenu.tscn")
		return
	_pending = ""
