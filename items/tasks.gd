extends Area2D

@onready var sprite = $"."
var clicks = 0
var _player_in_range: bool = false
var _e_prev: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_physics_process(true)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = true
	sprite.modulate = Color(1.3, 1.3, 1.3)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_range = false
	sprite.modulate = Color(1, 1, 1)

func _physics_process(_delta: float) -> void:
	var e_now := Input.is_physical_key_pressed(KEY_E)
	if _player_in_range and e_now and not _e_prev:
		clicks += 1
		LevelReturnState.change_scene_saving_player(get_tree(), "res://scenes/tasks.tscn")
	_e_prev = e_now

	
