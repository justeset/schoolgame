extends Area2D

@onready var sprite = $"."

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
	
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			LevelReturnState.change_scene_saving_player(get_tree(), "res://scenes/comp_scene.tscn")
