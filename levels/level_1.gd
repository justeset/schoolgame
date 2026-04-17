extends Node2D

@onready var side_panel: Panel = $CanvasLayer/SidePanel
@onready var menu_button: Button = $CanvasLayer/MenuToggleButton

var _menu_button_closed_style: StyleBoxFlat
var _menu_button_transparent_style: StyleBoxFlat


func _ready() -> void:
	side_panel.z_index = 1
	menu_button.z_index = 10
	menu_button.move_to_front()
	_menu_button_closed_style = StyleBoxFlat.new()
	_menu_button_closed_style.bg_color = Color(0.3, 0.3, 0.3, 0.65)
	_menu_button_closed_style.corner_radius_top_left = 64
	_menu_button_closed_style.corner_radius_top_right = 64
	_menu_button_closed_style.corner_radius_bottom_right = 64
	_menu_button_closed_style.corner_radius_bottom_left = 64
	_menu_button_closed_style.border_width_left = 2
	_menu_button_closed_style.border_width_top = 2
	_menu_button_closed_style.border_width_right = 2
	_menu_button_closed_style.border_width_bottom = 2
	_menu_button_closed_style.border_color = Color(1.0, 1.0, 1.0, 0.4)
	_menu_button_transparent_style = StyleBoxFlat.new()
	_menu_button_transparent_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	side_panel.visible = false
	_update_menu_button_style()
	_apply_pending_spawn()


func _apply_pending_spawn() -> void:
	if not LevelReturnState.has_pending_spawn:
		return
	var p: Node = get_tree().get_first_node_in_group("player")
	if p is CharacterBody2D:
		p.velocity = Vector2.ZERO
	if p is Node2D:
		p.global_position = LevelReturnState.pending_global_position
	var camera := get_viewport().get_camera_2d()
	if camera != null and LevelReturnState.has_pending_camera:
		camera.global_position = LevelReturnState.pending_camera_global_position
		if camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
		if camera.has_method("force_update_scroll"):
			camera.force_update_scroll()
	LevelReturnState.clear_pending_spawn()


func _on_menu_toggle_button_pressed() -> void:
	side_panel.visible = not side_panel.visible
	_update_menu_button_style()


func _on_topics_button_pressed() -> void:
	LevelReturnState.change_scene_saving_player(get_tree(), "res://scenes/themes.tscn")


func _on_common_errors_button_pressed() -> void:
	LevelReturnState.change_scene_saving_player(get_tree(), "res://scenes/error_review.tscn")


func _on_main_menu_button_pressed() -> void:
	LevelReturnState.clear_pending_spawn()
	get_tree().change_scene_to_file("res://mainmenu.tscn")


func _update_menu_button_style() -> void:
	if side_panel.visible:
		menu_button.add_theme_stylebox_override("normal", _menu_button_transparent_style)
		menu_button.add_theme_stylebox_override("hover", _menu_button_transparent_style)
		menu_button.add_theme_stylebox_override("pressed", _menu_button_transparent_style)
	else:
		menu_button.add_theme_stylebox_override("normal", _menu_button_closed_style)
		menu_button.add_theme_stylebox_override("hover", _menu_button_closed_style)
		menu_button.add_theme_stylebox_override("pressed", _menu_button_closed_style)


func _on_tasks_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tasks.tscn")
