extends Area2D

@onready var sprite = $"."
@onready var elevator_warning = $Label

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.modulate = Color(1.05, 1.05, 1.05)

func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
	elevator_warning.visible = false

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			elevator_warning.visible = true
