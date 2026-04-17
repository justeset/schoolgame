extends Node2D

@onready var tutorial_chat: CanvasLayer = $TutorialChat

func _ready() -> void:
	print("=== LEVEL_1 READY ===")
	
	# Подключаем сигнал от обучения
	if tutorial_chat:
		print("TutorialChat найден")
		if tutorial_chat.has_signal("tutorial_finished"):
			if not tutorial_chat.tutorial_finished.is_connected(_on_tutorial_finished):
				tutorial_chat.tutorial_finished.connect(_on_tutorial_finished)
				print("Сигнал tutorial_finished подключен")
		else:
			print("ОШИБКА: сигнал не найден")
	else:
		print("ОШИБКА: TutorialChat не найден")
		# Если обучения нет - сразу спавним игрока
		call_deferred("_apply_pending_spawn")

func _on_tutorial_finished() -> void:
	print("Обучение завершено, спавним игрока")
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
