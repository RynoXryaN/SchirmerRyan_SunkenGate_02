@tool
class_name HintTrigger
extends Area2D


enum HintType {
	NONE,
	INTERACT,
	ATTACK,
	JUMP,
	DOWN,
	DOWN_JUMP,
	DASH,
	BALL,
	GROUND_SLAM
}


const TILE_SIZE: int = 32

#region /// sizing

@export_range(1, 20, 1, "or_greater") var area_width_units: int = 3:
	set(value):
		area_width_units = value
		_update_area_size()

@export_range(1, 20, 1, "or_greater") var area_height_units: int = 2:
	set(value):
		area_height_units = value
		_update_area_size()

#endregion

#region /// export variables

@export var display_time: float = 10.0
@export var show_hud_label: bool = true
@export var show_input_hint: bool = true
@export var show_once: bool = true
@export var keep_message_while_inside: bool = false

@export var hint_type: HintType = HintType.DOWN
@export_multiline var message: String = "Press DOWN + JUMP to drop through thin platforms."

@export var requires_ability: bool = false
@export var required_ability_name: String = "ground_slam"

@export_multiline var locked_message: String = "This floor looks fragile, but you need another ability."
@export_multiline var unlocked_message: String = "While airborne, press DOWN + ATTACK to smash fragile floors."

@export var locked_hint_type: HintType = HintType.NONE
@export var unlocked_hint_type: HintType = HintType.GROUND_SLAM

#endregion


@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var has_shown: bool = false
var player_inside: bool = false
var shape_is_unique: bool = false


func _ready() -> void:
	_update_area_size()

	if Engine.is_editor_hint():
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	#print("HINT TRIGGER ENTERED BY: ", body.name)

	if not body.is_in_group("Player"):
		#print("HINT TRIGGER: body is not Player")
		return

	#print("HINT TRIGGER: Player entered")

	player_inside = true

	var message_to_show: String = message
	var hint_to_show: HintType = hint_type

	if requires_ability:
		if _has_required_ability():
			message_to_show = unlocked_message
			hint_to_show = unlocked_hint_type
		else:
			message_to_show = locked_message
			hint_to_show = locked_hint_type

	if show_input_hint:
		Messages.input_hint_changed.emit(_get_hint_name_from_type(hint_to_show))

	if not show_hud_label:
		return

	if show_once and has_shown:
		return

	has_shown = true

	if keep_message_while_inside:
		Messages.message_requested.emit(message_to_show, 9999.0)
	else:
		Messages.message_requested.emit(message_to_show, display_time)
	pass


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	player_inside = false

	if show_input_hint:
		Messages.input_hint_changed.emit("")

	if keep_message_while_inside:
		Messages.message_requested.emit("", 0.0)


func _get_hint_name() -> String:
	return _get_hint_name_from_type(hint_type)
	
func _get_hint_name_from_type(type_to_check: HintType) -> String:
	match type_to_check:
		HintType.INTERACT:
			return "interact"
		HintType.ATTACK:
			return "attack"
		HintType.JUMP:
			return "jump"
		HintType.DOWN:
			return "down"
		HintType.DOWN_JUMP:
			return "down_jump"
		HintType.DASH:
			return "dash"
		HintType.BALL:
			return "ball"
		HintType.GROUND_SLAM:
			return "ground_slam"

	return ""





func _update_area_size() -> void:
	if not is_inside_tree():
		return

	if not collision_shape:
		return

	if collision_shape.shape == null or not collision_shape.shape is RectangleShape2D:
		collision_shape.shape = RectangleShape2D.new()
		shape_is_unique = true

	if not shape_is_unique:
		collision_shape.shape = collision_shape.shape.duplicate()
		shape_is_unique = true

	var pixel_size := Vector2(
		area_width_units * TILE_SIZE,
		area_height_units * TILE_SIZE
	)

	collision_shape.shape.size = pixel_size
	pass
	
		
func _has_required_ability() -> bool:
	return SaveManager.persistent_data.get(required_ability_name, "") == "acquired"
	
