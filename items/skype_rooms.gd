extends Area2D

@onready var sprite = $"."

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.modulate = Color(1.05, 1.05, 1.05)

func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
