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

func transition_scene(
	new_scene: String,
	target_area: String,
	player_offset: Vector2,
	dir: String,
	player_spawn_position: Variant = null,
	player_setup: Callable = Callable(),
	replace_player: bool = false
) -> void:
	
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

	var loaded_scene := main_scene.load_level(new_scene)
	if not loaded_scene:
		push_error("Scene transition failed to load: %s" % new_scene)
		fade.visible = false
		get_tree().paused = false
		transition_locked = false
		return

	if is_playable_scene(new_scene):
		if replace_player:
			main_scene.clear_player()
		var player := main_scene.ensure_player_exists(player_spawn_position)
		if player_setup.is_valid():
			player_setup.call(player)
	else:
		# Menu-only scenes must not retain a dead or hidden gameplay Player.
		main_scene.clear_player()

	current_scene_uid = ResourceUID.path_to_uid(resolve_scene_path(new_scene))
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


func is_playable_scene(scene_reference: String) -> bool:
	return resolve_scene_path(scene_reference).begins_with("res://Levels/")


func resolve_scene_path(scene_reference: String) -> String:
	if scene_reference.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(scene_reference)
		if uid != ResourceUID.INVALID_ID and ResourceUID.has_id(uid):
			return ResourceUID.get_id_path(uid)
	return scene_reference


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
