extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const ACTION_JUMP := "jump"

@onready var anim = $AnimatedSprite2D

var facing_left: bool = false

func _ready() -> void:
	add_to_group("player")
	_ensure_jump_action_mapped()


func _ensure_jump_action_mapped() -> void:
	if InputMap.has_action(ACTION_JUMP):
		return
	InputMap.add_action(ACTION_JUMP)
	for code in [KEY_SPACE, KEY_UP, KEY_W]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		InputMap.action_add_event(ACTION_JUMP, ev)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		facing_left = direction < 0.0
	anim.flip_h = facing_left

	if Input.is_action_just_pressed(ACTION_JUMP) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if is_on_floor():
		anim.play("walk" if direction else "default")
	else:
		if anim.animation != &"jump":
			anim.play(&"jump")
