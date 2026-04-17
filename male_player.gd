extends CharacterBody2D


const SPEED = 150.0

@onready var anim = $AnimatedSprite2D

var facing_left: bool = false

func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		facing_left = direction < 0.0
	anim.flip_h = facing_left

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
