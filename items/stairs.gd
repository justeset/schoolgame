extends Area2D

enum StairsRole {
	FLOOR_1,
	FLOOR_2,
	FLOOR_3
}

@export var stairs_role: StairsRole = StairsRole.FLOOR_2
## Локальная точка на узле лестницы, в которой центрируется рамка со стрелками (по умолчанию центр коллизии).
@export var choice_ui_center_local: Vector2 = Vector2(0, 57)

const LANDING_1 := Vector2(1435, 569)
const LANDING_2 := Vector2(1435, 293)
const LANDING_3 := Vector2(1435, 61)

const ARROW_BLUE := Color(0.55, 0.82, 1.0, 0.5)

## Размер рамки (должен совпадать с custom_minimum_size панели).
const CHOICE_FRAME_SIZE := Vector2(52, 78)

var _player_in: CharacterBody2D = null
var _busy: bool = false
var _e_prev: bool = false
var _mouse_left_prev: bool = false

var _floor2_choice_layer: CanvasLayer = null
var _floor2_choice_pos_root: Control = null
var _choice_frame_half: Vector2 = CHOICE_FRAME_SIZE * 0.5


func _ready() -> void:
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(false)


func _process(_delta: float) -> void:
	if _floor2_choice_pos_root == null or not is_instance_valid(_floor2_choice_pos_root):
		return
	var center_canvas: Vector2 = get_viewport().get_canvas_transform() * to_global(choice_ui_center_local)
	_floor2_choice_pos_root.position = center_canvas - _choice_frame_half


func _physics_process(_delta: float) -> void:
	if _busy or _player_in == null:
		_e_prev = Input.is_physical_key_pressed(KEY_E)
		_mouse_left_prev = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		return
	var e_now := Input.is_physical_key_pressed(KEY_E)
	var mouse_now := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if (e_now and not _e_prev) or (mouse_now and not _mouse_left_prev):
		_try_use_stairs()
	_e_prev = e_now
	_mouse_left_prev = mouse_now


func _unhandled_input(event: InputEvent) -> void:
	if _floor2_choice_layer == null or not is_instance_valid(_floor2_choice_layer):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_stairs_dialog(_floor2_choice_layer)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in = body as CharacterBody2D


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in:
		_player_in = null


func _try_use_stairs() -> void:
	if _busy or _player_in == null:
		return
	match stairs_role:
		StairsRole.FLOOR_1:
			_busy = true
			_teleport_player(LANDING_2)
			_busy = false
		StairsRole.FLOOR_3:
			_busy = true
			_teleport_player(LANDING_2)
			_busy = false
		StairsRole.FLOOR_2:
			_open_floor2_choice()


func _teleport_player(pos: Vector2) -> void:
	if _player_in == null:
		return
	_player_in.velocity = Vector2.ZERO
	_player_in.global_position = pos


func _open_floor2_choice() -> void:
	_busy = true
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_floor2_choice_layer = layer
	
	var pos_root := Control.new()
	pos_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pos_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pos_root.custom_minimum_size = CHOICE_FRAME_SIZE
	_floor2_choice_pos_root = pos_root
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CHOICE_FRAME_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.42, 0.44, 0.47, 0.55)
	frame.border_color = Color(0.62, 0.64, 0.67, 0.72)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(4)
	frame.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", frame)
	
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var btn_up := _make_arrow_button("▲")
	var btn_dn := _make_arrow_button("▼")
	btn_up.pressed.connect(_on_floor2_chose_up.bind(layer))
	btn_dn.pressed.connect(_on_floor2_chose_down.bind(layer))
	
	vb.add_child(btn_up)
	vb.add_child(btn_dn)
	panel.add_child(vb)
	pos_root.add_child(panel)
	layer.add_child(pos_root)
	get_tree().root.add_child(layer)
	var center_canvas: Vector2 = get_viewport().get_canvas_transform() * to_global(choice_ui_center_local)
	pos_root.position = center_canvas - _choice_frame_half
	set_process(true)


func _make_arrow_button(arrow: String) -> Button:
	var b := Button.new()
	b.flat = true
	b.text = arrow
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(40, 30)
	var nf := load("res://fonts/NotoSans-Regular.ttf")
	if nf:
		b.add_theme_font_override("font", nf)
	b.add_theme_font_size_override("font_size", 30)
	var c := ARROW_BLUE
	var outline := Color(c.r * 0.35, c.g * 0.45, c.b * 0.55, 0.85)
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_color_override("font_outline_color", outline)
	b.add_theme_color_override("font_color", c)
	b.add_theme_color_override("font_focus_color", c)
	b.add_theme_color_override("font_hover_color", Color(c.r, c.g, c.b, min(c.a + 0.22, 0.92)))
	b.add_theme_color_override("font_pressed_color", Color(c.r, c.g, c.b, 0.92))
	return b


func _on_floor2_chose_up(layer: CanvasLayer) -> void:
	_teleport_player(LANDING_3)
	_close_stairs_dialog(layer)


func _on_floor2_chose_down(layer: CanvasLayer) -> void:
	_teleport_player(LANDING_1)
	_close_stairs_dialog(layer)


func _close_stairs_dialog(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
	_floor2_choice_layer = null
	_floor2_choice_pos_root = null
	set_process(false)
	_busy = false
