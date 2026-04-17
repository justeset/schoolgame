extends Node

## Запоминает позицию игрока при уходе с level_1 в сцены заданий и восстанавливает при возврате.

var has_pending_spawn: bool = false
var pending_global_position: Vector2 = Vector2.ZERO
var has_pending_camera: bool = false
var pending_camera_global_position: Vector2 = Vector2.ZERO


func clear_pending_spawn() -> void:
	has_pending_spawn = false
	has_pending_camera = false


func change_scene_saving_player(scene_tree: SceneTree, path: String) -> void:
	var p: Node = scene_tree.get_first_node_in_group("player")
	if p is Node2D:
		pending_global_position = p.global_position
		has_pending_spawn = true
	var current_camera := scene_tree.root.get_viewport().get_camera_2d()
	if current_camera != null:
		pending_camera_global_position = current_camera.global_position
		has_pending_camera = true
	scene_tree.change_scene_to_file(path)
