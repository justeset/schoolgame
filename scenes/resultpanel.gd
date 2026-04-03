extends CanvasLayer

signal continue_pressed(success: bool)
signal retry_pressed

@onready var card: Panel = $Card
@onready var overlay: ColorRect = $Overlay
@onready var icon_label: Label = $Card/VBoxContainer/Icon
@onready var title_label: Label = $Card/VBoxContainer/Title
@onready var explanation_label: RichTextLabel = $Card/VBoxContainer/Explanation
@onready var hint_label: Label = $Card/VBoxContainer/Hint
@onready var retry_button: Button = $Card/VBoxContainer/Buttons/RetryButton
@onready var continue_button: Button = $Card/VBoxContainer/Buttons/ContinueButton

var was_successful: bool = false

func _ready() -> void:
	overlay.modulate.a = 1.0
	card.scale = Vector2.ONE
	card.modulate.a = 1.0

func show_result(success: bool, title: String, explanation: String, hint: String = "") -> void:
	was_successful = success
	
	if success:
		icon_label.text = "✓"
		icon_label.modulate = Color(0, 0.9, 0.75)
		title_label.modulate = Color(0, 0.9, 0.75)
		continue_button.text = "Продолжить"
		retry_button.visible = false
	else:
		icon_label.text = "✕"
		icon_label.modulate = Color(1, 0.35, 0.35)
		title_label.modulate = Color(1, 0.35, 0.35)
		continue_button.text = "Закрыть"
		retry_button.visible = true
	
	title_label.text = title
	explanation_label.text = explanation
	
	if hint.strip_edges() != "":
		hint_label.text = hint
		hint_label.visible = true
	else:
		hint_label.visible = false


func _on_retry_button_pressed() -> void:
	queue_free()
	emit_signal("retry_pressed")


func _on_continue_button_pressed() -> void:
	queue_free()
	emit_signal("continue_pressed", was_successful)
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
