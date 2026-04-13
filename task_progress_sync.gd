class_name TaskProgressSyncService
extends Node

## Синхронизация выполненных задач с бэкендом (GET /tasks, POST /tasks/done).
## Доступ из других скриптов: TaskProgressSyncService.get_singleton() — см. [autoload] TaskProgressSync.
## База задач (API URL): переменная окружения SCHOOLGAME_API_BASE; по умолчанию локальный бэкенд.

const _DEFAULT_API_BASE := "http://127.0.0.1:8080"

var _api_base: String = _DEFAULT_API_BASE

## По умолчанию; можно переопределить переменной окружения TASK_USER_ID.
var user_id: int = 1

## id в игре → id задачи в БД (см. backend/db/db.go INSERT INTO tasks)
const GAME_TO_BACKEND := {
	"bubble_sort": 1,
	"binary-search": 2,
	"hash-tables": 3,
}

const BACKEND_TO_GAME := {
	1: "bubble_sort",
	2: "binary-search",
	3: "hash-tables",
}

var _post_http: HTTPRequest
var _get_http: HTTPRequest
var _fetch_done: Callable = Callable()
var _fetch_target: Dictionary = {}


static func get_singleton() -> TaskProgressSyncService:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("TaskProgressSync") as TaskProgressSyncService


func _ready() -> void:
	var api := OS.get_environment("SCHOOLGAME_API_BASE").strip_edges().rstrip("/")
	if api != "":
		_api_base = api

	var e := OS.get_environment("TASK_USER_ID").strip_edges()
	if e.is_valid_int():
		user_id = int(e)

	_post_http = HTTPRequest.new()
	add_child(_post_http)
	_post_http.request_completed.connect(_on_post_completed)

	_get_http = HTTPRequest.new()
	add_child(_get_http)
	_get_http.request_completed.connect(_on_get_completed)


func push_task_completed(game_task_id: String) -> void:
	if not GAME_TO_BACKEND.has(game_task_id):
		return
	var payload := JSON.stringify({
		"user_id": user_id,
		"task_id": GAME_TO_BACKEND[game_task_id],
	})
	var err := _post_http.request(
		_api_base + "/tasks/done",
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		payload
	)
	if err != OK:
		push_warning("TaskProgressSync: не удалось отправить POST /tasks/done")


func _on_post_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_warning("TaskProgressSync: сеть при сохранении на бэке")
		return
	if response_code < 200 or response_code >= 300:
		push_warning("TaskProgressSync: бэкенд %d %s" % [response_code, body.get_string_from_utf8()])


## Дополняет переданный словарь выполненными задачами с сервера; по завершении вызывает callback.
func fetch_into(completed_tasks: Dictionary, on_done: Callable = Callable()) -> void:
	_fetch_target = completed_tasks
	_fetch_done = on_done
	var err := _get_http.request(_api_base + "/tasks?user_id=" + str(user_id), [], HTTPClient.METHOD_GET)
	if err != OK:
		push_warning("TaskProgressSync: не удалось запросить GET /tasks")
		if on_done.is_valid():
			on_done.call()


func _on_get_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var done := _fetch_done
	var target := _fetch_target
	_fetch_done = Callable()
	_fetch_target = {}

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("TaskProgressSync: загрузка прогресса %d" % response_code)
		if done.is_valid():
			done.call()
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_ARRAY:
		if done.is_valid():
			done.call()
		return

	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var bid: int = int(item.get("id", 0))
		if BACKEND_TO_GAME.has(bid):
			target[BACKEND_TO_GAME[bid]] = true

	if done.is_valid():
		done.call()
