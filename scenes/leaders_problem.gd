extends CanvasLayer

const CHAT_IMAGE_TEX: Texture2D = preload("res://пикчи3/pic2.png")
const CHAT_FONT_SIZE := 26
const CHAT_TEXT_COLOR := Color("e9eefc")

const CHAT_MESSAGES: Array[Dictionary] = [
	{ "text": "О НЕТ!!!" },
	{ "text": "", "image": CHAT_IMAGE_TEX },
	{ "text": "Таблица лидеров сломалась!!! Все места перемешались, нужно срочно починить сортировку." },
	{ "text": "Поможешь?" },
]

@export var delay_per_message_sec: float = 1.2

@onready var messages_container: VBoxContainer = $Panel/MainVBox/ChatMargin/ChatScroll/Messages
@onready var solve_button: Button = $Panel/SolveButton

func _ready() -> void:
	solve_button.visible = false
	solve_button.disabled = true
	_play_chat()

func _play_chat() -> void:
	_clear_container(messages_container)

	for data in CHAT_MESSAGES:
		var bubble := _make_bubble(data)
		messages_container.add_child(bubble)
		_scroll_to_bottom()

		# плавное появление
		var tween := create_tween()
		tween.tween_property(bubble, "modulate:a", 1.0, 0.2)

		await get_tree().create_timer(delay_per_message_sec).timeout

	solve_button.visible = true
	solve_button.disabled = false

	solve_button.visible = true
	solve_button.disabled = false

func _make_bubble(data: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_FILL

	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(bubble)

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	inner.alignment = BoxContainer.ALIGNMENT_BEGIN
	bubble.add_child(inner)

	# --- стиль пузыря ---
	var style := StyleBoxFlat.new()
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.bg_color = Color("2732e5ff") if (data.has("image") and data["image"] != null) else Color("283361")
	bubble.add_theme_stylebox_override("panel", style)

	# --- текст ---
	var text_value := str(data.get("text", ""))
	if not text_value.is_empty():
		var label := Label.new()
		label.text = text_value
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", CHAT_FONT_SIZE)
		label.add_theme_color_override("font_color", CHAT_TEXT_COLOR)
		label.add_theme_color_override("font_color", Color("e9eefc"))
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		# Делаем пузырек "по тексту", но с ограничением max ширины
		var max_bubble_text_width := 540.0
		var font: Font = label.get_theme_default_font()
		var font_size: int = label.get_theme_default_font_size()
		var text_width := font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

		if text_width > max_bubble_text_width:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size = Vector2(max_bubble_text_width, 0)
		else:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF

		inner.add_child(label)

	# --- картинка ---
	if data.has("image") and data["image"] != null:
		var img := TextureRect.new()
		img.texture = data["image"]
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		img.custom_minimum_size = Vector2(260, 150)
		img.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		inner.add_child(img)

	row.modulate.a = 0.0
	return row

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _scroll_to_bottom() -> void:
	var parent_node := messages_container.get_parent()
	if parent_node is ScrollContainer:
		var scroll := parent_node as ScrollContainer
		var bar: ScrollBar = scroll.get_v_scroll_bar()
		if bar:
			scroll.scroll_vertical = bar.max_value

func _on_solve_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
