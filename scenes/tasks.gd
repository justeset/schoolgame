extends Control

@onready var tasks_container: VBoxContainer = $Board/TasksContainer

var custom_font = preload("res://fonts/kom-post.ttf")

var tasks_data = [
	{ "id": "bubble_sort",  "text": "Проверить таблицу лидеров" },
	{ "id": "hash-tables",  "text": "Проверить вендиговый аппарат" },
	{ "id": "binary-search", "text": "Проверить стеллаж с книгами" }
]

var completed_tasks: Dictionary = {}

func _ready() -> void:
	set_process_unhandled_input(true)
	load_progress()
	var sync := TaskProgressSyncService.get_singleton()
	if sync:
		sync.fetch_into(
			completed_tasks,
			func(): save_progress(); create_task_list()
		)
	else:
		create_task_list()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_button_pressed()

func create_task_list() -> void:
	for child in tasks_container.get_children():
		child.queue_free()

	for task in tasks_data:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 85)
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 10)

		var label = Label.new()
		label.text = task.text
		label.add_theme_font_override("font", custom_font)
		label.add_theme_font_size_override("font_size", 34)
		label.add_theme_color_override("font_color", Color.BLACK)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if completed_tasks.get(task.id, false):
			label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))

		row.add_child(label)

		var mark = Label.new()
		mark.text = "✓" if completed_tasks.get(task.id, false) else ""
		mark.custom_minimum_size = Vector2(28, 0)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_font_override("font", custom_font)
		mark.add_theme_font_size_override("font_size", 32)
		mark.add_theme_color_override("font_color", Color.BLACK)
		row.add_child(mark)

		tasks_container.add_child(row)

func mark_task_completed(task_id: String) -> void:
	completed_tasks[task_id] = true
	save_progress()
	var sync := TaskProgressSyncService.get_singleton()
	if sync:
		sync.push_task_completed(task_id)
	create_task_list()

func save_progress() -> void:
	var file = FileAccess.open("user://tasks_progress.save", FileAccess.WRITE)
	if file:
		file.store_var(completed_tasks)

func load_progress() -> void:
	if FileAccess.file_exists("user://tasks_progress.save"):
		var file = FileAccess.open("user://tasks_progress.save", FileAccess.READ)
		if file:
			completed_tasks = file.get_var()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
