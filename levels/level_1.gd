extends Node2D


func _ready() -> void:
	call_deferred("_apply_pending_spawn")


func _apply_pending_spawn() -> void:
	if not LevelReturnState.has_pending_spawn:
		return
	var p: Node = get_tree().get_first_node_in_group("player")
	if p is CharacterBody2D:
		p.velocity = Vector2.ZERO
	if p is Node2D:
		p.global_position = LevelReturnState.pending_global_position
	LevelReturnState.clear_pending_spawn()
