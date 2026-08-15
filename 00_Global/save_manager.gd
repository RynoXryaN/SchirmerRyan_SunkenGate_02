#Save Manager Script
extends Node

const SLOTS : Array[ String ] = [
	"save_01", "save_02", "save_03"
]

var current_slot : int = 0
var save_data : Dictionary
var discovered_areas : Array = []
var persistent_data : Dictionary ={}



func _ready() -> void:
	
	pass
	
	
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			save_game()
		elif event.keycode == KEY_F7:
			load_game( current_slot )
	pass
	
	
	
func create_new_game_save( slot : int ) -> void:
	current_slot = slot
	var new_game_scene : String = "uid://b5beoshdgyky1"
	discovered_areas.append( new_game_scene )
	save_data = {
		"scene_path" : new_game_scene,
		# check coordinates
		"x" : 60,
		"y" : 230,
		"hp" : 20,
		"max_hp" : 20,
		"right_dash" : false,
		"double_jump" : false,
		"ground_slam" : false,
		"morph_roll" : false,
		"discovered_areas" : discovered_areas, 
		"persistent_data" : persistent_data
	}
	# Save game data
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.WRITE )
	save_file.store_line( JSON.stringify(save_data) )
	
	save_file.close()
	
	load_game( slot )
	pass
	
func save_game() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	save_data = {
		"scene_path" : SceneManager.current_scene_uid,
		# check coordinates
		"x" : player.global_position.x,
		"y" : player.global_position.y,
		"hp" : player.hp,
		"max_hp" : player.max_hp,
		"right_dash" : player.dash,
		"double_jump" : player.double_jump,
		"ground_slam" : player.ground_slam,
		"morph_roll" : player.morph_roll,
		"discovered_areas" : discovered_areas, 
		"persistent_data" : persistent_data
	}
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.WRITE )
	save_file.store_line( JSON.stringify(save_data) )
	pass
	
func load_game( slot : int ) -> void:
	
	if not FileAccess.file_exists( get_file_name( current_slot ) ):
		return
	
	current_slot = slot
	
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.READ )
	save_data = JSON.parse_string( save_file.get_line() )
	
	persistent_data = save_data.get( "persistent_data", {} )
	discovered_areas = save_data.get( "discovered_areas", {} )
	var scene_path : String = save_data.get( "scene_path", "uid://b5beoshdgyky1" )
	await SceneManager.transition_scene( scene_path, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready
	setup_player()
	pass

func setup_player() -> void:
	var player : Player = null
	while not player:
		player = get_tree().get_first_node_in_group( "Player" )
		await get_tree().process_frame
	
	player.max_hp = save_data.get( "max_hp", 20 )
	player.hp = save_data.get( "hp", 20 )
	
	player.apply_saved_abilities()
	#player.dash = save_data.get( "right_dash", false )
	#player.double_jump = save_data.get( "double_jump", false )
	#player.ground_slam = save_data.get( "ground_slam", false )
	#player.morph_roll = save_data.get( "morph_roll", false )
	
	player.global_position = Vector2(
			save_data.get( "x", 0 ),
			save_data.get( "y", 0 )
		)

	pass

func get_file_name( slot : int ) -> String:
	
	return "user://" + SLOTS[ slot ] + ".sav"
	
func save_file_exists( slot : int ) -> bool:
	return FileAccess.file_exists( get_file_name( slot ) )
