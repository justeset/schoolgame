extends Area2D

@onready var sprite = $"."

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.modulate = Color(1.05, 1.05, 1.05)

func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
	
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file("res://scenes/leaders_problem.tscn")


func _on_button_pressed() -> void:
	_clear_progress()
	get_tree().change_scene_to_file("res://mainmenu.tscn")
	
func _clear_progress() -> void:
	var save_file = FileAccess.open("user://tasks_progress.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var({})
