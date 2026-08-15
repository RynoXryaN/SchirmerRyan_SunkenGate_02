@icon( "res://Player/Sprites/input_hints.svg" )
class_name InputHints
extends Node2D

const COMBO_SPACING := 16.0
const CONTROLLER_COMBO_Y := -67
const KEYBOARD_DOWN_JUMP_ARROW_POS := Vector2(-14, -75)
const KEYBOARD_DOWN_JUMP_TEXT_POS := Vector2(0, -80)
const HINT_MAP : Dictionary = {
	"keyboard" : {
		"interact" : 13,
		"attack" : 10,
		"jump" : 9,
		"right_dash" : 11,
		"up" : 13,
		"down" : 13,
		"ball" : 11,
	},
	"playstation" : {
		"interact" : 4,
		"attack" : 2,
		"jump" : 1,
		"right_dash" : 3,
		"up" : 4,
		"down" : 4,
		"ball" : 0,
	},
	"xbox" : {
		"interact" : 4,
		"attack" : 7,
		"jump" : 5,
		"right_dash" : 6,
		"up" : 4,
		"down" : 4,
		"ball" : 8,
	}
}

var controller_type : String = "keyboard"

@onready var hint_01: Sprite2D = %Hint_01
@onready var hint_02: Sprite2D = %Hint_02
@onready var hint_03: Sprite2D = %Hint_03
@onready var hint_text: Label = %HintText



func _ready() -> void:
	visible = false
	Messages.input_hint_changed.connect( _on_hint_changed )
	pass
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		controller_type = "keyboard"

	elif event is InputEventJoypadButton:
		get_controller_type(event.device)

	elif event is InputEventJoypadMotion:
		if abs(event.axis_value) > 0.35:
			get_controller_type(event.device)
		
func get_controller_type( device_id : int ) -> void:
	var n : String = Input.get_joy_name( device_id ).to_lower()
	
	if "xbox" in n or "x-box" in n or "stealth" in n or "turtle" in n:
		controller_type = "xbox"
	elif "playstation" in n or "ps" in n or "dualsense" in n:
		controller_type = "playstation"
	else:
		controller_type = "xbox"
	print(controller_type)
	set_process_input( false )
	pass
	
func _on_hint_changed(hint: String) -> void:
	if hint == "":
		visible = false
		return

	visible = true

	_reset_hints()

	if hint == "down_jump" and controller_type == "keyboard":
		_show_keyboard_down_jump()
		return
	
	match hint:
		"down_jump":
			_show_combo(["down", "jump"])

		"ground_slam":
			_show_combo(["down", "attack"])

		_:
			_show_single(hint)
	pass


func _reset_hints() -> void:
	hint_01.visible = false
	hint_02.visible = false
	hint_03.visible = false
	hint_text.visible = false

	hint_01.flip_v = false
	hint_02.flip_v = false
	hint_03.flip_v = false

	hint_01.position.x = 0
	hint_02.position.x = 0
	hint_03.position.x = 0
	hint_text.position.x = 0


func _show_single(hint: String) -> void:
	hint_01.visible = true
	hint_01.frame = HINT_MAP[controller_type].get(hint, 0)
	hint_01.position.x = 0

	if hint == "down":
		hint_01.flip_v = true


func _show_combo(hints: Array[String]) -> void:
	var sprites: Array[Sprite2D] = [hint_01, hint_02, hint_03]

	var spacing := 16.0
	var start_x := -spacing * float(hints.size() - 1) / 2.0

	for i in hints.size():
		var hint_name := hints[i]
		var sprite := sprites[i]

		sprite.visible = true
		sprite.frame = HINT_MAP[controller_type].get(hint_name, 0)
		sprite.position.x = start_x + spacing * i
		sprite.flip_v = hint_name == "down"
		
func _show_keyboard_down_jump() -> void:
	hint_01.visible = true
	hint_01.frame = HINT_MAP[controller_type].get("down", 0)
	hint_01.flip_v = true
	hint_01.position = KEYBOARD_DOWN_JUMP_ARROW_POS

	hint_02.visible = false
	hint_03.visible = false

	hint_text.visible = true
	hint_text.text = "SPACE"
	hint_text.position = KEYBOARD_DOWN_JUMP_TEXT_POS
	
