@tool
@icon( "res://General/Icons/level_transition.svg" )
class_name LevelTransition
extends Node2D

enum SIDE { LEFT, RIGHT, TOP, BOTTOM }
enum TRIGGER_TYPE { TOUCH, INTERACT }

@export_range( 2, 12, 1, "or greater" ) var size : int = 2 :
	set( value ):
		size = value
		apply_area_settings()

@export_range( 1, 12, 1, "or greater" ) var area_width : int = 1 :
	set( value ):
		area_width = value
		apply_area_settings()

@export_range( 2, 12, 1, "or greater" ) var area_height : int = 2 :
	set( value ):
		area_height = value
		apply_area_settings()
		
@export var location : SIDE = SIDE.LEFT :
	set( value ):
		location = value
		apply_area_settings()

@export var trigger_type : TRIGGER_TYPE = TRIGGER_TYPE.TOUCH :
	set(value):
		trigger_type = value
		apply_area_settings()

@export_file( "*.tscn" ) var target_level
@export var target_area_name : String = "LevelTransition"

@onready var area_2d: Area2D = $Area2D
@onready var editor_label: Label = $EditorLabel

var player_in_area: Node2D = null


func _ready() -> void:
	if Engine.is_editor_hint():
		update_editor_label()
		return
		
	editor_label.hide()
	
	#area_2d.body_entered.connect( _on_player_entered )
	
	SceneManager.new_scene_ready.connect( _on_new_scene_ready )
	SceneManager.load_scene_finished.connect( _on_load_scene_finished )

func _process( _delta: float ) -> void:
	if Engine.is_editor_hint():
		update_editor_label()
		return
		
	if trigger_type == TRIGGER_TYPE.INTERACT:
		if player_in_area and Input.is_action_just_pressed( "action_interact" ):
			_transition_player(player_in_area)


func _on_player_entered( _n : Node2D ) -> void:
	if not _n.is_in_group("Player"):
		return
	
	if trigger_type == TRIGGER_TYPE.TOUCH:
		_transition_player(_n)
	elif trigger_type == TRIGGER_TYPE.INTERACT:
		player_in_area = _n
		print("Player near transition.  Press Interact.")
		Messages.input_hint_changed.emit( "interact" )
	#SceneManager.transition_scene( target_level, target_area_name, get_offset( _n ), get_transition_direction() )
	#print("LOCATION = ", location, " DIRECTION = ", get_transition_direction())
	pass

func _on_player_exited( _n : Node2D ) -> void:
	Messages.input_hint_changed.emit( "" )
	if _n == player_in_area:
		player_in_area = null

func _transition_player( player : Node2D ) -> void:
	#SceneManager.player_transfer_velocity = player.velocity
#
	#if location == SIDE.TOP:
		#SceneManager.player_transfer_velocity.y = min(player.velocity.y, -350.0)
#
	#elif location == SIDE.BOTTOM:
		#SceneManager.player_transfer_velocity.y = max(player.velocity.y, 350.0)
		
		
	SceneManager.transition_scene(
		target_level,
		target_area_name,
		get_offset( player ),
		get_transition_direction() )
	print("LOCATION = ", location, " DIRECTION = ", get_transition_direction())

func _on_new_scene_ready( target_name : String, offset : Vector2 ) -> void:
	if target_name == name:
		var player : Node = get_tree().get_first_node_in_group( "Player" )
		player.global_position = global_position + offset
		
		#if "velocity" in player:
			#player.velocity = SceneManager.player_transfer_velocity
	pass

func _on_load_scene_finished() -> void:
	area_2d.monitoring = false
	
	if not area_2d.body_entered.is_connected(_on_player_entered):
		area_2d.body_entered.connect( _on_player_entered )
		
	if not area_2d.body_exited.is_connected(_on_player_exited):
		area_2d.body_exited.connect( _on_player_exited )

	await get_tree().physics_frame
	await get_tree().physics_frame
	
	area_2d.monitoring = true

func apply_area_settings() -> void:
	area_2d = get_node_or_null("Area2D")
	if not area_2d:
		return

	area_2d.position = Vector2.ZERO
	area_2d.scale = Vector2.ONE
	
	if trigger_type == TRIGGER_TYPE.INTERACT:
		area_2d.scale.x = area_width
		area_2d.scale.y = area_height
		return

	if location == SIDE.LEFT or location == SIDE.RIGHT:
		area_2d.scale.y = size

		if location == SIDE.LEFT:
			area_2d.position.x = -32
		elif location == SIDE.RIGHT:
			area_2d.position.x = 0

	elif location == SIDE.TOP or location == SIDE.BOTTOM:
		area_2d.scale.x = size

		if location == SIDE.TOP:
			area_2d.position.y = 0
		elif location == SIDE.BOTTOM:
			area_2d.position.y = 32
			
			
func get_offset( player : Node2D ) -> Vector2:
	var offset : Vector2 = Vector2.ZERO
	var player_pos : Vector2 = player.global_position
	
	if location == SIDE.LEFT or location == SIDE.RIGHT:
		offset.y = player_pos.y - self.global_position.y
		if location == SIDE.LEFT:
			offset.x = -12
		elif location == SIDE.RIGHT:
			offset.x = 12
	elif location == SIDE.TOP or location == SIDE.BOTTOM:
		offset.x = player_pos.x - self.global_position.x
		if location == SIDE.TOP:
			offset.y = -48
		elif location == SIDE.BOTTOM:
			offset.y = 48
	
	return offset
	
func get_transition_direction() -> String:
	if location == SIDE.LEFT:
		return "left"
	elif location == SIDE.RIGHT:
		return "right"
	elif location == SIDE.TOP:
		return "up"
	elif location == SIDE.BOTTOM:
		return "bottom"
	
	return "bottom"
	
func update_editor_label() -> void:
	if not is_instance_valid(editor_label):
		return

	editor_label.text = name
	editor_label.position = Vector2( -editor_label.size.x / 2.0, -32.0 )
	pass
	
