extends CanvasLayer

signal closed_pressed

@onready var overlay: ColorRect = $Overlay
@onready var title_label: Label = $Card/VBoxContainer/Title
@onready var body_label: RichTextLabel = $Card/VBoxContainer/BodyScroll/Body


func _ready() -> void:
	var font = load("res://fonts/NotoSans-Regular.ttf")
	if font:
		title_label.add_theme_font_override("font", font)
		body_label.add_theme_font_override("normal_font", font)
	body_label.scroll_active = false


func show_hint(text: String) -> void:
	body_label.text = text


func _on_close_button_pressed() -> void:
	queue_free()
	emit_signal("closed_pressed")
