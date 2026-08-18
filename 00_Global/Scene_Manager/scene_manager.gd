extends CanvasLayer

const MAIN_SCENE := preload("res://00_Global/Main_Scene/MainScene.tscn")

signal load_scene_started
signal new_scene_ready( target_name : String, offset : Vector2 )
signal load_scene_finished
signal scene_entered( uid : String )

@onready var fade: Control = $Fade

var current_scene_uid : String
var transition_locked: bool = false
var player_transfer_velocity : Vector2 = Vector2.ZERO

func _ready() -> void:
	fade.visible = false
	await get_tree().process_frame
	load_scene_finished.emit()
	pass

func transition_scene( new_scene : String, target_area : String, player_offset : Vector2, dir : String) -> void:
	
	if transition_locked:
		return
	transition_locked = true
	get_tree().paused = true
	
	var fade_pos : Vector2 = get_fade_pos( dir )
	
	fade.visible = true
	
	load_scene_started.emit()
	
	await fade_screen( fade_pos, Vector2.ZERO )
	
	var main_scene := get_tree().current_scene as MainScene
	if not main_scene:
		main_scene = MAIN_SCENE.instantiate() as MainScene
		get_tree().root.add_child(main_scene)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = main_scene

	main_scene.load_level(new_scene)
	current_scene_uid = ResourceUID.path_to_uid( new_scene )
	print( "new_scene: ", current_scene_uid )
	scene_entered.emit( current_scene_uid )
	
	await get_tree().process_frame

	new_scene_ready.emit( target_area, player_offset )
	
	await get_tree().process_frame
	await fade_screen( Vector2.ZERO, -fade_pos )
	
	fade.visible = false
	get_tree().paused = false
	load_scene_finished.emit()
	
	await get_tree().create_timer(0.35).timeout
	transition_locked = false
	pass


func fade_screen( from : Vector2, to : Vector2 ) -> Signal:
	fade.position = from
	var	tween : Tween = create_tween()
	tween.tween_property( fade, "position", to, 0.2 )
	return tween.finished
	
	
func get_fade_pos( dir : String ) -> Vector2:
	var pos : Vector2 = Vector2( 2304, 1296 )
	
	match dir:
		"left":
			pos *= Vector2( -1, 0 )
		"right":
			pos *= Vector2( 1, 0 )
		"up":
			pos *= Vector2( 0, -1 )
		"down":
			pos *= Vector2( 0, 1 )
	
	return pos
