extends CanvasLayer

const CHAT_IMAGE_TEX: Texture2D = preload("res://пикчи3/pic2.png")
const CHAT_FONT_SIZE := 26
const CHAT_TEXT_COLOR := Color(0.92, 0.95, 1.0, 1.0)

const CHAT_MESSAGES: Array[Dictionary] = [
	{ "text": "О НЕТ!!!" },
	{ "text": "", "image": CHAT_IMAGE_TEX },
	{ "text": "Таблица лидеров сломалась!!! Все места перемешались, нужно срочно починить сортировку." },
	{ "text": "Поможешь?" },
]

@export var delay_per_message_sec: float = 1.2

@onready var messages_container: VBoxContainer = $Panel/MainVBox/ChatMargin/ChatScroll/Messages
@onready var solve_button: Button = $Panel/SolveButton
@onready var back_bottom_button: Button = $Panel/BackBottom

var _chat_running: bool = false
var _skip_requested: bool = false


func _ready() -> void:
	set_process_unhandled_input(true)
	# Важно: снимаем паузу при входе в сцену
	get_tree().paused = false

	solve_button.visible = false
	solve_button.disabled = true
	back_bottom_button.visible = false
	back_bottom_button.disabled = true
	_play_chat()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if back_bottom_button.visible and not back_bottom_button.disabled:
			get_viewport().set_input_as_handled()
			_on_back_bottom_pressed()
		return
	if not _chat_running:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			_skip_requested = true
			get_viewport().set_input_as_handled()


func _play_chat() -> void:
	_chat_running = true
	_skip_requested = false
	_clear_container(messages_container)

	for i in range(CHAT_MESSAGES.size()):
		var data: Dictionary = CHAT_MESSAGES[i]
		var bubble: Control = _make_bubble(data)
		messages_container.add_child(bubble)

		await get_tree().process_frame
		_scroll_chat_to_bottom()

		if _skip_requested:
			bubble.modulate.a = 1.0
			await _add_remaining_bubbles_instant(i + 1)
			break

		var tw := create_tween()
		tw.tween_property(bubble, "modulate:a", 1.0, 0.3)
		while tw.is_running():
			if _skip_requested:
				tw.kill()
				bubble.modulate.a = 1.0
				break
			await get_tree().process_frame

		if _skip_requested:
			await _add_remaining_bubbles_instant(i + 1)
			break

		var wait_deadline_usec: int = Time.get_ticks_usec() + int(delay_per_message_sec * 1_000_000.0)
		while Time.get_ticks_usec() < wait_deadline_usec:
			if _skip_requested:
				break
			await get_tree().process_frame

		if _skip_requested:
			await _add_remaining_bubbles_instant(i + 1)
			break

	_chat_running = false
	solve_button.visible = true
	solve_button.disabled = false
	back_bottom_button.visible = true
	back_bottom_button.disabled = false


func _add_remaining_bubbles_instant(from_index: int) -> void:
	for j in range(from_index, CHAT_MESSAGES.size()):
		var bubble: Control = _make_bubble(CHAT_MESSAGES[j])
		bubble.modulate.a = 1.0
		messages_container.add_child(bubble)
	await get_tree().process_frame
	_scroll_chat_to_bottom()


func _scroll_chat_to_bottom() -> void:
	var scroll := $Panel/MainVBox/ChatMargin/ChatScroll as ScrollContainer
	if scroll:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value


func _make_bubble(data: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_FILL
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.modulate.a = 0.0

	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bubble)

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_FILL
	inner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.add_child(inner)

	var style := StyleBoxFlat.new()
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.bg_color = Color(0.16, 0.22, 0.38, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.89, 0.71, 0.75)
	bubble.add_theme_stylebox_override("panel", style)

	var text_value := str(data.get("text", ""))
	if text_value != "":
		var label := Label.new()
		label.text = text_value
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", CHAT_FONT_SIZE)
		label.add_theme_color_override("font_color", CHAT_TEXT_COLOR)
		label.custom_minimum_size = Vector2(520, 0)
		label.size_flags_horizontal = Control.SIZE_FILL
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inner.add_child(label)

	if data.has("image") and data["image"] != null:
		var img := TextureRect.new()
		img.texture = data["image"]
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		img.custom_minimum_size = Vector2(260, 150)
		img.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		img.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		inner.add_child(img)

	return row


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _on_solve_button_pressed() -> void:
	# Снимаем паузу перед переходом (на всякий случай)
	get_tree().paused = false
	get_tree().change_scene_to_file.bind("res://scenes/leaders_challenge.tscn").call_deferred()


func _on_back_bottom_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
