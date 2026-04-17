extends Area2D

@onready var sprite = $"."
var _player_in_range: bool = false
var _e_prev: bool = false
var _lmb_prev: bool = false

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
	var lmb_now := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if _player_in_range and ((e_now and not _e_prev) or (lmb_now and not _lmb_prev)):
		LevelReturnState.change_scene_saving_player(get_tree(), "res://scenes/leaders_problem.tscn")
	_e_prev = e_now
	_lmb_prev = lmb_now


func _on_button_pressed() -> void:
	_clear_progress()
	LevelReturnState.clear_pending_spawn()
	get_tree().change_scene_to_file("res://mainmenu.tscn")
	
func _clear_progress() -> void:
	var save_file = FileAccess.open("user://tasks_progress.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var({})
